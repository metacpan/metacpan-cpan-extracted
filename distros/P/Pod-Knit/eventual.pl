use Pod::Eventual::Simple;

package Foo {
use Pod::Simple::PullParser;

use Moo;

extends 'Pod::Simple::PullParser';

use experimental 'signatures';

my @levels = (
    [], 
    [ qw/ B L / ],
    [qw/ Para Verbatim /],
    [qw/ item-text /],
    [qw/ over-text /],
    ( map { ["head$_"] } reverse 1..4),
    [ 'Document' ],
);

my %commands = (
    'Document' => { },
    head1 => { section => 1, },
    'item-text' => { section => 1, },
);

use experimental qw/ postderef /;

sub add_directive($new, $alias) {
    $commands{$new}  = { $commands{$alias}->%*, alias => $alias };

    use List::AllUtils qw/ first /;

    push( (first { 
                $alias ~~ @$_
            } @levels)->@*, $new );

}

add_directive(synopsis => 'head1');

has xml => (
    is => 'ro',
    lazy => 1,
    default => sub {
        use XML::Writer;
        use XML::Writer::Simpler;
        XML::Writer::Simpler->new( OUTPUT => 'self' );
    },
);

sub run($self) {
    $self->parse_pod;
    $self->xml->to_string;
}

sub node_level($token) {
    use List::AllUtils qw/ first_index /;
    use experimental 'smartmatch';

    my $i = first_index { $token ~~ @$_ } @levels;
    warn $i;
    return $i;
}

sub parse_pod($self, $end_cond = undef ) {
    while( my $token = $self->get_token ) {
        if( $end_cond and $end_cond->($token) ) {
            $self->unget_token($token);
            return;
        }

       if( $token->is_text) {
           $self->xml->characters( $token->text );
           next;
       }

       my $tag = $token->tagname;
    
       next if $token->is_end;

       use experimental 'postderef';

       my $normalized = $tag;
       if( my $alias = $commands{$tag}{alias} ) {
           $normalized = $alias;
           $token->attr( class => $tag );
       }

       $self->xml->tag( $commands{$tag}{section} ? 'section' : $normalized, [ map { s/~//gr } $token->attr_hash->%* ], sub {
       if( $commands{$tag}{section} ) {
        $self->xml->tag( $normalized, sub { 
            $self->parse_pod( sub($tag) { $tag->is_end and $tag->is_tag( 
                $token->tagname
            ) } );
        });


        my $level = node_level($tag);

        $self->parse_pod( sub($tag) { 
                $tag->is_start and 
                $level <= node_level( $tag->tagname )
        } );

        }
        else {
            $self->parse_pod( sub($tag) { $tag->is_end and $tag->is_tag( 
                    $token->tagname
            ) } );
        }
        });


    }
}

}

my $parser = Foo->new;
my $document_source = join '', <DATA>;
$parser->accept_directive_as_processed(qw/ synopsis /);
$parser->set_source( \$document_source );
print $parser->run;
exit;

my $data = Pod::Eventual::Simple->read_string(
    join '', <DATA>
);

use DDP;




my %command_alias = (
    synopsis =>  'head1', 
);

$data = aggregate($data);
p $data;

use 5.20.0;
use experimental 'signatures';

sub node_level($node) {
    if( $node->{command} =~ /head(\d+)/ ) {
        return 6 - $1;
    }
    return 1 if $node->{command} eq 'over';
    return 1 if $node->{command} eq 'back';
    return 0;
}

sub aggregate($data,$processed=undef) {
    $processed ||= [];

    my @data = @$data;
    my $first = shift @data or return $processed;

    my $level = node_level($first);

    use List::MoreUtils qw/ before /;

    my @inner = before { node_level($_) >= $level  }  @data;

    $first->{inner} = __SUB__->(\@inner) if @inner;

    splice @data, 0, scalar @inner;

    @_ = ( \@data, [ @$processed, $first ] );

    goto __SUB__;
}


__DATA__

blah blah blah

=synopsis

Stuff that is B<quite> important.

    and now some verbatim 
    stuff


=head1 thing

Blah

=over

=item First

yadah some L<linkie|http://blah.org>

=item Second

yadah2

=back

=head1 other thing

Blah blah blah




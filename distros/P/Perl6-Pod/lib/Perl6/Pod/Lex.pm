#===============================================================================
#
#  DESCRIPTION:  Make objectx from syntax tree
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::Lex::RawText;
use base 'Perl6::Pod::Lex::Block';
our $VERSION = '0.01';

package Perl6::Pod::Lex::Text;
use base 'Perl6::Pod::Lex::RawText';
our $VERSION = '0.01';

package Perl6::Pod::Lex;
our $VERSION = '0.01';
use strict;
use warnings;
sub new {
    my $class = shift;
    my $self = bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
    $self;
}
use v5.10;
use Perl6::Pod::Utl;

sub make_block {
    my $self = shift;
    my %ref  = @_;
    #save original bloack name
    my $name = $ref{src_name} = $ref{name};
    #for items1,2  and heads
    if ($name =~ /(item|head)(\d+)/ ) {
        $name = $ref{name} = $1;
        $ref{level} = $2
    }   

    my $childs = $ref{content} || [];
    my $vmargin = length( $ref{spaces} // '' );

    #is first para if item|defn ?
    my $is_first = 1;

    foreach my $node (@$childs) {
        if ( $node->{type} eq 'block' ) {
            $node = $self->make_block(%$node);

        }
        elsif ( $node->{type} =~ /text|raw/ ) {
            my $type = $node->{type};
            if ( $type eq 'text' ) {
                $node = Perl6::Pod::Lex::Text->new(%$node);
            }
            else {
                $node = Perl6::Pod::Lex::RawText->new(%$node);
            }

        }
        else {
       
        $node = $self->make_block(%$node);
        
        }
        next
          unless UNIVERSAL::isa( $node, 'Perl6::Pod::Lex::Text' )
              || UNIVERSAL::isa( $node, 'Perl6::Pod::Lex::RawText' );
        my $content = delete $node->{''};
        
        #remove virual margin
        $content = Perl6::Pod::Utl::strip_vmargin( $vmargin, $content );

        #skip first text block for item| defn
        if ( $name =~ 'item|defn' and $is_first ) {

            #always ordinary text
            $content =~ s/^\s+//;
            $node = $content;
            $is_first=0;
            next;

        }

        #convert paragraph's to blocks
        my $is_implicit_code_and_para_blocks =
         $ref{force_implicit_code_and_para_blocks}
      || $name =~ /(pod|item|defn|nested|finish|\U $name\E )/x;
        if ($is_implicit_code_and_para_blocks) {
            my $block_name = $content =~ /^\s+/ ? 'code' : 'para';
            $node = Perl6::Pod::Lex::Block->new(
                %$node,
                name    => $block_name,
                srctype => 'implicit',
                content => [$content]
            );

        }
        else {
            if ( $name eq 'para' ) {

                #para blocks always
                # ordinary text
                $content =~ s/^\s+//;
            }
            $node = $content;
        }
    }
    return Perl6::Pod::Lex::Block->new(%ref);

}

sub process_file {
    my $self = shift;
    my $ref  = shift;
    $ref->{force_implicit_code_and_para_blocks} = 1;
    my $block = $self->make_block( %$ref, name => 'File' );
    unless ($self->{default_pod} ) {
       # filter all implicit blocks
       my @result = ();
       foreach my $node (@ { $block->childs}) {
            my $type = $node->{srctype} || 'UNKNOWN';
            push @result, $node unless $type eq 'implicit';       
       }
    $block->childs(\@result)
    }
    return $block->childs;
}

sub make_tree {
    my $self   = shift;
    my $tree   = shift;
    my $type   = $tree->{type};
    my $method = "process_" . $type;
    return $self->$method($tree);
}
1;


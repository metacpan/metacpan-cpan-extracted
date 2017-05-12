package Template::Teeny;

our $VERSION = '0.00_002';

our $CODE_START = <<'END';
sub {
    my ($stash_a, $out) = @_;
END

our $CODE_END = <<'END';
}
END

use Moose;

has include_path => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    required => 1,
    lazy => 1,
    default => sub { [qw(.)] },
);

my ($START,$END) = map { qr{\Q$_\E} } qw([% %]);
my $DECLARATION = qr{$START (?:.+?) $END}x;
my $TEXT = qr{
    (?:\A|(?<=$END))    # Start matching from the start of the file or end of a declaration
        .*?                 # everything in between
    (?:\Z|(?=$START))   # Finish at the end of the file or start of another declaration
}msx;
my $CHUNKS = qr{
    ($TEXT)?
    ($DECLARATION)?
}msx;

my $IDENT = qr{
    [a-z][a-z0-9_]+ # any alphanumeric characters and underscores, but must start
                    # with a letter; everything must be lower case
}x;

my $SECTION = qr{
    SECTION \s+ ($IDENT)
}x;
my $INCLUDE = qr{
    INCLUDE \s+ ["']? ([^"']+) ["']?
}x;

my $VARS = qr{
    (?: \s* \| \s* )?
    ( $IDENT )
}x;

my $DIRECTIVE = qr{
    $START
        \s*?
        (END
            | $SECTION
            | $INCLUDE
            | [a-z0-9_\s\|]+
        )
        \s*?
    $END
}x;

sub parse {
    my ($self, $tpl) = @_;
    my (@chunks) = grep { defined $_ && $_ } ($tpl =~ m{$CHUNKS}g);
  
    my @AST;
    while(my $chunk = shift @chunks){
        if(my ($dir) = $chunk =~ $DIRECTIVE){
            if(my ($name) = $dir =~ $SECTION){
                $name =~ s/['"]//g;
                push @AST, [SECTION => $name];
            }elsif(my ($nm) = $dir =~ $INCLUDE){
                $nm =~ s/['"]//g;
                push @AST, [INCLUDE => $nm];
            }elsif($dir =~ m{END}){
                push @AST, ['END'];
            }elsif(my (@items) = $dir =~ m{$VARS}g){
                push @AST, [VARS => [@items]];
            }
        } else {
            push @AST, [TEXT => $chunk];
        }
    }

    return [@AST];
}

# XXX - Tests should be added for this
sub _optimize {
    my (undef, $AST) = @_;

    my @OPT;

    while (my $item = shift @$AST){
        my ($type, $val) = @$item;

        if($type eq 'TEXT' || $type eq 'VARS'){
            my @long = ($item);
           
            # lets see what the next statement is to see if we can concat
            while( $AST->[0] && ($AST->[0][0] eq 'TEXT' || $AST->[0][0] eq 'VARS') ){

                # move this 
                push @long, shift @$AST;
            }

            # if there's only one statement, not much point in concat-ing.
            if(@long > 1){
                @long = [ CONCAT => [@long] ];
            }

            push @OPT, @long;
        } else {
            push @OPT, $item;
        }
    }

    return [@OPT];
}

sub compile {
    my ($self, $AST) = @_;

    my $current_level ||= 0;

    my $code = '';
    if(!$current_level){
        $code .= $CODE_START;
        $code .= 'my $output ;' ;

    }

    my @names = ('a'..'z');

    while(my $item = shift @$AST){
        my ($type, $val) = @$item;

        if($type eq 'TEXT'){
            $val =~ s{'}{\\'};
            $code .= q{  $output .= '}.$val.qq{';\n};

        } elsif ($type eq 'VARS') {
            $code .= q{  $output .=  $stash_} 
                    . $names[$current_level] 
                    . q{->get(qw(} 
                    . join(' ', @$val)
                    . qq{));\n};

        } elsif ($type eq 'END'){ 
            $code .= "  }\n";
            $current_level--;

        } elsif ($type eq 'SECTION') {
            my $old = $names[$current_level];
            my $new = $names[++$current_level];

            $code .= "  for my \$stash_$new ( \$stash_$old\->sections('$val') ) {\n";
        } elsif ($type eq 'CONCAT') {
            my ($t,$v) = @{ shift @$val };

            if($t eq 'TEXT'){
                $v =~ s{'}{\\'};
                $code .= q{  $output .=  '}.$v.qq{'\n};
            }elsif($t eq 'VARS'){
                $code .= q{  $output .=  $stash_} 
                        . $names[$current_level] 
                        . q{->get(qw(} 
                        . join(' ', @$v)
                        . qq{))};
            }

            for my $concat (@$val){
                my ($ct,$cv) = @$concat;
                
                if($ct eq 'TEXT'){
                    $cv =~ s{'}{\\'};
                    $code .= qq{\n    . '}.$cv.q{'};
                }elsif($ct eq 'VARS'){
                    $code .= qq{\n    . \$stash_} 
                            . $names[$current_level] 
                            . q{->get(qw(} 
                            . join(' ', @$cv)
                            . qq{))};
                }
            }

            $code .= ";\n";

        } else {
            die "Could not understand type '$type'";
        }
    }

    if(!$current_level){

        $code .= <<'CODE' ;
	if ( $out ) {
		print {$out} $output ;
	}
	else {
		return $output ;
	}
CODE

        $code .= $CODE_END;
    }

#print $code ;

    return $code;
}


my $compiled_tpls = {};
sub process {
    my ($self, $tpl, $stash, $fh) = @_;

    if(!$fh){
#        $fh = \*STDOUT;
    }

    my $tpl_str = '';
    
    # XXX - This should really take the full name
    my $compile = $compiled_tpls->{ $tpl } ||= do {
        if(!ref $tpl){
            $tpl_str .= $self->_get_tpl_str($tpl);
        }

        my $AST = $self->parse($tpl_str);
        $AST = $self->_optimize($AST);
        my $code_str = $self->compile($AST);

        my $coderef = eval($code_str) or die "Could not compile template: $@";
    };
    return $compile->($stash, $fh);

#    return;
}

sub _get_tpl_str {
    my ($self, $tpl) = @_;

    my $tpl_str = '';
    my @dirs_to_try = @{ $self->include_path };

    my $file;
    while(my $dir = shift @dirs_to_try){
        my $tmp = $dir . '/' . $tpl;
        if(-e $tmp){
            $file = $tmp;
            last;
        }
    }
    
    die "Could not find $tpl" if(!$file);

    open my $fh, $file or die "Could not open '$file': $!";
    $tpl_str .= do { local $/; <$fh>; };
    close $fh or die "Could not close '$file': $!";

    return $tpl_str;
}

1;

__END__

=head1 NAME

Template::Teeny - Teeny-weeny templating system

=head1 VERSION

Version 0.00_002

=head1 SYNOPSIS

    use Template::Teeny;

    my $tt = Template::Teeny->new({
        include_path => ['foo/templates']    
    });

    my $stash = Template::Teeny->new({
        a => 1, b => 2, c => 3
    });

    $stash->add_section('items', $item1);
    $stash->add_section('items', $item2);

    $tt->process('foo.html', $stash);

=head1 DESCRIPTION

Template::Teeny is a more perlish implementation of the concepts in googles
ctemplate library. The template syntax does not have any conditionals or
looping directly.

A basic template would look like so:

    Hi [% name %],

    You ordered the following:
    [% SECTION items %]
        Title: [% title %]
        Date: [% date %]
        Identifier: [% id | uc %]

        [% INCLUDE 'full_description.txt' %]

    [% END %]

When processing the template, we supply a stash object which contains all the
variables for processing.

=over

=item [% name %]

This pulls variables directly from the current stash.

=item [% SECTION items %]

The current stash may have other stashes associated with it by name

  $stash->add_section('foo', $other_stash);

This would then would run the SECTION block with $other_stash as its
stash.

=item [% id | uc %]

TODO - This still need implemented

This is a variable which will be run through the filter 'uc' before being
output. These filters can be chained.

=item [% INCLUDE 'full_description.txt %]

TODO - This still need implemented

This will pull in the template from the file 'full_description.txt'

=item [% END %]

This simply marks the end of a section.

=back

=head2 Why yet another templating system?

There are a multitude of different templating systems out there, so what
makes this one so different? The aim of this system is to move all business
logic out of the templates and back into the code where it belongs. This
means that the templating becomes very lightweight and fast.

The Google CTemplate library is a great example of this approach, however I
had attempted to bind this to perl and unfortunately was unable to make it
work correctly enough for production use.

I aim to have a fully working perl version and further down the line
implement a full C version with XS bindings. Other than that, I wanted to
have a try at writing parsers/compilers for fun.

=head1 METHODS

=head2 process

    $tt->process('foo/bar/baz.tpl', $stash);

This method takes a template file name and a stash object to be processed.

=head2 parse

    $tt->parse('[% foo %]');

Takes a string representing the template. Returns an AST.

=head2 compile

    my $eval_string = $tt->compile( ...<AST>... );

This method take a generated AST and translates it into an eval-able
string of perl code.

=head2 include_path

This is an accessor for the template include path.

=head1 AUTHOR

Scott McWhirter, C<< <konobi at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Teeny

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Teeny>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Teeny>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Teeny>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Teeny>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Scott McWhirter, all rights reserved.

This program is released under the following license: BSD

=cut

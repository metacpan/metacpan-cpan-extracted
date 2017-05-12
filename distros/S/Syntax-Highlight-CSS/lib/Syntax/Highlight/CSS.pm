package Syntax::Highlight::CSS;

use warnings;
use strict;

our $VERSION = '0.0102';

# # # 
# # # 
# # #
#
#
#
#    WARNING!!!! The code presented below is NOT suitable for persons
#    with heart deseases and mental disorders,
#  
#    LOOK AT IT AT YOUR OWN RISK!!!!
#
#
#
# # # 
# # # 
# # # 

sub new {
    my $class = shift;
    my %args = @_;
    $args{ +lc } = delete $args{$_}
        for keys %args;

    my $self = bless {}, $class;

    $self->_pre( defined $args{pre} ? $args{pre} : 1 );
    $self->_line_numbers( defined $args{nnn} ? $args{nnn} : 0 );
    
    return $self;
}

sub parse {
    my ( $self, $input ) = @_;

    $input = ''
        unless defined $input;

    my $text = $self->_parse_css( $input );

    if ( $self->_line_numbers ) {
        $text = $self->_add_line_numbers( $text );
    }

    if ( $self->_pre ) {
        $text = '<pre class="css-code">' . $text . '</pre>';
    }

    return $text;
}

sub _add_line_numbers {
    my ( $self, $text ) = @_;
    my $line = 0;
    $text =~ s|^|
        '<span class="ch-l">'
        . sprintf('%3d', $line++)
        . '</span> '
    |gem;

    return $text;
}

sub _parse_css {
    my $self = shift;

    $_ = shift; # input CSS

    # yes YES, <SYNTAX<>blah blah is really retarded.. but oh well
    my @quoted;
    s/("  .+?  (?<!\\)" )/
        push @quoted, $1;
        '<SYNTAX<>HIGHLIGHT<>PARSER<>QUOTED<>' . $#quoted . '>'
    /gsex;

    my @comments;
    s{(/\* .+? \*/)}{
        push @comments, $1;
        '<SYNTAX<>HIGHLIGHT<>PARSER<>COMMENT<>' . $#comments . '>'
    }gsex;

    my @rulesets;
    s/(?<={)([^{}]+)(?=})/
        push @rulesets, $1;
        '<SYNTAX<>HIGHLIGHT<>PARSER<>RULESET<>' . $#rulesets . '>';
    /gex;

    # parse selectors
    s# (?:\A | (?<=[{};]) )
        (\s*)
        ( [^;{}]+? )
        (\s*)
      (?=[{;])#
      $1
      . $self->_parse_sel($2)
      . $3
    #gex;
    
    # properties/values;
    for my $ruleset ( @rulesets ) {
        $ruleset =~ s#(?: \A | (?<=[;]) )
            (\s*) ([a-zA-Z-]+) (\s*) : (\s*) (.+?) (\s*)
            (?=[;}]|\z)#$1<span class="ch-p">$2</span>$3:$4<span class="ch-v">$5</span>$6#gsx;
    }

    s#<SYNTAX<>HIGHLIGHT<>PARSER<>RULESET<>(\d+)>#$rulesets[$1]#g;

    s#<span\sclass="ch-sel">
        (<SYNTAX<>HIGHLIGHT<>PARSER<>COMMENT<>\d+>)
        (\s*)#$1$2<span class="ch-sel">#xg;

    s{(<span class="ch-sel">)((?:(?!</span>).)+)}{
        my ($one, $two) = ($1, $2);
        $two =~ /(.+?)(\s*<SYNTAX<>HIGHLIGHT<>PARSER<>COMMENT<>\d>\s*)(.+)/
        ? qq|$one$1</span>$2<span class="ch-sel">$3|
        : "$one$two";
    }ges;

    s#<SYNTAX<>HIGHLIGHT<>PARSER<>COMMENT<>(\d+)>#<span class="ch-com">$comments[$1]</span>#g;

    s#<SYNTAX<>HIGHLIGHT<>PARSER<>QUOTED<>(\d+)>#$quoted[$1]#g;

    return $_;
}

sub _parse_sel {
    my $self = shift;
    $_ = shift; # selector

    unless ( s#
        ( \@(?:media|charset|import) )
        (\s+)
        ([^;{]+?)
        (\s*)
        \z#<span class="ch-at">$1$2$3</span>$4#gix
    ) {
        s{(:{1,2} \s*)(\S+)}{<span class="ch-ps">$1$2</span>}gx;
        s#(\s*)(.+)(\s*)#$1<span class="ch-sel">$2</span>$3#sg;
    }

    return $_;
}

sub _pre {
    my $self = shift;
    if ( @_ ) {
        $self->{PRE} = shift;
    }
    return $self->{PRE};
}

sub _line_numbers {
    my $self = shift;
    if ( @_ ) {
        $self->{LINE_NUMBERS} = shift;
    }
    return $self->{LINE_NUMBERS};
}

1;
__END__

=encoding utf8

=head1 NAME

Syntax::Highlight::CSS - highlight CSS syntax

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Syntax::Highlight::CSS;

    my $p = Syntax::Highlight::CSS->new;

    print $p->parse('a:hover { font-weight: bold; }');

=head1 DESCRIPTION

The module takes CSS code and wraps different pieces of syntax into
HTML C<< <span> >> elements with appropriate class names which enables
you to highlight syntax of the snippet using.. CSS ^_^

I honestly suggest you to try L<Syntax::Highlight::Engine::Kate::CSS>
first and see if it does what you want. Personally, I found that it
wasn't interpeting C<@media> blocks properly, but I could've been
DoingItWrong. In constrast, with L<Syntax::Highlight::Engine::Kate::CSS>
you will be able to differentiate between B<more> syntax elements than
with this module.

=head1 CONSTRUCTOR

=head2 C<new>

    my $p = Syntax::Highlight::CSS->new;

    my $p = Syntax::Highlight::CSS->new(
        pre => 0,
        nnn => 1,
    );

Constructs and returns a brand new Syntax::Highlight::CSS object ready
to be exploited. Takes two I<optional> arguments which are passed in
a arg/value fashion. Possible arguments are as follows:

=head3 C<pre>

    my $p = Syntax::Highlight::CSS->new( pre => 0, );

B<Optional>. Takes either true or false values.
When set to a true value, the C<parse()> method will wrap
the result into HTML C<< <pre class="css-code"> >> element. Otherwise,
no C<< <pre> >>s will be inserted. B<Defaults to:> C<1>

=head3 C<nnn>

    my $p = Syntax::Highlight::CSS->new( nnn => 1, );

B<Optional>. Takes either true or false values. When set to a true
value will ask the highlighter to insert line numbers in the resulting
code. B<Defaults to:> C<0>

=head1 METHODS

=head2 C<parse>

    my $highlighted_text = $p->parse('a:hover { font-weight: bold; }');

Takes one mandatory argument which is a string of CSS code to highlight.
Returns the highlighted code.

=head1 COLORING YOUR HIGHLIGHTED CSS

To actually set any colors on your "highlighted" CSS code returned
from the C<parse()> method you need to style all the generated C<< <spans>
>> with CSS; a sample CSS code to do that is shown in the section below.
Each C<< <span> >> will have the following class names/meanings:

=over 6

=item *

C<css-code> - this is actually the class name that will be set on the
C<< <pre>> >> element if you have that option turned on.

=item *

C<ch-sel> - Selectors

=item *

C<ch-com> - Comments

=item *

C<ch-p> - Properties

=item *

C<ch-v> - Values

=item *

C<ch-ps> - Pseudo-selectors and pseudo-elements

=item *

C<ch-at> - At-rules

=item *

C<ch-n> - The line numbers inserted by C<parse()> method if that option is
turned on

=back


=head1 SAMPLE STYLE SHEET FOR COLORING HIGHLIGHTED CODE

    .css-code {
        font-family: 'DejaVu Sans Mono Book', monospace;
        color: #000;
        background: #fff;
    }
        .ch-sel, .ch-p, .ch-v, .ch-ps, .ch-at {
            font-weight: bold;
        }
        .ch-sel { color: #007; } /* Selectors */
        .ch-com {                /* Comments */
            font-style: italic;
            color: #777;
        }
        .ch-p {                  /* Properties */
            font-weight: bold;
            color: #000;
        }
        .ch-v {                  /* Values */
            font-weight: bold;
            color: #880;
        }
        .ch-ps {                /* Pseudo-selectors and Pseudo-elements */
            font-weight: bold;
            color: #11F;
        }
        .ch-at {                /* At-rules */
            font-weight: bold;
            color: #955;
        }
        .ch-n {
            color: #888;
        }

=head1 SEE ALSO

L<Syntax::Highlight::Engine::Kate::CSS>, L<CSS::Parse>,
L<http://w3.org/Style/CSS/>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

There are likely to be many bugs in this module. It was tested only
with common CSS codes and definitely not the entire CSS spec.

Please report any bugs or feature requests to C<bug-syntax-highlight-css at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Syntax-Highlight-CSS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Syntax::Highlight::CSS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Syntax-Highlight-CSS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Syntax-Highlight-CSS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Syntax-Highlight-CSS>

=item * Search CPAN

L<http://search.cpan.org/dist/Syntax-Highlight-CSS>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


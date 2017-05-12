package Template::Plugin::GoogleLaTeX;

use strict; use warnings;
our $VERSION = '0.03';

use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

use URI::Escape;
use constant API_URL => 'http://chart.apis.google.com/chart?cht=tx';

use constant IMG_ATTRS => [ qw(
    src id name class style alt title longdesc align width height border
    hspace vspace usemap ismap lang dir onclick ondblclick onmousedown
    onmouseup onmouseover onmousemove onmouseout onkeypress onkeydown
    onkeyup
) ];

sub init {
    my $self = shift;
    $self->{ _DYNAMIC} = 1;

    # first arg can specify filter name
    $self->install_filter($self->{ _ARGS }->[0] || 'latex');

    return $self;
}

sub filter {
    my ($self, $text, $args, $config) = @_;

    my %config = %{ $self->merge_config($config) };
    my %qs;

    $qs{chl} = uri_escape( $text );

    if ( defined (my $h = $config{height} ) ) {
        if ( defined ( my $w = $config{width} ) ) {
            $qs{chs} ="${h}x${w}"
        }
        else {
            $qs{chs} = $h;
        }
    }

    if ( defined ( my $fill = $config{fill} ) ) {
        $qs{chf} = $fill;
    }

    if ( defined ( my $color = $config{color} ) ) {
        $qs{chco} = $color;
    }

    $config{src} = join('&amp;',
        $self->API_URL,
        (
            map sprintf(q{%s=%s}, $_, $qs{$_}), keys %qs
        ),
    );

    my @attrs = grep defined( $config{$_} ), @{ $self->IMG_ATTRS };

    my $out = join(' ',
        '<img',
        (
            map sprintf(q{%s="%s"}, $_, $config{$_}), @attrs
        ),
    );
    $out .= $config{xhtml} ? '/>' : '>';
    return $out;

}

"Template::Plugin::GoogleLaTeX"
__END__

=head1 NAME

Template::Plugin::GoogleLaTeX - Render LaTeX equations using Google's
Chart API

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Generates an image tag to render the given LaTeX equation using Google's
chart API. See
http://code.google.com/apis/chart/docs/gallery/formulas.html.

    [%- USE GoogleLaTeX -%]
    <p>[%- FILTER latex
        alt = '[ Utility maximization ]',
        title = 'Utility maximization',
        class = 'display',
        style = 'border:3px outset #dde; padding:16px;',
        id = 'umax',
        height = 100,
        color = 'fa1111',
        fill = 'bg,lg,20,ddddee,1,1111ff,0'
    -%]
    \begin{eqnarray}
    \max U(x,y) & = & \ln x + \ln y \\
    \mathrm{s.t.} & & p_xx + p_yy = I \\
    & & x \geq 0, y \geq 0
    \end{eqnarray}
    [%- END -%]
    </p>

=head1 METHODS

=head2 init

See http://search.cpan.org/perldoc/Template::Plugin::Filter#EXAMPLE

=head2 filter

See http://search.cpan.org/perldoc/Template::Plugin::Filter#EXAMPLE

=head1 AUTHOR

A. Sinan Unur, C<< <nanis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-plugin-googlelatex at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-GoogleLaTeX>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::GoogleLaTeX

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-GoogleLaTeX>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Plugin-GoogleLaTeX>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Plugin-GoogleLaTeX>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Plugin-GoogleLaTeX/>

=back

=head1 ACKNOWLEDGEMENTS

Thank you Andy Wardley and all contributors to Template-Toolkit.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 A. Sinan Unur.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


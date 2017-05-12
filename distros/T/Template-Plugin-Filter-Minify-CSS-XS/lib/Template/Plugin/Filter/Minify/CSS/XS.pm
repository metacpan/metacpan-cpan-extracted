package Template::Plugin::Filter::Minify::CSS::XS;
$Template::Plugin::Filter::Minify::CSS::XS::VERSION = '0.96';
# ABSTRACT: CSS::Minifier::XS filter for Template Toolkit

use 5.006;
use strict;
use base 'Template::Plugin::Filter';
use CSS::Minifier::XS;

sub init {
    my $self = shift;

    $self->install_filter('minify_css');

    return $self;
}

sub filter {
    my ($self, $text) = @_;

    $text = CSS::Minifier::XS::minify($text);

    return $text;
}

1;

__END__

=pod

=head1 NAME

Template::Plugin::Filter::Minify::CSS::XS - CSS::Minifier::XS filter for Template Toolkit

=head1 VERSION

version 0.96

=head1 SYNOPSIS

  [% USE Filter.Minify.CSS.XS %]

  [% FILTER minify_css %]
    .foo {
        color: #aabbcc;
        margin: 0 10px 0 10px;
    }
  [% END %]

=head1 DESCRIPTION

This module is a Template Toolkit filter, which uses CSS::Minifier::XS to minify
css code from filtered content during template processing.

=for Pod::Coverage init
filter

=head1 SEE ALSO

L<CSS::Minifier::XS>, L<Template::Plugin::Filter>, L<Template>

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/template-plugin-filter-minify-css-xs>
and may be cloned from L<git://github.com/mschout/template-plugin-filter-minify-css-xs.git>

=head1 BUGS

Please report any bugs or feature requests to bug-template-plugin-filter-minify-css-xs@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Template-Plugin-Filter-Minify-CSS-XS

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

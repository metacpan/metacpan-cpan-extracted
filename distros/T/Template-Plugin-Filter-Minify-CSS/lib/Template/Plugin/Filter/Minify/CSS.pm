package Template::Plugin::Filter::Minify::CSS;
# ABSTRACT: CSS::Minifier filter for Template Toolkit
$Template::Plugin::Filter::Minify::CSS::VERSION = '0.95';
use 5.006;
use strict;
use base 'Template::Plugin::Filter';
use CSS::Minifier;


sub init {
    my $self = shift;

    $self->install_filter('minify_css');

    return $self;
}

sub filter {
    my ($self, $text) = @_;

    $text = CSS::Minifier::minify(input => $text);

    return $text;
}

1;

__END__

=pod

=head1 NAME

Template::Plugin::Filter::Minify::CSS - CSS::Minifier filter for Template Toolkit

=head1 VERSION

version 0.95

=head1 SYNOPSIS

  [% USE Filter.Minify.CSS %]

  [% FILTER minify_css %]
    .foo {
        color: #aabbcc;
        margin: 0 10px 0 10px;
    }
  [% END %]

=head1 DESCRIPTION

This module is a Template Toolkit filter, which uses CSS::Minifier to minify
css code from filtered content during template processing.

=for Pod::Coverage init
filter

=head1 SEE ALSO

L<CSS::Minifier>, L<Template::Plugin::Filter>, L<Template>

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/template-plugin-filter-minify-css>
and may be cloned from L<git://github.com/mschout/template-plugin-filter-minify-css.git>

=head1 BUGS

Please report any bugs or feature requests to bug-template-plugin-filter-minify-css@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Template-Plugin-Filter-Minify-CSS

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Template::Plugin::Filter::Minify::JavaScript;
$Template::Plugin::Filter::Minify::JavaScript::VERSION = '0.94';
# ABSTRACT: JavaScript::Minifier filter for Template Toolkit

use 5.006;
use strict;
use base 'Template::Plugin::Filter';
use JavaScript::Minifier;

sub init {
    my $self = shift;

    $self->install_filter('minify_js');

    return $self;
}

sub filter {
    my ($self, $text) = @_;

    $text = JavaScript::Minifier::minify(input => $text);

    return $text;
}

1;

__END__

=pod

=head1 NAME

Template::Plugin::Filter::Minify::JavaScript - JavaScript::Minifier filter for Template Toolkit

=head1 VERSION

version 0.94

=head1 SYNOPSIS

  [% USE Filter.Minify.JavaScript %]

  [% FILTER minify_js %]
    $(document).ready(
        function() {
            $('body').append('<div>Hello World!</div>');
        }
    );
  [% END %]

=head1 DESCRIPTION

This module is a Template Toolkit filter, which uses JavaScript::Minifier to
compress javascript code from filtered content during template processing.

=for Pod::Coverage init
filter

=head1 SEE ALSO

L<JavaScript::Minifier>, L<Template::Plugin::Filter>, L<Template>

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/template-plugin-filter-minify-javascript>
and may be cloned from L<git://github.com/mschout/template-plugin-filter-minify-javascript.git>

=head1 BUGS

Please report any bugs or feature requests to bug-template-plugin-filter-minify-javascript@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Template-Plugin-Filter-Minify-JavaScript

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Mojolicious::Plugin::Text::Minify;

# ABSTRACT: remove HTML indentation on the fly

use v5.16; # Mojolicious minimum version

use Mojo::Base 'Mojolicious::Plugin';

use Text::Minify::XS v0.6.2 ();

our $VERSION = 'v0.2.4';

sub register {
    my ($self, $app, $conf) = @_;
    $app->hook( after_render => sub {
        my ($c, $output, $format) = @_;

        return if $c->stash->{'mojox.no-minify'};

        if ($format eq "html") {
            $$output = Text::Minify::XS::minify( $$output );
        }
    });

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Text::Minify - remove HTML indentation on the fly

=head1 VERSION

version v0.2.4

=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin "Text::Minify";

  # Mojolicious
  $app->plugin("Text::Minify");

=head1 DESCRIPTION

This plugin uses L<Text::Minify::XS> to remove indentation and
trailing whitespace from HTML content.

If the C<mojox.no-minify> key in the stash is set to a true value,
then the result will not be minified.

You can also use of the minifier conditional on the application mode

  plugin 'Text::Minify' if app->mode eq "production";

Note that this is naive minifier which does not understand markup, so
newlines will still be collapsed in HTML elements where whitespace is
meaningful, e.g. C<pre> or C<textarea>.

=head1 SUPPORT FOR OLDER PERL VERSIONS

This module requires Perl v5.16, which is the same minimum version that the current version of L<Mojolicious> requires.

Future releases may only support Perl versions released in the last ten years.

=head1 SEE ALSO

L<Text::Minify::XS>

L<Plack::Middleware::Text::Minify>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Mojolicious-Plugin-Text-Minify>
and may be cloned from L<git://github.com/robrwo/Mojolicious-Plugin-Text-Minify.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Mojolicious-Plugin-Text-Minify/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021-2023 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

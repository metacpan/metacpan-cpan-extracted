package Mojolicious::Plugin::NoReferrer;

# ABSTRACT: add meta tag to HTML output to define a referrer policy

use Mojo::Base 'Mojolicious::Plugin';

use Carp qw(croak);

our $VERSION = '0.02';

sub register {
    my ($self, $app, $config) = @_;

    my $value = $config->{content} // 'no-referrer';

    if ( $value ne 'no-referrer' && $value ne 'same-origin' ) {
        croak 'invalid value: ' . $value;
    }

    $app->hook(
        after_render => sub {
            my ($c, $content, $format) = @_;

            return if !$format;
            return if $format ne 'html' && $format ne 'css';

            $$content =~ s{<head>\K}{<meta name="referrer" content="$value">};
        }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::NoReferrer - add meta tag to HTML output to define a referrer policy

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('NoReferrer');

  # Mojolicious::Lite
  plugin 'NoReferrer';

  # to allow sending referrer information to the origin
  plugin 'NoReferrer' => { content => 'same-origin' };

=head1 DESCRIPTION

L<Mojolicious::Plugin::NoReferrer> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::NoReferrer> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head2 HOOKS INSTALLED

This plugin adds one C<after_render> hook to add the <meta> tag.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

package MojoX::Renderer::JSON::XS;
use 5.010;
use strict;
use warnings;
our $VERSION = "0.07";

use JSON::XS;
use Mojo::Exception ();
use Mojo::Util qw(monkey_patch);

monkey_patch 'Mojo::Exception', TO_JSON => \&Mojo::Exception::to_string;

our $JSON = JSON::XS->new->utf8->convert_blessed;

sub build {
    sub { ${$_[2]} = $JSON->encode($_[3]{json}); };
}

1;

__END__

=encoding utf-8

=head1 NAME

MojoX::Renderer::JSON::XS - Fast JSON::XS handler for Mojolicious::Renderer

=head1 SYNOPSIS

    sub setup {
        my $app = shift;

        # Via plugin
        $app->plugin('JSON::XS');

        # Or manually
        $app->renderer->add_handler(
            json => MojoX::Renderer::JSON::XS->build,
        );
    }

=head1 DESCRIPTION

MojoX::Renderer::JSON::XS provides fast L<JSON::XS> renderer to L<Mojolicious> applications.

=head1 METHODS

=head2 build

Returns a handler for C<Mojolicious::Renderer> that calls C<JSON::XS::encode_json>.

=head1 SEE ALSO

L<JSON::XS>
L<Mojolicious>
L<Mojolicious::Renderer>

=head1 LICENSE

Copyright (C) yowcow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

yowcow E<lt>yowcow@cpan.orgE<gt>

=cut


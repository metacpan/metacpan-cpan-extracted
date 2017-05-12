package Plack::App::Vhost;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use parent qw/Plack::Component/;
use Plack::Util::Accessor qw/vhosts fallback/;
use List::Util 1.28 qw/pairs/;

sub prepare_app {
    my $self = shift;
    $self->vhosts([])                       unless defined $self->vhosts;
    $self->fallback(sub { $self->res_404 }) unless defined $self->fallback;
}

sub call {
    my ($self, $env) = @_;

    for my $vhost (pairs @{ $self->vhosts }) {
        my ($rx, $app) = @$vhost;
        return $app->($env) if $env->{HTTP_HOST} =~ $rx;
    }

    return $self->fallback->($env);
}

sub res_404 {
    my $self = shift;
    return [404, ['Content-Type' => 'text/plain', 'Content-Length' => 9], ['not found']];
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::App::Vhost - Simple virtual host implementation on Plack.

=head1 SYNOPSIS

    use Plack::App::Vhost;

    Plack::App::Vhost->new(
       vhosts => [
          qr/^foo-mode\.my-app/ => $foo_app,
          qr/^bar-mode\.my-app/ => $bar_app,
       ],
       fallback => sub {
           my $env = shift;
           open my $fh, '<', 'path/to/404.html';
           return [404, ['Content-Type' => 'text/html', 'Content-Length' => -s $fh], [$fh]];
       },
    )->to_app;

=head1 DESCRIPTION

Plack::App::Vhost is virtual host implementation on Plack.

=head1 METHODS

=over

=item my $vhost = Plack::App::Vhost->new(\%args)

Creates a new Plack::App::Vhost instance.
Arguments can be:

=over

=item * C<vhosts>

Specify regex and PSGI application pairs in order of preference.
If C<HTTP_HOST> matches to the regexp, Executes PSGI application of the pair.

=item * C<fallback>

Specify fallback PSGI application.
If C<HTTP_HOST> does not match to any regexp, Executes fallback PSGI application.

=back

=item $vhost->to_app()

Creates as a PSGI application.

=back

=head1 SEE ALSO

L<Plack::App::HostMap>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut


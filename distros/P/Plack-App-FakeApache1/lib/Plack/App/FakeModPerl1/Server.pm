package Plack::App::FakeModPerl1::Server;
{
  $Plack::App::FakeModPerl1::Server::DIST = 'Plack-App-FakeApache1';
}
$Plack::App::FakeModPerl1::Server::VERSION = '0.0.5';
# ABSTRACT: Mimic Apache mod_perl1's server
use strict;
use warnings;
use 5.10.1;
use Carp;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $what = $AUTOLOAD;
    $what =~ s/.*:://;
    carp "!!server->$what(@_)" unless $what eq 'DESTROY';
}

sub dir_config {
    my ( $self, $c ) = @_;

    # Translate the legacy WebguiRoot and WebguiConfig PerlSetVar's into known values
    return $self->{env}->{'wg.WEBGUI_ROOT'} if $c eq 'WebguiRoot';
    return $self->{env}->{'wg.WEBGUI_CONFIG'} if $c eq 'WebguiConfig';

    # Otherwise, we might want to provide some sort of support (which Apache is still around)
    return $self->{env}->{"wg.DIR_CONFIG.$c"};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::FakeModPerl1::Server - Mimic Apache mod_perl1's server

=head1 VERSION

version 0.0.5

=head2 new

=head2 dir_config

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

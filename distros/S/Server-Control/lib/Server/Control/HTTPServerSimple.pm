package Server::Control::HTTPServerSimple;
BEGIN {
  $Server::Control::HTTPServerSimple::VERSION = '0.20';
}
use Carp;
use Moose;
use MooseX::StrictConstructor;
use Moose::Meta::Class;
use Moose::Util::TypeConstraints;
use strict;
use warnings;

extends 'Server::Control';

has 'net_server_params' => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
has 'server'            => ( is => 'ro', lazy_build => 1 );
has 'server_class'      => ( is => 'ro', required => 1 );

__PACKAGE__->meta->make_immutable();

sub _build_port {
    my $self = shift;
    return $self->net_server_params->{port}
      || die "port must be passed in net_server_params";
}

sub _build_pid_file {
    my $self = shift;
    return $self->net_server_params->{pid_file}
      || die "pid_file must be passed in net_server_params";
}

sub _build_error_log {
    my $self            = shift;
    my $server_log_file = $self->net_server_params->{log_file};
    return ( defined($server_log_file) && $server_log_file ne 'Sys::Syslog' )
      ? $server_log_file
      : undef;
}

sub _build_server {
    my $self = shift;

    my $server_class = $self->server_class;
    Class::MOP::load_class($server_class);
    unless ( $server_class->can('net_server')
        && defined( $server_class->net_server() ) )
    {
        die
          "bad server_class '$server_class' - must be an HTTP::Server::Simple subclass with a net_server defined";
    }
    return $server_class->new( $self->port );
}

sub do_start {
    my $self = shift;

    $self->server->background( %{ $self->net_server_params } );
}

1;



=pod

=head1 NAME

Server::Control::HTTPServerSimple -- apachectl style control for
HTTP::Server::Simple servers

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    package My::Server;
    use base qw(HTTP::Server::Simple);
    sub net_server { 'Net::Server::PreForkSimple' }

    ---

    use Server::Control::HTTPServerSimple;
    my $ctl = Server::Control::HTTPServerSimple->new(
        server_class => 'My::Server',
        net_server_params => {
            pid_file => '/path/to/server.pid',
            port     => 5678,
            log_file => '/path/to/file.log'
        }
    );
    if ( !$ctl->is_running() ) {
        $ctl->start(...);
    }

=head1 DESCRIPTION

C<Server::Control::HTTPServerSimple> is a subclass of
L<Server::Control|Server::Control> for
L<HTTP::Server::Simple|HTTP::Server::Simple> servers.

=head1 CONSTRUCTOR

The constructor options are as described in L<Server::Control|Server::Control>,
except for:

=over

=item server_class

Required. Specifies a C<HTTP::Server::Simple> subclass. Will be loaded if not
already.

This subclass must specify a C<net_server> class, because vanilla
HTTP::Server::Simple does not create pid files.

=item net_server_params

Specifies a hashref of parameters to pass to the server's C<run()> method.

=item pid_file

Will be taken from L</net_server_params>.

=item port

Will be taken from L</net_server_params>.

=item error_log

If not provided, will attempt to get from C<log_file> key in
L</net_server_params>.

=back

=head1 SEE ALSO

L<Server::Control|Server::Control>,
L<HTTP::Server::Simple|HTTP::Server::Simple>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


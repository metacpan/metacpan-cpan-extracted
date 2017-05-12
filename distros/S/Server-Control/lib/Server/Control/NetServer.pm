package Server::Control::NetServer;
BEGIN {
  $Server::Control::NetServer::VERSION = '0.20';
}
use Carp;
use Moose;
use MooseX::StrictConstructor;
use strict;
use warnings;

extends 'Server::Control';

has 'net_server_class'  => ( is => 'ro', isa => 'Str', required => 1 );
has 'net_server_params' => ( is => 'ro', isa => 'HashRef', default => sub { {} } );

# All of this hackery is to skip the port check on start during a HUP,
# because Net::Server leaves the sockets open.
#
has 'in_hup' => ( is => 'ro' );

before '_perform_cli_action' => sub {
    push( @ARGV, '--in-hup' ) if !( grep { $_ eq '--in-hup' } @ARGV );
};
around '_listening_before_start' => sub {
    my $orig = shift;
    my $self = shift;
    return $self->in_hup() ? 0 : $self->$orig(@_);
};

__PACKAGE__->meta->make_immutable();

sub _cli_option_pairs {
    my $class = shift;
    return ( $class->SUPER::_cli_option_pairs, 'in-hup' => 'in_hup', );
}

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

sub do_start {
    my $self = shift;

    # Fork child. Child will fork again to start server, and then exit in
    # Net::Server::post_configure. Parent continues with rest of
    # Server::Control::start() to see if the server has started correctly
    # and report status.
    #
    my $child = fork;
    croak "Can't fork: $!" unless defined($child);
    if ( !$child ) {
        Class::MOP::load_class( $self->net_server_class );
        $self->net_server_class->run(
            background => 1,
            %{ $self->net_server_params }
        );
        exit(0);    # Net::Server should exit, but just to be safe
    }
}

1;



=pod

=head1 NAME

Server::Control::NetServer -- apachectl style control for Net::Server servers

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    package My::Server;
    use base qw(Net::Server);
    sub process_request {
       #...code...
    }

    ---

    use Server::Control::NetServer;

    my $ctl = Server::Control::NetServer->new(
        net_server_class  => 'My::Server',
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

C<Server::Control::NetServer> is a subclass of
L<Server::Control|Server::Control> for L<Net::Server|Net::Server> servers.

=head1 CONSTRUCTOR

The constructor options are as described in L<Server::Control|Server::Control>,
except for:

=over

=item net_server_class

Required. Specifies a C<Net::Server> subclass. Will be loaded if not already.

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

L<Server::Control|Server::Control>, L<Net::Server|Net::Server>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


package Server::Control::Nginx;
BEGIN {
  $Server::Control::Nginx::VERSION = '0.20';
}
use Log::Any qw($log);
use Moose;
use strict;
use warnings;

extends 'Server::Control';

has '+binary_name' => ( is => 'ro', isa => 'Str', default => 'nginx' );
has 'conf_file'    => ( is => 'ro', required => 1 );

sub do_start {
    my $self = shift;

    $self->run_system_command(
        sprintf( '%s -c %s', $self->binary_path, $self->conf_file ) );
}

sub do_stop {
    my $self = shift;

    $self->run_system_command(
        sprintf( '%s -c %s -s stop', $self->binary_path, $self->conf_file ) );
}

__PACKAGE__->meta->make_immutable();

1;



=pod

=head1 NAME

Server::Control::Nginx -- Control Nginx

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    use Server::Control::Nginx;

    my $nginx = Server::Control::Nginx->new(
        binary_path => '/usr/sbin/nginx',
        conf_file => '/path/to/nginx.conf'
    );
    if ( !$nginx->is_running() ) {
        $nginx->start();
    }

=head1 DESCRIPTION

Server::Control::Nginx is a subclass of L<Server::Control|Server::Control> for
L<Nginx|http://nginx.org/> processes.

=head1 CONSTRUCTOR

In addition to the constructor options described in
L<Server::Control|Server::Control>:

=over

=item conf_file

Path to conf file - required.

=back

=head1 SEE ALSO

L<Server::Control|Server::Control>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


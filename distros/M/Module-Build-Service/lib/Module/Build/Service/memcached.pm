package Module::Build::Service::memcached;
{
  $Module::Build::Service::memcached::VERSION = '0.91';
}
# ABSTRACT: Service implementation for memcached

use Log::Any qw{$log};
use Moo;
extends 'Module::Build::Service::Base';
with 'Module::Build::Service::Fork';


sub _build_command {
    my ($self) = @_;
    [$self->bin, "-l", $self->listen, "-p", $self->port, "-vv"];
}


has 'listen' => (is => 'lazy');
sub _build_listen {'127.0.0.1'}


sub _build_path {['/usr/sbin', '/usr/local/sbin', '/usr/bin', '/usr/local/bin']}


has 'port' => (is => 'lazy',
               isa => sub {$_[0] =~ m/^\d+$/});
sub _build_port {'50098'}


1;

__END__
=pod

=head1 NAME

Module::Build::Service::memcached - Service implementation for memcached

=head1 VERSION

version 0.91

=head1 SYNOPSIS

  $self->services ([[memcached => 1]]);

=head1 DESCRIPTION

This is a service definition for memcached.  By default we start the
service listening to on localhost:50098 with no config.  You can use
the following arguments to the service definition to customize this.

=head1 ATTRIBUTES

=head2 command

The command line to use when invoking memcached.  Defaults to:

  <bin> -l <listen> -p <port> -vv

=head2 listen

If you just want memcached to listen on a different address, specify
the address here.

=head2 path

The path(s) in which to look for the memcached executable.  Defaults to
is C</usr/sbin>, C</usr/local/sbin>, C</usr/bin> and C</usr/local/bin>.

=head2 port

If you just want memcached to listen on a different port, specify the
port here.

=head2 OTHER

See L<Module::Build::Service::Base> and
L<Module::Build::Service::Fork> for more configurable attributes.

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ironic Design, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


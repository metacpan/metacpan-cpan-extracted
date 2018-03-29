package Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Devices;

use Mojo::Base -base;

use constant {
  DEVICES_ALLOW_INTERFACE => 'devices.allow',
  DEVICES_DENY_INTERFACE  => 'devices.deny'
};

has cgroup => sub { Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new };

sub allow { shift->cgroup->_write(DEVICES_ALLOW_INTERFACE, @_) }
sub deny  { shift->cgroup->_write(DEVICES_DENY_INTERFACE,  @_) }

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Devices - CGroups v1 Devices Controller.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::CGroup::v1;

    my $cgroup = Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new( name => "test" );

    $cgroup->devices->allow('a *:* rwm');

=head1 DESCRIPTION

This module uses features that are only available on Linux,
and requires cgroups and capability for unshare syscalls to achieve pid isolation.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Devices> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut

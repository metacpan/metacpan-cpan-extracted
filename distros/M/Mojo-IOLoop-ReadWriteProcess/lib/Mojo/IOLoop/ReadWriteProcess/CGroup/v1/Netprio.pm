package Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Netprio;

use Mojo::Base -base;

use constant {
  PRIOIDX_INTERFACE   => 'net_prio.prioidx',
  IFPRIOMAP_INTERFACE => 'net_prio.ifpriomap',

};

has cgroup => sub { Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new };

sub ifpriomap { shift->cgroup->_setget(IFPRIOMAP_INTERFACE, @_) }
sub prioidx   { shift->cgroup->_list(PRIOIDX_INTERFACE) }

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Netprio - CGroups v1 Netprio Controller.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::CGroup::v1;

    my $cgroup = Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new( name => "test" );

    $cgroup->netprio->prioidx;

=head1 DESCRIPTION

This module uses features that are only available on Linux,
and requires cgroups and capability for unshare syscalls to achieve pid isolation.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Netprio> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut

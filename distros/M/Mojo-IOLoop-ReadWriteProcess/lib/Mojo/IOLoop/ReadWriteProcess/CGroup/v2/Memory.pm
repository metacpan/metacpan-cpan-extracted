package Mojo::IOLoop::ReadWriteProcess::CGroup::v2::Memory;

use Mojo::Base -base;

use constant {
  CURRENT_INTERFACE      => 'memory.current',
  LOW_INTERFACE          => 'memory.low',
  HIGH_INTERFACE         => 'memory.high',
  MAX_INTERFACE          => 'memory.max',
  EVENTS_INTERFACE       => 'memory.events',
  STAT_INTERFACE         => 'memory.stat',
  SWAP_CURRENT_INTERFACE => 'memory.swap.current',
  SWAP_MAX_INTERFACE     => 'memory.swap.max',
};


has cgroup => sub { Mojo::IOLoop::ReadWriteProcess::CGroup::v2->new };

sub current      { shift->cgroup->_list(CURRENT_INTERFACE) }
sub swap_current { shift->cgroup->_list(SWAP_CURRENT_INTERFACE) }
sub low          { shift->cgroup->_setget(LOW_INTERFACE, @_) }
sub high         { shift->cgroup->_setget(HIGH_INTERFACE, @_) }
sub max          { shift->cgroup->_setget(MAX_INTERFACE, @_) }
sub swap_max     { shift->cgroup->_setget(SWAP_MAX_INTERFACE, @_) }
sub events       { shift->cgroup->_list(EVENTS_INTERFACE) }
sub stat         { shift->cgroup->_list(STAT_INTERFACE) }

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::CGroup::v2::Memory - CGroups v2 Memory Controller

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::CGroup::v2;

    my $cgroup = Mojo::IOLoop::ReadWriteProcess::CGroup::v2->new( name => "test" );

    $cgroup->memory->current;

=head1 DESCRIPTION

This module uses features that are only available on Linux,
and requires cgroups and capability for unshare syscalls to achieve pid isolation.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::CGroup::v2::Memory> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut

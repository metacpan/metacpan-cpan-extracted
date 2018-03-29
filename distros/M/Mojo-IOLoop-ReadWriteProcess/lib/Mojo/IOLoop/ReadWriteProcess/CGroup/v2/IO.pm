package Mojo::IOLoop::ReadWriteProcess::CGroup::v2::IO;

use Mojo::Base -base;

use constant {
  STAT_INTERFACE   => 'io.stat',
  WEIGHT_INTERFACE => 'io.weight',
  MAX_INTERFACE    => 'io.max',
};

has cgroup => sub { Mojo::IOLoop::ReadWriteProcess::CGroup::v2->new };

sub stat   { shift->cgroup->_list(STAT_INTERFACE) }
sub weight { shift->cgroup->_setget(WEIGHT_INTERFACE, @_) }
sub max    { shift->cgroup->_setget(MAX_INTERFACE, @_) }

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::CGroup::v2::IO - CGroups v2 Memory Controller

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::CGroup::v2;

    my $cgroup = Mojo::IOLoop::ReadWriteProcess::CGroup::v2->new( name => "test" );

    $cgroup->io->stat;

=head1 DESCRIPTION

This module uses features that are only available on Linux,
and requires cgroups and capability for unshare syscalls to achieve pid isolation.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::CGroup::v2::IO> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut

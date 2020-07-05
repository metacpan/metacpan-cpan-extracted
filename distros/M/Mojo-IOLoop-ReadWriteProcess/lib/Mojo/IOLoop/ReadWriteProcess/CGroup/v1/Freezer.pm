package Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Freezer;

use Mojo::Base -base;

use constant {
  STATE_INTERFACE           => 'freezer.state',
  SELF_FREEZING_INTERFACE   => 'freezer.self_freezing',
  PARENT_FREEZING_INTERFACE => 'freezer.parent_freezing',
};

has cgroup => sub { Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new };

sub state           { shift->cgroup->_setget(STATE_INTERFACE, @_) }
sub self_freezing   { shift->cgroup->_list(SELF_FREEZING_INTERFACE) }
sub parent_freezing { shift->cgroup->_list(PARENT_FREEZING_INTERFACE) }

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Freezer - CGroups v1 Freezer Controller.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::CGroup::v1;

    my $cgroup = Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new( name => "test" );

    $cgroup->freezer->state('FROZEN');

=head1 DESCRIPTION

This module uses features that are only available on Linux,
and requires cgroups and capability for unshare syscalls to achieve pid isolation.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Freezer> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut

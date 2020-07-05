package Mojo::IOLoop::ReadWriteProcess::CGroup::v1::PID;

use Mojo::Base -base;

use constant {CURRENT_INTERFACE => 'pids.current', MAX_INTERFACE => 'pids.max'};

has cgroup => sub { Mojo::IOLoop::ReadWriteProcess::CGroup::v2->new };

sub current { shift->cgroup->_list(CURRENT_INTERFACE) }
sub max     { shift->cgroup->_setget(MAX_INTERFACE, @_) }

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::CGroup::v1::PID - CGroups v1 PID Controller.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::CGroup::v1;

    my $cgroup = Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new( name => "test" );

    $cgroup->pid->current;

=head1 DESCRIPTION

This module uses features that are only available on Linux,
and requires cgroups and capability for unshare syscalls to achieve pid isolation.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::CGroup::v1::PID> inherits all methods from L<Mojo::EventEmitter> and implements
the following new ones.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut

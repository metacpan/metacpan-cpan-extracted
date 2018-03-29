package Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuacct;

use Mojo::Base -base;

use constant USAGE_INTERFACE => 'cpuacct.usage';

has cgroup => sub { Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new };

sub usage { shift->cgroup->_list(USAGE_INTERFACE) }

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::CGroup::v1::Cpuacct - CGroups v1 Cpuacct Controller.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::CGroup::v1;

    my $cgroup = Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new( name => "test" );

    $cgroup->cpuacct->current;

=head1 DESCRIPTION

This module uses features that are only available on Linux,
and requires cgroups and capability for unshare syscalls to achieve pid isolation.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::CGroup::v1::PID> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut

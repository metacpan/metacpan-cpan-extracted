package Mojo::IOLoop::ReadWriteProcess::CGroup::v1::RDMA;

use Mojo::Base 'Mojo::IOLoop::ReadWriteProcess::CGroup::v2::RDMA';


has cgroup => sub { Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new };

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::CGroup::v2::RDMA - CGroups v2 RDMA Controller

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::CGroup::v2;

    my $cgroup = Mojo::IOLoop::ReadWriteProcess::CGroup::v2->new( name => "test" );

    $cgroup->rdma->current;

=head1 DESCRIPTION

This module uses features that are only available on Linux,
and requires cgroups and capability for unshare syscalls to achieve pid isolation.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::CGroup::v2> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut

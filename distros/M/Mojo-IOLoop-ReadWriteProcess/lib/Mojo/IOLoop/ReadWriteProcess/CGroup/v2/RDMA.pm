package Mojo::IOLoop::ReadWriteProcess::CGroup::v2::RDMA;

use Mojo::Base -base;

use constant {CURRENT_INTERFACE => 'rdma.current', MAX_INTERFACE => 'rdma.max',
};

has cgroup => sub { Mojo::IOLoop::ReadWriteProcess::CGroup::v2->new };

sub current { shift->cgroup->_list(CURRENT_INTERFACE) }
sub max { shift->cgroup->_setget(MAX_INTERFACE, @_) }

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::CGroup::v2::RDMA - CGroups v2 RDMA Controller

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::CGroup::v2;

    my $cgroup = Mojo::IOLoop::ReadWriteProcess::CGroup::v2->new( name => "test" );

    $cgroup->rdma->current;

=head1 DESCRIPTION

This module uses features that are only available on Linux kernels.

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

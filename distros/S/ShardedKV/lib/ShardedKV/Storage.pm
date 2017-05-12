package ShardedKV::Storage;
$ShardedKV::Storage::VERSION = '0.20';
use Moose::Role;
# ABSTRACT: Role for classes implementing storage backends

with 'ShardedKV::HasLogger';


requires qw(get set delete reset_connection);

no Moose;

1;

__END__

=pod

=head1 NAME

ShardedKV::Storage - Role for classes implementing storage backends

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    package ShardedKV::Storage::MyBackend;
    use Moose;
    with 'ShardedKV::Storage';

    sub get { ... }
    sub set { ... }
    sub delete { ... }
    sub reset_connection { ... }
    1;

=head1 DESCRIPTION

ShardedKV::Storage provides a role/interface that storage backends must
consume. Consuming the role requires implementing the three important
operations necessary for a storage backend. There are a few storage backends
that come with ShardedKV. Please see those modules for their specific details.

=head1 ROLE REQUIRES

=head2 get

get() needs to accept a key of some sort and return whatever is relevant.

=head2 set

set() needs to accept both a key, and a reference to a datastructure suitable for storing

=head2 delete

delete() needs to accept a key and it must remove the data stored under that key

=head2 reset_connection

Storage backends must implement reset_connection() to allow for reconnects.
Since most things are not reentrant and signals can mess with the state of
sockets and such, the ability to reset the connection (whatever that means for
your particular storage backend), is paramount. 

=head1 SEE ALSO

=over 4

=item *

L<ShardedKV>

=item *

L<ShardedKV::Storage::Memory>

=item *

L<ShardedKV::Storage::Redis>

=item *

L<ShardedKV::Storage::MySQL>

=back

=head1 AUTHORS

=over 4

=item *

Steffen Mueller <smueller@cpan.org>

=item *

Nick Perez <nperez@cpan.org>

=item *

Damian Gryski <dgryski@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

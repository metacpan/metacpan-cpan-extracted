package Scaffold::Lockmgr::SharedMem;

use base 'IPC::SharedMem';

use Carp;
use IPC::SysV qw( IPC_SET );

sub set {
    my $self = shift;

    my $ds;

    if (@_ == 1) {

        $ds = shift;

    } else {

        croak 'Bad arg count' if @_ % 2;

        my %arg = @_;

        $ds = $self->stat or return undef;

        while (my ($key, $val) = each %arg) {

            $ds->$key($val);

        }

    }

    my $v = shmctl($self->id, IPC_SET, $ds->pack);
    $v ? 0 + $v : undef;

}

1;

__END__

=head1 NAME

Scaffold::Lockmgr::SharedMem - Use SysV IPC for resource locking.

=head1 DESCRIPTION

This module is an extended version of IPC::SharedMem. It adds a set() method.

=head1 METHODS

=over 4

=item set( STAT )

=item set( NAME => VALUE [, NAME => VALUE ...] )

set will set the following values of the stat structure associated with 
the shared memory set.

 uid
 gid
 mode (only the permission bits)

set accepts either a stat object, as returned by the stat method, or a 
list of name-value pairs.

=back

=head1 SEE ALSO

 IPC::Semaphore
 IPC::SharedMem

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

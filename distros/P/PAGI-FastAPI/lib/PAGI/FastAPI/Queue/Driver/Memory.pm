package PAGI::FastAPI::Queue::Driver::Memory;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v1.2.4');
our $AUTHORITY = 'cpan:MANWAR';

use Future::AsyncAwait;
use PAGI::FastAPI::Queue::Driver;

class PAGI::FastAPI::Queue::Driver::Memory :isa(PAGI::FastAPI::Queue::Driver) {
    field %queues;

    async method push ($topic, $payload) {
        push @{ $queues{$topic} //= [] }, $payload;
        return 1;
    }

    async method pop ($topic) {
        return undef unless exists $queues{$topic} && @{ $queues{$topic} };
        return shift @{ $queues{$topic} };
    }

    async method size ($topic = undef) {
        if (defined $topic) {
            return scalar @{ $queues{$topic} // [] };
        }

        my $total = 0;
        $total += scalar @$_ for values %queues;
        return $total;
    }

    method clear ($topic = undef) {
        if (defined $topic) {
            delete $queues{$topic};
        }
        else {
            %queues = ();
        }
        return $self;
    }
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Queue::Driver::Memory - Default In-Memory Storage Driver for PAGI::FastAPI::Queue

=head1 VERSION

Version v1.2.4

=head1 SYNOPSIS

    use PAGI::FastAPI::Queue::Driver::Memory;

    my $driver = PAGI::FastAPI::Queue::Driver::Memory->new;

    $driver->push('emails', { to => 'a@b.com' })->get;
    my $item = $driver->pop('emails')->get;
    my $count = $driver->size('emails')->get;

    # Memory-driver-specific extension (not part of the base Driver contract)
    $driver->clear('emails');  # empty a single topic
    $driver->clear;            # empty every topic

=head1 DESCRIPTION

C<PAGI::FastAPI::Queue::Driver::Memory> is the standard implementation of
L<PAGI::FastAPI::Queue::Driver>. It comes with the core L<PAGI::FastAPI>
package and is utilised directly by L<PAGI::FastAPI::Queue> unless another
driver is used.

All messages of a certain topic are stored as an array in an in-process
hash table; C<push> adds a message and C<pop> removes it in C<FIFO> order.

B<Note:> Everything happens entirely in process memory and is kept private
to the driver instance. Messages in queue are B<not> accessible from outside,
that is from other processes (e.g. Starman, Hypnotoad) or different instances
of C<PAGI::FastAPI::Queue::Driver::Memory>. Use distributed storage driver
(e.g. Redis or SQS) in production.

=head1 METHODS

Inherits C<push>, C<pop>, and C<size> from L<PAGI::FastAPI::Queue::Driver>.

=head2 C<new()>

Instantiates a new in-memory queue driver. Takes no required arguments.

=head2 C<push($topic, $payload)>

Appends C<$payload> (any scalar) to the end of C<$topic>. Returns a
L<Future> resolving to C<1>.

=head2 C<pop($topic)>

Removes and returns a L<Future> resolving to the item at the front of
C<$topic>, or C<undef> if C<$topic> is empty or has never been pushed to.

=head2 C<size($topic = undef)>

Returns a L<Future> resolving to the number of pending items in
C<$topic>, or C<0> if unknown/empty. If C<$topic> is omitted (or
C<undef>), resolves to the sum of pending items across every topic.

=head2 C<clear($topic = undef)>

Memory-driver-specific extension, not part of the base
L<PAGI::FastAPI::Queue::Driver> contract and not exposed through
L<PAGI::FastAPI::Queue>. Empties C<$topic> if given, or every topic if
omitted. Returns C<$self> for chaining. Synchronous (does not return a
L<Future>).

=head1 SEE ALSO

L<PAGI::FastAPI::Queue::Driver>, L<PAGI::FastAPI::Queue>

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/PAGI-FastAPI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::Queue::Driver::Memory

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI/issues>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).

=cut

1; # End of PAGI::FastAPI::Queue::Driver::Memory

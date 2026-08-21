package PAGI::FastAPI::Queue::Driver;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v1.2.4');
our $AUTHORITY = 'cpan:MANWAR';

use Future::AsyncAwait;

class PAGI::FastAPI::Queue::Driver {
    async method push ($topic, $payload) {
        die ref($self) . " must implement push()";
    }

    async method pop ($topic) {
        die ref($self) . " must implement pop()";
    }

    async method size ($topic = undef) {
        die ref($self) . " must implement size()";
    }
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Queue::Driver - Abstract Base Class for Message Queue Storage Drivers

=head1 VERSION

Version v1.2.4

=head1 SYNOPSIS

    package PAGI::FastAPI::Queue::Driver::Custom;

    use v5.38;
    use experimental 'class';
    use Future::AsyncAwait;

    use PAGI::FastAPI::Queue::Driver;

    class PAGI::FastAPI::Queue::Driver::Custom
        :isa(PAGI::FastAPI::Queue::Driver) {

        async method push ($topic, $payload) {
            # Enqueue $payload onto $topic asynchronously...
            return 1;
        }

        async method pop ($topic) {
            # Dequeue and return the next item for $topic asynchronously...
            return $item;
        }

        async method size ($topic = undef) {
            # Report pending item count asynchronously...
            return $count;
        }
    }

=head1 DESCRIPTION

C<PAGI::FastAPI::Queue::Driver> creates the asynchronous abstract interface
used for all message queue backends by L<PAGI::FastAPI::Queue>.

Any new storage drivers (like C<Redis>, C<SQS>, or a queue based on a database)
should use this class as a superclass and code the asynchronous methods in
it to ensure these methods result in the creation of L instances and
consequently, will not block the event loop of PAGI.

As of version C<v1.1.0>, we have built-in support for in memory message queue by
+L<PAGI::FastAPI::Queue::Driver::Memory>.
+
+We even have demo app created for in memory rate limit: C<eg/memory_queue_demo.pl>
+
+If you are looking for more specialised options then you have another choice
as a separate companion package: L<PAGI::FastAPI::Queue::Driver::Redis>.

=head1 REQUIRED METHODS

Subclasses B<must> override the following methods. Calling any of these
directly on the base class returns a failed L<Future>.

=head2 C<push($topic, $payload)>

    my $future = $driver->push($topic, $payload);

Enqueues C<$payload> (any scalar) onto C<$topic>. Returns a L<Future>
resolving to a true value on success.

=head2 C<pop($topic)>

    my $future = $driver->pop($topic);

Dequeues and returns a L<Future> resolving to the next pending item for
C<$topic>, or C<undef> if C<$topic> is empty or unknown.

=head2 C<size($topic = undef)>

    my $future = $driver->size($topic);

Returns a L<Future> resolving to the integer count of pending items in
C<$topic>. If C<$topic> is omitted (or C<undef>), should resolve to the
total pending item count across all topics.

=head1 SEE ALSO

L<PAGI::FastAPI::Queue::Driver::Memory>, L<PAGI::FastAPI::Queue>

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

    perldoc PAGI::FastAPI::Queue::Driver

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

1; # End of PAGI::FastAPI::Queue::Driver

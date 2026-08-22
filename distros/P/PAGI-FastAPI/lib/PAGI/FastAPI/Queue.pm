package PAGI::FastAPI::Queue;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v1.2.5');
our $AUTHORITY = 'cpan:MANWAR';

use Future::AsyncAwait;

class PAGI::FastAPI::Queue {
    field $driver  :param = 'Memory';
    field $options :param = {};
    field $backend;

    ADJUST {
        my $driver_class = $driver =~ /^PAGI::FastAPI::Queue::Driver::/
            ? $driver
            : "PAGI::FastAPI::Queue::Driver::$driver";

        (my $driver_file = "$driver_class.pm") =~ s{::}{/}g;

        eval { require $driver_file; 1 }
            or die "Failed to load queue driver '$driver_class': $@";

        $backend = $driver_class->new(%$options);
    }

    # Returns a closure suitable for Depends(); the closure ignores any
    # arguments (Depends() invokes dependency code with the request
    # context as its argument).
    method dep () {
        return sub { $self };
    }

    async method push ($topic, $payload) {
        return await $backend->push($topic, $payload);
    }

    async method pop ($topic) {
        return await $backend->pop($topic);
    }

    async method size ($topic = undef) {
        return await $backend->size($topic);
    }
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Queue - Pluggable Async Message Queue Facade for PAGI::FastAPI

=head1 VERSION

Version v1.2.5

=head1 SYNOPSIS

    use PAGI::FastAPI::Queue;
    use PAGI::FastAPI::Depends qw(Depends);

    my $queue = PAGI::FastAPI::Queue->new; # Defaults to the Memory driver

    $app->post('/jobs',
        dependencies => [ Depends($queue->dep, key => 'queue') ],
        handler      => async sub ($c) {
            await $c->stash->{queue}->push('emails', { to => 'a@b.com' });
            return { queued => 1 };
        },
    );

    # Selecting a driver by short name (resolved under
    # PAGI::FastAPI::Queue::Driver::*) or by fully-qualified class name
    my $q1 = PAGI::FastAPI::Queue->new(driver => 'Memory');
    my $q2 = PAGI::FastAPI::Queue->new(
        driver  => 'PAGI::FastAPI::Queue::Driver::Memory',
        options => {},
    );

=head1 DESCRIPTION

C<PAGI::FastAPI> is an asynchronous application programming interface (API)
for interacting with the L<PAGI::FastAPI::Queue::Driver> storage mechanism.
It offers an easy way to perform operations such as C<push>, C<pop>, and
C<size>, and has included L<PAGI::FastAPI::Queue::Driver::Memory>
implementation by default in the API.

Developers may create their implementations of the L<PAGI::FastAPI::Queue::Driver>
storage mechanism for other systems such as SQS, or queue on the database level.
Developers can create a new driver by extending from the L<PAGI::FastAPI::Queue::Driver::*>
API and using the class name either in the shortened form or in the long form.
A companion C<Redis> driver is available using L<PAGI::FastAPI::Queue::Driver::Redis>.

B<Unlike> L<PAGI::FastAPI::Middleware::RateLimit>, which is working with an
instance of I<object>, C<PAGI::FastAPI::Queue> expects I<name> (a string) of
the driver and creates an instance from the given class.

=head1 METHODS

=head2 C<new(%options)>

Constructs a new queue facade.

=over 4

=item * C<driver> - (Optional) Scalar string naming the driver to use.
Defaults to C<'Memory'>. A bare name (no C<::>) is resolved as
C<PAGI::FastAPI::Queue::Driver::$name>; a string already prefixed with
C<PAGI::FastAPI::Queue::Driver::> is used as-is. Dies if the resulting
class cannot be loaded.

=item * C<options> - (Optional) HashRef of constructor arguments forwarded
to the driver class's C<new()>. Defaults to C<{}>.

=back

=head2 C<dep()>

Returns a zero-argument closure that resolves to this C<PAGI::FastAPI::Queue>
instance, suitable for use with L<PAGI::FastAPI::Depends>:

    Depends($queue->dep, key => 'queue')

=head2 C<push($topic, $payload)>

Pushes C<$payload> (any scalar) onto the end of C<$topic>. Returns a
L<Future> resolving to the underlying driver's result (true on success).

=head2 C<pop($topic)>

Removes and returns a L<Future> resolving to the item at the front of
C<$topic>, or C<undef> if the topic is empty or unknown.

=head2 C<size($topic = undef)>

Returns a L<Future> resolving to the number of pending items in
C<$topic>. If C<$topic> is omitted (or C<undef>), resolves to the total
number of pending items across all topics.

=head1 SEE ALSO

L<PAGI::FastAPI::Queue::Driver>, L<PAGI::FastAPI::Queue::Driver::Memory>,
L<PAGI::FastAPI::Depends>

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

    perldoc PAGI::FastAPI::Queue

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

1; # End of PAGI::FastAPI::Queue

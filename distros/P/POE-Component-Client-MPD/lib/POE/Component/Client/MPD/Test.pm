#
# This file is part of POE-Component-Client-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package POE::Component::Client::MPD::Test;
# ABSTRACT: automate pococ-mpd testing
$POE::Component::Client::MPD::Test::VERSION = '2.001';
use Moose 0.92;
use MooseX::Has::Sugar;
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use MooseX::Types::Moose qw{ ArrayRef Str };
use POE;
use Readonly;

Readonly my $K => $poe_kernel;


has alias => ( ro, isa=>Str, default=>'tester' );
has tests => (
    ro, auto_deref, required,
    isa      => ArrayRef,
    traits   => [ 'Array' ],
    handles  => {
        peek     => [ get => 0 ],
        pop_test => 'shift',
        nbtests  => 'count',
    },
);


# -- builders & initializer

#
# START()
#
# called as poe session initialization
#
sub START {
    my $self = shift;
    $K->alias_set($self->alias);     # refcount++
    $K->yield( 'next_test' );        # launch the first test.
}


# -- public events


event next_test => sub {
    my $self = shift;

    if ( $self->nbtests == 0 ) { # no more tests.
        $K->alias_remove( $self->alias );
        $K->post('mpd', 'disconnect');
        return;
    }

    # post next event.
    my $test  = $self->peek;
    my $event = $test->[0];
    my $args  = $test->[1];
    $K->post( 'mpd', $event, @$args );
};



event mpd_result => sub {
    my ($self, $msg, $results) = @_[OBJECT, ARG0, ARG1];
    my $test = $self->peek;

    $test->[3]->($msg, $results);               # check if everything went fine
    $K->delay_set( next_test => $test->[2] );   # call next test after some time
    $self->pop_test;                            # remove test being played
};


1;

__END__

=pod

=head1 NAME

POE::Component::Client::MPD::Test - automate pococ-mpd testing

=head1 VERSION

version 2.001

=head1 SYNOPSIS

    POE::Component::Client::MPD->spawn( ... );
    POE::Component::Client::MPD::Test->new( { tests => [
        [ 'event', [ $arg1, $arg2, ... ], $sleep, \&check_results ],
        ...
    ] } );
    POE::Kernel->run;

=head1 DESCRIPTION

This module implements a L<POE::Session> used to schedule tests
according to a plan, calling hooks used to check whether a given test
was successful.

To use it, you need to first spawn a L<POE::Component::Client::MPD>
session - it's this session that will be tested. And don't forget to
call L<POE>'s mainloop!

Once started, it will fire the first event to the
L<MPD|POE::Component::Client::MPD> session, wait for the return message,
call the check callback, and wait a bit... before starting again with
the next event in the list.

When all events have been sent, the session will shut down itself.

=head1 ATTRIBUTES

=head2 alias

The session alias. Defaults to C<tester>.

=head2 tests

The list (array ref) of tests to run. It is required in the constructor
call. Each list item is an array reference with the following sub-items:

=over 4

=item * event - the event to send to the
L<POE::Component::Client::MPD> session

=item * args - event arguments (an array reference)

=item * sleep - number of seconds to wait before calling next events

=item * callback - a sub reference to check the results of current
event. The real tests should be done in this sub. It will be called with
the message received and the message payload.

=back

=head1 PUBLIC EVENTS ACCEPTED

=head2 next_test( )

Called to schedule the next test.

=head2 mpd_result( $msg )

Called when mpd talks back, with C<$msg> as a
L<POE::Component::Client::MPD::Message> param.

=for Pod::Coverage::TrustPod START

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

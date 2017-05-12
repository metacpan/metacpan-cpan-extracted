package POE::Component::WWW::Google::Time;

use warnings;
use strict;

our $VERSION = '0.0102';

use POE;
use WWW::Google::Time;
use base 'POE::Component::NonBlockingWrapper::Base';

sub _methods_define {
    return ( get_time => '_wheel_entry' );
}

sub get_time {
    $poe_kernel->post( shift->{session_id} => get_time => @_ );
}

sub _prepare_wheel {
    my $self = shift;
    $self->{obj} = WWW::Google::Time->new(
        $self->{ua} ? ( ua => $self->{ua} ) : ()
    );
}

sub _process_request {
    my ( $self, $in_ref ) = @_;
    my $t = $self->{obj};
    $t->get_time( $in_ref->{where} )
        or $in_ref->{error} = $t->error
        and return;

    $in_ref->{result} = $t->data;

    return;
}

1;
__END__

=encoding utf8

=head1 NAME

POE::Component::WWW::Google::Time - non-blocking wrapper around WWW::Google::Time

=head1 SYNOPSIS

    use strict;
    use warnings;
    use POE qw/Component::WWW::Google::Time/;

    my $poco = POE::Component::WWW::Google::Time->spawn;

    POE::Session->create( package_states => [ main => [qw(_start results)] ], );

    $poe_kernel->run;

    sub _start {
        $poco->get_time({ event => 'results', where => 'Toronto' });
    }

    sub results {
        my $data = $_[ARG0];

        if ( $data->{error} ) {
            print "Error: $data->{error}\n";
        }
        else {
            printf "It is %s, %s (%s) in %s\n",
                @{ $data->{result} }{ qw/day_of_week  time  time_zone  where/ };
        }
        $poco->shutdown;
    }

Using event based interface is also possible of course.

=head1 DESCRIPTION

The module is a non-blocking wrapper around L<WWW::Google::Time>
which provides interface to fetch time data for various locations from Google.

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::WWW::Google::Time->spawn;

    POE::Component::WWW::Google::Time->spawn(
        alias => 'google_time',
        ua      => LWP::UserAgent->new( ua => "Mozilla" ),
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::WWW::Google::Time object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    ->spawn( alias => 'google_time' );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 C<ua>

    ->spawn( ua => LWP::UserAgent->new( agent => "Mozilla" );

B<Optional>. Same as the C<ua> argument in L<WWW::Google::Time> constructor. Note that Google
blocks L<LWP::UserAgent>'s default "User-Agent" header.

=head3 C<options>

    ->spawn(
        options => {
            trace => 1,
            default => 1,
        },
    );

B<Optional>.
A hashref of POE Session options to pass to the component's session.

=head3 C<debug>

    ->spawn(
        debug => 1
    );

When set to a true value turns on output of debug messages. B<Defaults to:>
C<0>.

=head1 METHODS

=head2 C<get_time>

    $poco->get_time( {
            event       => 'event_for_output',
            where       => 'Toronto',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<get_time> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<get_time>

    $poe_kernel->post( google_time => get_time => {
            event       => 'event_for_output',
            where       => 'Toronto',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to fetch time data from Google. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 C<event>

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 C<where>

    { where => 'Toronto' }

B<Mandatory>. Specifies the place for which to fetch the time data.

=head3 C<session>

    { session => 'other' }

    { session => $other_session_reference }

    { session => $other_session_ID }

B<Optional>. Takes either an alias, reference or an ID of an alternative
session to send output to.

=head3 user defined

    {
        _user    => 'random',
        _another => 'more',
    }

B<Optional>. Any keys starting with C<_> (underscore) will not affect the
component and will be passed back in the result intact.

=head2 C<shutdown>

    $poe_kernel->post( google_time => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        'where' => 'Toronto',
        'result' => {
            'time' => '11:06pm',
            'day_of_week' => 'Saturday',
            'time_zone' => 'EDT',
            'where' => 'Toronto, Ontario'
        },
        '_blah' => 'foos',
    };

    $VAR1 = {
        'error' => 'Could not find time data for that location',
        'where' => 'Nonexistant',
        '_blah' => 'foos',
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<get_time()> method/event will recieve input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 C<where>

    { where => 'Toronto' }

The C<where> key will contain the same value as what you passed in C<where> argument to the
C<get_time()> event/method.

=head2 C<error>

    { 'error' => 'Could not find time data for that location' }

The C<error> key will be present if a network error occured or Google doesn't know about the
location you passed as C<where> argument to the C<get_time()> method/event.

=head2 C<result>

    'result' => {
        'time' => '11:06pm',
        'day_of_week' => 'Saturday',
        'time_zone' => 'EDT',
        'where' => 'Toronto, Ontario'
    },

The C<result> key (upon success, that is when C<error> key is not present) will contain the
same hashref as returned by the L<WWW::Google::Time>'s C<get_time()> method. See documentation
for L<WWW::Google::Time> for more information.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<get_time()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<WWW::Google::Time>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com/>, L<http://haslayout.net/>, L<http://zofdesign.com/>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-www-google-time at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-WWW-Google-Time>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::WWW::Google::Time

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-WWW-Google-Time>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-WWW-Google-Time>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-WWW-Google-Time>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-WWW-Google-Time>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


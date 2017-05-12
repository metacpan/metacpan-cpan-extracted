package POE::Component::WWW::CPANRatings::RSS;

use warnings;
use strict;

our $VERSION = '0.0101';

use POE;
use base 'POE::Component::NonBlockingWrapper::Base';
use WWW::CPANRatings::RSS;

sub _methods_define {
    return (
        fetch => '_wheel_entry',
        stop_repeat => '_stop_repeat',
    );
}

sub fetch {
    $poe_kernel->post( shift->{session_id} => fetch => @_ );
}

sub stop_repeat {
    $poe_kernel->call( shift->{session_id} => stop_repeat => @_ );
}

sub _stop_repeat {
    my ( $kernel, $self, $repeat_name ) = @_[ KERNEL, OBJECT, ARG0 ];
    return
        unless exists $self->{timers}{ $repeat_name };

    $kernel->refcount_decrement(
        $self->{timers}{ $repeat_name }{session}
        =>'POE::Component::NonBlockingWrapper::Base'
    );

    $kernel->alarm_remove( $_ )
        for @{ $self->{timers}{ $repeat_name }{timers} };

    delete $self->{timers}{ $repeat_name };
}

sub _prepare_wheel {
    my $self = shift;
    $self->{obj} = WWW::CPANRatings::RSS->new(
        $self->{ua} ? ( ua => $self->{ua} ) : ()
    );
}

sub _process_request {
    my ( $self, $req_ref ) = @_;

    my $method = $req_ref->{unique} ? 'fetch_unique' : 'fetch';
    my $ratings_ref = $self->{obj}->$method(
        $method eq 'fetch_unique' ? $req_ref->{file} : ()
    );

    if ( $ratings_ref ) {
        $req_ref->{ratings} = $ratings_ref;
        delete $req_ref->{error};
    }
    else {
        $req_ref->{error} = $self->{obj}->error;
    }
}

sub _child_stdout {
    my ( $kernel, $self, $input ) = @_[ KERNEL, OBJECT, ARG0 ];

    delete $input->{session};
    my $session = delete $input->{sender};
    my $event   = delete $input->{event};

    if ( $input->{repeat} ) {
        my $repeat_name = $input->{repeat_name} || 'GENERAL';
    
        $kernel->refcount_increment( $session =>'POE::Component::NonBlockingWrapper::Base' );

        if ( exists $self->{timers}{ $repeat_name } ) {
            $kernel->refcount_decrement( $session =>'POE::Component::NonBlockingWrapper::Base' );
            $kernel->alarm_remove( $_ )
                for @{ $self->{timers}{ $repeat_name }{timers} || [] };

            delete $self->{timers}{ $repeat_name };
        }

        push @{ $self->{timers}{ $repeat_name }{timers} },
            $kernel->delay_set(
                fetch => $input->{repeat} => {
                    %$input,
                    session => $session,
                    event   => $event,
                }
            );

        $self->{timers}{ $repeat_name }{session} = $session;
    }

    $kernel->post( $session, $event, $input );
    $kernel->refcount_decrement( $session =>'POE::Component::NonBlockingWrapper::Base' );
    
    undef;
}

sub _shutdown {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    for my $timer ( values %{ $self->{timers} } ) {
        $kernel->refcount_decrement( $timer->{session} =>'POE::Component::NonBlockingWrapper::Base');
        $kernel->alarm_remove( $_ )
            for @{ $timer->{timers} || [] };
    }
    delete $self->{timers};
    $kernel->alarm_remove_all;
    $kernel->alias_remove( $_ ) for $kernel->alias_list;
    $kernel->refcount_decrement( $self->{session_id} => 'POE::Component::NonBlockingWrapper::Base' )
        unless $self->{alias};

    $self->{shutdown} = 1;
    
    $self->{wheel}->shutdown_stdin
        if $self->{wheel};
}

1;
__END__

=head1 NAME

POE::Component::WWW::CPANRatings::RSS - non-blocking wrapper around WWW::CPANRatings::RSS

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::WWW::CPANRatings::RSS);

    my $poco = POE::Component::WWW::CPANRatings::RSS->spawn;

    POE::Session->create(
        package_states => [ main => [qw(_start ratings )] ],
    );

    my $Count = 0;

    $poe_kernel->run;

    sub _start {
        $poco->fetch( {
                event   => 'ratings',
                unique  => 1,
                repeat  => 10,
            }
        );
    }

    sub ratings {
        my $in_ref = $_[ARG0];
        if ( $in_ref->{error} ) {
            print "ERROR: $in_ref->{error}\n\n";
        }
        else {
            print "New reviews:\n";
            for ( @{ $in_ref->{ratings} } ) {
                printf "%s - %s stars - by %s\n--- %s ---\nsee %s\n\n\n",
                    @$_{ qw/dist rating creator comment link/ };
            }
        }
    }

Using event based interface is also possible of course.

=head1 DESCRIPTION

The module is a non-blocking wrapper around L<WWW::CPANRatings::RSS>
which provides interface to fetch data from the RSS feed on
L<http://cpanratings.perl.org/>

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::WWW::CPANRatings::RSS->spawn;

    POE::Component::WWW::CPANRatings::RSS->spawn(
        alias => 'cpan_ratings',
        ua    => {
            timeout => 30,
        },
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::WWW::CPANRatings::RSS object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    ->spawn( alias => 'cpan_ratings' );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 C<ua>

    ua => {
        timeout => 30,
    },

B<Optional>. Takes a hashref as a value. That hashref will be directly
dereferenced into L<LWP::UserAgent>'s constructor. See L<LWP::UserAgent>
documentation for possible keys/values. B<Defaults to:>
C<< { timeout => 30 } >>

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

=head2 C<fetch>

    $poco->fetch( {
            event       => 'event_for_output',
            unique      => 1,
            repeat      => 60,
            repeat_name => 'foos',
            file        => 'cpan_ratings.store',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<fetch> event's description for more information.

=head2 C<stop_repeat>

    $poco->stop_repeat('GENERAL');

Takes one mandatory argument which is the name of the repeat to clear,
this will be whatever was set in C<repeat_name> argument of C<fetch()>
event/method. See C<stop_repeat> event description for details.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<fetch>

    $poe_kernel->post( cpan_ratings => fetch => {
            event       => 'event_for_output',
            unique      => 1,
            repeat      => 60,
            repeat_name => 'foos',
            file        => 'cpan_ratings.store',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to fetch RSS feed from
L<http://cpanratings.perl.org/>.
Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 C<event>

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 C<unique>

    { unique => 1, }

B<Optional>. Takes either true or false values. When set to a true value
will instruct the component to report only the reviews which
it hasn't reported yet (basically a call to C<fetch_unique()> in
L<WWW::CPANRatings::RSS>). B<Defaults to:> C<0>

=head3 C<repeat>

    { repeat => 60, }

B<Optional>. Takes a positive integer as a value.
When specified will instruct the component to repeat the
fetch of info every C<repeat> seconds.
This generally makes sense to use along with C<unique> argument.
B<By default> is not specified.

=head3 C<repeat_name>

    { repeat_name => 'foos', }

B<Optional>. When C<repeat> is set, specifies a name for the "alarm". You
can use this name in the C<stop_repeat()> event/method. B<Defaults to:>
C<GENERAL>

=head3 C<file>

    { file => 'cpan_ratings.store', }

B<Optional>. When C<unique> option is turned on, the component will store
already reported reviews in a file. You can specify the name of the file
with C<file> argument. B<Defaults to:> C<cpan_ratings.rss.storable>

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

=head2 C<stop_repeat>

    $poe_kernel->post( cpan_ratings => stop_repeat => 'GENERAL');

Takes one mandatory argument which is the name of the repeat to clear,
this will be whatever was set in C<repeat_name> argument of C<fetch()>
event/method. Instructs the component to stop repeating the fetch request.
Using this event/method you can stop the request which was set when
the C<repeat> argument was specified to the C<fetch> event/method.

=head2 C<shutdown>

    $poe_kernel->post( cpan_ratings => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        'unique' => 1,
        'ratings' => [
            {
                'link' => 'http://cpanratings.perl.org/#4446',
                'comment' => 'This module has failed on all swf\'s ive tried it on.  All attempts at transcoding has resulted in contentless flv that will not play.
',
                'creator' => 'Dave Williams',
                'dist' => 'FLV-Info',
                'rating' => '1'
            }
        ],
        'file' => 'foo.file.store',
        'repeat' => 10,
        '_user'  => 'defined variable',
    };


The event handler set up to handle the event which you've specified in
the C<event> argument to C<fetch()> method/event will recieve input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 C<ratings>

    'ratings' => [
        {
            'link' => 'http://cpanratings.perl.org/#4446',
            'comment' => 'This module has failed on all swf\'s ive tried it on.  All attempts at transcoding has resulted in contentless flv that will not play.
',
            'creator' => 'Dave Williams',
            'dist' => 'FLV-Info',
            'rating' => '1'
        }
    ],

The C<ratings> key will contain a (possibly empty) arrayref of hashrefs,
each hashref represents a review. See documentation for C<fetch()> and
C<fetch_unqiue()> methods in L<WWW::CPANRatings::RSS> for description
of each of the keys in those hashrefs.

=head2 C<error>

    'error' => 'Network error: 500 Timeout',

If an error occured the C<error> key will be present and it will contain
the explanation of the error.

=head2 arguments passed to C<fetch>

    {
        'unique' => 1,
        'file' => 'foo.file.store',
        'repeat' => 10
    }

The C<unique>, C<file>, C<repeat> and C<repeat_name> will be present in
the result intact.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<EXAMPLE()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<WWW::CPANRatings::RSS>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-www-cpanratings-rss at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-WWW-CPANRatings-RSS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::WWW::CPANRatings::RSS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-WWW-CPANRatings-RSS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-WWW-CPANRatings-RSS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-WWW-CPANRatings-RSS>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-WWW-CPANRatings-RSS>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


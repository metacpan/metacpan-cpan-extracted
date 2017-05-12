package POE::Component::WWW::Google::Calculator;

use strict;
use warnings;

our $VERSION = '0.03';

use POE qw( Filter::Reference  Filter::Line  Wheel::Run );
use WWW::Google::Calculator;
use Carp;
sub spawn {
    my $package = shift;
    croak "$package requires an even number of arguments"
        if @_ & 1;

    my %params = @_;

    $params{ lc $_ } = delete $params{ $_ } for keys %params;

    delete $params{options}
        unless ref $params{options} eq 'HASH';

    my $self = bless \%params, $package;

    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => {
                calc     => '_calc',
                shutdown => '_shutdown',
            },
            $self => [
                qw(
                    _child_error
                    _child_closed
                    _child_stdout
                    _child_stderr
                    _sig_child
                    _start
                )
            ]
        ],
        ( defined $params{options} ? ( options => $params{options} ) : () ),
    )->ID();

    return $self;
}

sub _start {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $self->{session_id} = $_[SESSION]->ID();
    if ( $self->{alias} ) {
        $kernel->alias_set( $self->{alias} );
    }
    else {
        $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
    }

    $self->{wheel} = POE::Wheel::Run->new(
        Program    => \&_calc_wheel,
        ErrorEvent => '_child_error',
        CloseEvent => '_child_close',
        StdoutEvent => '_child_stdout',
        StderrEvent => '_child_stderr',
        StdioFilter => POE::Filter::Reference->new,
        StderrFilter => POE::Filter::Line->new,
        ( $^O eq 'MSWin32' ? ( CloseOnCall => 0 ) : ( CloseOnCall => 1 ) )
    );

    $kernel->yield('shutdown')
        unless $self->{wheel};

    $kernel->sig_child( $self->{wheel}->PID(), '_sig_child' );

    undef;
}

sub _sig_child {
    $poe_kernel->sig_handled;
}

sub session_id {
    return $_[0]->{session_id};
}

sub calc {
    my $self = shift;
    $poe_kernel->post( $self->{session_id} => 'calc' => @_ );
}

sub _calc {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    my $sender = $_[SENDER]->ID;

    return
        if $self->{shutdown};

    my $args;
    if ( ref $_[ARG0] eq 'HASH' ) {
        $args = { %{ $_[ARG0] } };
    }
    else {
        warn "First parameter must be a hashref, trying to adjust...";
        $args = { @_[ARG0 .. $#_] };
    }

    $args->{ lc $_ } = delete $args->{ $_ }
        for grep { !/^_/ } keys %{ $args };

    unless ( $args->{event} ) {
        warn "Missing 'event' parameter to calc";
        return;
    }

    unless ( $args->{term} ) {
        warn "No 'term' parameter specified";
        return;
    }

    if ( $args->{session} ) {
        if ( my $ref = $kernel->alias_resolve( $args->{session} ) ) {
            $args->{sender} = $ref->ID;
        }
        else {
            warn "Could not resolve 'session' parameter to a valid"
                    . " POE session";
            return;
        }
    }
    else {
        $args->{sender} = $sender;
    }

    $kernel->refcount_increment( $args->{sender} => __PACKAGE__ );
    $self->{wheel}->put( $args );

    undef;
}

sub shutdown {
    my $self = shift;
    $poe_kernel->call( $self->{session_id} => 'shutdown' => @_ );
}

sub _shutdown {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $kernel->alarm_remove_all;
    $kernel->alias_remove( $_ ) for $kernel->alias_list;
    $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ )
        unless $self->{alias};

    $self->{shutdown} = 1;

    $self->{wheel}->shutdown_stdin
        if $self->{wheel};
}

sub _child_closed {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];

    warn "_child_closed called (@_[ARG0..$#_])\n"
        if $self->{debug};

    delete $self->{wheel};
    $kernel->yield('shutdown')
        unless $self->{shutdown};

    undef;
}

sub _child_error {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    warn "_child_error called (@_[ARG0..$#_])\n"
        if $self->{debug};

    delete $self->{wheel};
    $kernel->yield('shutdown')
        unless $self->{shutdown};

    undef;
}

sub _child_stderr {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    warn "_child_stderr: $_[ARG0]\n"
        if $self->{debug};

    undef;
}

sub _child_stdout {
    my ( $kernel, $self, $input ) = @_[ KERNEL, OBJECT, ARG0 ];

    my $session = delete $input->{sender};
    my $event   = delete $input->{event};

    $kernel->post( $session, $event, $input );
    $kernel->refcount_decrement( $session => __PACKAGE__ );

    undef;
}

sub _calc_wheel {
    if ( $^O eq 'MSWin32' ) {
        binmode STDIN;
        binmode STDOUT;
    }

    my $raw;
    my $size = 4096;
    my $filter = POE::Filter::Reference->new;

    my $calculator = WWW::Google::Calculator->new;

    while ( sysread STDIN, $raw, $size ) {
        my $requests = $filter->get( [ $raw ] );
        foreach my $req ( @$requests ) {
            $req->{out} = $calculator->calc( $req->{term} );
            unless ( defined $req->{out} ) {
                $req->{error} = $calculator->error;
            }

            my $response = $filter->put( [ $req ] );
            print STDOUT @$response;
        }
    }
}

1;
__END__

=encoding utf8

=head1 NAME

POE::Component::WWW::Google::Calculator - A non-blocking POE wrapper
around WWW::Google::Calculator

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::WWW::Google::Calculator);

    my $poco = POE::Component::WWW::Google::Calculator->spawn( alias => 'calc' );

    POE::Session->create(
        package_states => [
            'main' => [ qw( _start calc_result ) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $poe_kernel->alias_set('foo');
        $poe_kernel->post( 'calc' => 'calc' => {
                term => '2+2',
                event => 'calc_result',
                session => 'foo',
                _random_name => 'random_value',
            }
        );
    }

    sub calc_result {
        my ( $kernel, $result ) = @_[ KERNEL, ARG0 ];

        if ( $result->{error} ) {
            print "ZOMG! Error: $result->{error}\n";
        }
        else {
            print "Results: $result->{out}\n";
        }

        print "Oh, and BTW: $result->{_random_name}\n";

        $kernel->post( 'calc' => 'shutdown' );
    }

=head1 DESCRIPTION

This module is a simple non-blocking L<POE> wrapper around
L<WWW::Google::Calculator>

=head1 CONSTRUCTOR

    my $poco = POE::Component::WWW::Google::Calculator->spawn;

    POE::Component::WWW::Google::Calculator->spawn( alias => 'calc' );

Takes three I<optional> arguments:

=head2 alias

    POE::Component::WWW::Google::Calculator->spawn( alias => 'calc' );

Specifies a POE Kernel alias for the component

=head2 options

    POE::Component::WWW::Google::Calculator->spawn(
        options => {
            trace => 1,
            default => 1,
        },
    );

A hashref of POE Session options to pass to the component's session.

=head2 debug

    POE::Component::WWW::Google::Calculator->spawn( debug => 1 );

When set to a true value turns on output of debug messages.

=head1 METHODS

These are the object-oriented methods of the components.

=head2 calc

    $poco->calc( {
            term  => '2+2',
            event => 'calc_result',
        }
    );

Takes hashref of options. See C<calc> event below for description.

=head2 session_id

    my $calc_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 shutdown

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACEPTED EVENTS

=head2 calc

    $poe_kernel->post( 'calc' => 'calc' => {
            term          => '2+2',
            event         => 'calc_result',
            session       => $some_other_session,
            _user_defined => $whatever,
        }
    );

Instructs the component to do a calculation. Options are passed in a hashref
with keys as follows:

=head3 term

    { term => '2+2' }

B<Mandatory>. The term you wish to solve. Whatever Google's calculator
would take. Such as C<'2*2+2'> or C<'2USD in CAD'>

=head3 event

    { event => 'calc_result' }

B<Mandatory>. An event to send the result to.

=head3 session

    { session => $some_other_session_ref }

    { session => 'some_alias' }

    { session => $session->ID }

B<Optional>. An alternative session alias, reference or ID that the
response should be sent to, defaults to sending session.

=head3 user defined

B<Optional>. Any keys starting with C<_> (underscore) will not affect the
component and will be passed back in the result intact.

=head2 shutdown

    $poe_kernel->post( 'calc' => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    sub calc_result {
        my ( $kernel, $result ) = @_[ KERNEL, ARG0 ];

        if ( $result->{error} ) {
            print "ZOMG! Error: $result->{error}\n";
        }
        else {
            print "Results: $result->{out}\n";
        }

        print "Oh, and BTW: $result->{_random_name}\n";

        $kernel->post( 'calc' => 'shutdown' );
    }

The result will be posted to the event and (optional) session specified in
the arguments to the C<calc> (event or method). The result, in the form
of a hashref, will be passed in ARG0. The keys of that hashref are as
follows

=head3 out

    print "Results: $result->{out}\n";

The C<out> key will contain the result of the "calculation" in scalar form.
If an error occured it will be undefined and C<error> key will also be
present.

=head3 error

    if ( $result->{error} ) {
        print "Error calculating :( $result->{error}\n";
    }
    else {
        print "Result: $result->{out}\n";
    }

If an error occured during the calculation the C<error> key will be present
with possibly meaningful description of the error.

=head3 user defined

    print "$result->{_name}, the answer is $result->{out}\n";

Any arguments beginning with C<_> (underscore) passed into the C<calc>
event/method will be present intact in the result.

=head1 PREREQUISITES

Needs L<POE> and L<WWW::Google::Calculator>

=head1 SEE ALSO

L<POE> L<WWW::Google::Calculator>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-www-google-calculator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-WWW-Google-Calculator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::WWW::Google::Calculator

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-WWW-Google-Calculator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-WWW-Google-Calculator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-WWW-Google-Calculator>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-WWW-Google-Calculator>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

package POE::Component::WWW::DoingItWrongCom::RandImage;

use warnings;
use strict;

our $VERSION = '0.03';

use POE qw( Filter::Reference  Filter::Line  Wheel::Run );
use WWW::DoingItWrongCom::RandImage;
use Carp;

sub spawn {
    my $package = shift;
    croak "$package requires an even number of arguments"
        if @_ & 1;

    my %params = @_;

    $params{ lc $_ } = delete $params{ $_ } for keys %params;

    delete $params{options}
        unless ref $params{options} eq 'HASH';

    croak "`ua_args` parameter must be a hashref"
        if exists $params{ua_args}
            and ref $params{ua_args} ne 'HASH';

    unless ( exists $params{ua_args}{timeout} ) {
        $params{ua_args}{timeout} = 30;
    }

    my $self = bless \%params, $package;

    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => {
                fetch     => '_fetch',
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
        Program    => sub { _wheel( $self->{ua_args} ); },
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

sub fetch {
    my $self = shift;
    $poe_kernel->post( $self->{session_id} => 'fetch' => @_ );
}

sub _fetch {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    my $sender = $_[SENDER]->ID;

    return
        if $self->{shutdown};

    my $args;
    if ( ref $_[ARG0] eq 'HASH' ) {
        $args = { %{ $_[ARG0] } };
    }
    else {
        carp "First parameter must be a hashref, trying to adjust...";
        $args = { @_[ARG0 .. $#_] };
    }

    $args->{ lc $_ } = delete $args->{ $_ }
        for grep { !/^_/ } keys %{ $args };

    unless ( $args->{event} ) {
        carp "Missing 'event' parameter to fetch";
        return;
    }

    if ( $args->{session} ) {
        if ( my $ref = $kernel->alias_resolve( $args->{session} ) ) {
            $args->{sender} = $ref->ID;
        }
        else {
            carp "Could not resolve 'session' parameter to a valid"
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

sub _wheel {
    my $ua_args = shift;

    if ( $^O eq 'MSWin32' ) {
        binmode STDIN;
        binmode STDOUT;
    }

    my $raw;
    my $size = 4096;
    my $filter = POE::Filter::Reference->new;

    my $wrong = WWW::DoingItWrongCom::RandImage->new(
        ua_args => $ua_args,
    );

    while ( sysread STDIN, $raw, $size ) {
        my $requests = $filter->get( [ $raw ] );
        foreach my $req ( @$requests ) {

            $req->{out} = $wrong->fetch;

            unless ( defined $req->{out} ) {
                delete $req->{out};
                $req->{error} = $wrong->err_str;
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

POE::Component::WWW::DoingItWrongCom::RandImage - non-blocking
way to get URIs to random images from L<http://www.doingitwrong.com>

=head1 SYNOPSIS

    use strict;
    use warnings;
    use POE qw(Component::WWW::DoingItWrongCom::RandImage);

    POE::Component::WWW::DoingItWrongCom::RandImage->spawn(
        alias => 'wrong',
    );

    POE::Session->create(
        package_states => [
            main => [ qw( _start  got_pic ) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $_[KERNEL]->post( wrong => fetch => { event => 'got_pic' } );
    }

    sub got_pic {
        my ( $kernel, $input ) = @_[ KERNEL, ARG0 ];

        if ( $input->{error} ) {
            print "ERROR: $input->{error}\n";
        }
        else {
            print "You are doing it wrong: $input->{out}\n";
        }

        $kernel->post( wrong => 'shutdown' );
    }

=head1 DESCRIPTION

The module is a non-blocking wrapper around
L<WWW::DoingItWrongCom::RandImage> which fetches a URI for a random image
from L<http://www.doingitwrong.com>

=head1 CONSTRUCTOR

=head2 spawn

    my $poco = POE::Component::WWW::DoingItWrongCom::RandImage->spawn;

    POE::Component::WWW::DoingItWrongCom::RandImage->spawn(
        alias => 'wrong',
    );

    POE::Component::WWW::DoingItWrongCom::RandImage->spawn(
        alias => 'wrong',
        ua_args => {
            timeout => 30, # that's the default
            agent   => 'WrongAgent',
            # the rest of LWP::UserAgent options can go here.
        },
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );


The C<spawn> method returns a
POE::Component::WWW::DoingItWrongCom::RandImage object and takes several
aruments I<all of which are optional>. The possible arguments
are as follows:

=head3 alias

    POE::Component::WWW::DoingItWrongCom::RandImage->spawn(
        alias => 'calc'
    );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 ua_args

    my $poco = POE::Component::WWW::DoingItWrongCom::RandImage->spawn(
        ua_args => {
            timeout => 30, # that's the default
            agent   => 'WrongAgent',
            # the rest of LWP::UserAgent options can go here.
        },
    );

B<Optional>. The C<ua_args> argument takes a hashref as a value which
will be passed to L<LWP::UserAgent> object constructor. See
L<LWP::UseAgent> documentation for possible keys/values. B<By default>
the default L<LWP::UserAgent>'s constructor will be used I<except> for
C<timeout> which, unless specified by you, will default to C<30> seconds.

=head3 options

    my $poco = POE::Component::WWW::DoingItWrongCom::RandImage->spawn(
        options => {
            trace => 1,
            default => 1,
        },
    );

A hashref of POE Session options to pass to the component's session.

=head3 debug

    my $poco = POE::Component::WWW::DoingItWrongCom::RandImage->spawn(
        debug => 1
    );

When set to a true value turns on output of debug messages. B<Defaults to:>
C<0>.

=head1 METHODS

These are the object-oriented methods of the components.

=head2 fetch

    $poco->fetch( { event => 'got_pic' } );

    $poco->fetch( {
            event         => 'got_pic',
            session       => 'other_session',
            _user_defined => 'something_random',
            _random       => 'moar_randomness',
        }
    );

Takes hashref of options. See C<fetch> event below for description.

=head2 session_id

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 shutdown

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACEPTED EVENTS

=head2 fetch

    $poe_kernel->post( wrong => fetch => {
            event         => 'got_pic',
            session       => 'other_session',
            _user_defined => 'something_random',
            _random       => 'moar_randomness',
        }
    );

Instructs the component to fetch a URI to a random image from
L<http://www.doingitwrong.com>. Takes one argument which is a hashref
of options with keys/values as follows:

=head3 event

    { event => 'got_pic' }

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

    $poe_kernel->post( wrong => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

 $VAR1 = {
    'out' => bless( do{\(my $o = 'http://www.doingitwrong.com/wrong/20070527-113810.jpg')}, 'URI::http' ),
    '_num' => 4
 };


The event handler set up to handle the event, the name of which you've
specified in the C<event> parameter of the C<fetch()> event/method
will recieve the results of the request from C<fetch>. They will be
passed in a form of a hashref in C<ARG0>. The possible keys will be
as follows:

=head2 out

 {
    'out' => bless( do{\(my $o = 'http://www.doingitwrong.com/wrong/20070527-113810.jpg')}, 'URI::http' ),
 }

If no errors occured, the C<out> key will be present and the value
will be a L<URI> object for the URI of the random image from
L<http://www.doingitwrong.com>.

=head2 error

    { 'error' => '500: Request timed out' }

If some sort of an error occured during the request, the C<error>
key will be present and will contain the description of an error.


=head3 user defined

    { '_num' => 4 }

Any arguments beginning with C<_> (underscore) passed into the C<fetch>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<LWP::UserAgent>, L<URI>, L<WWW::DoingItWrongCom::RandImage>

=head1 PREREQUISITES

For healthy life this module requires the following modules/versions:

    'Carp'                            => 1.04,
    'POE'                             => 0.9999,
    'POE::Filter::Reference'          => 1.2187,
    'POE::Filter::Line'               => 1.1920,
    'POE::Wheel::Run'                 => 1.2179,
    'WWW::DoingItWrongCom::RandImage' => 0.01,

The module might work with older versions but that wasn't tested.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-www-doingitwrongcom-randimage at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-WWW-DoingItWrongCom-RandImage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::WWW::DoingItWrongCom::RandImage

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-WWW-DoingItWrongCom-RandImage>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-WWW-DoingItWrongCom-RandImage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-WWW-DoingItWrongCom-RandImage>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-WWW-DoingItWrongCom-RandImage>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

package POE::Component::WWW::WebDevout::BrowserSupportInfo;

use warnings;
use strict;

our $VERSION = '2.001001'; # VERSION

use Carp;
use POE qw(Wheel::Run Filter::Reference Filter::Line);
use WWW::WebDevout::BrowserSupportInfo;

sub spawn {
    my $package = shift;

    croak "Must have even number of arguments to spawn()"
        if @_ & 1;

    my %params = @_;

    $params{ lc $_ } = delete $params{ $_ } for keys %params;

    delete $params{options}
        unless ref $params{options} eq 'HASH';

    my $self = bless \%params, $package;

    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => {
                fetch      => '_fetch',
                shutdown   => '_shutdown',
            },
            $self => [
                qw(
                    _child_error
                    _child_close
                    _child_stderr
                    _child_stdout
                    _sig_chld
                    _start
                )
            ],
        ],
        ( exists $params{options} ? ( options => $params{options} ) : () ),
    )->ID;

    return $self;
}

sub _start {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
     $self->{session_id} = $_[SESSION]->ID();
    if  ( $self->{alias} ) {
        $kernel->alias_set( $self->{alias} );
    }
    else {
        $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
    }

    $self->{wheel} = POE::Wheel::Run->new(
        Program => sub { _wheel( $self->{obj_args} || {} ); },
        ErrorEvent => '_child_error',
        CloseEvent => '_child_close',
        StderrEvent => '_child_stderr',
        StdoutEvent => '_child_stdout',
        StdioFilter => POE::Filter::Reference->new,
        StderrFilter => POE::Filter::Line->new,
        ( $^O eq 'MSWin32' ? ( CloseOnCall => 0 ) : ( CloseOnCall => 1 ) ),
    );

    $kernel->call('shutdown')
        unless $self->{wheel};

    $kernel->sig_child( $self->{wheel}->PID, '_sig_chld' );
}

sub _sig_chld {
    $poe_kernel->sig_handled;
}

sub _child_close {
    my ( $kernel, $self, $wheel_id ) = @_[ KERNEL, OBJECT, ARG0 ];

    warn "_child_close called (@_[ARG0..$#_])\n"
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

    delete @$input{ qw(login pass ua_args) };

    $kernel->post( $session, $event, $input );
    $kernel->refcount_decrement( $session => __PACKAGE__ );

    undef;
}

sub shutdown {
    my $self = shift;
    $poe_kernel->post( $self->{session_id} => 'shutdown' );
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

sub session_id {
    return $_[0]->{session_id};
}

sub fetch {
    my $self = shift;
    $poe_kernel->post( $self->{session_id} => 'fetch' => @_ );
}

sub _fetch {
    my ( $kernel, $self, $args )= @_[ KERNEL, OBJECT, ARG0 ];

    my $sender = $_[SENDER]->ID;

    return
        if $self->{shutdown};

    $args->{ lc $_ } = delete $args->{ $_ }
        for grep { !/^_/ } keys %{ $args };

    unless ( defined $args->{what} ) {
        carp "Missing the term to look up (`what` argument)";
        return;
    }

    unless ( defined $args->{event} ) {
        carp "Missing the name of the event for results (`event` argument)";
        return;
    }

    if ( $args->{session} ) {
        if ( my $ref = $kernel->alias_resolve( $args->{session} ) ) {
            $args->{sender} = $ref->ID;
        }
        else {
            carp "Could not resolve `session` parameter to a "
                    . "valid POE session. Aborting...";
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

sub _wheel {
    my $poco_args = shift;
    if ( $^O eq 'MSWin32' ) {
        binmode STDIN;
        binmode STDOUT;
    }

    my $wd = WWW::WebDevout::BrowserSupportInfo->new( %$poco_args );

    my $raw;
    my $size = 4096;
    my $filter = POE::Filter::Reference->new;

    while ( sysread STDIN, $raw, $size ) {
        my $requests = $filter->get( [ $raw ] );
        foreach my $req_ref ( @$requests ) {

            _retrieve_browser_info( $wd, $req_ref );

            my $response = $filter->put( [ $req_ref ] );
            print STDOUT @$response;
        }
    }
}

sub _retrieve_browser_info {
    my ( $wd, $req_ref ) = @_;

    my $results = $wd->fetch( $req_ref->{what} );
    if ( defined $results ) {
        @$req_ref{   qw( uri_info  results ) }
        = ( $wd->uri_info, $wd->browser_results );
    }
    else {
        $req_ref->{error} = $wd->error;
    }
    undef;
}

1;
__END__

=encoding utf8

=head1 NAME

POE::Component::WWW::WebDevout::BrowserSupportInfo - non-blocking
access to browser support API on L<http://webdevout.net>

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::WWW::WebDevout::BrowserSupportInfo);

    my $poco = POE::Component::WWW::WebDevout::BrowserSupportInfo->spawn(
        obj_args => { long => 1 },
    );

    POE::Session->create(
        package_states => [
            main => [ qw( _start  fetched ) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $poco->fetch( {
                what  => 'display block',
                event => 'fetched',
            }
        );
    }

    sub fetched {
        my $in = $_[ARG0];

        print "Support for $in->{what}\n";

        print "\t$_ => $in->{results}{ $_ }\n"
            for keys %{ $in->{results} };

        print "For more information visit: $in->{uri_info}\n";

        $poco->shutdown;
    }

=head1 DESCRIPTION

The module is a non-blocking L<POE> wrapper around
L<WWW::WebDevout::BrowserSupportInfo> which provides access to
browser support API on L<http://webdevout.net>

=head1 CONSTRUCTOR

=head2 spawn

    my $poco = POE::Component::WWW::WebDevout::BrowserSupportInfo->spawn;

    POE::Component::WWW::WebDevout::BrowserSupportInfo->spawn(
        alias => 'info',
        obj_args => {   # WWW::WebDevout::BrowserSupportInfo..
            long => 1,  # ... constructor options here.
        },
        options  => {   # POE::Session options here
            debug => 1,
        }
        debug => 1,
    );

Constructs and returns a brand new out of the box
C<POE::Component::WWW::WebDevout::BrowserSupportInfo> object. However,
you don't have to store it anywhere if you set the C<alias> argument.
Takes a number of arguments I<all of which are optional>. The possible
arguments/values are as follows:

=head3 alias

    ->spawn( alias => 'recent' );

B<Optional>. Specifies the component's L<POE::Session> alias of the
component.

=head3 obj_args

    ->spawn(
        obj_args => {
            long => 1,
            browser => [ qw(IE6 IE7) ],
        },
    );

B<Optional>. Takes a hashref as an argument which contains
L<WWW::WebDevout::BrowserSupportInfo> constructor's arguments.
See L<WWW::WebDevout::BrowserSupportInfo> documentation for possible
arguments. B<Defaults to:> default L<WWW::WebDevout::BrowserSupportInfo>
constructor.

=head3 debug

B<Optional>.

    ->spawn( debug   => 1 );

B<Optional>. When set to a true value will make the component emit some
debugging info. Defaults to false.

=head3 options

    {
        options => {
            trace   => 1,
            default => 1,
        }
    }

A hashref of POE Session options to pass to the component's session.

=head1 METHODS

These are the object-oriented methods of the component.

=head2 fetch

    $poco->fetch( {
            what    => 'css',                 # mandatory
            event   => 'event_for_results',   # mandatory
            session => 'other_session',       # optional
        }
    );

Instructs the component to fetch browser support information. Takes
a hashref as an argument. See C<fetch> event description for details.

=head2 session_id

    my $info_poco_id = $poco->session_id;

Takes no arguments. Returns POE Session ID of the component.

=head2 shutdown

    $poco->shutdown;

Takes no arguments. Shuts the component down.

=head1 ACCEPTED EVENTS

The interaction with the component is also possible via event based
interface. The following events are accepted by the component:

=head2 fetch

    $poe_kernel->post( info => fetch => {
            what    => 'css',                 # mandatory
            event   => 'event_for_results',   # mandatory
            session => 'other_session',       # optional
            _user   => 'defined',             # optional user defined arg.
        }
    );

Instructs the component to fetch browser support information. Takes
a hashref as an argument. The possible key/values of that hashref
are as follows:

=head3 what

    { what => 'css' }
    { what => 'display block' }
    { what => 'span' }

B<Mandatory>. Takes a scalar as a value which is the term to look up.
There are no set definitions on
what the term might be. The possible values would resemble something from
L<http://www.webdevout.net/browser-support>. Try to omit some
punctuation, in other words if you want to look up browser support
for CSS C<{ display: block; }> property/value, use C<display block> as
a value to C<what>.

=head3 event

    { event => 'results_event' }

B<Mandatory>. Takes a scalar as a value, which is the name of the event
to send the results to. See also OUTPUT section.

=head3 session

    { session => 'other_session_alias' }

    { session => $other_session_ID }

    { session => $other_session_ref }

B<Optional>. Specifies an alternative POE Session to send the output to.
Accepts either session alias, session ID or session reference. Defaults
to the current session.

=head3 user defined arguments

    {
        _user_var    => 'foos',
        _another_one => 'bars',
        _some_other  => 'beers',
    }

B<Optional>. Any keys beginning with the C<_> (underscore) will be present
in the output intact.

=head1 OUTPUT

    $VAR1 = {
        'what' => 'html',
        'uri_info' => 'http://www.webdevout.net/browser-support-html#support-html401',
        'results' => {
            'SF2' => '?',
            'FX1_5' => '91.741%',
            'FX2' => '91.741%',
            'IE6' => '80.211%',
            'IE7' => '80.802%',
            'OP8' => '85.822%',
            'OP9' => '86.361%',
            'KN3_5' => '?'
        },
        _user => 'defined',
    };

    # with ->spawn( obj_args => { long => 1 } );
    $VAR1 = {
        'what' => 'html',
        'uri_info' => 'http://www.webdevout.net/browser-support-html#support-html401',
        'results' => {
            'Opera 9' => '86.361%',
            'Internet Explorer 6' => '80.211%',
            'FireFox 1.5' => '91.741%',
            'Safari 2' => '?',
            'FireFox 2' => '91.741%',
            'Opera 8' => '85.822%',
            'Internet Explorer 7' => '80.802%',
            'Konqueror 3.5' => '?'
        },
        _user => 'defined',
    };

The event handler set up to handle the event you've specified in the
C<event> argument to C<fetch()> event/method will receive input from
the component in C<$_[ARG0]> in a form of a hashref. The possible keys
of the hashref are as follows:

=head2 what

    { what => 'html' }

The C<what> key will contain the term, support for which we looked up.
This is basically what you have supplied into C<what> argument of the
C<fetch()> event/method.

=head2 uri_info

    { 'uri_info' => 'http://www.webdevout.net/browser-support-html#support-html401' }

The C<uri_info> key will contain a URI pointing to the support information
of the term you've looked up on L<http://webdevout.net>.

=head2 results

    'results' => {
        'Opera 9' => '86.361%',
        'Internet Explorer 6' => '80.211%',
        'FireFox 1.5' => '91.741%',
        'Safari 2' => '?',
        'FireFox 2' => '91.741%',
        'Opera 8' => '85.822%',
        'Internet Explorer 7' => '80.802%',
        'Konqueror 3.5' => '?'
    }

Unless an error occurred, the C<results> key will contain the output
of L<WWW::WebDevout::BrowserSupportInfo>'s C<browser_results()> method,
which is a hashref with keys being browser names or browser codes depending
on the C<long> argument which you've might have supplied to C<obj_args>
to the component's constructor. See L<WWW::WebDevout::BrowserSupportInfo>
C<browser_results()> method documentation for more information.

=head2 error

    { 'error' => 'No results' }

If an error occurred during the look up, or no results were returned,
the C<error> key will be present with the explanation of the error.

=head2 user defined arguments

    {
        _user_var    => 'foos',
        _another_one => 'bars',
        _some_other  => 'beers',
    }

B<Optional>. Any keys beginning with the C<_> (underscore) will be present
in the output intact.

=head1 SEE ALSO

L<WWW::WebDevout::BrowserSupportInfo>, L<POE>, L<http://webdebout.net>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/POE-Component-Bundle-WebDevelopment>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/POE-Component-Bundle-WebDevelopment/issues>

If you can't access GitHub, you can email your request
to C<bug-POE-Component-Bundle-WebDevelopment at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
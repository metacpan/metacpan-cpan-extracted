package POE::Component::NonBlockingWrapper::Base;

use warnings;
use strict;

our $VERSION = '1.001002'; # VERSION

use Carp;
use POE qw( Filter::Reference  Filter::Line  Wheel::Run );

sub spawn {
    my $package = shift;
    croak "$package requires an even number of arguments"
        if @_ & 1;

    my %args = @_;

    $args{ lc $_ } = delete $args{ $_ } for keys %args;

    delete $args{options}
        unless ref $args{options} eq 'HASH';

    my $self = bless \%args, $package;

    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => {
                $self->_methods_define( \%args ),
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
        ( defined $args{options} ? ( options => $args{options} ) : () ),
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
        Program    => sub{ $self->_wheel; },
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

sub _wheel_entry {
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
        for grep { !/^_/ } keys %$args;

    $self->_check_args( $args )
        or return;

    unless ( defined $args->{event} ) {
        carp '`event` argument is not defined';
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

    carp "_child_closed called (@_[ARG0..$#_])\n"
        if $self->{debug};

    delete $self->{wheel};
    $kernel->yield('shutdown')
        unless $self->{shutdown};

    undef;
}

sub _child_error {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    carp "_child_error called (@_[ARG0..$#_])\n"
        if $self->{debug};

    delete $self->{wheel};
    $kernel->yield('shutdown')
        unless $self->{shutdown};

    undef;
}

sub _child_stderr {
    my $self = $_[ OBJECT ];
    carp "_child_stderr: $_[ARG0]\n"
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
    my $self = shift;

    $self->_prepare_wheel;

    if ( $^O eq 'MSWin32' ) {
        binmode STDIN;
        binmode STDOUT;
    }

    my $raw;
    my $size = 4096;
    my $filter = POE::Filter::Reference->new;

    while ( sysread STDIN, $raw, $size ) {
        my $requests = $filter->get( [ $raw ] );
        foreach my $req_ref ( @$requests ) {

            $self->_process_request( $req_ref ); # changes $req_ref

            my $response = $filter->put( [ $req_ref ] );
            print STDOUT @$response;
        }
    }
}

sub _process_request {
    croak 'Looks like the author of the module did not override '
            . '_process_request() sub';
}

sub _check_args { 1; }
sub _prepare_wheel { 1; }

sub _methods_define {
    croak 'Looks like the author of the module did not override '
            . '_methods_define() sub';
}


1;
__END__

=encoding utf8

=for stopwords AnnoCPAN RT thingy PoCo

=head1 NAME

POE::Component::NonBlockingWrapper::Base - POE based base class for non-blocking wrappers around blocking stuff

=head1 SYNOPSIS

    use strict;
    use warnings;

    package POE::Component::Example;

    use POE;
    use base 'POE::Component::NonBlockingWrapper::Base';

    sub _methods_define {
        return ( get_time => '_wheel_entry' );
    }

    sub get_time {
        $poe_kernel->post( shift->{session_id} => get_time => @_ );
    }

    sub _process_request {
        # of course, here you'd normally do your blocking stuff
        $_[1]->{time} = localtime;
    }

    package main;

    use POE;
    my $poco = POE::Component::Example->spawn;

    POE::Session->create( package_states => [ main => [qw(_start results)] ], );

    $poe_kernel->run;

    sub _start {
        $poco->get_time({ event => 'results' });
    }

    sub results {
        print "Current time is: $_[ARG0]->{time}\n";
        $poco->shutdown;
    }

=head1 DESCRIPTION

The module is a base class for modules which are non-blocking POE based
wrappers around blocking stuff. Non-blocking stuff is run via a I<single>
L<POE::Wheel::Run> process. You might also want to check out
L<POE::Component::Generic> or
L<POE::Component::Generic::Object> for more goodies.

=head1 HOW TO USE THIS

First read the "DOCUMENTATION FOR YOUR MODULE" section at the bottom, then
read the "METHODS TO OVERRIDE" and "METHODS TO DEFINE" sections below,
that should fill you up.

Then you need to C<use base> with this class:

    use base 'POE::Component::NonBlockingWrapper::Base';

Finally, you need to redefine some methods and make some of your own.

=head1 METHODS TO OVERRIDE

=head2 C<_methods_define>

    sub _methods_define {
        my $self = shift;
        return (
            get_time        => '_wheel_entry',
            something_else  => $self->{args_from_new_methods},
        );
    }

This sub must return a list of key/value pairs which will be passed into
the L<POE::Session> the base class creates. The first element of C<@_>
will be your PoCo object, the arguments which were passed into the
constructor (new()) will be available as hashref keys in your object.

The keys returned will be valid POE events your POE::Component will accept.
B<Note:> the method/event which will be talking to the non-blocking wheel
B<must> contain C<_wheel_entry> as the value. Also note that the
C<shutdown> method/event is pre-made already so you don't have to worry
about returning it from C<_methods_define()> sub.

The call to C<_methods_define> is made as:

    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => {
                $self->_methods_define,
                shutdown => '_shutdown',
            },
            # blah blah

=head2 C<_prepare_wheel>

    sub _prepare_wheel {
        my $self = shift;
        $self->{premade_obj} = Some::Module->new;
    }

You don't have to override this sub, but you can if you want to "prepare"
the POE::Wheel::Run'ed child process before it goes down into listening
for requests. The first and only element in C<@_> will be your PoCo
object, note that the (probably) only useful thing from it might be the
args you've passed to it in the C<new()> method as POE goodies won't be
preserved for the kiddo process. The args can be accessed as hashref keys in
your PoCo object. You can also stuff it up in the same manner to later
use those in C<_process_request()> sub (see below)

=head2 C<_check_args>

    sub _check_args {
        my ( $self, $args_ref ) = @_;

        return
            unless $args_ref->{foos} eq 'bar';

        return 1;
    }

Redefining this method allows you to check up the arguments the user
passed in the method calling the C<_wheel_entry> (see description of
C<_methods_define()> above). All arguments will be lowercased, special
keys are C<event> and C<sender>, if C<event> is not present after
the call to C<_check_args()> C<_wheel_entry> will C<carp()> and abort.
The C<sender> is used internally and your data assigned to this key will
get corrupted. The C<_check_args()> must return a true value if arguments
look fine, if it returns a false value C<_wheel_entry> will abort (by
doing C<return;>). The first element of C<@_> will be your POE::Component
object, second element will be hashref of arguments passed to the method
mapped to C<_wheel_entry> (see description of C<_methods_define()> above).

=head2 C<_process_request>

    sub _process_request {
        my ( $self, $req_ref ) = @_;
        $req_ref->{time} = localtime;
        # blah blah, do blocking stuff
    }

The C<_process_request()> sub is the core of non-blocking doings your
module would perform. This will be run in the child process so you can
block it all you want (note, however, than any other requests for this
non-blocked thingy will be queried up, we are doing everything with
I<one> wheel, remember). The first element of C<@_> will be your
(semi-crippled) PoCo object and the second element of C<@_> will be a
hashref containing the "request" (see C<_check_args()> method's description
above). Don't touch the C<event> and C<sender> keys, otherwise your
code will grow arms and bad things will happen. Generally you'd only want
to I<add> keys to this hashref. This "request" hashref will be returned
as C<$_[ARG0]> on the event listening for the output and your edits to
it are "live", i.e. the return value of C<_process_request()> method is
discarded and C<$_[1]> will be passed along.

=head1 METHODS TO DEFINE

    sub get_time {
        $poe_kernel->post( shift->{session_id} => get_time => @_ );
    }

Basically, you would need to declare any methods ( the "keys" returned
from the C<_methods_define()> sub) to call POE events, this is done so
your PoCo could be used with OO interface instead of sending it events.
The C<@_> will look like standard OO stuff, your PoCo object in C<$_[0]>
and args filled in the rest of C<@_>. The session you need to post to
is stored in C<< $_[0]->{session_id} >>. I can't really think of anything
else you'd be wanting to do here except for what is done in the code above
(well, I CAN, but I am too lazy to explain because if I *do* question
starting with "Well, why didn't you then..." will follow :D )

=head1 DOCUMENTATION FOR YOUR MODULE

This sections contains a copy/paste friendly POD which you might wish
to include in your module to describe functionality. This section
also describes the functionality of this base class which is "visible"
to the user of your module. The stuff you'd want to edit is marked with
word "EXAMPLE" but make sure to proof read the entire thing :)

    =head1 NAME

    POE::Component::EXAMPLE - non-blocking wrapper around EXAMPLE

    =head1 SYNOPSIS

        use strict;
        use warnings;

        use POE qw(Component::EXAMPLE);

        my $poco = POE::Component::EXAMPLE->spawn;

        POE::Session->create(
            package_states => [ main => [qw(_start EXAMPLE )] ],
        );

        $poe_kernel->run;

        sub _start {
            $poco->EXAMPLE( {
                    EXAMPLE => 'EXAMPLE',
                    event => 'EXAMPLE',
                }
            );
        }

        sub EXAMPLE {
            my $in_ref = $_[ARG0];

            EXAMPLE
            EXAMPLE

            $poco->shutdown;
        }

    Using event based interface is also possible of course.

    =head1 DESCRIPTION

    The module is a non-blocking wrapper around L<EXAMPLE>
    which provides interface to EXAMPLE

    =head1 CONSTRUCTOR

    =head2 C<spawn>

        my $poco = POE::Component::EXAMPLE->spawn;

        POE::Component::EXAMPLE->spawn(
            alias => 'EXAMPLE',
            EXAMPLE => 'EXAMPLE',
            options => {
                debug => 1,
                trace => 1,
                # POE::Session arguments for the component
            },
            debug => 1, # output some debug info
        );

    The C<spawn> method returns a
    POE::Component::EXAMPLE object. It takes a few arguments,
    I<all of which are optional>. The possible arguments are as follows:

    =head3 C<alias>

        ->spawn( alias => 'EXAMPLE' );

    B<Optional>. Specifies a POE Kernel alias for the component.

    =head3 C<EXAMPLE>

        EXAMPLE

    EXAMPLE

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

    =head2 C<EXAMPLE>

        $poco->EXAMPLE( {
                event       => 'event_for_output',
                EXAMPLE     => 'EXAMPLE,
                _blah       => 'pooh!',
                session     => 'other',
            }
        );

    Takes a hashref as an argument, does not return a sensible return value.
    See C<EXAMPLE> event's description for more information.

    =head2 C<session_id>

        my $poco_id = $poco->session_id;

    Takes no arguments. Returns component's session ID.

    =head2 C<shutdown>

        $poco->shutdown;

    Takes no arguments. Shuts down the component.

    =head1 ACCEPTED EVENTS

    =head2 C<EXAMPLE>

        $poe_kernel->post( EXAMPLE => EXAMPLE => {
                event       => 'event_for_output',
                EXAMPLE     => 'EXAMPLE',
                _blah       => 'pooh!',
                session     => 'other',
            }
        );

    Instructs the component to EXAMPLE. Takes a hashref as an
    argument, the possible keys/value of that hashref are as follows:

    =head3 event

        { event => 'results_event', }

    B<Mandatory>. Specifies the name of the event to emit when results are
    ready. See OUTPUT section for more information.

    =head3 EXAMPLE

        EXAMPLE

    EXAMPLE

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

        $poe_kernel->post( EXAMPLE => 'shutdown' );

    Takes no arguments. Tells the component to shut itself down.

    =head1 OUTPUT

        $VAR1 = {
            'EXAMPLE' => 'EXAMPLE',
            '_blah' => 'foos'
        };

    The event handler set up to handle the event which you've specified in
    the C<event> argument to C<EXAMPLE()> method/event will recieve input
    in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
    that hashref are as follows:

    =head2 EXAMPLE

        EXAMPLE
        EXAMPLE

    =head2 user defined

        { '_blah' => 'foos' }

    Any arguments beginning with C<_> (underscore) passed into the C<EXAMPLE()>
    event/method will be present intact in the result.

    =head1 SEE ALSO

    L<POE>, L<EXAMPLE>

=head1 SEE ALSO

L<POE>, L<POE::Wheel::Run>, L<POE::Component::Generic>,
L<POE::Component::Generic::Object>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/POE-Component-NonBlockingWrapper-Base>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/POE-Component-NonBlockingWrapper-Base/issues>
If you can't access GitHub, you can email your request
to C<bug-poe-component-nonblockingwrapper-base at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org> (L<http://zoffix.com/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
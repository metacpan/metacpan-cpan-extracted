# NAME

POE::Component::NonBlockingWrapper::Base - POE based base class for non-blocking wrappers around blocking stuff

# SYNOPSIS

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

# DESCRIPTION

The module is a base class for modules which are non-blocking POE based
wrappers around blocking stuff. Non-blocking stuff is run via a _single_
[POE::Wheel::Run](https://metacpan.org/pod/POE::Wheel::Run) process. You might also want to check out
[POE::Component::Generic](https://metacpan.org/pod/POE::Component::Generic) or
[POE::Component::Generic::Object](https://metacpan.org/pod/POE::Component::Generic::Object) for more goodies.

# HOW TO USE THIS

First read the "DOCUMENTATION FOR YOUR MODULE" section at the bottom, then
read the "METHODS TO OVERRIDE" and "METHODS TO DEFINE" sections below,
that should fill you up.

Then you need to `use base` with this class:

    use base 'POE::Component::NonBlockingWrapper::Base';

Finally, you need to redefine some methods and make some of your own.

# METHODS TO OVERRIDE

## `_methods_define`

    sub _methods_define {
        my $self = shift;
        return (
            get_time        => '_wheel_entry',
            something_else  => $self->{args_from_new_methods},
        );
    }

This sub must return a list of key/value pairs which will be passed into
the [POE::Session](https://metacpan.org/pod/POE::Session) the base class creates. The first element of `@_`
will be your PoCo object, the arguments which were passed into the
constructor (new()) will be available as hashref keys in your object.

The keys returned will be valid POE events your POE::Component will accept.
__Note:__ the method/event which will be talking to the non-blocking wheel
__must__ contain `_wheel_entry` as the value. Also note that the
`shutdown` method/event is pre-made already so you don't have to worry
about returning it from `_methods_define()` sub.

The call to `_methods_define` is made as:

    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => {
                $self->_methods_define,
                shutdown => '_shutdown',
            },
            # blah blah

## `_prepare_wheel`

    sub _prepare_wheel {
        my $self = shift;
        $self->{premade_obj} = Some::Module->new;
    }

You don't have to override this sub, but you can if you want to "prepare"
the POE::Wheel::Run'ed child process before it goes down into listening
for requests. The first and only element in `@_` will be your PoCo
object, note that the (probably) only useful thing from it might be the
args you've passed to it in the `new()` method as POE goodies won't be
preserved for the kiddo process. The args can be accessed as hashref keys in
your PoCo object. You can also stuff it up in the same manner to later
use those in `_process_request()` sub (see below)

## `_check_args`

    sub _check_args {
        my ( $self, $args_ref ) = @_;

        return
            unless $args_ref->{foos} eq 'bar';

        return 1;
    }

Redefining this method allows you to check up the arguments the user
passed in the method calling the `_wheel_entry` (see description of
`_methods_define()` above). All arguments will be lowercased, special
keys are `event` and `sender`, if `event` is not present after
the call to `_check_args()` `_wheel_entry` will `carp()` and abort.
The `sender` is used internally and your data assigned to this key will
get corrupted. The `_check_args()` must return a true value if arguments
look fine, if it returns a false value `_wheel_entry` will abort (by
doing `return;`). The first element of `@_` will be your POE::Component
object, second element will be hashref of arguments passed to the method
mapped to `_wheel_entry` (see description of `_methods_define()` above).

## `_process_request`

    sub _process_request {
        my ( $self, $req_ref ) = @_;
        $req_ref->{time} = localtime;
        # blah blah, do blocking stuff
    }

The `_process_request()` sub is the core of non-blocking doings your
module would perform. This will be run in the child process so you can
block it all you want (note, however, than any other requests for this
non-blocked thingy will be queried up, we are doing everything with
_one_ wheel, remember). The first element of `@_` will be your
(semi-crippled) PoCo object and the second element of `@_` will be a
hashref containing the "request" (see `_check_args()` method's description
above). Don't touch the `event` and `sender` keys, otherwise your
code will grow arms and bad things will happen. Generally you'd only want
to _add_ keys to this hashref. This "request" hashref will be returned
as `$_[ARG0]` on the event listening for the output and your edits to
it are "live", i.e. the return value of `_process_request()` method is
discarded and `$_[1]` will be passed along.

# METHODS TO DEFINE

    sub get_time {
        $poe_kernel->post( shift->{session_id} => get_time => @_ );
    }

Basically, you would need to declare any methods ( the "keys" returned
from the `_methods_define()` sub) to call POE events, this is done so
your PoCo could be used with OO interface instead of sending it events.
The `@_` will look like standard OO stuff, your PoCo object in `$_[0]`
and args filled in the rest of `@_`. The session you need to post to
is stored in `$_[0]->{session_id}`. I can't really think of anything
else you'd be wanting to do here except for what is done in the code above
(well, I CAN, but I am too lazy to explain because if I \*do\* question
starting with "Well, why didn't you then..." will follow :D )

# DOCUMENTATION FOR YOUR MODULE

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

# SEE ALSO

[POE](https://metacpan.org/pod/POE), [POE::Wheel::Run](https://metacpan.org/pod/POE::Wheel::Run), [POE::Component::Generic](https://metacpan.org/pod/POE::Component::Generic),
[POE::Component::Generic::Object](https://metacpan.org/pod/POE::Component::Generic::Object)

# REPOSITORY

Fork this module on GitHub:
[https://github.com/zoffixznet/POE-Component-NonBlockingWrapper-Base](https://github.com/zoffixznet/POE-Component-NonBlockingWrapper-Base)

# BUGS

To report bugs or request features, please use
[https://github.com/zoffixznet/POE-Component-NonBlockingWrapper-Base/issues](https://github.com/zoffixznet/POE-Component-NonBlockingWrapper-Base/issues)
If you can't access GitHub, you can email your request
to `bug-poe-component-nonblockingwrapper-base at rt.cpan.org`

# AUTHOR

Zoffix Znet <zoffix at cpan.org> ([http://zoffix.com/](http://zoffix.com/))

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.

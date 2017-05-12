use 5.008;
use strict;
use warnings;

package Sub::StopCalls;

our $VERSION = '0.02';

use XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

=head1 NAME

Sub::StopCalls - stop sub calls (make it a constant)

=head1 SYNOPSIS

    my $i = 0;

    sub boo {
        return foo();
    }
    sub foo {
        $i++;
        return Sub::StopCalls::stop();
    }

    print "$i\n"; # 0
    boo();
    print "$i\n"; # 1
    boo();
    print "$i\n"; # 1

=head1 DESCRIPTION

Basicly you can do the following in a function to mean "Hey, You!
You, who called me, stop calling me, I will always return
the same result":

    return Sub::StopCalls::stop( @result );

Still no idea how to use? Ok, here some use cases:

=head1 USE CASES

=head2 conditional constants

Classic C<if DEBUG> thing:

    sub debug {
        return Sub::StopCalls::stop() unless $ENV{'MY_APP_DEBUG'};
        ...
    }

Or logger:

    package My::Logger;
    sub warn {
        return Sub::StopCalls::stop() if $self->{max_level} < LEVEL_WARN;
        ...
    }

=head2 accessors to singletons

    package MyApp;
    
    my $system;
    sub system {
        $system ||= do {
            ... init system object ...
        };
        return Sub::StopCalls::stop( $system );
    }

=head2 hooks, triggers and callbacks

    sub trigger {
        my $self = shift;
        my @triggers = $self->find_triggers(caller);
        return Sub::StopCalls::stop() unless @triggers;

        ...
    }

=head1 FUNCTIONS

=head2 stop

Does the job. Replaces call on upper level with whatever
is passed into the function. Expected usage:

    return Sub::StopCalls::stop(...) if ...;

Some details

=head3 context

Result depends on context of the call that is replaced.
Nothing special about void or array context, however,
in scalar context if more than one argument passed into
the function then number of elements returned:

    # replaces with undef
    sub foo { return Sub::StopCalls::stop(); }
    # replaces with 'const'
    sub foo { return Sub::StopCalls::stop( 'const' ); }
    
    # replaces with number of element in @a,
    # but only if @a > 1, otherwise first element or undef
    return Sub::StopCalls::stop( @a );

=head3 arguments

Arguments of the replaced call also "stopped", for example:

    for (1..10) {
        function_that_stops_calls( other(...) );
    }

C<other(...)> called only once. Second iteration just jumps
over.

It's good in theory, but in some situations it can result in
bugs.

=head3 threads

This module is not thread-safe at the moment.

=cut

=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;

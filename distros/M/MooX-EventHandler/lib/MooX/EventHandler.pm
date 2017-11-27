package MooX::EventHandler;

our $VERSION = '0.000';
$VERSION = eval $VERSION;

use Moo ();
use strictures 2;

our %TRACKED_EVENTS;
our %TRACKED_EVENTS_TRACKER;

sub import {
    my $class = shift;
    my %extra = @_;
    my $target = caller;
    my $has = $target->can('has');

    $TRACKED_EVENTS{$target} //= [];
    Moo::_install_tracked $target, has_event => sub {
        if (exists $extra{-tracked} and not $TRACKED_EVENTS_TRACKER{$target}) {
            $TRACKED_EVENTS_TRACKER{$target} = 1;
            $has->($extra{-tracked} =>
                is      => 'ro',
                default => sub { %TRACKED_EVENTS{$target} },
            );
        }
        my @all_names = ref $_[0] eq 'ARRAY' ? @{ shift() } : ( shift );
        my %proto = @_; # Should take advantage of Moo's own error handling here
        $proto{is} //= 'lazy';
        for my $event (@all_names) {
            my $attribute = "_${event}_event";
            my %spec = %proto;
            $spec{init_arg} = $event unless exists $spec{init_arg};
	    if ($spec{is} eq 'lazy' or $spec{lazy}) {
		my $default_name = "_build_$event";
		my $can = ref $spec{builder} eq 'CODE'
		    ? delete $spec{builder}
		    : $target->can($default_name)
		    // ($spec{required}
			? sub { sub { die "Unimplemented event handler $event" } }
			: sub { sub {} });
		$spec{builder} //= $default_name;
		Moo::_install_coderef("${target}::$spec{builder}" => sub {
					  my $self = shift;
					  $can = $can->();
					  sub { $self->$can(@_) }
				      });
	    }
            $has->($attribute => %spec);
            Moo::_install_coderef("${target}::${event}" =>
		    sub { $_[0]->$attribute->(@_[1..$#_]) })
		unless $target->can($event);
            push @{$TRACKED_EVENTS{$target}}, $event if exists $extra{-tracked};
        }
    };
}

1;

=head1 NAME

MooX::EventHandler - Use Moo modules with event handlers.

=head1 SYNOPSIS

    package Daisy;
    use Moo;
    use MooX::EventHandler;

    has_event 'on_abattoir';

    sub on_abattoir { die } # Cannot be replaced by users

    has_event 'on_new_grass' => builder => sub { sub { # Yes, two
        my $self = shift;
        $self->eat();
    }};

    has_event 'on_bull' => builder => 'make_calf';

    sub make_calf { sub { # Two again
        Daisy->new();
    }}

=head1 DESCRIPTION

Exports a function C<has_event> which creates an attribute with
settings useful for writing event-driven code.

Specifically:

=over

=item * Event attributes are lazy by default.

=item * The attribute is named C<_${event}_event> so that C<$event()>
calls the event handler rather than returning the coderef which
implements it. The C<init_arg> remains C<$event> and the default
builder C<_build_$event>.

=item * C<required> now means that the default event handler will die,
not that a handler must be passed to the constructor.

=item * (Optionally) Another attribute is added to the class which
returns a listref of this object's event.

=back

=head1 BUGS

=over

=item Tracked events do not work correctly with inheritence or roles.

=item Double-layered subs are ugly.

=item This was written primarily for use with L<IO::Async> and has not
been tested with other event libraries.

=item Overriding/updating attribute options in subclasses has no
explicit support and probably doesn't work.

=item There are no tests.

=back

=head1 EVENT ATTRIBUTES

Event attributes are simply regular L<Moo> attributes with defaults
useful for writing event-driven code and as such can be treated like
any other attribute, but see L</BUGS>.

There are 3 different ways to assign handlers to an event.

=over

=item A lazy builder.

A coderef can be returned from an event attribute's C<builder> or
C<default> in the usual way.

=item Passed to the constructor.

Coderefs can be passed to the constructor with the name of the event
just like any other attribute.

=item Directly in the object.

The event handler can be installed as a regular method in the
class. This B<overrides> the ability to pass event handlers to the
constructor.

=back

=head1 EVENT TRACKING

If MooX::EventHandler is imported with the C<-tracked> option and the
name of an attribute, that attribute is created and set up to return a
list of all of the object's events. This feature is buggy and does not
work properly with inheritence.

    package Foo;
    use Moo;
    use MooX::EventHandler -tracked => 'all_events';
    has_event 'on_foo';
    has_event 'on_bar';

    # Foo->new->all_events will now return ['on_foo', 'on_bar'];

=head1 SEE ALSO

L<Moo>

=head1 AUTHOR

Matthew King <chohag@jtan.com>

=cut

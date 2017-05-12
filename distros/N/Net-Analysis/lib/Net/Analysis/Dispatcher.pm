package Net::Analysis::Dispatcher;
# $Id: Dispatcher.pm 131 2005-10-02 17:24:31Z abworrall $

use 5.008000;
our $VERSION = '0.01';
use strict;
use warnings;
use overload q("") => sub { $_[0]->as_string() }; # OO style stringify
use Carp qw(carp croak);

use Params::Validate qw(:all);

# {{{ POD

=head1 NAME

Net::Analysis::Dispatcher - handle the event stuff for the proto analysers

=head1 SYNOPSIS

  use Net::Analysis::Dispatcher;

  my $d = Net::Analysis::Dispatcher->new();
  my $listener = Net::Analysis::Listener::TCP->new();
  $d->add_listener (listener => $listener);

=head1 DESCRIPTION

This class is used to register listener objects. Whenever any of the objects
emit an event, the dispatcher is used to make sure other interested listeners
receive the event.

=cut

# }}}

# {{{ new

# {{{ POD

=head2 new ()

Takes no arguments, tells no lies.

=cut

# }}}

sub new {
    my ($class) = shift;

    my %h;

    $h{listeners} = []; # List of objects that are listening to events

    my ($self) = bless (\%h, $class);

    return $self;
}

# }}}

# {{{ add_listener

=head2 add_listener (listener => $obj, config => $hash)

This method adds a new listener to the list of things to be notified of each
event.

If the listener object has a field C<pos>, then we attempt to put the listener
in that position in the event queue. Valid values are C<first> and C<last>, to
receive events first and last. Listener::TCP likes to be first, since it adds
extra info to the C<tcp_packet> that other modules might like to see.

If a listener has already claimed the first or last spot, then we croak with an
error.

=cut

sub add_listener {
    my ($self) = shift;

    my %h = validate (@_, { listener => 1, #{ can => "emit" }, <-- broken :(
                            config   => { default => {} },
                          });

    # XXXX workaround issue where Params::Validate rejects mocked methods
    if (!$h{listener}->can('emit')) {
        carp "add_listener needs an object that can ->emit() !\n";
        return undef;
    }

    if (exists $h{listener}{pos}) {
        if ($h{listener}{pos} !~ /^(first|last)$/) {
            croak "$h{listener} has invalid pos; $h{listener}{pos}\n";
        }
        if (exists $self->{pos}{$h{listener}{pos}}) {
            croak "position '$h{listener}{pos}' taken; bad $h{listener}\n";
        }
        $self->{pos}{$h{listener}{pos}} = $h{listener};

    } else {
        push (@{$self->{listeners}}, $h{listener});
    }
}

# }}}
# {{{ emit_event

=head2 emit_event (name => 'event_name', args => $hash)

The name must be a valid Perl function name. By convention, it should start
with the name of the module that is emitting the event (e.g.
C<http_transaction>).

Where your code is emitting events, it must must document the args in detail,
so that listeners will know what to do with them.

This method runs through the listener list, and if appropriate, invokes the
listening method for each listener.

A listener gets the event if it has a method which has the same name as the
C<event_name>.

=cut

sub emit_event {
    my $self = shift;

    my %h = @_;
    $h{args} ||= {};

    if ($self->{_i_am_invoking}) {
#        warn "Argh, circular mayhem ($h{name})\n"; exit;
    }

## Adverse performance impacts, so commented out
#    my %h = validate (@_, { name => { regex => qr/^[a-z][a-z0-9_]+$/ },
#                            args => { default => {} },
#                          });

    # If we have any listeners that wanted a special place in the queue, then
    #  give it to them. This stuff will only trigger on the very first event.
    if (exists $self->{pos}{first}) {
        unshift (@{$self->{listeners}}, delete ($self->{pos}{first}));
    }
    if (exists $self->{pos}{last}) {
        push (@{$self->{listeners}}, delete ($self->{pos}{last}));
    }

    $self->_invoke_callbacks (\%h);
}

# }}}

# {{{ as_string

sub as_string {
    my ($self) = @_;
    my $s = '';

    $s .= "Dispatching to [".join(',', map {"$_"} @{$self->{listeners}})."]";

    return $s;
}

# }}}

# {{{ _invoke_callbacks

sub _invoke_callbacks {
    my $self = shift;
    my ($h) = @_;

    $self->{_i_am_invoking} = 1;

    # Memoise this iteration & 'can' call ? Results won't change !
    foreach my $l (@{$self->{listeners}}) {
        my $method = $h->{name};
        if ($l->can($method)) {
            eval {
                $l->$method($h->{args});
            }; if ($@) {
                carp ("Listener '$l' die()d on method $h->{name}:\n$@");
            }
        }
    }

    delete ($self->{_i_am_invoking});
}

# }}}


1;
__END__
# {{{ POD

=head2 EXPORT

None by default.

=head1 SEE ALSO

Net::Analysis::Listener::Base

=head1 AUTHOR

Adam B. Worrall, E<lt>adam@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Adam B. Worrall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

# }}}
# {{{ emit_event

=head2 emit_event (name => 'event_name', args => $hash)

The name must be a valid Perl function name. By convention, it should start
with the name of the module that is emitting the event (e.g.
C<http_transaction>).

Where your code is emitting events, it must must document the args in detail,
so that listeners will know what to do with them.

This method runs through the listener list, and if appropriate, invokes the
listening method for each listener.

A listener gets the event if it has a method which has the same name as the
C<event_name>.

=cut

sub emit_event {
    my $self = shift;

    my %h = @_;

    $h{args} ||= {};

#    my %h = validate (@_, { name => { regex => qr/^[a-z][a-z0-9_]+$/ },
#                            args => { default => {} },
#                          });

    # If we have any listeners that wanted a special place in the queue, then
    #  give it to them. This stuff will only trigger on the very first event.
    if (exists $self->{pos}{first}) {
        unshift (@{$self->{listeners}}, delete ($self->{pos}{first}));
    }
    if (exists $self->{pos}{last}) {
        push (@{$self->{listeners}}, delete ($self->{pos}{last}));
    }

    print " ]]]] $h{name}\n";

    # Memoise this iteration & 'can' call ? Results won't change !
    foreach my $l (@{$self->{listeners}}) {
        print "   ]] $h{name} $l\n";
        my $method = $h{name};
        if ($l->can($method)) {
            eval {
                $l->$method($h{args});
            }; if ($@) {
                carp ("Listener '$l' die()d on method $h{name}:\n$@");
            }
        }
    }
}

# }}}

# {{{ -------------------------={ E N D }=----------------------------------

# Local variables:
# folded-file: t
# end:

# }}}

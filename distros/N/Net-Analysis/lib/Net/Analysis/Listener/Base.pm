package Net::Analysis::Listener::Base;
# $Id: Base.pm 131 2005-10-02 17:24:31Z abworrall $

use 5.008000;
our $VERSION = '0.01';
use strict;
use warnings;
use overload q("") => sub { $_[0]->as_string() }; # OO style stringify

use Carp qw(carp croak);

use Params::Validate qw(:all);

# {{{ POD

=head1 NAME

Net::Analysis::Listener::Base - base class for event listeners

=head1 SYNOPSIS

This module should be subclassed as follows:

  package Net::Analysis::Listener::MyThing;

  use base 'Net::Analysis::Listener::Base';

  sub event_listener {
    my ($self, $args_hash) = @_;
    ... do something ...

    if (event_is_exciting($args_hash)) {
      $self->emit (name => 'my_event',
                   args => {what => 'listeners to this event will get'});
    }
  }

=head1 DESCRIPTION

This module is a virtual base class for Listeners. To create a new listener,
just subclass this, and add methods. If you want to listen to an event, create
a method with the name of that event - the dispatcher takes care of the rest.

If you want to store state between events (such as a hash of open sessions),
stuff it into C<$self>. Any configuration for your listener will also be
exploded all over $<$self>, so take care. Subclasses can use anything in $self
they want, except the key '_', which contains private stuff used by the base
class.

You can emit events if you like; if you add new types of event, take care not
to collide with existing ones (e.g. tcp_blah, http_blah). The best way to do
this is to select a prefix for your event names based on your protocol.

=head1 INHERITED METHODS

B<You should just inherit these methods>, you don't need to implement them.
They're documented here for reference, so don't be put off - they can be safely
ignored :)

=cut

# }}}

# These should not be overridden
# XXXX Create a DESTROY method that breaks all the circular refs.
# {{{ new

# {{{ POD

=head2 new (dispatcher => $obj [, config => $hash] [, pos => 'first|last'])

Mandatory argument is the dispatcher object which will dispatch any events
that originate from this module, or any that subclass from it.

Note that we immediately register this new object with the dispatcher; this
will create circular references.

The config hash is optional. Standard key/val pairs are:

 * v => 0..3 (verbosity; 0==silent, 9==noisy)

The pos parameter is optional. It specifies if the listener sould catch events
first, or last. Only one listener can be first, or last.

The rest of the hash varies on a per-listener basis.

The returned object has one reserved field: C<$self->{_}>. This is used for the
behind-the-scenes plumbing. All other fields in C<$self> are free for the
subclass to use.

Note that the config hash is exploded over C<$self>; that is, C<$self->{v}>
will contain the verbosity value passed in via the config hash (or a
default, if no config is passed in.)

=cut

# }}}

sub new {
    my ($class) = shift;

    my %args = validate (@_, {
                              dispatcher => { can  => 'emit_event'   },
                              pos        => { regex => qr/^(first|last)$/,
                                              optional => 1},
                              config     => { type => HASHREF,
                                              default => {v => 0},   },
                             }
                        );

    # Place the dispatcher into our private subhash
    my %h = ('_' => {dispatcher => $args{dispatcher}});

    my ($self) = bless (\%h, $class);

    # Allow the module to validate the configuration, if it wants
    my $cnf = $self->validate_configuration (%{$args{config}});
    if (! defined $cnf) {
        carp "no configuration, despite default setting above ?";
        return undef;
    }

    # Explode the config all over self, provided we haven't already used it
    foreach my $k (keys %{$cnf}) {
        croak "bad config '$k': '$k' is reserved !\n" if (exists $h{$k});
        $h{$k} = $cnf->{$k};
    }

    # If a position was specified, put it where the dispatcher will look for it
    $self->{pos} = $args{pos} if (exists $args{pos});

    $h{_}{dispatcher}->add_listener (listener => $self); # Circular ref joy

    return $self;
}

# }}}
# {{{ emit

=head2 emit (...)

This is a convenience wrapper on top of
L<Net::Analysis::Dispatcher::emit_event>. It takes exactly the same arguments.
Please refer to that module for documentation.

=cut

sub emit {
    my ($self) = shift;
    $self->{_}{dispatcher}->emit_event (@_);
}

# }}}
# {{{ trace

sub trace {
    my ($self) = shift;

    foreach (@_) {
        my $l = $_; #  Skip 'Modification of a read-only value' errors
        chomp ($l);
        print "$l\n";
    }
}

# }}}

# These can (should) be overridden
# {{{ as_string

# This should really be overridden by our subclass

sub as_string {
    my ($self) = @_;
    my $s = '';

    $s .= "[".ref($self)."]";

    return $s;
}

# }}}
sub validate_configuration { my $self=shift; return {@_}; }

#sub setup    {}
#sub teardown {}


# Utilities for viewing binary data
# {{{ sanitize_raw

sub sanitize_raw {
    my ($self, $raw, $max, $append_binary) = @_;
    $raw = substr($raw,0,$max) if ($max && length($raw) > $max);

    my $s = $raw;
    $s =~ s {([^\x20-\x7e])} {.}g;
    $s .= " ".$self->map2bin($raw) if ($append_binary);
    return "{$s}";
}

# }}}
# {{{ map2bin

sub map2bin {
    my ($self,$raw) = @_;
    my $bin = unpack("B*", $raw);
    $bin =~ s{([^ ]{8})(?! )}{ $1}g;
    $bin =~ s{(^ *| *$)}{}g;
    return "<$bin>";
}

# }}}
# {{{ map2hex

sub map2hex {
    my ($self,$raw, $prefix, $append_binary) = @_;

    $prefix ||= '';
    my $hex = unpack("H*", $raw);

    $hex =~ s {([0-9a-f]{2}(?! ))}     { $1}mg;

    $hex =~ s {(( [0-9a-f]{2}){16})}
              {"$1   ".$self->hex2saferaw($1,$append_binary)."\n"}emg;

    # Unfinished last line
    $hex =~ s {(( [0-9a-f]{2})*)$}
              {sprintf("%-47.47s    ",$1) .$self->hex2saferaw($1,$append_binary)."\n"}es;

    chomp($hex);

    $hex =~ s/^/$prefix/msg;

    return $hex."\n";
}

sub hex2saferaw {
    my ($self, $hex, $append_binary) = @_;

    $hex =~ s {\s+} {}mg;
    my $raw = pack("H*", $hex);

    return $self->sanitize_raw($raw,undef,$append_binary);
}

# }}}

1;
__END__
# {{{ POD

=head2 EXPORT

None by default.

=head1 SEE ALSO

Net::Analysis::Dispatcher

Net::Analysis::Listener::HTTP - a useful example listener

=head1 AUTHOR

Adam B. Worrall, E<lt>worrall@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Adam B. Worrall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

# }}}

# {{{ -------------------------={ E N D }=----------------------------------

# Local variables:
# folded-file: t
# end:

# }}}

##########################################################################
#
# Module template
#
##########################################################################
package Pots::Message;

##########################################################################
#
# Modules
#
##########################################################################
use threads;
use threads::shared;

use strict;

##########################################################################
#
# Global variables
#
##########################################################################
our $Serial : shared = 0;

##########################################################################
#
# Private methods
#
##########################################################################

##########################################################################
#
# Public methods
#
##########################################################################

sub new {
    my $class = shift;
    my $type = shift || undef;
    my $href = shift || undef;

    my $serial;
    my $self = {};
    bless ($self, ref ($class) || $class);

    {
        lock($Serial);
        $serial = $Serial++;
    }

    if (defined($type)) {
        $self->{_type} = $type;
    } else {
        $self->{_type} = '';
    }

    $self->set('_pots_msg_serial', $serial);

    if (defined($href) && ref($href) eq 'HASH') {
        foreach my $key (keys(%{$href})) {
            $self->set($key, $href->{$key});
        }
    }

    return $self;
}

sub type {
    my $self = shift;

    if (@_) {
        $self->{_type} = $_[0];
    }

    return $self->{_type};
}

sub set {
    my $self = shift;
    my $key = shift || return;

    my $field = "_field_" . $key;

    $self->{$field} = (@_ == 1 ? $_[0] : [@_]);
}

sub get {
    my $self = shift;
    my $key = shift || return undef;

    my $field = "_field_" . $key;

    return $self->{$field};
}

1; #this line is important and will help the module return a true value
__END__

=head1 NAME

Pots::Message - Perl ObjectThreads message class

=head1 SYNOPSIS

    use Pots::Message;

    my $msg = Pots::Message->new();
    $msg->type('MyMessage');
    $msg->set('key1', $data1);

    my $msg = Pots::Message->new(
        'MyMessage',
        {
            'key1' => $data1,
        }
    );

=head1 DESCRIPTION

This class allows you to store arbitrary data in an object and is very
similar in purpose to a standard Perl hash.
It is the base element for data exchange between threads along with
C<Pots::MessageQueue>.

=head1 METHODS

=over

=item new ([$type] [, {'key' => $value, ...}])

This method creates a new message object.
You can optionaly set message content (message type and message data).

=item type ($type)

Sets message type (arbitrary string) so that you can later filter messages.

=item set ('key', $value)

Add arbitrary data to the message, identified by 'key'.

=item get ('key')

Retrieves data stored in the message, identified by 'key'.

=back

=head1 AUTHOR and COPYRIGHT

Remy Chibois E<lt>rchibois at free.frE<gt>

Copyright (c) 2004 Remy Chibois. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

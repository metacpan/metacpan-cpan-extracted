use strict;
use warnings;

############################################################################
# GuessProtocol
# tries to guess protocol of connection and redirect it to the appropriate
# protocol specific handler
############################################################################

package Net::Inspect::L5::GuessProtocol;
use base 'Net::Inspect::Connection';
use fields qw(meta fwd protocols);

use constant EXPIRE => 300;

sub new {
    my ($class,@protocols) = @_;
    if ( ! ref($class) ) {
	my $self = $class->SUPER::new(
	    Net::Inspect::Flow::Any->new('guess_protocol'));
	$self->{upper_flow}->attach($_) for(@protocols);
	return $self;
    } else {
	return $class->SUPER::new(); # just clone
    }
}

sub attach   { shift->{upper_flow}->attach(@_) }
sub detach   { shift->{upper_flow}->detach(@_) }
sub attached { shift->{upper_flow}->attached }

# forward expire to fwd flow
sub expire   {
    my ($self,$time) = @_;
    if ( my $obj = $self->{fwd} ) {
	return $obj->expire($time);
    }
    return $self->SUPER::expire($time);
}

sub syn { 1 }
sub new_connection {
    my ($self,$meta) = @_;
    my $obj = $self->new; # clone
    $obj->{meta} = $meta;
    $obj->{expire} = $meta->{time} + EXPIRE;
    return $obj;
}

sub in {
    my ($self,$dir,$data,$eof,$time) = @_;

    if ( my $obj = $self->{fwd} ) {
	return $obj->in($dir,$data,$eof,$time);
    }

    # let attached flows guess:
    # if they return an object they get used
    # they might detach themself if they are definitly not responsable
    if ( my ($obj,$n) = $self->{upper_flow}->guess_protocol(
	$self,$dir,$data,$eof,$time,$self->{meta}) ) {
	$self->{fwd} = $obj;
	# might consume not all from the last data
	return $n;
    }

    # guessing objects must keep data for replaying if necessary, so
    # consider everything consumed
    return length($data);
}

sub fatal {
    my ($self,$reason,$dir,$time) = @_;
    my $obj = $self->{fwd} or return;
    return $obj->fatal($reason,$dir,$time);
}


1;

__END__

=head1 NAME

Net::Inspect::L5::GuessProtocol - tries to find and redirect to appropriate
protocol handler

=head1 SYNOPSIS

 ...
 my $guess = Net::Inspect::L5::GuessProtocol->new;
 $guess->attach($http);
 $guess->attach($null);
 ...
 my $tcp = Net::Inspect::L4::TCP->new($guess);

=head1 DESCRIPTION

Uses the attached flows to find out, which OSI Layer 7 protocol the data might
be in and then gives control to the appropriate protocol handler.

Implements the hooks required for C<Net::Inspect::L4::TCP>.
Usually attached to C<Net::Inspect::L4::TCP> and attached flows are usually
C<Net::Inspect::Connection::*>.

Methods:

=over 4

=item attach(flow)

attaches specified flow, which should provide C<guess_protocol> method

=item detach(flow)

detaches specified flow

=item attached

returns list of attached flows

=back

Hooks provided:

=over 4

=item new_connection(\%meta)

=item in($dir,$data,$eof,$time)

forwarded to protocol implementing object if it is already found.
Otherwise calls C<guess_protocol> and C<< length($data) >>.

=item fatal($reason,$time)

forwarded to protocol implementing object

=back

Called hooks:

=over 4

=item guess_protocol($guess,$dir,$data,$eof,$time,\%meta)

The flow should return an appropriate L<Net::Inspect::Connection> object if it
does implement the protocol. If it does not implement the protocol it should
detach itself from the C<$guess> flow using C<< $guess->detach($self) >>
and return ().  If it needs more data to decide it should simply return ().

The hook must do it's own buffering of the given data and process them before
returning itself as the protocol handler.

=back

The hooks C<in> and C<fatal> gets forwarded to the protocol implementing object
once it is found.

############################################################################
# Net::Inspect::L5::Unknown
# guessing handler for connections which are not handled by anything else
############################################################################
use warnings;
use strict;
package Net::Inspect::L5::Unknown;
use base 'Net::Inspect::Connection';
use fields qw(replay);
use Net::Inspect::Debug;

sub guess_protocol {
    my ($self,$guess,$dir,$data,$eof,$time,$meta) = @_;

    # keep all calls for replaying later
    push @{ $self->{replay} ||=[] },[$dir,$data,$eof,$time];

    $guess->attached == 1 or return; # let others try first

    # it's just me left
    my $obj = $self->new_connection($meta);
    if ( ! $obj ) {
	$guess->detach($self);
	return;
    }

    # replay all
    $obj->in(@$_) for @{ $self->{replay} };
    undef $self->{replay};
    return ($obj,length($data));
}

sub new_connection {
    my ($self,$meta) = @_;
    return $self->{upper_flow}->new_connection($meta) if $self->{upper_flow};
    return $self->new;
}

sub in {
    my ($self,$dir,$data,$eof,$time) = @_;
    $self->{expire} = $time + 500;
    return $self->{upper_flow}->in($dir,$data,$eof,$time) if $self->{upper_flow};
    return length($data); # ignores
}

sub fatal {
    my ($self,$reason,$dir,$time) = @_;
    trace($reason);
}

1;

__END__

=head1 NAME

Net::Inspect::L5::Unknown - handles the connections nobody else deals with

=head1 SYNOPSIS

 my $guess = Net::Inspect::L5::GuessProtocol->new;
 my $fallback = Net::Inspect::L5::Unknown->new;
 $guess->attach($fallback);
 $fallback->attach(...);

=head1 DESCRIPTION

Connection handling flow, which gets used together with
C<Net::Inspect::L5::GuessProtocol> in case no other protocol handler matched.

Will return connection object if it detects, that it is the only flow still
attached to the C<Net::Inspect::L5::GuessProtocol> object.

The default implementation will just ignore the connection.
To change this behavior subclass it and implement the following methods:

=over 4

=item new_connection(\%meta)

Should return new connection object.

=item in($self,$dir,$data,$eof,$time)

Process the given data. Should return the number of bytes processed.

=back

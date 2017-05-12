
package SRS::EPP::Session::CmdQ;
{
  $SRS::EPP::Session::CmdQ::VERSION = '0.22';
}

use Moose;
use MooseX::Params::Validate;
use SRS::EPP::Command;
use SRS::EPP::Response;

has 'queue' =>
	is => "ro",
	isa => "ArrayRef[SRS::EPP::Command]",
	default => sub { [] },
	;

has 'responses' =>
	is => "ro",
	isa => "ArrayRef[Maybe[SRS::EPP::Response]]",
	default => sub { [] },
	;

has 'next' =>
	is => "rw",
	isa => "Num",
	default => 0,
	traits => ['Number'],
	handles   => {
	add_next => 'add',
	},
	;

sub next_command {
    my $self = shift;
    
	my $q = $self->queue;
	my $next = $self->next;
	while ( $self->responses->[$next] ) {

		# no processing needed?  skip
		$self->add_next(1);
		$next++;
	}
	if ( my $item = $q->[$next] ) {
		$self->add_next(1);
		return $item;
	}
	else {
		();
	}
}

sub commands_queued {
    my $self = shift;
    
	my $q = $self->queue;
	return scalar(@$q);
}

sub queue_command {
    my $self = shift;
    
    my ( $cmd ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::Command' },
    );        
    
	push @{ $self->queue }, $cmd;
	push @{ $self->responses }, undef;
}

# with a command object, place a response at the same place in the queue
sub add_command_response {
    my $self = shift;
    
    my ( $response, $cmd ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::Response' },
        { isa => 'SRS::EPP::Command', optional => 1 },
    );            
    
    
	my $q = $self->queue;
	my $rs = $self->responses;
	my $ok;
	for ( my $i = 0; $i <= $#$q; $i++ ) {
		if (
			($cmd and $q->[$i] == $cmd)
			or
			!defined $rs->[$i]
			)
		{
			$rs->[$i] = $response;
			$ok = 1;
			last;
		}
	}
	confess "Could not queue response, not found" if !$ok;
}

sub response_ready {
    my $self = shift;
    
	defined($self->responses->[0]);
}

sub dequeue_response {
    my $self = shift;
    
	if ( $self->response_ready ) {
		my $cmd = shift @{ $self->queue };
		my $response = shift @{ $self->responses };
		if ( $self->next ) {
			$self->add_next(-1);
		}
		if (wantarray) {
			($response, $cmd);
		}
		else {
			$response;
		}
	}
	else {
		();
	}
}

1;

__END__

=head1 NAME

SRS::EPP::Session::CmdQ - manage epp command/response queue

=head1 SYNOPSIS

 my $q = SRS::EPP::Session::CmdQ->new( );

 # put requests on queue
 $q->queue_command( $epp_command );

 # pull a command off the queue; mark it in progress
 my @rq = $q->next_command;

 # put a response in
 $q->add_command_response( $epp_response, $epp_command? );

 # if a message has had all its requests answered, it can be dequeued
 ($epp_response, $epp_command) = $q->dequeue_response();

 # also available in scalar context
 $epp_response = $q->dequeue_response();

=head1 DESCRIPTION

This class implements a simple FIFO queue, but with small
customizations to operation to suit the use case of the SRS EPP
Proxy's queue of EPP commands and responses.

=head1 SEE ALSO

L<SRS::EPP::Session>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut


# Local Variables:
# mode:cperl
# indent-tabs-mode: t
# cperl-continued-statement-offset: 8
# cperl-brace-offset: 0
# cperl-close-paren-offset: 0
# cperl-continued-brace-offset: 0
# cperl-continued-statement-offset: 8
# cperl-extra-newline-before-brace: nil
# cperl-indent-level: 8
# cperl-indent-parens-as-block: t
# cperl-indent-wrt-brace: nil
# cperl-label-offset: -8
# cperl-merge-trailing-else: t
# End:

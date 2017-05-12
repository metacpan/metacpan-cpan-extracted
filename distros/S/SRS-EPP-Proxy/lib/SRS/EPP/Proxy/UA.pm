
package SRS::EPP::Proxy::UA;
{
  $SRS::EPP::Proxy::UA::VERSION = '0.22';
}

use Moose;
use MooseX::Params::Validate;
use LWP::UserAgent;
use Net::SSLeay::OO;
use Moose::Util::TypeConstraints;
use IO::Handle;
use Storable qw(store_fd retrieve_fd);

with 'MooseX::Log::Log4perl::Easy';

enum __PACKAGE__."::states" => qw(waiting busy ready);

BEGIN {
	class_type "HTTP::Request";
	class_type "HTTP::Response";
	class_type "IO::Handle";
}

has 'write_fh' =>
	is => "rw",
	isa => "IO::Handle|GlobRef",
	;

has 'read_fh' =>
	is => "rw",
	isa => "IO::Handle|GlobRef",
	;

has 'pid' =>
	is => "rw",
	isa => "Int",
	;

has 'state' =>
	is => "rw",
	isa => __PACKAGE__."::states",
	default => "waiting",
	;

sub busy {
    my $self = shift;
    
	$self->state eq "busy";
}

sub ready {
    my $self = shift;
    
	if ( $self->busy ) {
		$self->check_reader_ready;
	}
	$self->state eq "ready";
}

sub waiting {
    my $self = shift;
    
	$self->state eq "waiting";
}

sub check_reader_ready {
    my $self = shift;
    
    my ( $timeout ) = pos_validated_list(
        \@_,
        { isa => 'Num', default => 0 },
    );       
    
	my $fh = $self->read_fh;
	my $rin = '';
	vec($rin, fileno($fh), 1) = 1;
	my $win = '';
	my $ein = $rin;
	my ($nfound) = select($rin, $win, $ein, $timeout);
	if ($nfound) {
		if ( vec($ein, fileno($fh), 1) ) {
			die "reader handle in error state";
		}
		elsif ( vec($rin, fileno($fh), 1) ) {
			$self->state("ready");
			return 1;
		}
		else {
			die "??";
		}
	}
	else {
		return;
	}
}

sub BUILD {
	my $self = shift;
	{
		$self->log_trace("setting up pipes...");
		pipe(my $rq_rdr, my $rq_wtr);
		pipe(my $rs_rdr, my $rs_wtr);
		$self->log_trace("forking...");
		my $pid = fork;
		defined $pid or die "fork failed; $!";
		if ($pid) {
			$self->log_trace(
				"parent, child pid = $pid, reading from ".fileno($rs_rdr)
					.", writing to ".fileno($rq_wtr)
			);
			$self->pid($pid);
			$self->read_fh($rs_rdr);
			$self->write_fh($rq_wtr);
			return;
		}
		else {
			$self->log_trace(
				"child, I am $$, reading from "
					.fileno($rq_rdr).", writing to ".fileno($rs_wtr)
			);
			$0 = __PACKAGE__;
			$self->read_fh($rq_rdr);
			$self->write_fh($rs_wtr);
		}
	}
	$self->loop;
}

sub DESTROY {
	my $self = shift;
	if (my $pid = $self->pid) {
		kill 15, $pid;
		waitpid($pid,0);
	}
}

use Storable qw(fd_retrieve store_fd);

has 'ua' =>
	is => "ro",
	isa => "LWP::UserAgent",
	lazy => 1,
	default => sub {
	LWP::UserAgent->new(
		agent => __PACKAGE__,
		timeout => 30,  # 'fast' timeout for EPP sessions
		)
	};

sub loop {
    my $self = shift;
    
	$SIG{TERM} = sub { exit(0) };
	while (1) {
		$self->log_debug("UA waiting for request");
		$0 = __PACKAGE__." - idle";
		my $request = eval { fd_retrieve($self->read_fh) }
			or do {

			#$self->log_error("failed to read request; $@");
			last;
			};
		$self->log_debug("sending a request to back-end");
		$0 = __PACKAGE__." - active";
		my $response = $self->ua->request($request);
		$self->log_debug("got response - writing to response socket");
		$0 = __PACKAGE__." - responding";
		store_fd $response, $self->write_fh;
		$self->write_fh->flush;
	}
	$self->log_trace("UA exiting");
	exit(0);
}

sub request {
    my $self = shift;
    
    my ( $request ) = pos_validated_list(
        \@_,
        { isa => 'HTTP::Request' },
    );           
    
	die "sorry, can't handle a request in state '".$self->state."'"
		unless $self->waiting;
	$self->log_trace("writing request to child UA socket");
	store_fd $request, $self->write_fh;
	$self->write_fh->flush;
	$self->log_trace("flushed");
	$self->state("busy");
}

sub get_response {
    my $self = shift;
    
	die "sorry, not ready yet" unless $self->ready;
	my $response = retrieve_fd($self->read_fh);
	$self->state("waiting");
	return $response;
}

1;

__END__

=head1 NAME

SRS::EPP::Proxy::UA - subprocess-based UserAgent

=head1 SYNOPSIS

 my $ua = SRS::EPP::Proxy::UA->new;   # creates sub-process.

 $ua->request($req);          # off it goes!
 print "yes" if $ua->busy;    # it's busy!
 sleep 1 until $ua->ready;    # do other stuff
 my $response = $ua->get_response;
 print "yes" if $ua->waiting; # it's waiting for you!

=head1 DESCRIPTION

This class provides non-blocking UserAgent behaviour, by using a slave
sub-process to call all the blocking L<LWP::UserAgent> functions to do
the retrieval.

This is done because the L<SRS::EPP::Session> class is designed to be
a non-blocking system.

=head1 SEE ALSO

L<LWP::UserAgent>, L<SRS::EPP::Session>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut

use v5.12;
use warnings;

package Neo4j::Driver::Result::Bolt 1.02;
# ABSTRACT: Bolt result handler


# This package is not part of the public Neo4j::Driver API.


use parent 'Neo4j::Driver::Result';

use Carp qw(croak);
our @CARP_NOT = qw(Neo4j::Driver::Net::Bolt Neo4j::Driver::Result);
use List::Util ();

use Neo4j::Driver::Net::Bolt;


our $gather_results = 0;  # 1: detach from the stream immediately (yields JSON-style result; used for testing)


sub new {
	# uncoverable pod (private method)
	my ($class, $params) = @_;
	
	# Holding a reference to the Bolt connection is important, because
	# Neo4j::Bolt automatically closes the session upon object destruction.
	# Perl uses reference counting to control its garbage collector, so we
	# need to hold that reference {cxn} until we detach from the stream,
	# even though we never use the connection object directly.
	
	my $self = {
		attached => 1,   # 1: unbuffered records may exist on the stream
		exhausted => 0,  # 1: all records read by the client; fetch() will fail
		buffer => [],
		field_names_cache => undef,
		summary => undef,
		query => $params->{query},
		cxn => $params->{bolt_connection},  # important to avoid dereferencing the connection
		stream => $params->{bolt_stream},
		server_info => $params->{server_info},
		error_handler => $params->{error_handler},
	};
	bless $self, $class;
	
	return $self->_gather_results if $gather_results;
	
	my @names = $params->{bolt_stream}->field_names;
	$self->{result} = { columns => \@names };
	
	return $self;
}


sub _gather_results {
	my ($self) = @_;
	
	my $stream = $self->{stream};
	my @names = $stream->field_names;
	my @data = ();
	while ( my @row = $stream->fetch_next ) {
		
		croak 'next true and failure/success mismatch: ' . $stream->failure . '/' . $stream->success unless $stream->failure == -1 || $stream->success == -1 || ($stream->failure xor $stream->success);  # assertion
		Neo4j::Driver::Net::Bolt->_trigger_bolt_error( $stream, $self->{error_handler}, $self->{cxn} ) if $stream->failure && $stream->failure != -1;
		
		push @data, { row => \@row };
	}
	
	croak 'next false and failure/success mismatch: ' . $stream->failure . '/' . $stream->success unless  $stream->failure == -1 || $stream->success == -1 || ($stream->failure xor $stream->success);  # assertion
	Neo4j::Driver::Net::Bolt->_trigger_bolt_error( $stream, $self->{error_handler}, $self->{cxn} ) if $stream->failure && $stream->failure != -1;
	
	$self->{stream} = undef;
	$self->{cxn} = undef;
	$self->{result} = {
		columns => \@names,
		data => \@data,
		stats => $stream->update_counts(),
	};
	return $self->_as_fully_buffered;
}


sub _fetch_next {
	my ($self) = @_;
	
	return $self->SUPER::_fetch_next unless $self->{stream};
	
	my (@row, $record);
	@row = $self->{stream}->fetch_next;
	$record = { row => \@row } if @row;
	
	unless ($self->{stream}->success) {
		# success() == -1 is not an error condition; it simply
		# means that there are no more records on the stream
		Neo4j::Driver::Net::Bolt->_trigger_bolt_error( $self->{stream}, $self->{error_handler}, $self->{cxn} );
	}
	
	return $self->_init_record( $record );
}


sub _init_record {
	my ($self, $record) = @_;
	
	return undef unless $record;  ##no critic (ProhibitExplicitReturnUndef)
	
	$record->{field_names_cache} = $self->{field_names_cache};
	return bless $record, 'Neo4j::Driver::Record';
}


1;

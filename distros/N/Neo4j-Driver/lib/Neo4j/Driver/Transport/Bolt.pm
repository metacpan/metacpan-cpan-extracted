use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Transport::Bolt;
# ABSTRACT: Adapter for Neo4j::Bolt
$Neo4j::Driver::Transport::Bolt::VERSION = '0.11';

use Carp qw(croak);
our @CARP_NOT = qw(Neo4j::Driver::Transaction);

use URI 1.25;
use Neo4j::Bolt;

use Neo4j::Driver::StatementResult;


sub new {
	my ($class, $driver) = @_;
	
	my $uri = $driver->{uri};
	if ($driver->{auth}) {
		croak "Only Basic Authentication is supported" if $driver->{auth}->{scheme} ne 'basic';
		$uri = $uri->clone;
		$uri->userinfo( $driver->{auth}->{principal} . ':' . $driver->{auth}->{credentials} );
	}
	
	my $cxn = Neo4j::Bolt->connect_("$uri");
	croak "Unauthorized" unless $cxn;
	
	return bless {
		connection => $cxn,
		uri => $driver->{uri},
	}, $class;
}


# Prepare query statement, including parameters. When multiple statements
# are to be combined in a single server communication, this method allows
# preparing each statement individually.
sub prepare {
	my ($self, $tx, $query, $parameters) = @_;
	
	my $statement = [$query, $parameters // {}];
	return $statement;
}


# Send statements to the Neo4j server and return all results. Will either
# continue to use the existing open server transaction or create a new one
# (iff the server transaction is not yet open).
sub run {
	my ($self, $tx, @statements) = @_;
	
	# multiple statements not yet supported for Bolt
	my ($statement) = @statements;
	
	my ($stream, $json);
	if ($statement->[0]) {
		$stream = $self->{connection}->run_query_( @$statement );
		
		# There is some sort of strange problem passing the stream along
		# to StatementResult. As a workaround, for now we consume the full
		# stream right here and re-create the JSON result data structure.
		my @names = $stream->fieldnames_;
		my @data = ();
		while ( my @row = $stream->fetch_next_ ) {
			push @data, { row => \@row };
		}
		$json = {
			columns => \@names,
			data => \@data,
		};
	}
	
	my $summary;  # not yet implemented
	my $result = Neo4j::Driver::StatementResult->new( $json, $summary );
	return ($result);
}


# Declare that the specified transaction should be treated as an explicit
# transaction (i. e. it is opened at this time and will be closed by
# explicit command from the client).
sub begin {
	my ($self, $tx) = @_;
	
	$self->run( $tx, $self->prepare($tx, 'BEGIN') );
}


# Declare that the specified transaction should be treated as an autocommit
# transaction (i. e. it should automatically close successfully when the
# next statement is run).
sub autocommit {
}


# Mark the specified server transaction as successful and close it.
sub commit {
	my ($self, $tx) = @_;
	
	$self->run( $tx, $self->prepare($tx, 'COMMIT') );
}


# Mark the specified server transaction as failed and close it.
sub rollback {
	my ($self, $tx) = @_;
	
	$self->run( $tx, $self->prepare($tx, 'ROLLBACK') );
}


sub server_info {
	my ($self) = @_;
	
	# That the ServerInfo is provided by the same object
	# is an implementation detail that might change in future.
	return $self;
}


# server_info->
sub address {
	my ($self) = @_;
	
	return URI->new( $self->{uri} )->host_port;
}


# server_info->
sub version {
	my ($self) = @_;
	
	...
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Transport::Bolt - Adapter for Neo4j::Bolt

=head1 VERSION

version 0.11

=head1 DESCRIPTION

The L<Neo4j::Driver::Transport::Bolt> package is not part of the
public L<Neo4j::Driver> API.

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2019 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

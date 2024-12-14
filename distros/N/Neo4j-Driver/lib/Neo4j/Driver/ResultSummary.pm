use v5.12;
use warnings;

package Neo4j::Driver::ResultSummary 1.02;
# ABSTRACT: Details about the result of running a query


use Carp qw(croak);

use Neo4j::Driver::SummaryCounters;


sub new {
	# uncoverable pod (private method)
	my ($class, $result, $notifications, $query, $server_info) = @_; 
	
	return bless {
		counters => $result->{stats},
		notifications => $notifications,
		plan => $result->{plan},
		query => $query,
		server_info => $server_info,
	}, $class;
}


sub counters {
	my ($self) = @_;
	
	$self->{counters} //= {};
	return Neo4j::Driver::SummaryCounters->new( $self->{counters} );
}


sub notifications {
	my ($self) = @_;
	
	$self->{notifications} //= [];
	return @{ $self->{notifications} };
}


sub plan {
	my ($self) = @_;
	
	return $self->{plan};
}


sub statement {
	# uncoverable pod (see query)
	warnings::warnif deprecated => "statement() in Neo4j::Driver::ResultSummary is deprecated; use query() instead";
	&query;
}


sub query {
	my ($self) = @_;
	
	$self->{query} //= [ '', {} ];
	return ref $self->{query} eq 'ARRAY' ? {
		text       => $self->{query}->[0],
		parameters => $self->{query}->[1],
	} : {
		text       => $self->{query}->{statement},
		parameters => $self->{query}->{parameters} // {},
	};
}


sub server {
	my ($self) = @_;
	
	return $self->{server_info};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::ResultSummary - Details about the result of running a query

=head1 VERSION

version 1.02

=head1 SYNOPSIS

 $summary = $session->execute_write( sub ($transaction) {
   return $transaction->run( ... )->consume;
 });
 
 # SummaryCounters
 $counters = $summary->counters;
 
 # Query information
 $query  = $summary->query->{text};
 $params = $summary->query->{parameters};
 $plan   = $summary->plan;
 @notes  = $summary->notifications;
 
 # ServerInfo
 $address = $summary->server->address;
 $version = $summary->server->agent;

=head1 DESCRIPTION

The result summary of running a query. The result summary can be
used to investigate details about the result, like the Neo4j server
version, how many and which kinds of updates have been executed, and
query plan information if available.

To obtain a result summary, call L<Neo4j::Driver::Result/"consume">.

=head1 METHODS

L<Neo4j::Driver::ResultSummary> implements the following methods.

=head2 counters

 $summary_counters = $summary->counters;

Returns the L<SummaryCounters|Neo4j::Driver::SummaryCounters> with
statistics counts for operations the query triggered.

=head2 notifications

 @notifications = $summary->notifications;
 
 use Data::Printer;
 p @notifications;

A list of notifications that might arise when executing the
query. Notifications can be warnings about problematic queries
or other valuable information that can be presented in a client.
Unlike failures or errors, notifications do not affect the execution
of a query.
In scalar context, return the number of notifications.

This driver only supports notifications over HTTP.

=head2 plan

 $plan = $summary->plan;
 
 use Data::Printer;
 p $plan;

This describes how the database will execute your query.
Available if this is the summary of a Cypher C<EXPLAIN> query.

This driver only supports execution plans over HTTP.

=head2 query

 $query  = $summary->query->{text};
 $params = $summary->query->{parameters};

The executed query and query parameters this summary is for.

Before driver S<version 1.00>, the query was retrieved with the
C<statement()> method. That method has since been deprecated,
matching a corresponding change in S<Neo4j 4.0>.

=head2 server

 $address = $summary->server->address;
 $version = $summary->server->agent;

The L<ServerInfo|Neo4j::Driver::ServerInfo>, consisting of
the host, port, protocol and Neo4j version.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * L<Neo4j::Driver::B<ServerInfo>>

=item * L<Neo4j::Driver::B<SummaryCounters>>

=back

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://metacpan.org/author/AJNN>)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2024 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut

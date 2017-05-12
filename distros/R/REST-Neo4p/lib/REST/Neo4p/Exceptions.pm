#$Id$
package REST::Neo4p::Exceptions;
use strict;
use warnings;

BEGIN {
  $REST::Neo4p::Exceptions::VERSION = '0.3012';
  $REST::Neo4p::Exceptions::VERSION = '0.3012';
}
use Exception::Class (
  'REST::Neo4p::Exception',
  'REST::Neo4p::LocalException' => {
    isa => 'REST::Neo4p::Exception',
    fields => [ 'code' ],
    description => 'REST::Neo4p code-local error'
   },
  'REST::Neo4p::Neo4jException' => {
    isa => 'REST::Neo4p::Exception',
    fields => [ 'code', 'neo4j_message', 
		'neo4j_exception', 'neo4j_stacktrace' ],
    description => 'Neo4j server errors'
   },
  'REST::Neo4p::CommException' =>
    {
    isa => 'REST::Neo4p::Exception',
    fields => [ 'code' ],
    description => 'Network or HTTP errors'
   },
  'REST::Neo4p::AuthException' =>
    {
    isa => 'REST::Neo4p::Exception',
    fields => [ 'code', 'message' ],
    description => 'Authorization error'
   },
  'REST::Neo4p::NotFoundException' => {
    isa => 'REST::Neo4p::Neo4jException',
    fields => [ 'code', 'neo4j_message', 
		'neo4j_exception', 'neo4j_stacktrace' ],
    description => 'URL or item not found'
   },
  'REST::Neo4p::ConflictException' => {
    isa => 'REST::Neo4p::Neo4jException',
    fields => [ 'code', 'neo4j_message', 
		'neo4j_exception', 'neo4j_stacktrace' ],
    description => 'Conflict (409) thrown when fail is specified for create_unique on indexes'
   },
  'REST::Neo4p::TxQueryException' => 
    {
    isa => 'REST::Neo4p::Neo4jException',
    fields => [qw/error_list message code/],
    description => 'List of errors returned by query executed within a txn'
   },
  'REST::Neo4p::QuerySyntaxException' =>
    {
      isa => 'REST::Neo4p::Neo4jException',
      fields => [ 'code', 'neo4j_message', 
		  'neo4j_exception', 'neo4j_stacktrace' ],
      description => 'Cypher query language syntax error'
     },
  'REST::Neo4p::NotImplException' => {
    isa => 'REST::Neo4p::LocalException',
    description => 'Attempt to call an currently unimplemented method'
   },
  'REST::Neo4p::NotSuppException' => {
    isa => 'REST::Neo4p::LocalException',
    description => 'Attempt to call a non-supported inherited method'
   },
  'REST::Neo4p::TxException' => {
    isa => 'REST::Neo4p::LocalException',
    description => 'Problem with transaction building or execution'
   },
  'REST::Neo4p::AbstractMethodException' => {
    isa => 'REST::Neo4p::LocalException',
    description => 'Attempt to call a subclass-only method from a parent class'
   },
  'REST::Neo4p::ClassOnlyException' => {
    isa => 'REST::Neo4p::LocalException',
    message => 'This is a class method only',
    description => 'Attempt to call a class method from an instance'
   },
  'REST::Neo4p::VersionMismatchException' => {
    isa => 'REST::Neo4p::LocalException',
    message => 'This feature is not supported in your neo4j server version',
    description => 'Use of features only implemented in a more recent neo4j version'
   },
  'REST::Neo4p::QueryResponseException' => {
    isa => 'REST::Neo4p::LocalException',
    description => 'Problem parsing the response to a cypher query (prob. a bug)'
   },
  'REST::Neo4p::EmptyQueryResponseException' => {
    isa => 'REST::Neo4p::LocalException',
    description => 'The server response body was empty; connection problem?'
   },
  'REST::Neo4p::StreamException' => {
    isa => 'REST::Neo4p::LocalException',
    description => 'Neo4j JSON response parsing error',
    fields => ['message']
   },
  'REST::Neo4p::ConstraintException' => {
    isa => 'REST::Neo4p::LocalException',
    description => 'Application-level database constraint violated',
    fields => ['args']
   },
  'REST::Neo4p::ConstraintSpecException' => {
    isa => 'REST::Neo4p::LocalException',
    description => 'Constraint specification syntax incorrect',
  }
   );

=head1 NAME

REST::Neo4p::Exceptions - Exception::Class objects for REST::Neo4p

=head1 SYNOPSIS

 use REST::Neo4p;
 
 my $server = 'http:127.0.0.1:7474';
 my $RETRIES = 3;
 my $e;
 do {
   eval {
     REST::Neo4p->connect($server);
     $RETRIES--;
   };
 } while ( $e = Exception::Class->caught('REST::Neo4p::CommException') );
 (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e if $e;

=head1 Classes

=over

=item * Base Class : REST::Neo4p::Exception

=over

=item * REST::Neo4p::CommException

Network and server communication errors. Method C<code()> returns the
HTTP status code.

=item * REST::Neo4p::LocalException

L<REST::Neo4p> module-local errors.

=over

=item * REST::Neo4p::ClassOnlyException

Attempt to use a class-only method on a class instance.

=item * REST::Neo4p::NotSuppException

Attempt to use a base method not supported in the subclass.

=item * REST::Neo4p::NotImplException

Attempt to use a not yet implemented method.

=item * REST::Neo4p::AbstractMethodException

Attempt to call a subclass-only method from a parent class.

=item * REST::Neo4p::ConstraintException

Attempt to perform a database action that violates an application-level
constraint (L<REST::Neo4p::Constrain>, L<REST::Neo4p::Constraint>).

=item * REST::Neo4p::ConstraintSpecException

Attempt to create a new constraint with incorrect constraint syntax
(L<REST::Neo4p::Constrain>,L<REST::Neo4p::Constraint>)

=back

=item * REST::Neo4p::Neo4jException

Exceptions and errors generated by the Neo4j server. Methods
C<neo4j_message()>, C<neo4j_stacktrace()>, C<neo4j_exception()> return
server-generated info.

=over 

=item * REST::Neo4p::NotFoundException

Requested item not found in database.

=item * REST::Neo4p::QuerySyntaxException

Bad query syntax (see L<REST::Neo4p::Query>).

=back

=back

=back

=head1 SEE ALSO

L<REST::Neo4p>, L<Exception::Class>

=head1 AUTHOR

    Mark A. Jensen
    CPAN ID: MAJENSEN
    TCGA DCC
    mark -dot- jensen -at- nih -dot- gov
    http://tcga-data.nci.nih.gov

=head1 LICENSE

Copyright (c) 2012-2015 Mark A. Jensen. This program is free software; you
can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;

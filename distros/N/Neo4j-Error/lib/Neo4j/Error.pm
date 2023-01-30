use v5.10;
use strict;
use warnings;

package Neo4j::Error;
# ABSTRACT: Common Neo4j exception representations
$Neo4j::Error::VERSION = '0.01';

use List::Util 1.33 qw(first none);
use Module::Load qw(load);

my @SOURCES = qw( Server Network Internal Usage );
my @KEYS = qw(
	as_string
	category
	classification
	code
	is_retryable
	message
	raw
	related
	source
	title
	trace
);


sub _croak {
	require Carp;
	Carp::croak(@_);
}


sub new {
	my ($class, $source, $info, @extra) = @_;
	
	_croak "Call as instance method unsupported for %s->new()", __PACKAGE__ if ref $class ne '';
	_croak sprintf "Source param required for %s->new()", __PACKAGE__ unless $source && ref $source eq '';
	if ($class eq __PACKAGE__) {
		$class = first { $_ eq $source } @SOURCES;
		_croak sprintf "Source '%s' is unsupported for %s->new()", $source, __PACKAGE__ unless $class;
		$class = __PACKAGE__ . "::$class";
		load $class;
	}
	else {  # subclass
		_croak sprintf "Class %s fails to implement source()", $class unless $class->can('source');
		_croak sprintf "Ambiguous source %s for %s", $source, $class if $class->source ne $source;
	}
	
	if ($info && ref $info eq '') {
		$info = { as_string => '' . $info };
	}
	elsif (ref $info ne 'HASH') {
		_croak sprintf "Hashref or string required for %s->new()", $class;
	}
	_croak "Too many arguments for $class->new()" if @extra;
	
	my $self = bless {}, $class;
	$self->{$_} = $info->{$_} for @KEYS;
	
	require Devel::StackTrace;
	my $trace_config = $info->{trace} // {};
	$trace_config->{skip_frames}++;
	$trace_config->{message} //= $self->as_string;
	$self->{trace} = Devel::StackTrace->new(%$trace_config);
	
	return $self;
}


sub append_new {
	my ($self, $source, $related, @extra) = @_;
	
	_croak sprintf "Source param required for %s->append_new()", __PACKAGE__ unless $source && ref $source eq '';
	_croak sprintf "Ambiguous source %s for %s", $source, $self if ref $self eq '' && $self->can('source') && $self->source ne $source;
	
	if ($related && ref $related eq '') {
		$related = { as_string => '' . $related };
	}
	elsif (ref $related ne 'HASH') {
		_croak sprintf "Hashref or string required for %s->append_new()", __PACKAGE__;
	}
	
	my $class = ref $self eq '' ? $self : __PACKAGE__;
	$related->{trace}{skip_frames}++;
	$related = $class->new($source => $related, @extra);
	return $related if ref $self eq '';  # if called as class method, behave just like new()
	
	my $tail = $self;
	$tail = $tail->{related} while $tail->{related};
	$tail->{related} = $related;
	return $self;
}


sub as_string {
	my ($self) = @_;
	
	my $str = $self->{as_string};
	return $str if defined $str;
	
	my $code = $self->code;
	my $message = $self->message;
	$str = sprintf "%s: %s", $code, $message if $code && $message;
	$str = sprintf "%s %s", ref $self, $code if $code && ! $message;
	$str = sprintf "%s", $message if ! $code && $message;
	$str = $self->trace unless $str;  # last resort
	return $self->{as_string} = $str;
}


sub message { shift->{message} // '' }
sub code { shift->{code} // '' }
sub classification { '' }
sub category { '' }
sub title { '' }
sub is_retryable { !!0 }

sub related { shift->{related} }

sub raw { shift->{raw} }
sub trace { shift->{trace} }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Error - Common Neo4j exception representations

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 # Consumer:
 QUERY: {
   $result = $dbh->run_neo4j($query);
   if ($result isa Neo4j::Error) {
     redo QUERY if $e->is_retryable && ++$counter < 3;
     printf "Neo4j [%s] error %s: %s",
       $e->source, $e->code, $e->as_string;
   }
 }
 
 # Producer:
 $server_error = Neo4j::Error->new( Server => {
   code      => 'Neo.ClientError.Statement.SyntaxError',
   message   => 'Expected Cypher query',
 });
 $http_error   = Neo4j::Error->new( Network => {
   code      => '401',
   message   => 'Unauthorized',
 });
 $intern_error = Neo4j::Error->new( Internal => {
   as_string => 'JSON decoding failure',
 });
 $usage_error  = Neo4j::Error->new( Usage => {
   as_string => 'Calling get() with two args is not allowed',
 });

=head1 DESCRIPTION

Common Neo4j exception representations.

Each instance represents an error (or warning) that was issued by
the Neo4j graph database server, networking library, Neo4j Perl
driver or similar source. Instances are meant to be immutable.

Instances are not necessarily meant to be thrown as exceptions
with C<die>. They might be used for error reporting through other
means.

=head1 METHODS

L<Neo4j::Error> implements the following methods.

=head2 as_string

 $text = $error->as_string;

Return a human-readable error message that also includes the
error code and possibly further information. Basically something
you would expect to be passed to C<die>.

If C<as_string> has not been provided to C<new()>, this software
tries to auto-generate something suitable.

=head2 category

 $string = $error->category;

The Neo4j "category" of this error, parsed from the Neo4j
status code. One of: C<Cluster>, C<Database>, C<Fabric>,
C<General>, C<LegacyIndex>, C<Procedure>, C<Request>,
C<Schema>, C<Security>, C<Statement>, C<Transaction>.

For errors that don't originate on the Neo4j server,
this method returns the empty string.

=head2 classification

 $string = $error->classification;

The Neo4j "classification" of this error, parsed from the Neo4j
status code. One of: C<ClientError>, C<ClientNotification>,
C<TransientError>, C<DatabaseError>.

For errors that don't originate on the Neo4j server,
this method returns the empty string.

=head2 code

 $code = $error->code;

Return a machine-readable error identification.
The kind of code varies by the source of this error.
For errors that originate on the Neo4j server, the
L<Neo4j status code|https://neo4j.com/docs/status-codes/current/>
string is passed through. For other error sources,
the code may be an error number or other identifier.

Note that some error conditions are not associated with
a machine-readable code. For such errors, this method
returns the empty string.

=head2 is_retryable

 $boolean = $error->is_retryable;

Whether the error is of a type that suggests it would be safe
and reasonable to retry the original request without alteration
(assuming it is idempotent). Examples of such errors might be
deadlocks or memory issues.

In particular, this method returns true for the following errors:

=over

=item * Neo4j errors with the classification C<TransientError>

=item * currently, all network errors (liable to change)

=back

=head2 message

 $text = $error->message;

Return a human-readable error message. Basically something you
would expect to be passed to C<die>, except it should I<not>
include the error code and should also be reasonably short.

If no message is available, this method returns the empty string.

=head2 raw

 $data = $error->raw;

Return raw data if available, which might potentially contain
additional information about the error. For example, the body
content of an HTTP response or the "failure details" hashref
of a L<Neo4j::Bolt::ResultStream>.

If no raw data is available, this method returns C<undef>.

=head2 related

 $next_error = $error->related;
 
 # Traverse the linked list
 do { say $error->as_string } while $error = $error->related;

Return the next related error.

When multiple errors occur at the same time, they may be made
available in the form of a singly-linked list. This method
provides the next error in that list. This is conceptually
similar to the "caused by" relationship known from exception
systems in some other languages such as Java, but different
in that the type of the relationship is not defined.
In general, the first error object you receive directly from
your database driver should represent the primary error
condition, with additional supporting information made
available by any related errors. Consequently, it should
in general be safe to ignore any related errors altogether;
however, this depends on the database driver's behaviour
and is not necessarily guaranteed.

If there is no next related error, this method returns C<undef>.

=head2 source

 $source = $error->source;

The original source of this error.
One of: C<Server>, C<Network>, C<Internal>, C<Usage>.

See L</"ERROR SOURCES"> below.

=head2 title

 $string = $error->title;

The Neo4j "title" of this error, parsed from the Neo4j
status code.

For errors that don't originate on the Neo4j server,
this method returns the empty string.

=head2 trace

 $stack_trace = $error->trace;
 print $stack_trace->as_string;

Return a stack trace in the form of a L<Devel::StackTrace> object.
The trace begins at the point where the error object was created.

=head1 CONSTRUCTORS

I<See also: L</"BUGS AND LIMITATIONS">>

L<Neo4j::Error> implements the following constructor methods.

=head2 new

 $e = Neo4j::Error->new( $source => \%error_info );
 
 # Hashref optional for pure string error messages
 $e = Neo4j::Error->new( Internal =>
          { as_string => $error_string });
 $e = Neo4j::Error->new( Internal => "$error_string" );

Construct a new L<Neo4j::Error> object.

The C<new()> method expects to be given an error source and a
hashref with further information about the error the new object
is meant to represent. Hash entries should have the same names
as methods in this module. Not all hash entries might be used.
Any unneeded hash entries are silently ignored.

When C<as_string> would be the only hash entry, the hashref may
optionally be replaced by a string.

If the optional C<trace> hash entry is present, its contents
are interpreted as L<Devel::StackTrace> constructor parameters.

As decoded Neo4j Jolt/JSON error events are simply hashrefs
with two entries C<code> and C<message>, they can be passed to
C<new()> as-is. This software will properly handle both Jolt
formats ("sparse" and "strict").

=head2 append_new

 $e = 'Neo4j::Error';
 $e = $e->append_new( ... ) if $error_cond_1;
 $e = $e->append_new( ... ) if $error_cond_2;
 $e = $e->append_new( ... ) if $error_cond_3;
 if (ref $e) {
   # Handle errors in the order they occurred
   do { handle_error $e } while $e = $e->related;
 }

If called as class method, C<append_new()> behaves identically
to C<new()>.

If called as object method, C<append_new()> traverses the linked
list of related errors and appends the newly constructed error
to the end of the list. In situations where a variety of error
conditions might or might not apply, this constructor provides a
way to assemble an error object with any number of related errors
using a simple and consistent call syntax.

=head1 ERROR SOURCES

I<See also: L</"BUGS AND LIMITATIONS">>

The source of the error is indicated by the error object's class.
It is also available as a string via L<C<source()>|/"source">.

Reported error sources aren't necessarily indicative of the true
error cause, because not every error fits neatly into one single
group. For example, an authentication failure (wrong password)
might legitimately be reported as coming from any of these sources:

=over

=item * B<Server:> Neo4j status C<Neo.ClientError.Security.Unauthorized>

=item * B<Network:> HTTP status C<401> or Bolt libneo4j-client C<-15>

=item * B<Internal:> Default fallback because the true cause is unclear

=item * B<Usage:> Wrong password supplied by user

=back

For an individual L<Neo4j::Error> object, the primary significance
of the source is to define the semantics of the error's
L<C<code()>|/"code">.

=head2 Server

Represents an error that originates on a Neo4j server.
Always has a code in the form of a
L<Neo4j status code|https://neo4j.com/docs/status-codes/current/>,
with individual components that can be queried using
L<C<classification()>|/"classification">,
L<C<category()>|/"category">, and L<C<title()>|/"title">.

=head2 Network

Represents a network protocol or network library having signalled
an error condition. The error code is either defined by the
protocol (as is the case for HTTP) or by the networking library
(for example libneo4j-client, used by L<Neo4j::Bolt>). The actual
cause of the error may or may not be network-related.

=head2 Internal

Represents an error condition that originates locally in the
software creating the L<Neo4j::Error> object (the database driver).
The "internal" source is also used as a default fallback in case
the error is not clearly attributable to a more specific source.
May or may not have an error code.

Note that depending on the cause of the error, your software might
just C<die> ordinarily with a string message instead of reporting
the error using this class.

=head2 Usage

Represents a case of the user supplying the wrong arguments to
a method or using an object in an illegal state. Usually has
no error code. Note that your software might well just C<die>
ordinarily with a string message instead of reporting the error
using this class.

=head1 BUGS AND LIMITATIONS

This distribution is new and still somewhat experimental.
Aspects of the interface that are still evolving are primarily
the constructors and the semantics of "sources".

=head1 SEE ALSO

=over

=item *

L<Neo4j status codes|https://neo4j.com/docs/status-codes/current/>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut

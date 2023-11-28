=head1 NAME

   PGObject::Util::DBException -- Database Exceptions for PGObject

=cut

package PGObject::Util::DBException;

=head1 VERSION

   2.4.0

=cut

our $VERSION = '2.4.0';

=head1 SYNOPSIS

   use PGObject::Util::DBException;

   $dbh->execute(@args) || die 
       PGObject::Util::DBException->new($dbh, $query, @args);

   # if you need something without dbh:

   die PGObject::Util::DBException->internal($state, $string, $query, $args);

   # if $dbh is undef, then we assume it is a connection error and ask DBI

   # in a handler you can check
   try {
       some_db_func();
   } catch {
       if ($_->isa('PGObject::Util::DBException')){
           if ($_->{state} eq '23505') {
               warn "Duplicate data detected.";
           }
           log($_->log_msg);
           die $_;
       }
       else {
           die $_;
       }

=cut

use strict;
use warnings;
use overload '""' => 'short_string';
use DBI;

our $STRINGIFY_STACKTRACE = 1;

=head1 DESCRIPTION

Database errors occur sometimes for a variety of reasons, including bugs,
environmental, security, or user access problems, or a variety of other
reasons.  For applications to appropriately handle database errors, it is often
necessary to be able to act on categories of errors, while if we log errors for
later analysis we want more information there.  For debugging (or even logging)
we might even want to capture stack traces in order to try to understand where
errors came from.  On the other hand, if we just want to display an error, we
want to get an appropriate error string back.

This class provides both options.  On one side, it provides data capture for
logging, introspection, and analysis.  On the other it provides a short string
form for display purposes.

This is optimized around database errors.  It is not intended to be a general
exception class outside the database layer.

If C<Devel::StackTrace> is loaded we also capture a stack trace.

=head2 Internal Error Codes

In order to handle internal PGObject errors, we rely on the fact that no
current SQL subclasses contian the letter 'A' which we will use to mean
Application.  We therefore take existing SQLState classes and use AXX
(currently only A01 is used currently) to handle these errors.

=over

=item 26A01

Function not found.  No function with the discovery criteria set was found.

=item 42A01

Function not unique.  Multiple functions for the discovery criteria were
found.

=back

=head2 Stack Traces

If C<Devel::StackTrace> is loaded, we will capture stack traces starting at the
exception class call itself.

In order to be unobtrusive, these are stringified by default.  This is to avoid
problems of reference counting and lifecycle that can happen when capturing
tracing information,  If you want to capture the whole stack trace without
stringification, then you can set the following variable to 0:
C<PGObject::Util::DBException::STRINGIFY_STACKTRACE>.  Naturally this is best
done using the C<local> keyword.

Note that non-stringified stacktraces are B<not> weakened and this can cause
things like database handles to persist for longer than they ordinarily would.
For this reason, turning off stringification is best reserved for cases where
it is absolutely required.

=head1 CONSTRUCTORS

All constructors are called exclusively via C<$class->method> syntax.

=head2 internal($state, $errstr, $query, $args);

Used for internal application errors.  Creates an exception of this type with
these attributes.  This is useful for appication errors within the PGObject
framework.

=cut

sub internal ($$$$@) {
    my ($class, $state, $errstr, $query, @args) = @_;
    my $self = {
        state  => $state,
        errstr => $errstr,
        query  => $query,
        args   => \@args,
        trace  => undef,
    };
    if (scalar grep { $_ eq 'Devel/StackTrace.pm' } keys %INC){
        $self->{trace} = $STRINGIFY_STACKTRACE ? Devel::StackTrace->new->as_string
                                               : Devel::StackTrace->new;
    }
    bless $self, $class;
}


=head2 new($dbh, $query, @args)

This creates a new exception object.  The SQL State is taken from the C<$dbh>
database handle if it is defined, and the C<DBI> module if it is not.

=cut

sub new ($$$@) {
    my ($class, $dbh, $query, @args) = @_;
    return $class->internal(
        (defined $dbh ? $dbh->state  : $DBI::state  ),
        (defined $dbh ? $dbh->errstr : $DBI::errstr ),
        $query, @args
    );
}

=head1 Stringificatoin

This module provides two methods for string representation.  The first, for
human-focused error messages also overloads stringification generally.  The
second is primarily intended for logging purposes.

=head2 short_string

The C<short_string> method returns a short string of C<state: errstr> for human
presentation.

=cut

sub short_string ($) {
    my $self = shift;
    return "$self->{state}: $self->{errstr}";
}

=head2 log_msg

As its name suggests, C<log_msg> aimes to provide full infomation for logging
purposes.

The format here is:

  STATE state, errstr
  Query: query
  Args: joun(',', @args)
  Trace: Stacktrace


=cut

sub log_msg ($) {
    my $self = shift;
    my $query = ( $self->{query} // 'None' );
    my $string = join "\n",
       "STATE $self->{state}, $self->{errstr}",
       "Query: $query",
       "Args: " . (join ',', @{$self->{args}}),
       ($self->{trace} ? "Trace: $self->{trace}" : ());
    return $string;
}

1;

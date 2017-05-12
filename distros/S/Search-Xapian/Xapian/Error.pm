package Search::Xapian::Error;

=head1 NAME

Search::Xapian::Error - Base class for all exceptions in Search::Xapian

=head1 DESCRIPTION

This is an abstract class in C++, i.e. it cannot be instantiated directly.
In Perl there is no such concept, but you should not need to create instances
of this class yourself.

=head1 METHODS

All exception objects have the following methods

=head2 get_msg

Returns a string with a descriptive error message, useful for outputting

=head2 get_type

The type of this error (e.g. "DocNotFoundError").

=head2 get_context

Optional context information, returned as a string

=head2 get_error_string

Returns any error string from errno or similar associated with this error

=cut

use 5.006;
use strict;
use warnings;

require DynaLoader;

use Search::Xapian::LogicError;
use Search::Xapian::RuntimeError;

our @ISA = qw(DynaLoader);

# Preloaded methods go here.

# In a new thread, copy objects of this class to unblessed, undef values.
sub CLONE_SKIP { 1 }

sub new {
    my $class = shift;
    my ($self);
    bless $self, $class;

    return $self;
}

1;

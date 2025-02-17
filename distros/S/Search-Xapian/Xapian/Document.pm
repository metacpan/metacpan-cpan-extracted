package Search::Xapian::Document;

use 5.006;
use strict;
use warnings;
use Carp;

require DynaLoader;

our @ISA = qw(DynaLoader);

# Preloaded methods go here.

# In a new thread, copy objects of this class to unblessed, undef values.
sub CLONE_SKIP { 1 }

use overload '='  => sub { $_[0]->clone() },
	     'fallback' => 1;

sub clone() {
  my $self = shift;
  my $class = ref( $self );
  my $copy = new2( $self );
  bless $copy, $class;
  return $copy;
}
sub new() {
  my $class = shift;
  my $document;
  my $invalid_args;
  if( scalar(@_) == 0 ) {
    $document = new1();
  } elsif( scalar(@_) == 1 and ref( $_[1] ) eq $class ) {
    $document = new2(@_);
  } else {
    $invalid_args = 1;
  }
  if( $invalid_args ) {
    Carp::carp( "USAGE: $class->new(), $class->new(\$document)" );
    exit;
  }
  bless $document, $class;
  return $document;
}

1;

__END__

=head1 NAME

Search::Xapian::Document - Document object

=head1 DESCRIPTION

This class represents a document in a Xapian database.

=head1 METHODS

=over 4

=item new

Class constructor.

=item clone

Return a clone of this class.

=item get_value (value_no)

Returns the value by the assigned number.

=item add_value <value_no> <value>

Set a value by value number.

=item remove_value <value_no>

Removes the value with the assigned number.

=item clear_values

Clear all set values.

=item get_data

Return all document data.

=item set_data <data>

Set all document data. This can be anything you like.

=item add_posting <term> <position> [<wdfinc>]

Adds a term at the given position. wdfinc defaults to 1.

=item remove_posting <term> <position> [<wdfdec>]

Removes a term from the given position. wdfdec defaults to 1.

=item add_term <term> [<wdfinc>]

Adds a term without positional information. wdfinc defaults to 1.

=item add_boolean_term <term>

Adds a term intended for boolean filtering (its wdf contribution will be 0).

=item remove_term <term>

Removes a term and all postings associated with it.

=item clear_terms

Remove all terms from the document.

=item termlist_count

Returns number of different terms in the document.

=item termlist_begin

Iterator for the terms in this document. Returns a
L<Search::Xapian::TermIterator>.

=item termlist_end

Equivalent end iterator for termlist_begin().  Returns a
L<Search::Xapian::TermIterator>.

=item values_count

Return number of defined values for this document.

=item values_begin

Return a L<Search::Xapian::ValueIterator> pointing at the start of the
values in this document.

=item values_end

Return a L<Search::Xapian::ValueIterator> pointing at the end of the
values in this document.

=item get_description

Return a description of this object.

=back

=head1 SEE ALSO

L<Search::Xapian::Database>

=cut

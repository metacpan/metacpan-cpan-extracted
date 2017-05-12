package Sort::MergeSort::Iterator;

# $Id: Iterator.pm 13859 2009-07-24 08:02:37Z david $

use strict;
use warnings;
use Carp;
use Carp qw(confess);
our $VERSION = '0.01';
use Symbol;

##############################################################################
# Constructor.
##############################################################################

sub new {
	my ( $class, $code, $destroy ) = @_;
	croak qq{Argument "$code" is not a code reference} if ref $code ne 'CODE';
	croak qq{Argument "$destroy" is not a code reference}
		if $destroy && ref $destroy ne 'CODE';

	my $self = bless gensym, $class;
	${*$self}{code} = $code;
	${*$self}{destroy} = $destroy;
	${*$self}{count} = 0;

	tie(*$self, $class, $self);

	return $self;
}

DESTROY {
	my $self = shift;
	my $dest = ${*$self}{destroy} or return;
	$dest->();
}

##############################################################################
# Instance Methods.
##############################################################################

sub next {
	my $self = shift;
	${*$self}{curr} = exists ${*$self}{peek}
		? delete ${*$self}{peek}
		: ${*$self}{code}->();
	${*$self}{count}++ if defined ${*$self}{curr};
	return ${*$self}{curr};
}

##############################################################################

sub current { 
	my $self = shift;
	${*$self}{curr};
}

##############################################################################

sub peek {
	my $self = shift;
	return ${*$self}{peek} ||= ${*$self}{code}->();
}

##############################################################################

sub position { 
	my $self = shift;
	${*$self}{count};
}

##############################################################################

sub all {
	my $self = shift;
	my @items;
	push @items, $self->next while $self->peek;
	return wantarray ? @items : \@items;
}

##############################################################################

sub do {
	my ( $self, $code ) = @_;
	while ( local $_ = $self->next ) {
		return unless $code->($_);
	}
}

##############################################################################

sub close
{
	my $self = shift;
	my $dest = ${*$self}{destroy} or return;
	$dest->();
	delete ${*$self}{destroy};
	${*self}{code} = sub { die "attempt to read a closed iterator" };
}

*CLOSE = \&close;

sub sysread { die "not implemented" }
sub open { die "not implemented" }
sub syswrite { die "not implemented" }
sub ungetc { die "not implemented" }
sub getc { die "not implemented" }
sub ungetline { die "not implemented" }
sub xungetc { die "not implemented" }
sub print { die "not implemented" }
sub fileno { die "not implemented" }
sub PRINTF { die "not implemented" }
sub PRINT { die "not implemented" }
sub READ { confess "not implemented" }
sub read { die "not implemented" }
sub WRITE { die "not implemented" }
sub TELL { die "not implemented" }
sub SEEK { die "not implemented" }
sub OPEN { die "not implemented" }
sub GETC { die "not implemented" }
sub BINMODE { }

sub eof 
{
	my $self = shift;
	return ! defined $self->peek;
}

*EOF = \&eof;

sub getlines
{
	my $self = shift;
	die unless wantarray;
	return ($self->all());
}

sub TIEHANDLE
{
	my ($class, $self) = @_;
	return $self;
}

*READLINE = \&next;

1;
__END__

=head1 Name

Sort::MergeSort::Iterator - iteration object

=head1 Synopsis

  my $input = Sort::MergeSort::Iterator->new( sub { ... } );

  while (<$input>) {
  }

  while (my $i = $input->next) {
  }

  my $ahead = $input->peek;

=head1 Description

This class implements a simple iterator interface for iterating over items.
Just pass a code reference to the constructor that returns the next value over
which to iterate. Sort::MergeSort::Iterator will do the rest.

=head2 FileHandle Interface

You can pretend that an Iterator object is a filehandle.   It doesn't support
all filehandle operations, but it does allow you to iterate in the natural
way:

 while (<$input>) {
 }

=head2 Instance Methods

=head1 Class Interface

=head2 Constructors

=head3 new

  my $iter = Sort::MergeSort::Iterator->new(\&code_ref);
  my $iter = Sort::MergeSort::Iterator->new(\&code_ref, \&destroy_code_ref);

Constructs and returns a new iterator object. The code reference passed as the
first argument is required and must return the next item to iterate over each
time it is called, and C<undef> when there are no more items. C<undef> cannot
itself be an item. The optional second argument must also be a code reference,
and will only be executed when the iterator object is destroyed (that is, it
will be called in the C<DESTROY()> method).

=head3 current

  my $current = $iter->current;

Returns the current item in the iterator--that is, the same item returned by
the most recent call to C<next()>.

=head3 next

  while (my $thing = $iter->next) {
	  # Do something with $thing.
  }

Returns the next item in the iterator. Returns C<undef> when there are no more
items to iterate.

=head3 peek

  while ($iter->peek) {
	  $iter->next;
  }

Returns the next item to be returned by C<next()> without actually removing it
from the list of items to be returned. The item returned by C<peek()> will be
returned by the next call to C<next()>. After that, it will not be available
from C<peek()> but the next item will be.

=head3 position

  my $pos = $iter->position;

Returns the current position in the iterator. After the first time C<next()>
is called, the position is set to 1. After the second time, it's set to 2. And
so on. If C<next()> has never been called, C<position()> returns 0.

=head3 all

  for my $item ($iter->all) {
	  print "Item: $item\n";
  }

Returns a list or array reference of all of the items to be returned by the
iterator. If C<next()> has been called prior to the call to C<all()>, then
only the remaining items in the iterator will be returned. Use this method
with caution, as it could cause a large number of items to be loaded into
memory at once.

=head3 do

  $iter->do( sub { print "$_[0]\n"; return $_[0]; } );
  $iter->do( sub { print "$_\n"; return $_; } );

Pass a code reference to this method to execute it for each item in the
iterator. Each item will be set to C<$_> before executing the code reference,
and will also be passed as the sole argument to the code reference. If
C<next()> has been called prior to the call to C<do()>, then only the
remaining items in the iterator will passed to the code reference. Iteration
terminates when the code reference returns false, so be sure to have it return
a true value if you want it to iterate over every item.

=head1 Author

David Wheeler <wheeler@searchme.com>

=head1 Copyright and License

Copyright (c) 2004-2008 Kineticode, Inc. <info@kineticode.com>.

This work was based on
L<Object::Relation::Iterator|Object::Relation::Iterator> module developed by
Kineticode, Inc. As such, it is is free software; it can be redistributed it
and/or modified it under the same terms as Perl itself.

=cut

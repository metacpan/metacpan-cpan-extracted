package Set::Light;
use Array::RefElem qw/hv_store/;
use strict;
require 5.006;

our $VERSION = '0.04';

# shared undef variable
my $UNDEF = undef;

BEGIN
  {
  # handy aliases
  *has = \&exists;
  *contains = \&exists;
  *is_null = \&is_empty;
  *remove = \&delete;
  }

#############################################################################
# creation

sub new 
  {
  my $class = shift; my $x = bless { }, $class;

  my $opt;
  $opt = shift if ref($_[0]) eq 'HASH';
 
  $x->insert(@_) if @_ != 0;

  $x;
  }

#############################################################################
# inserting

sub insert
  {
  my ($x) = shift;
 
  my $inserted = 0;
  for (@_)
    {
    $inserted++, hv_store(%$x, $_, $UNDEF) if ! exists $x->{$_};
    }
  $inserted;
  }

#############################################################################
# size/empty

sub is_empty
  {
  my ($x) = @_;

  scalar keys %$x == 0;
  }

sub size
  {
  my ($x) = @_;

  scalar keys %$x;
  }

#############################################################################
# test for existance

sub exists
  {
  my ($x,$key) = @_;

  exists $x->{$key};
  }

#############################################################################
# deletion

sub delete
  {
  my ($x) = shift;

  my $deleted = 0;
  for (@_)
    {
    $deleted++, delete $x->{$_} if exists $x->{$_};
    };
  $deleted;
  }

1;
__END__

=pod

=head1 NAME

Set::Light - (memory efficient) unordered set of strings

=head1 SYNOPSIS

	use Set::Light;

	my $set = Set::Light->new( qw/foo bar baz/ );

	if (!$set->is_empty())
	  {
	  print "Set has ", $set->size(), " elements.\n";
	  for (qw/umpf foo bar baz bam/)
	    {
	    print "Set does ";
	    print " not " unless $set->has($_);
	    print "contain '$_'.\n";
            }
	  }

=head1 DESCRIPTION

Set::Light implements an unordered set of strings. Set::Light currently
uses underneath a hash, and each key of the hash points to the same
scalar, thus saving memory per item.

=head2 Why not use a hash?

Usually you would use a hash to keep track of a list of items like:

	my %SEEN;
	...
	if (!$SEEN->{$item}++)
	  {
	  # haven't seen item before
	  }

While this is very fast (both on inserting items, as well as looking them up),
it wastes quite a lot of memory, since each key in %SEEN needs one scalar.

=head2 Why not use Set::Object or Set::Scalar?

These waste even more memory and/or are slower than an ordinary hash.

=head1 METHODS

=head2 new()

	my $set = Set::Light->new();

Creates a new Set::Light object. An optionally passed hash reference can
contain options. Currently no options are supported:

	my $set = Set::Light->new( { myoption => 1, foobar => 2 });

Note that:

	my $set = Set::Light->new( qw/for bar baz/);

will create a set with the members C<for>, C<bar> and C<baz>.

=head2 size()

	my $elems = $set->size();

Returns the number of elements in the set.

=head2 is_empty()

	if (!$set->is_empty()) { ... }

Returns true if the set is empty (has zero elements).

=head2 is_null()

C<is_null()> is an alias to L<is_empty()>.

=head2 has()/contains()/exists/()

	if ($set->has($member)) { ... }

Returns true if the set contains the string C<$member>.

C<contains()> and C<exists()> are aliases to L<has()>.

=head2 insert()

	$set->insert( $string );
	$set->insert( @strings );

Inserts one or more strings into the set. Returns the number of insertions
it really did. Elements that are already contained in the set do not
get inserted twice. So:

	use Set::Light;
	my $set = Set::Light->new();
	print $set->insert('foo');		# 1
	print $set->insert('foo');		# 0
	print $set->insert('bar','baz','foo');	# 2	(foo already inserted)

=head2 delete()/remove()

	$set->delete( $string );
	$set->delete( @strings );

Deletes one or more strings from the set. Returns the number of deletions
it really did. Elements that are not contained in the set cannot be deleted.
So:

	use Set::Light;
	my $set = Set::Light->new();
	print $set->insert('foo','bar');	# 2
	print $set->delete('foo','foo');	# 1 	(only once deleted)
	print $set->delete('bar','foo');	# 1 	(only once deleted)

C<remove()> is an alias for C<delete()>.

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

(c) Tels bloodgate.com 2004 - 2008.

=head1 SEE ALSO

L<Set::Object>, L<Set::Scalar>.

=cut

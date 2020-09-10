package Set::Light;

# ABSTRACT: (memory efficient) unordered set of strings

require 5.006;

use strict;
use warnings;

use Array::RefElem ();

our $VERSION = '0.94';


# shared undef variable
my $UNDEF = undef;

BEGIN {
    # handy aliases
    *has      = \&exists;
    *contains = \&exists;
    *is_null  = \&is_empty;
    *remove   = \&delete;
}


sub new {
    my $class = shift;
    my $x     = bless {}, $class;

    my $opt;
    $opt = shift if ref( $_[0] ) eq 'HASH';

    $x->insert(@_) if @_ != 0;

    $x;
}


sub insert {
    my $x = shift;

    # Note: this trick may no longer be necessesary for modern perls,
    # when storing an undef value.

    my $inserted = 0;
    for (@_) {
        $inserted++, Array::RefElem::hv_store( %$x, $_, $UNDEF )
          unless CORE::exists $x->{$_};
    }
    $inserted;
}


sub is_empty {
    my ($x) = @_;

    scalar keys %$x == 0;
}


sub size {
    my ($x) = @_;

    scalar keys %$x;
}


sub exists {
    my ( $x, $key ) = @_;

    CORE::exists $x->{$key};
}


sub delete {
    my $x = shift;

    my $deleted = 0;
    for (@_) {
        $deleted++, delete $x->{$_} if CORE::exists $x->{$_};
    }
    $deleted;
}


sub members {
    my ($x) = @_;
    return keys %$x;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Set::Light - (memory efficient) unordered set of strings

=head1 VERSION

version 0.94

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

Set::Light implements an unordered set of strings. Set::Light
currently uses a hash underneath, and each key of the hash points to
the same scalar, thus saving memory per item.

=head2 Why not use a hash?

Usually you would use a hash to keep track of a list of items like:

  my %SEEN;

  ...

  if (!$SEEN->{$item}++)
  {
    # haven't seen item before
  }

While this is very fast (both on inserting items, as well as looking them up),
it uses quite a lot of memory, since each key in C<%SEEN> needs one scalar.

=head2 Why not use Set::Object or Set::Scalar?

These use even more memory and/or are slower than an ordinary hash.

=head1 METHODS

=head2 new

  my $set = Set::Light->new( \%opts, @members );

Creates a new Set::Light object. An optionally passed hash reference can
contain options.

Any members passed to the constructor will be inserted.

Currently no options are supported.

=head2 insert

  $set->insert( $string );
  $set->insert( @strings );

Inserts one or more strings into the set. Returns the number of insertions
it really did. Elements that are already contained in the set do not
get inserted twice. So:

  use Set::Light;

  my $set = Set::Light->new();
  print $set->insert('foo');              # 1
  print $set->insert('foo');              # 0
  print $set->insert('bar','baz','foo');  # 2     (foo already inserted)

=head2 is_empty

  if (!$set->is_empty()) { ... }

Returns true if the set is empty (has zero elements).

=head2 is_null

This is an alias to L</is_empty>.

=head2 size

  my $elems = $set->size();

Returns the number of elements in the set.

=head2 has

  if ($set->has($member)) { ... }

Returns true if the set contains the string C<$member>.

=head2 contains

This is an alias for L</has>.

=head2 exists

This is an alias for L</has>.

=head2 delete

  $set->delete( $string );
  $set->delete( @strings );

Deletes one or more strings from the set. Returns the number of
deletions it really did. Elements that are not contained in the set
cannot be deleted.  So:

  use Set::Light;

  my $set = Set::Light->new();
  print $set->insert('foo','bar');	# 2
  print $set->delete('foo','foo');	# 1 	(only once deleted)
  pprint $set->delete('bar','foo');	# 1 	(only once deleted)

=head2 remove

This is an alias for L</delete>.

=head2 members

  my @members = $set->members;

This returns an array of set members in an unsorted array.

This was added in v0.91.

=head1 SEE ALSO

L<Set::Object>, L<Set::Scalar>.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Set-Light>
and may be cloned from L<git://github.com/robrwo/Set-Light.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Set-Light> or by email
to L<bug-Set-Light@rt.cpan.org|mailto:bug-Set-Light@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Tels <nospam-abuse@bloodgate.com>

=head1 CONTRIBUTOR

=for stopwords Robert Rothenberg

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004-2008, 2019-2020 by Tels.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

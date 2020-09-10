# NAME

Set::Light - (memory efficient) unordered set of strings

# VERSION

version 0.94

# SYNOPSIS

```perl
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
```

# DESCRIPTION

Set::Light implements an unordered set of strings. Set::Light
currently uses a hash underneath, and each key of the hash points to
the same scalar, thus saving memory per item.

## Why not use a hash?

Usually you would use a hash to keep track of a list of items like:

```perl
my %SEEN;

...

if (!$SEEN->{$item}++)
{
  # haven't seen item before
}
```

While this is very fast (both on inserting items, as well as looking them up),
it uses quite a lot of memory, since each key in `%SEEN` needs one scalar.

## Why not use Set::Object or Set::Scalar?

These use even more memory and/or are slower than an ordinary hash.

# METHODS

## new

```perl
my $set = Set::Light->new( \%opts, @members );
```

Creates a new Set::Light object. An optionally passed hash reference can
contain options.

Any members passed to the constructor will be inserted.

Currently no options are supported.

## insert

```
$set->insert( $string );
$set->insert( @strings );
```

Inserts one or more strings into the set. Returns the number of insertions
it really did. Elements that are already contained in the set do not
get inserted twice. So:

```perl
use Set::Light;

my $set = Set::Light->new();
print $set->insert('foo');              # 1
print $set->insert('foo');              # 0
print $set->insert('bar','baz','foo');  # 2     (foo already inserted)
```

## is\_empty

```
if (!$set->is_empty()) { ... }
```

Returns true if the set is empty (has zero elements).

## is\_null

This is an alias to ["is\_empty"](#is_empty).

## size

```perl
my $elems = $set->size();
```

Returns the number of elements in the set.

## has

```
if ($set->has($member)) { ... }
```

Returns true if the set contains the string `$member`.

## contains

This is an alias for ["has"](#has).

## exists

This is an alias for ["has"](#has).

## delete

```
$set->delete( $string );
$set->delete( @strings );
```

Deletes one or more strings from the set. Returns the number of
deletions it really did. Elements that are not contained in the set
cannot be deleted.  So:

```perl
use Set::Light;

my $set = Set::Light->new();
print $set->insert('foo','bar');      # 2
print $set->delete('foo','foo');      # 1     (only once deleted)
pprint $set->delete('bar','foo');     # 1     (only once deleted)
```

## remove

This is an alias for ["delete"](#delete).

## members

```perl
my @members = $set->members;
```

This returns an array of set members in an unsorted array.

This was added in v0.91.

# SEE ALSO

[Set::Object](https://metacpan.org/pod/Set::Object), [Set::Scalar](https://metacpan.org/pod/Set::Scalar).

# SOURCE

The development version is on github at [https://github.com/robrwo/Set-Light](https://github.com/robrwo/Set-Light)
and may be cloned from [git://github.com/robrwo/Set-Light.git](git://github.com/robrwo/Set-Light.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://rt.cpan.org/Public/Dist/Display.html?Name=Set-Light](https://rt.cpan.org/Public/Dist/Display.html?Name=Set-Light) or by email
to [bug-Set-Light@rt.cpan.org](mailto:bug-Set-Light@rt.cpan.org).

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Tels <nospam-abuse@bloodgate.com>

# CONTRIBUTOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2004-2008, 2019-2020 by Tels.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

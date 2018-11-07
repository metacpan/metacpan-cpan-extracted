# NAME

SemanticWeb::Schema - Moo classes for http://schema.org/ classes

# VERSION

version v0.0.4

# SYNOPSIS

```perl
use aliased 'SemanticWeb::Schema::Person' => 'Person';

my $person = Person->new(
  name        => 'James Clerk Maxwell',
  birth_date  => '1831-06-13',
  birth_place => 'Edinburgh',
);

print $person->json_ld;
```

# DESCRIPTION

This is a base class for the `SemanticWeb::Schema` classes, which
were generated automatically from the following sources:

- [http://schema.org/version/3.4/ext-meta.rdf](http://schema.org/version/3.4/ext-meta.rdf)
- [http://schema.org/version/3.4/schema.rdf](http://schema.org/version/3.4/schema.rdf)

# ATTRIBUTES

## `id`

If this is set, it adds a `@id` to the ["json\_ld\_data"](#json_ld_data).

## `context`

The context defaults to "http://schema.org/".

# SEE ALSO

- [Moo](https://metacpan.org/pod/Moo)
- [MooX::JSON\_LD](https://metacpan.org/pod/MooX::JSON_LD)
- [http://schema.org/](http://schema.org/)

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

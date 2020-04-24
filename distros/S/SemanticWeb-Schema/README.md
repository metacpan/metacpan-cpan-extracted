# NAME

SemanticWeb::Schema - Moo classes for http://schema.org/ classes

# VERSION

version v7.0.4

The version number of this distribution is based on the corresponding
version of schema classes.

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

This distribution contains Perl classes for [https://schema.org](https://schema.org)
semantic markup. These can be used to generate JSON-LD
to embed in websites.

This is a base class for the `SemanticWeb::Schema` classes, which
were generated automatically from the following sources:

- [https://schema.org/version/7.04/ext-auto.rdf](https://schema.org/version/7.04/ext-auto.rdf)
- [https://schema.org/version/7.04/ext-bib.rdf](https://schema.org/version/7.04/ext-bib.rdf)
- [https://schema.org/version/7.04/ext-health-lifesci.rdf](https://schema.org/version/7.04/ext-health-lifesci.rdf)
- [https://schema.org/version/7.04/ext-meta.rdf](https://schema.org/version/7.04/ext-meta.rdf)
- [https://schema.org/version/7.04/ext-pending.rdf](https://schema.org/version/7.04/ext-pending.rdf)
- [https://schema.org/version/7.04/schema.rdf](https://schema.org/version/7.04/schema.rdf)

# ATTRIBUTES

## `id`

If this is set, it adds a `@id` to the ["json\_ld\_data"](#json_ld_data).

## `context`

The context defaults to "http://schema.org/".

# SEE ALSO

- [Moo](https://metacpan.org/pod/Moo)
- [MooX::JSON\_LD](https://metacpan.org/pod/MooX::JSON_LD)
- [http://schema.org/](http://schema.org/)

# SOURCE

The development version is on github at [https://github.com/robrwo/SemanticWeb-Schema](https://github.com/robrwo/SemanticWeb-Schema)
and may be cloned from [git://github.com/robrwo/SemanticWeb-Schema.git](git://github.com/robrwo/SemanticWeb-Schema.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/SemanticWeb-Schema/issues](https://github.com/robrwo/SemanticWeb-Schema/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# CONTRIBUTORS

- Arikawa Takaya <tky.c10.ver@gmail.com>
- Mohammad S Anwar <mohammad.anwar@yahoo.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# NAME

Stencil - Code Generation

# ABSTRACT

Code Generation Tool for Perl 5

# SYNOPSIS

    use Stencil;
    use Stencil::Repo;
    use Stencil::Space;
    use Stencil::Data;

    my $repo = Stencil::Repo->new;
    my $space = Stencil::Space->new(name => 'gen', repo => $repo);
    my $spec = Stencil::Data->new(name => 'foo', repo => $repo);
    my $stencil = Stencil->new(repo  => $repo, space => $space, spec  => $spec);

    # $stencil->init;
    # $stencil->seed;
    # $stencil->make;

# DESCRIPTION

This package provides a framework for generating source code, and methods for
rapidly generating one or more files from a single, human readable
specification. See the [stencil](https://metacpan.org/pod/stencil) command-line tool for additional usage
details.

# LIBRARIES

This package uses type constraints from:

[Types::Standard](https://metacpan.org/pod/Types::Standard)

# ATTRIBUTES

This package has the following attributes:

## repo

    repo(Object)

This attribute is read-only, accepts `(Object)` values, and is required.

## space

    space(Maybe[Object])

This attribute is read-only, accepts `(Maybe[Object])` values, and is required.

## spec

    spec(Maybe[Object])

This attribute is read-only, accepts `(Maybe[Object])` values, and is required.

# METHODS

This package implements the following methods:

## init

    init() : Object

The init method initialize the stencil store and logs.

- init example #1

        # given: synopsis

        $stencil->init;

## make

    make() : ArrayRef[Object]

The make method generate source code from the generator specification (yaml) file.

- make example #1

        # given: synopsis

        $stencil->seed;
        $stencil->make;

## seed

    seed() : Object

The seed method creates the generator specification (yaml) file.

- seed example #1

        # given: synopsis

        $stencil->seed;

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/stencil/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/stencil/wiki)

[Project](https://github.com/iamalnewkirk/stencil)

[Initiatives](https://github.com/iamalnewkirk/stencil/projects)

[Milestones](https://github.com/iamalnewkirk/stencil/milestones)

[Contributing](https://github.com/iamalnewkirk/stencil/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/stencil/issues)

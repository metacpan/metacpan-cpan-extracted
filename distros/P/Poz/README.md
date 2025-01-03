[![Actions Status](https://github.com/ytnobody/p5-Poz/actions/workflows/test.yml/badge.svg)](https://github.com/ytnobody/p5-Poz/actions)
# NAME

Poz - A simple, composable, and extensible data validation library for Perl.

# SYNOPSIS

    use Poz qw/z/;
    use Data::UUID;
    use Time::Piece;
    my $bookSchema = z->object({
        id         => z->string->uuid->default(sub { Data::UUID->new->create_str }),   
        title      => z->string,
        author     => z->string->default("Anonymous"),
        published  => z->date,
        created_at => z->date->default(sub { Time::Piece::localtime()->strftime('%Y-%m-%d') }),
        updated_at => z->date->default(sub { Time::Piece::localtime()->strftime('%Y-%m-%d') }),
    })->as("My::Book");

    my $book = $bookSchema->parse({
        title     => "Spidering Hacks",
        author    => "Kevin Hemenway",
        published => "2003-10-01",
    }) or die "Invalid book data";
    $book->isa("My::Book"); # true

    my ($otherBook, $err) = $bookSchema->safe_parse({
        title => "Eric Sink on the Business of Software",
        author => "Eric Sink",
        published => "2006-0i-01",
    });
    $otherBook; # undef
    $err; # [{key => "", error => "Not a date"}]

    my $bookOrNumberSchema = z->union($bookSchema, z->number);
    my $bookOrNumber = $bookOrNumberSchema->parse(123);
    $bookOrNumber = $bookOrNumberSchema->parse({
        title => "Perl Best Practices",
        date => "2005-07-01",
        author => "Damian Conway",
    }); 

    my $bookArraySchema = z->array($z->is("My::Book"));
    my $book1 = $bookSchema->parse({title => "Perl Best Practices", author => "Damian Conway", published => "2005-07-01"});
    my $book2 = $bookSchema->parse({title => "Spidering Hacks", author => "Kevin Hemenway", published => "2003-10-01"});
    my $bookArray = $bookArraySchema->parse([$book1, $book2]);
    
    

# DESCRIPTION

Poz is a simple, composable, and extensible data validation library for Perl. It is inspired heavily from Zod [https://zod.dev/](https://zod.dev/) in TypeScript.

# EXPORTS

## z

    use Poz qw/z/;
    my $builder = z;

Returns a new instance of Poz::Builder.

# METHODS

## z->object($schema)

    my $schema = z->object({
        id         => z->string->uuid->default(sub { Data::UUID->new->create_str }),   
        title      => z->string,
        author     => z->string->default("Anonymous"),
        published  => z->date,
        created_at => z->date->default(sub { Time::Piece::localtime()->strftime('%Y-%m-%d') }),
        updated_at => z->date->default(sub { Time::Piece::localtime()->strftime('%Y-%m-%d') }),
    })->as("My::Book");

Creates a new schema object.

## z->string

    my $schema = z->string;

Creates a new string schema object.

## z->number

    my $schema = z->number;

Creates a new number schema object.

## z->date

    my $schema = z->date;

Creates a new date schema object.

## z->object

    my $schema = z->object($schema);

Creates a new object schema object.

## z->array

    my $schema = z->array($schema);

Creates a new array schema object.

## z->enum

    my $schema = z->enum(@values);

Creates a new enum schema object.

## z->union

    my $schema = z->union(@schemas);

Creates a new union schema object.

# SEE ALSO

- [Zod](https://zod.dev/)
- [Poz::Builder](https://metacpan.org/pod/Poz%3A%3ABuilder)
- [Poz::Types](https://metacpan.org/pod/Poz%3A%3ATypes)
- [Poz::Types::null](https://metacpan.org/pod/Poz%3A%3ATypes%3A%3Anull)
- [Poz::Types::string](https://metacpan.org/pod/Poz%3A%3ATypes%3A%3Astring)
- [Poz::Types::number](https://metacpan.org/pod/Poz%3A%3ATypes%3A%3Anumber)
- [Poz::Types::object](https://metacpan.org/pod/Poz%3A%3ATypes%3A%3Aobject)
- [Poz::Types::array](https://metacpan.org/pod/Poz%3A%3ATypes%3A%3Aarray)
- [Poz::Types::enum](https://metacpan.org/pod/Poz%3A%3ATypes%3A%3Aenum)
- [Poz::Types::union](https://metacpan.org/pod/Poz%3A%3ATypes%3A%3Aunion)
- [Poz::Types::is](https://metacpan.org/pod/Poz%3A%3ATypes%3A%3Ais)

# HOW TO CONTRIBUTE

If you want to contribute to Poz, you can follow the steps below:

- 1. Prepare: Install cpanm and Minilla

        $ curl -L https://cpanmin.us | perl - --sudo App::cpanminus
        $ cpanm Minilla

- 2. Fork: Please fork the repository on GitHub.

    The Repository on GitHub: [https://github.com/ytnobody/p5-Poz](https://github.com/ytnobody/p5-Poz)

- 3. Clone: Clone the repository.

        $ git clone

- 4. Branch: Create a feature branch from the main branch.

        $ git checkout -b feature-branch main

- 5. Code: Write your code and tests, then build.

        $ minil build

- 6. Test: Run the tests.

        $ minil test

- 7. Commit: Commit your changes.

        $ git commit -am "Add some feature"

- 8. Push: Push to your branch.

        $ git push origin feature-branch

- 9. Pull Request: Create a new Pull Request on GitHub.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>

# Search::MultiMatch

[Search::MultiMatch](https://metacpan.org/release/Search-MultiMatch) works by creating a multidimensional hash-table with keys as 2D-arrays, which are stored as nodes.

It accepts matching the stored entries with a pattern, that is also a 2D-array, identifying matches by walking the table from node to node.

```perl
    use Search::MultiMatch;

    # Create a SMM object
    my $smm = Search::MultiMatch->new();

    # Add an entry
    $smm->add($key, $value);                # key is a 2D-array

    # Search with a pattern
    my @matches = $smm->search($pattern);   # pattern is a 2D-array
```

This example illustrates how to add some key/value pairs to the table and how to search the table with a given pattern at a later time:

```perl
    use Search::MultiMatch;
    use Data::Dump qw(pp);

    # Creates a SMM object
    my $smm = Search::MultiMatch->new();

    # Create a 2D-array key, by splitting the string
    # into words, then each word into characters.
    sub make_key {
        [map { [split //] } split(' ', lc($_[0]))];
    }

    my @movies = (
                  'My First Lover',
                  'A Lot Like Love',
                  'Funny Games (2007)',
                  'Cinderella Man (2005)',
                  'Pulp Fiction (1994)',
                  'Don\'t Say a Word (2001)',
                  'Secret Window (2004)',
                  'The Lookout (2007)',
                  '88 Minutes (2007)',
                  'The Mothman Prophecies',
                  'Love Actually (2003)',
                  'From Paris with Love (2010)',
                  'P.S. I Love You (2007)',
                 );

    # Add the entries
    foreach my $movie (@movies) {
        $smm->add(make_key($movie), $movie);
    }

    my $pattern = make_key('i love');        # make the search-pattern
    my @matches = $smm->search($pattern);    # search by the pattern

    pp \@matches;                            # dump the results
```

The results are:

```perl
    [
     {match => "P.S. I Love You (2007)",      score => 2},
     {match => "My First Lover",              score => 1},
     {match => "A Lot Like Love",             score => 1},
     {match => "Love Actually (2003)",        score => 1},
     {match => "From Paris with Love (2010)", score => 1},
    ]
```

## INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Search::MultiMatch

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-MultiMatch

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Search-MultiMatch

    CPAN Ratings
        http://cpanratings.perl.org/d/Search-MultiMatch

    Search CPAN
        http://search.cpan.org/dist/Search-MultiMatch/


## LICENSE AND COPYRIGHT

Copyright (C) 2016 Daniel Șuteu

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

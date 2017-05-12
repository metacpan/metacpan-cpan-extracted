# Search::ByPrefix

[Search::ByPrefix](https://metacpan.org/release/Search-ByPrefix) works by creating an internal table from a list of key/value pairs, where each key is an array.

Then, this table can be efficiently searched with an array prefix-key, which finds and returns all the values that have this certain prefix.

```perl
    use Search::ByPrefix;
    my $sbp = Search::ByPrefix->new;

    # Add an entry
    $sbp->add($key, $value);                 # where $key is an array

    # Search by a prefix
    my @matches = $sbp->search($prefix);     # where $prefix is an array
```

This example illustrates how to add some key/value pairs to the table and how to search the table with a given prefix:

```perl
    use 5.010;
    use Search::ByPrefix;
    my $obj = Search::ByPrefix->new;

    sub make_key {
        [split('/', $_[0])]
    }

    foreach my $dir (
                     qw(
                     /home/user1/tmp/coverage/test
                     /home/user1/tmp/covert/operator
                     /home/user1/tmp/coven/members
                     /home/user2/tmp/coven/members
                     /home/user1/tmp2/coven/members
                     )
      ) {
        $obj->add(make_key($dir), $dir);
    }

    # Finds the directories that have this common path
    say for $obj->search(make_key('/home/user1/tmp'));
```

The results are:

```perl
    "/home/user1/tmp/coverage/test"
    "/home/user1/tmp/covert/operator"
    "/home/user1/tmp/coven/members"
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

    perldoc Search::ByPrefix

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-ByPrefix

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Search-ByPrefix

    CPAN Ratings
        http://cpanratings.perl.org/d/Search-ByPrefix

    Search CPAN
        http://search.cpan.org/dist/Search-ByPrefix/


## LICENSE AND COPYRIGHT

Copyright (C) 2016-2017 Daniel Șuteu

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

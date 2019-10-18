## Proc-Forkmap

This module provides mapping with built-in forking.

EXAMPLE:

```perl
  use Proc::Forkmap qw(forkmap);

  $Proc::Forkmap::MAX_PROC = 4;

  sub foo {
    my $n = shift;
    sleep($n);
    print "slept for $n seconds\n";
  }

  my @x = (1, 2, 3);

  forkmap { foo($_) } @x;

  # Or OO interface, if you like that sort of thing

  use Proc::Forkmap;

  sub foo {
    my $x = shift;
    my $t = sprintf("%1.0f", $x + 1);
    sleep $t;
    print "slept $t seconds\n";
  }

  my @x = (rand(), rand(), rand());
  my $p = Proc::Forkmap->new(max_kids => 4);
  $p->fmap(\&foo, @x);
```

RESULTS:

```bash
  $ time perl t/test.pl
  slept 1 seconds
  slept 2 seconds
  slept 2 seconds

  real  0m2.053s
  user  0m0.055s
  sys 0m0.005s
```

INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Proc::Forkmap

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Proc-Forkmap

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Proc-Forkmap

    CPAN Ratings
        http://cpanratings.perl.org/d/Proc-Forkmap

    Search CPAN
        http://search.cpan.org/dist/Proc-Forkmap/


LICENSE AND COPYRIGHT

Copyright (C) 2019 Andrew Shapiro

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


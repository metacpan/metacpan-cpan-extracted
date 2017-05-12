==============================================================================
                Version 1.9 of Randomize
==============================================================================

NAME

  Randomize - Perl extension for randomizing things.

SYNOPSIS

  use Randomize;
  my $randomizer = Randomize->new(\@rules);
  print "There are ", $randomizer->permutations(),
        " different possible outcomes.\n";
  while (1) {
    my $random_hash = $randomizer->generate();
  }

DESCRIPTION

  This packages takes a set of randomization rules in the form of an 
  array reference, and creates random hashes on request based on 
  the rules given.

  I know that doesn't make sense, so here's an example.

    my @randomizer_rules =
      [ {Field  => 'Street',
         Values => [{Data   => ['Preston', 'Hillcrest'],
                     Weight => 1},
                    {Data   => ['Coit'],
                     Weight => 2}]},
        {Field  => 'Number', 
         Values => [18100..18299]}
      };

    my $randomizer = Randomize->new(\@randomizer_rules);
    while (1)
      my $hashref = $randomizer->generate();
    }


  Each time through the loop, $hashref contains a reference to a hash.
  That hash contains two fields, "Street", and "Number".  "Street" will
  be "Coit" about half the time, and evenly split between "Preston" and
  "Hillcrest" the rest of the time.  "Number" is a number from 18100 to 
  18299.


INSTALLATION

  perl Makefile.PL
  make
  make test
  make install

  Note that during "make test", I try to verify that Randomize is,
  indeed, generating random hashes.  Occasionally, the results for a
  given "make test" may be a little skewed because of the vagaries of
  random number generation.  So, if one of those test cases fails, just
  re-run "make test" and see if it happens again.


AUTHOR

    Brand Hilton <bhilton@pobox.com>


COPYRIGHT

       Copyright (c) 2001, Brand Hilton. All Rights Reserved.
     This module is free software. It may be used, redistributed
         and/or modified under the same terms as Perl itself.


==============================================================================

CHANGES FROM VERSION 1.7 TO VERSION 1.9

  Added permutations() method

  Fixed a bug that would cause problems if you used both
  varieties of Retry_If at the same time

  Documentation updates


==============================================================================

AVAILABILITY

  Randomize is available on CPAN.

==============================================================================

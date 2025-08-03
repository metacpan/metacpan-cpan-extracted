# helper command oodist

From release 0.96, the OODoc module contains a script named 'oodist',
which simplifies the creation of pod and HTML enormously.  You do not
need to create mkdoc and mkdist scripts anymore: simply add a few lines
to your Makefile.PL is sufficient.

## Examples:

examples/markov.pm
   The simpelist set-up of a manual-page.  But... you can copy the
   structure from any module published by Markov.

There are a few examples for the html templates.  Before, they were
included inside this distribution, but now you can get them on
github.

  * Relatively small: https://github.com/markov2/perl5-OODoc/tree/master/html
  * A bit larger set-up: https://github.com/markov2/perl5-Log-Report/tree/master/html
  * Huge collection: https://github.com/markov2/perl5-Mail-Box/tree/master/html

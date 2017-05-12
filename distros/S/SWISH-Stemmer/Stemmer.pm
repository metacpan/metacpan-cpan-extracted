package SWISH::Stemmer;
use strict;

require Exporter;
require DynaLoader;

use vars qw/@ISA @EXPORT $VERSION/;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw( SwishStem );

$VERSION = '0.03';

bootstrap SWISH::Stemmer $VERSION;


1;
__END__

=head1 NAME

Stemmer - Perl extension for stemming words using a modified version of the 
Stem routine from the SWISH search engine.  (http://sunsite.berkeley.edu/SWISH-E/)


=head1 SYNOPSIS

  use SWISH::Stemmer;
  $stemmed_word = SwishStem( $word );

=head1 DESCRIPTION

This module provides access to the Stem() function used in SWISH-E to stem words.
This module is needed if you wish to highlight words in source documents.

Not that this module includes the stemmer.c function from the SWISH-E distribution.  You should make
sure that the stemmer.c file contained here is closely matched to the stemmer.c module in the
SWISH-E distribution.

Also, there is a SWISH-E library that will contain the Stem() and SwishStem() functions.  So
you may be able to access that library instead of using this module.  Check the SWISH-E
discussion list for more info.


   Purpose:    Implementation of the Porter stemming algorithm documented 
               in: Porter, M.F., "An Algorithm For Suffix Stripping," 
               Program 14 (3), July 1980, pp. 130-137.

   Provenance: Written by B. Frakes and C. Cox, 1986.
               Changed by C. Fox, 1990.
                  - made measure function a DFA
                  - restructured structs
                  - renamed functions and variables
                  - restricted function and variable scopes
               Changed by C. Fox, July, 1991.
                  - added ANSI C declarations 
                  - branch tested to 90% coverage

   Notes:      This code will make little sense without the the Porter
               article.  The stemming function converts its input to
               lower case.




=head1 AUTHOR

Bill Moseley used the stemmer.c from the Swish-e distribution for this module.

=head1 SEE ALSO

perl(1)

=cut

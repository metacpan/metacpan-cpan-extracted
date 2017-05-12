#! /usr/bin/perl -w
=head1

=cut


use lib 'example/lib';  # boring 
use strict;             # boring 
use warnings;           # boring 

print <<EOF;
this script is an example of how to use Somelib
It is unlikely to be useful to you, but shows you many of the more
sneaky features abailable to users of this software.

Please select from the list below to see more details:

 1. API documentation
 2. HACKING guide
 3. README (for latest version)
 4. Changes (major releases only)
 5. exit

 [SomeLib examples] 5

EOF



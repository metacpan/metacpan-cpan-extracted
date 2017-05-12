#! /opt/local/bin/perl5.10.0
use 5.010;
use warnings;

use Perl6::Form;


print form {interleave=>1,,single=>'^'},{single=>'='},{single=>'_'},
		   <<'.',
~~~~~~~~~
^ = ^ _ ^ {|||}
~~~~~~~~~
.
			qw(China's first taikonaut lands safely okay!);

print "\n--------------------------\n\n";

print form {single=>'='}, {interleave=>1}, <<'.',
   ^
 = | {""""""""""""""""""""""""""""""""""""}
   +--------------------------------------->
    {|||||||||||||||||||||||||||||||||||}
.
 "Height", [<DATA>], "Time";


print form <<'.',
Passed:
	{[[[[[[[[[[[[[[[[[[[}
Failed:
	{[[[[[[[[[[[[[[[[[[[}
.
[qw(Smith Simmons Sutton Smee)], [qw(Richards Royce Raighley)];


print form {interleave=>1}, <<'.',
Passed:
	{[[[[[[[[[[[[[[[[[[[}
Failed:
	{[[[[[[[[[[[[[[[[[[[}
.
[qw(Smith Simmons Sutton Smee)], [qw(Richards Royce Raighley)];

__DATA__
      *
    *   *
   *     *
          
  *       *
           
 *         *
          
         
        
*           *


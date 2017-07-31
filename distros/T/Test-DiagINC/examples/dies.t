use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC';
use ExtUtils::MakeMaker;
use lib 'examples/lib';
use Foo;
eval { require SyntaxErr };

chdir ".." or die "$!"; # try to mess up relative entry in %INC

die("this fails\n");

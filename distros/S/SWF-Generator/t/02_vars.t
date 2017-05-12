use strict;
use Test::More;

use Path::Class;
use SWF::Generator;

my $swfgen = SWF::Generator->new();

my $swf = $swfgen->process('t/test2.xml', { initialText => 'TESTTESTTEST' });

my $swf_pref = file('t/test2.swf')->slurp;

is $swf, $swf_pref;

done_testing;

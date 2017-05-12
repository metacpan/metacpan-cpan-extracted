use strict;
use Test::More;

use Path::Class;
use SWF::Generator;

my $swfgen = SWF::Generator->new(tt_option => {INCLUDE_PATH => ['t']});

my $swf = $swfgen->process('test.xml');

my $swf_pref = file('t/test.swf')->slurp;

is $swf, $swf_pref;

done_testing;

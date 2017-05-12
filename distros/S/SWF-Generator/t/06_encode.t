use strict;
use utf8;
use Test::More;

use Path::Class;
use SWF::Generator;

my $swfgen = SWF::Generator->new(swfmill_option => [qw(-e cp932)], tt_option => {ENCODING => 'utf-8'});

my $swf = $swfgen->process('t/test3.xml');

my $swf_pref = file('t/test3.swf')->slurp;

is $swf, $swf_pref;

done_testing;

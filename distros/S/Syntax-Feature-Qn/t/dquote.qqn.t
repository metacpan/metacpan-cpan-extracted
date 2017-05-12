use Test::More;
use strict;
use warnings;
BEGIN { use_ok('syntax', 'qqn') }


my @a = qqn "
asdf
line with spaces
bleh
	line with leading tab
        line with leading spaces
mooo
line with trailing tab	
line with trailing spaces     
weee
now a line with trailing spaces    
   followed by a line with leading spaces
bzzz
";

ok($a[0] eq 'asdf', $a[0]);
ok($a[1] eq 'line with spaces', $a[1]);
ok($a[2] eq 'bleh', $a[2]);
ok($a[3] eq 'line with leading tab', $a[3]);
ok($a[4] eq 'line with leading spaces', $a[4]);
ok($a[5] eq 'mooo', $a[5]);
ok($a[6] eq 'line with trailing tab', $a[6]);
ok($a[7] eq 'line with trailing spaces', $a[7]);
ok($a[8] eq 'weee', $a[8]);
ok($a[9] eq 'now a line with trailing spaces', $a[9]);
ok($a[10] eq 'followed by a line with leading spaces', $a[10]);
ok($a[11] eq 'bzzz', $a[11]);

my @b = qqn "
	now lets try one indented
		indented more
			and even more
				with trailing tab	
				with trailing spaces   
			outdent
		with   multiple   spaces
	with	tabs	included
done
";

ok($b[0] eq 'now lets try one indented',$b[0]);
ok($b[1] eq 'indented more',$b[1]);
ok($b[2] eq 'and even more',$b[2]);
ok($b[3] eq 'with trailing tab',$b[3]);
ok($b[4] eq 'with trailing spaces',$b[4]);
ok($b[5] eq 'outdent',$b[5]);
ok($b[6] eq 'with   multiple   spaces',$b[6]);
ok($b[7] eq "with\ttabs\tincluded",$b[7]);
ok($b[8] eq 'done',$b[8]);

my $test = 'boo';
my @c = qqn "
	test one
		test	two
	$test three
	done
";

ok($c[0] eq 'test one',$c[0]);
ok($c[1] eq "test\ttwo",$c[1]);
ok($c[2] eq 'boo three',$c[2]);
ok($c[3] eq 'done',$c[3]);

$test = "line two\nline three";
my @d = qqn "
	one line, then
	$test
	and finally,
	the last
";

ok($d[0] eq 'one line, then',$d[0]);
ok($d[1] eq "line two\nline three",$d[1]);  #XXX split or interp first?
ok($d[2] eq 'and finally,',$d[2]);
ok($d[3] eq 'the last',$d[3]);

my $var = 'VAR';

is_deeply [ qqn"1 $var 3"   ], [ '1 VAR 3' ], 'single var';
is_deeply [ qqn "1 $var 3"  ], [ '1 VAR 3' ], 'wide single var';
is_deeply [ qqn  "1 $var 3" ], [ '1 VAR 3' ], 'wider single var';

done_testing;

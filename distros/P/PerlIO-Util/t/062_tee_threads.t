#!perl -w

use constant HAS_THREADS => eval{ require threads };

use strict;
use Test::More;

BEGIN{
	if($] < 5.010){
		my $version = sprintf '%vd', $^V;
		diag "Perl $version (<5.10.0) may leak scalars (probably it's a core problem).";
	}

	if(HAS_THREADS){
		plan tests => 20;
	}
	else{
		plan skip_all => 'no threads';
		exit;
	}
}

use FindBin qw($Bin);
use File::Spec;
use PerlIO::Util;

sub slurp{
	my $file = shift;
	open my $in, '<:raw', $file or die $!;
	local $/;
	return scalar <$in>;
}

my $file1 = File::Spec->join($Bin, 'util', 'thr1');
my $file2 = File::Spec->join($Bin, 'util', 'thr2');

ok open(my $tee, '>:tee', $file1, $file2), 'open:tee file1, file2';

#diag 'main ', $tee->inspect;

my $thr1 = threads->new(sub{
	#diag 'subthr', $tee->inspect;
	ok defined fileno($tee), 'opened (thr1)';
	ok print($tee 'foo'), 'print (thr1)';
	ok close($tee), 'close (thr1)';
});

$thr1->join();

ok print($tee 'bar'), 'print (main)';

ok close($tee), 'close (main)';

is slurp($file1), 'foobar', 'print to file1';
is slurp($file2), 'foobar', 'print to file2';

{
	open my $out2, '>', $file2;
	ok open($tee, '>:tee', $file1, $out2), 'open:tee file1, out2';
	my $thr2 = threads->new(sub{
		#diag 'subthr ', $tee->inspect;
		ok defined fileno($tee), 'opend (thr2)';
		ok print($tee 'FOO'), 'print (thr2)';
		ok close($tee), 'close (thr2)';
	});
	$thr2->join();

	ok print($tee 'BAR'), 'print (main)';
	ok close($tee), 'close (main)';

	ok print($out2 'BAZ'), 'print out2 (main)';

	ok close($out2), 'close out2 (main)';
}

is slurp($file1), 'FOOBAR', 'print to file1';
is slurp($file2), 'FOOBARBAZ', 'print to out2';


ok unlink($file1), "unlink $file1";
ok unlink($file2), "unlink $file2";



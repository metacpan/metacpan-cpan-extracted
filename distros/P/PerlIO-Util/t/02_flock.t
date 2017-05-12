#!perl
use strict;
use warnings;
use Test::More tests => 20;

use FindBin qw($Bin);
use File::Spec;

BEGIN{
	eval 'use Fcntl;1'
		or *O_RDONLY = sub(){ 0 }; # maybe
}

my $file = File::Spec->catfile($Bin, "util/lockfile");
   { open my $touch, '>', $file; print $touch "OK"; }
END{ unlink $file if $file and -e $file }

my $helper = File::Spec->catfile($Bin, "util/locktest.pl");

my $in;
ok open($in, "<:flock", $file), "open with :flock";
ok close($in), "close";

{
	local $@ = '';
	eval{
		open $in, "<:flock(blocking)", $file or die;
	};
	is $@, '', ":flock(blocking) - OK";

	eval{
		open $in, "<:flock(non-blocking)", $file or die;
	};
	is $@, '', ":flock(non-blocking) - OK";

	eval{
		open $in, "<:flock(foo)", $file or die;
	};
	isnt $@, '', ":flock(foo) - FATAL";

}

{
	no warnings 'io';
	select select my $unopened;
	
	ok !defined(binmode $unopened, ':flock'),     ":flock to unopened filehandle (binmode)";
	ok !eval{ $unopened->push_layer('flock');1 }, ":flock to unopened filehandle (push_layer)";
}
ok open($in, "<:flock", $file), "open(readonly) in this process";
ok system($^X, "-Mblib", $helper, "<:flock", $file),
	"open(readonly) in child process";

is scalar(<$in>), "OK", "readline";

isnt system($^X, "-Mblib", $helper, "+<:flock(non-blocking)", $file), 0,
	"open(rdwr) in child process -> failed";


open $in, "<", $file;

ok binmode($in, ":flock"), "binmode $in, ':flock'";
ok system($^X, "-Mblib", $helper, "<:flock", $file),
	"open(readonly) in child process";
isnt system($^X, "-Mblib", $helper, "+<:flock(non-blocking)", $file), 0,
	"open(rdwr) in child process -> failed";

{
	use open IO => ':flock';

	ok sysopen($in, $file, O_RDONLY), "sysopen with :flock";
	ok system($^X, "-Mblib", $helper, "<:flock", $file),
		"shared lock in child process";
	isnt system($^X, "-Mblib", $helper, "+<:flock(non-blocking)", $file), 0,
		"exclusive lock in child process";
	close $in;
}

# irregular
open my $s, '>', \my $x;
$! = 0;
ok binmode($s, ':flock'), 'flock to scalar handle is noop';
is $!, '', '... no error';


# invalid filehandle
1 while $s->pop_layer();
eval{
	$s->push_layer('flock');
};
ok $@, ":flock to invalid filehandle (\$!='$!')";

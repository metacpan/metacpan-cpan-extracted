#!perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 66;

use FindBin qw($Bin);
use File::Spec;
use Fcntl qw(SEEK_SET SEEK_END);
use Errno qw(EBADF EINVAL);
use IO::Handle ();

use PerlIO::Util;

ok open(my $tee, ">:scalar :tee", \my($x, $y, $z)), "open";

is_deeply [ $tee->get_layers ], [qw(scalar tee tee)], "2 tees opened";

is fileno($tee), -1, "fileno";
is tell($tee), 0,    "tell == 0";

print $tee "foo";

is $x, "foo", "to x";
is $y, "foo", "to y";
is $z, "foo", "to z";

is tell($tee), length($x), 'tell == length($x)';

ok close($tee), "close";

is_deeply [ map{ Internals::SvREFCNT($_) } $x, $y, $z ], [1, 1, 1], "(refcnt aftere closed)";

open $tee, ">:scalar", \$x;

$tee->push_layer(tee => \$y);
$tee->push_layer(tee => \$z);

is_deeply [ $tee->get_layers ], [qw(scalar tee tee)], "2 tees pushed";

print $tee "bar";

is $x, "bar", "to x";
is $y, "bar", "to y";
is $z, "bar", "to z";


ok close($tee), "close";

is_deeply [ map{ Internals::SvREFCNT($_) } $x, $y, $z ], [1, 1, 1], "(refcnt aftere closed)";

# push filehandle

open $tee, ">", \$x;
open my $o, ">", \$y;

ok $tee->push_layer(tee => $o), "push a filehandle to a filehandle";

print $tee "foo";
is $x, "foo", "to x";
is $y, "foo", "to y";

ok close($tee), "close";

print $o "bar";
is $y, "foobar", "the pushed filehandle remains opened";
ok close($o), "close the pushed filehandle";

# with open mode
$x = $y = 'x';
open $tee, ">>:scalar :tee", \$x, \$y;
print $tee "y";
print $tee "z";

is $x, "xyz", "append to x";
is $y, "xyz", "append to y";

close $tee;

### FILE ###

sub slurp{
	my $file = shift;
	open my $in, '<', $file or die $!;
	local $/;
	binmode $in;
	return scalar <$in>;
}

my $file  = File::Spec->join($Bin, 'util', 'tee1');
my $file2 = File::Spec->join($Bin, 'util', 'tee2');
my $file3 = File::Spec->join($Bin, 'util', 'tee3');

# \$x, $file
ok open($tee, '>:tee', \$x, $file), 'open \$scalar, $file';
ok -e $file, '$file created';

print $tee "foobar";
close $tee;

is $x, "foobar", "to scalar";
is slurp($file), "foobar", "to file";

# $file, \$x
ok open($tee, '>:tee', $file, \$x), 'open $file, \$x';

print $tee "fooba";

ok seek($tee, 2, SEEK_SET), "seek SET";
print $tee "*";
ok seek($tee, 0, SEEK_END), "seek END";
print $tee "r";

close $tee;

is $x, "fo*bar", "to scalar";
is slurp($file), "fo*bar", "to file";


# '>>'
open($tee, '>', \$x);
$tee->push_layer(tee => ">> $file");

print $tee "foobar";
close $tee;

is slurp($file), "fo*barfoobar", '>>';

# '>'
open($tee, '>', \$x);
$tee->push_layer(tee => "> $file");
print $tee "foobar";
close $tee;

is slurp($file), 'foobar', '>';

# open three files

ok open($tee, '>:tee', $file, $file2, $file3), "open three files";
print $tee 'foo';
close $tee;
is slurp($file),  'foo', 'to file (1)';
is slurp($file2), 'foo', 'to file (2)';
is slurp($file3), 'foo', 'to file (3)';


# a layer before :tee
ok open($tee, '>:stdio:tee', $file, $file2), "open:stdio:tee";
is_deeply [$tee->get_layers], ['stdio', "tee($file2)"], "layer stack";
print $tee "foo";
close $tee;
is slurp($file), "foo", "stdio(1)";
is slurp($file), "foo", "stdio(2)";

# auto flush

ok open($tee, '>:tee', \$x, $file), "open";
$tee->autoflush(1);

print $tee "foo";

is slurp($file), "foo", "autoflush enabled";

$tee->autoflush(0);

print $tee "bar";

is slurp($file), "foo", "autoflush disabled";

# duplicate
open $tee, '>:tee', \$x, $file;
ok open(my $t2, '>&', $tee), "dup";

is_deeply [ $t2->get_layers() ], [ $tee->get_layers() ], "layer stack";

print $t2  "foo.";
close $t2;

is slurp($file), "foo.", "print to duplicated handle";

seek $tee, 0, SEEK_END;

print $tee "bar";
close $tee;

is slurp($file), "foo.bar", "print to duplicating handle";


# Error Handling

ok !eval{ open $tee, '<:tee', \($x, $y) }, "cannot tee for reading";

ok !open($tee, '>:tee', \$x, File::Spec->join($Bin, 'util', 'no_such_dir', 'file')),
	"no such file";

ok !open($tee, '>:tee', File::Spec->join($Bin, 'util', 'no_such_dir', 'file'), \$x),
	"no such file";

ok !open($tee, ">:tee(<$file)", \$x), ':tee(x) with read-mode';


ok !eval{
	*STDIN->push_layer(tee => \*STDOUT);
}, 'Cannot tee';
#is $!+0, EBADF, "Bad file descriptor";

ok !eval{
	*STDOUT->push_layer(tee => \*STDIN);
}, 'Cannot tee';
#is $!+0, EBADF, "Bad file descriptor";

ok !eval{
	*STDOUT->push_layer('tee');
}, 'Not enough arguments';
#is $!+0, EINVAL, 'Invalid argument';

ok !eval{
	no warnings 'layer';
	*STDOUT->push_layer('tee' => '<foo');
}, 'Invalid argument';
#is $!+0, EINVAL, 'Invalid argument';

eval{
	PerlIO::Util->open('>:tee', File::Spec->devnull, File::Spec->curdir);
};
ok $@, 'cannot open';

my $a = PerlIO::Util->open('>', $file);
$tee = PerlIO::Util->open('>:tee', $file2, $a);

print $tee "foo";

close $a;

eval{
	use warnings FATAL => 'all';
	$tee->flush();
};
ok $@, 'failed to flush';

eval{
	use warnings FATAL => 'all';
	print $tee $a;
};
ok $@, 'failed to write';
eval{
	use warnings FATAL => 'all';
	seek $tee, 0, 0;
};
ok $@, 'failed to seek';

ok do{
	no warnings;
	close $tee;
}, 'close';

## cleanup

ok unlink($file),  "unlink $file";
ok unlink($file2), "unlink $file2";
ok unlink($file3), "unlink $file3";

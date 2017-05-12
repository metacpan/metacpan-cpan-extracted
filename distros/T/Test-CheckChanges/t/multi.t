use strict;
use warnings;

use Test::More;
require Test::CheckChanges;

$Test::CheckChanges::test = bless {}, 'Dummy';
our $x = $Test::CheckChanges::test;

our @q = (
    qr/Multiple Changes files found \("Changes", "CHANGES"\) using "Changes"./,
);

our $name = File::Spec->catdir('t', 'bad', 'multiple', 'CHANGES');
if (-e $name) {
    plan skip_all => "case insensitive filesystem";
}

our @files;
for $x (qw( CHANGES CHanges ChangeS)) {
    push @files, File::Spec->catdir('t', 'bad', 'multiple', $x);
}

for (@files) {
    open X, ">$_";
    print X "bob";
    close X;
}

our $count = 0;
{
    package Dummy;
    sub done_testing {
	print "1..2\n";
    };
    sub ok {
	shift;
	if (my $x = shift) {
	    print "ok 1 - @_\n";
	} else {
	    print "not ok 1 - @_\n";
	}
    }; 
    sub diag {
	shift;
	my $x = shift;
	if ($x =~ $q[$count]) {
	    print sprintf("ok %s - $x\n", ++$count+1);;
        } else {
	    print sprintf("not ok %s - $x\n", ++$count+1);;
	}
    }; 
    sub has_plan { undef; }
}


Test::CheckChanges::ok_changes(
    base => File::Spec->catdir('t', 'bad', 'multiple'),
);

while ($count < 1) {
    print sprintf("not ok %s\n", ++$count+1);;
}

for (@files) {
    unlink;
}

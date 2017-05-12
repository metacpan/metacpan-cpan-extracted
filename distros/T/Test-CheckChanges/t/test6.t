use strict;

require Test::CheckChanges;

$Test::CheckChanges::test = bless {}, 'Dummy';
our $x = $Test::CheckChanges::test;

our @q = (
    qr/expecting version 0.02, But no versions where found in the Changes file./,
);

our $count = 0;

{
    package Dummy;
    sub done_testing {
	print "1.." . (@q + 1) . "\n";
    };
    sub ok {
	shift;
	if (my $x = shift) {
	    print "not ok 1 @_\n";
	} else {
	    print "ok 1 @_\n";
	}
    }; 
    sub diag {
	shift;
	my $x = shift;
warn $x unless defined $q[$count];
	if ($x =~ $q[$count]) {
	    print sprintf("ok %s - $x\n", ++$count+1);;
        } else {
	    print sprintf("not ok %s - $x\n", ++$count+1);;
	}
    }; 
    sub has_plan { undef; };
}


use File::Basename;

our $name = basename($0, qw(.t));
Test::CheckChanges::ok_changes(
    base => File::Spec->catdir('t', 'bad', $name),
);

while ($count < @q) {
    print sprintf("not ok %s\n", ++$count+1);;
}

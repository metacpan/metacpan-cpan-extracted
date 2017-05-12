require Test::CheckChanges;

$Test::CheckChanges::test = bless {}, 'Dummy';
our $x = $Test::CheckChanges::test;

our @q = (
qr/No way to determine version/,
qr/No 'Changes' file found/,
);

our $count = 0;
{
    package Dummy;
    sub plan {
       die caller;
    }
    sub done_testing {
	print "1..3\n";
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
	if ($x =~ $q[$count]) {
	    print sprintf("ok %s - $x\n", ++$count+1);;
        } else {
	    print sprintf("not ok %s - $x\n", ++$count+1);;
	}
    }; 
    sub has_plan { undef; }
}

Test::CheckChanges::ok_changes(
    base => File::Spec->catdir('t', 'bad', 'missing2'),
);

while ($count < 2) {
    print sprintf("not ok %s\n", ++$count+1);;
}

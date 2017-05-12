
use Test::More;

open(STDOUT, ">&STDERR");

# <test_type>, <filter>, <expected rows>
# test_type: 
#			N - nfdump, 
#			L - libnf, 
#			B - nfdump and libnf and compare results
#			E - expected error (3rd argumed is a regexp of error string)
# filter : filter expression 
# expected rows: (undef if no check required)
#			for test N,L,B - number of rows in result
#			for test E - regexp of expected error message
#
@tests = (
#	'any',
	[ 'N', 'src ip 147.229.3.10', undef ],
	[ 'L', 'srcip 147.229.3.10', undef ],
	[ 'B', 'bytes > 10', undef ],
	[ 'E', 'bytues > 10', 'Can\'t lookup field type' ],

);

# prepare data 
system("./libnf/examples/lnf_ex01_writer -n 1000 -r 12 -f t/filter.tmp > /dev/null 2>&1 ");

my $ARG = "libnf/bin/nfdumpp -R t/filter.tmp";

my $x = 0;
foreach my $f (@tests) {
	$x++;
	my $filter = $f->[1];

	if ($f->[0] eq 'B' || $f->[0] eq 'N') {
		system("$ARG --filter-type=nfdump \'$filter\' 2>&1 > t/filter-nfdump-$x.txt 2>&1");

		if ($? != 0) {
			diag("\nCan't initialise nfdump filter \'$filter\' (see t/filter-nfdump-$x.txt)\n");
			ok( 0 );
			next;
		} else {
			ok( 1 );
		}
	}

#	if (defined($f->[2])) {
#	}

	if ($f->[0] eq 'B' || $f->[0] eq 'L' || $f->[0] eq 'E' ) {
		system("$ARG --filter-type=libnf \'$filter\' 2>&1 > t/filter-libnf-$x.txt 2>&1");

		if ($? != 0 && $f->[0] ne 'E') {
			diag("\nCan't initialise libnf filter \'$filter\' (see t/filter-libnf-$x.txt)\n");
			ok( 0 );
			next;
		} elsif ($? != 0 && $f->[0] eq 'E' ) {
			# match error output against defined regexp
			if (defined($f->[2])) {
				my $file = "";
				open F1, "< t/filter-libnf-$x.txt";
				while (<F1>) { $file .= $_; }; 
				close F1;
				if ($file !~ /$f->[2]/) {
					diag("\nError msg do not macth pattern for filter \'$filter\' (see t/filter-libnf-$x.txt)\n");
					ok( 0 );
				} else {
					ok( 1 );
				}
			} else {
				ok( 1 );
			}
		} elsif ($? == 0 && $f->[0] eq 'E' ) {
			diag("\nError expected for filter \'$filter\' (see t/filter-libnf-$x.txt)\n");
		} else {
			ok( 1 );
		}


		# check number of lines 
		my $lines = `wc -l t/filter-libnf-$x.txt`;
		if ($f->[0] ne 'E' && defined($f->[2]) && $f->[2] != $lines) {
			diag(sprintf("\nInvalid number of returned lines %d (expected %d, see t/filter-libnf-$x.txt)\n",
				$lines, $f->[2]));
		}
	}

	if ($f->[0] eq 'B') {
		system("diff t/filter-nfdump-$x.txt t/filter-libnf-$x.txt > t/filter-diff-$x.txt");

	    if ($? != 0) {
	        diag("\nDifferend nfdump/libnf filter result for \'$filter\' (see t/filter-diff-$x.txt)\n");
			ok( 0 );
	    } else {
			ok( 1 );
		}
	}
}

done_testing();

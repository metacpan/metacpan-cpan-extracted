use Perl6::Gather;
use Data::Dumper 'Dumper';

@data = (1..9,"one","two","three");

@odds = gather {
			for (@data) {
				take if /(one|three|five|nine)$/;
				take if /^\d+$/ && $_ %2;
			}
			unshift @{+gathered}, {lettery => 0+grep /[a-z]/i, @data};
		};

print Dumper [ @odds ];

@data = ("six","two","four");

@odds = gather {
			for (@data) {
				take if /(one|three|five|nine)$/;
				take if /^\d+$/ && $_ %2;
			}
			take 99, 101 unless gathered;
		};

print Dumper [ @odds ];

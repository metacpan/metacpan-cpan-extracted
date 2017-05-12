use Perl6::Form;

my @amounts = (0, 1, 1.2345, 1234.56, -1234.56, 1234567.89);

print form
	 "Farsi (Iranian):",
	 "        {-IRR 0/[[[[[[[[}",
			  farsi(@amounts);


sub farsi {
	[ map { /(-?)(\d+)(?:\.(\d\d))?/; $1.($3||0).".".$2 } @_ ];
}


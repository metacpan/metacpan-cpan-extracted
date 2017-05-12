use Perl6::Form;

print form {layout=>'down'},
     "                     {<<<<<<<<<<<}",
						   "baz" . "bar "x100,
	 "{[[[[[[[[[[[[}       {VVVVVVVVVVV}",
	  "foo "x20,
     "--------------       {VVVVVVVVVVV}",
	 "                     {VVVVVVVVVVV}";

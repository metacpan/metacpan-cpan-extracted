use Perl6::Form;

print form
	{page=>{length=>4, header=>'=========='}},
	"{>>>>>>>>} {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
     "foo bar baz qux",
                "foo bar baz qux" x 30,

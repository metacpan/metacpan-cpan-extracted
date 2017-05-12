use Perl6::Form;

for (10,20,30,40,50,100,1000) {
	print form
		 {page=>{feed=>"----------\n"}},
		 '{=]]]]=} |{=IIIIIIIII=}|',
		 {height=>'minimal'}, [1..20],
		 {height=>{min=>5,max=>15}}, "foo" x $_;
}

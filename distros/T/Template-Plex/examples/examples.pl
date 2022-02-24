use Template::Plex;
{	
	print "EXAMPLE SYNOPSIS\n";
	my $base_data={name=>"James", age=>"12", fruit=>"banana"};
	my $template = '$name is $age and favourite fruit is $fruit';
	print "Template is: $template\n";

	my $t=plex [$template], $base_data;

	my $string=$t->render();		#renders with base values. 
	print "Rendered: $string\n";
	#James's age is 12 and favourite fruit is banana

	$base_data->{name}="John";
	$base_data->{fruit}="apple";

	$string=$t->render();		#render with updated base values
	print "Rendered: $string\n";
	#John's age is 12 and favourite fruit is apple
	print "\n\n";
}

{
	print "EXAMPLE 1a: BASIC LEXICAL TEXT TEMPLATE\n";
	#
	#Note the string mus be in literal quotes ie ''  or q() et al
	#String must be valid perl code. This example is simply interpolated perl string
	#hence the use of double quotes
	#
	my $template='Template filled with $field1 and $field2';
	print "Template is: $template\n";


	#Data must be provided in a hash
	my $data={field1=>"monkeys", field2=>"hippos"};		


	#Any keys present at preparation time are used to generate lexical aliases of the hash entries. This 
	#Returned item is  code ref to execute
	my $t=plex [$template], $data;


	#executing with no arguments will only draw data from the base values specified
	my $string=$t->render();	

	print "Rendered: $string";
	print "\n\n";



	print "EXAMPLE 1b: UPDATE BASE/LEXICAL VALUES DYNAMICALLY\n";

	$data->{field1}="lions";
	$string=$t->render();
	print "Rendered: $string";

	print "\n\n";

}

{
	print "EXAMPLE 2: Accessing hash fields and override\n";

	#The template can also access fields directly in the hash used instead of lexical aliases.
	#Its a little more to type but allows the render code to use completely instead of updating the base data hash
	#
	my $template='Template filled with $fields{field1} and $fields{field2} and $fields{field3}';
	print "Template is: $template\n";
	my $data={field1=>"monkeys", field2=>"hippos"};		
	#field3 is not specified and will be undefined
	
	my $t=plex [$template], $data;
	my $string=$t->render();	

	print "Rendered (base): $string\n";
	my $new_data={field1=>"lions", field3=>"tigers"};

	#Note that the new data has no field2. Thus will not be in the rendered output
	$string=$t->render($new_data);
	print "Rendered (override): $string\n";
	print "\n\n";
}

use Perl6::Form;

%categories = (
	Animal    => ["The mighty destrider,\nship of the knight",
				  "The patient cat, warden of the granary",
				  "Our beloved king, whom we shall soon have to kill"],
	Vegetable => ["The lovely peony, garland of Eddore",
			      "The mighty oak, from which tiny acorns grow",
				  "The humble cabbage, both food and metaphor for the fool"],
	Mineral   => ["Gold, for which men thirst",
				  "Salt, by which men thirst",
				  "Sand, on which men thirst",
				 ],
);

for my $category (keys %categories) {
	print form
		 {bullet=>'*'},
		 "** * {<<<<<<<<<<<<<<<<<<<<<<<<<<<<} **", $category,
		 {bullet=>'-'},
		 "     - {[[[[[[[[[[[[[[[[[[[[[[[[[[} - ", $categories{$category};
}

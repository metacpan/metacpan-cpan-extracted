grammar Perl6::Conf::Grammar {
	regex TOP { ^ <comment>* <section>* $ }; 

	regex section { <heading> <body> };
	regex body { <chunk>* };
	regex chunk { <comment> | <entry> };
	regex heading { ^^ '[' <ident> ']' $$ };

	regex entry { ^^ <key> \= <value> $$ };
	regex key   { \w+ };
	regex value { \N+ };
	regex ident { \w+ };
	regex comment { ^^ \s* (\#\N*)? $$ };  # comment and empty line
};

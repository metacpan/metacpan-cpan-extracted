use Perl6::Form;

@character = ("Macbeth", "King Lear", "Juliet", "Othello", "Hippolyta",
	          "Gildenstern", "Don John", "Richard III", "Malvolio", "Snug");

$disclaimer = "WARNING:\nThis list is roles constitutes a personal opinion "
			. "only and is in no way endorsed by Shakespeare'R'Us. "
			. "It may contain nuts.";

print "The best Shakespearean roles are:\n\n";

print form
	 "   * {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<}   |{:<<<<<<<>>>>>>>:}|",
           $character[$_],                $disclaimer
				for 0..$#character;

pos $disclaimer = 0;
unshift @character, "Either of the 'two foolish officers': Dogberry and Verges";

print "\n\nThe best Shakespearean roles are:\n\n";

print form
	 "   * {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}   |{[[[[[[[[]]]]]]]]}|",
		   \@character,                            $disclaimer;

pos $disclaimer = 0;
print "\n\nThe best Shakespearean roles are:\n\n";

print form
	 {bullet=>'*'},
     "   * {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}   |{[[[[[[[[]]]]]]]]}|",
		   \@character,                            $disclaimer;

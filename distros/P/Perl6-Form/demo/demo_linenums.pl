use Perl6::Form;

my $linenum = 1;
sub numerate {
    my ($lines, $fill, $opts) = @_;
	my $body = form '{]]]]} {"""{*}"""}',
					[$linenum..$linenum+@$lines-1], $lines,
					@$fill;
	$linenum += @$lines;
	return $body;
}

my $richardIII_soliloquy = <<EOR3;
Now is the winter of our discontent / Made glorious summer by this sun of York; / And all the clouds that lour'd upon our house / In the deep bosom of the ocean buried. / Now are our brows bound with victorious wreaths; / Our bruised arms hung up for monuments; / Our stern alarums changed to merry meetings, / Our dreadful marches to delightful measures. Grim-visaged war hath smooth'd his wrinkled front; / And now, instead of mounting barded steeds / To fright the souls of fearful adversaries, / He capers nimbly in a lady's chamber.
EOR3

my $hamlet_soliloquy = <<EOH;
To be, or not to be -- that is the question: / Whether 'tis nobler in the mind to suffer / The slings and arrows of outrageous fortune / Or to take arms against a sea of troubles / And by opposing end them. To die, to sleep -- / No more -- and by a sleep to say we end / The heartache, and the thousand natural shocks / That flesh is heir to. 'Tis a consummation / Devoutly to be wished. To die, to sleep -- / To sleep -- perchance to dream: ay, there's the rub, / For in that sleep of death what dreams may come / When we have shuffled off this mortal coil, / Must give us pause. There's the respect / That makes calamity of so long life. 
EOH

print form {page=>{ header => "\n==========\n\n",
			  length => 12,
			  body   => \&numerate
			}
	 },
	 "{[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
	 $richardIII_soliloquy,
	 {page=>{}},
	 "                 {]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]}",
	 $hamlet_soliloquy;

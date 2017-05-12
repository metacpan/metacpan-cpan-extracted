use Perl6::Form;

print form { ws=>qr/\s/, page=>{header=>"Report",
								footer=>{other=>sub{"../".($_[0]{page}{number}+1)},
										 last=>"THE\nEND"
										},
								feed=>{other=>sub{".\n.\n.\n"}, last=>""},
								body=>'{=I{*}I=}',
								length=>5,
							   }
		   },
           "= [{[[[[[[[[[[[[[[[[[[[[]]]]]]]]]]}]",
		   [<DATA>],
           "= [{[[[[[[[[[[[[[[[[[[[[]]]]]]]]]]}]",
		   [1..100],
		   {page=>{length => 12, number=>100}},
           "= [{[[[[[[[[[[[[[[[[[[[[]]]]]]]]]]}]",
		   [101..200],
		   {page=>{}},
           "= [{[[[[[[[[[[[[[[[[[[[[]]]]]]]]]]}]",
		   [201..280],


__DATA__
Now is the winter of our discontent / Made glorious summer by this sun of York; / And all the clouds that lour'd upon our house / In the deep bosom of the ocean buried. / Now are our brows bound with victorious wreaths; / Our bruised arms hung up for monuments; / Our stern alarums changed to merry meetings, / Our dreadful marches to delightful measures. / Grim-visaged war hath smooth'd his wrinkled front; / And now, instead of mounting barded steeds / To fright the souls of fearful adversaries, / He capers nimbly in a lady's chamber.

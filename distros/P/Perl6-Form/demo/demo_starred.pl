use Perl6::Form;

$line = <<EOSOL;
Now is the winter of our discontent / Made glorious summer by this sun of York; / And all the clouds that lour'd upon our house / In the deep bosom of the ocean buried. / Now are our brows bound with victorious wreaths; / Our bruised arms hung up for monuments; / Our stern alarums changed to merry meetings, / Our dreadful marches to delightful measures. / Grim-visaged war hath smooth'd his wrinkled front; / And now, instead of mounting barded steeds / To fright the souls of fearful adversaries, / He capers nimbly in a lady's chamber.
EOSOL

print form
	 {under=>'*'},
	 '{:[{20}]]} | {:I{*}II}', $line, $line;

$lines = <<EOSOL;
Now is the winter of our discontent
Made glorious summer by this sun of York;
And all the clouds that lour'd upon our house
In the deep bosom of the ocean buried.
Now are our brows bound with victorious wreaths;
Our bruised arms hung up for monuments;
Our stern alarums changed to merry meetings,
Our dreadful marches to delightful measures.
Grim-visaged war hath smooth'd his wrinkled front;
And now, instead of mounting barded steeds
To fright the souls of fearful adversaries,
He capers nimbly in a lady's chamber.
EOSOL

print form
	 {under=>'*'}, '| {:"{*}""} | {:"{*}""} |', $lines, $lines;

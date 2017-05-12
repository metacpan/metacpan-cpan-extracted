use 5.010;
use warnings;

use Perl6::Form;

$text = <<EOSOL;
Now is the winter of our discontent / Made glorious summer by this sun of York; / And all the clouds that lour'd upon our house / In the deep bosom of the ocean buried. / Now are our brows bound with victorious wreaths; / Our bruised arms hung up for monuments; / Our stern alarums changed to merry meetings, / Our dreadful marches to delightful measures. Grim-visaged war hath smooth'd his wrinkled front; / And now, instead of mounting barded steeds / To fright the souls of fearful adversaries, / He capers nimbly in a lady's chamber.
EOSOL

my $advert = join "", <DATA>;

print form
	{page=>{width=>70}, layout=>'across' },
   	 '{[[[[[[[[[[[[{*}]]]]]]]]]]]]}', {height=>2}, $text,
   	 '{V{*}V}   {="{*}"=}   {V{*}V}', $advert,
   	 '{VVVVVVVVVVVV{*}VVVVVVVVVVVV}', {height=>undef};

__DATA__

+---------------------+
|                     |
| Eat at Mrs Miggins! |
|                     |
+---------------------+


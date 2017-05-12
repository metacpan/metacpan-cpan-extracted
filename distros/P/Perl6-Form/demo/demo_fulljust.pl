use Perl6::Form;

$text = <<EOSOL;
Now is the winter of our discontent / Made glorious summer by this sun of York; / And all the clouds that lour'd upon our house / In the deep bosom of the ocean buried. / Now are our brows bound with victorious wreaths; / Our bruised arms hung up for monuments; / Our stern alarums changed to merry meetings, / Our dreadful marches to delightful measures. Grim-visaged war hath smooth'd his wrinkled front; / And now, instead of mounting barded steeds / To fright the souls of fearful adversaries, / He capers nimbly in a lady's chamber.
EOSOL

print form
	{page=>{width=>50}},
   	 '    {[[[[[[[[[[[[{*}]]]]]]]]]]]]}',
	  	  $text;

$text = <<EOTEXT;
I think one of the outstanding features of OO Perl is that is allows you
to approach OO with the same mindset as you're used to in another
language. By that I mean that you can write OO Perl that's similar in
structure and operation to a C++ program, or OO Perl that's very like
Smalltalk, or OO Perl that mimics Self, or CLOS, or Eiffel. I once even
implemented a Perl module that added Python-esque scoping-by-indentation.
In other words, whatever brand of OO you're used to using,
you can stick with it when you move to Perl. Eventually you discover
that your notions about what OO actually is have been stretched and
challenged so often that you've developed an entirely new understanding
of what OO truly is -- your own OO mindset. But there's another important
aspect to all that flexibility. Because it can accommodate such a wide
range of approaches, as you become a more accomplished OO programmer
Perl also lets you select the most appropriate mindset -- or mindsets! --
for a particular problem. If you need OO closures in one application,
and interfaces in another, and prototype cloning in a third, you can
implement each in Perl. And if you need closures and interfaces and
cloning and inheritance polymorphism and objects that can change their
class and classes that can modify their inheritance hierarchies, all in
the same application, in Perl you can do that too. So, although you
don't need to approach OO Perl with a different mindset, after a while
you're almost certain to discover one. I don't know of any other
programming language that can give you that.
EOTEXT


print form
	{page=>{width=>50}, ws=>qr/\s+/},
   	 '    {[[[[[[[[[[[[{*}]]]]]]]]]]]]}',
	  	  $text;


__END__

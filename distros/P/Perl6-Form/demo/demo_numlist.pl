use Perl6::Form;

@reason = (
	"Three witches told me I was going to be king.",
	"I was busy explaining wherefore am I Romeo.",
	"I was busy scrubbing the blood off my hands.",
	"Some dear friends had to charge once more unto the breach.",
	"My so-called best friend tricked me into killing my wife.",
	"My so-called best friend tricked me into killing Caesar.",
	"My so-called best friend tricked me into taming a shrew.",
	"My uncle killed my father and married my mother.",
	"I fell in love with my manservant, who was actually the disguised twin sister of the man that my former love secretly married, having mistaken him for my manservant who was wooing her in my behalf whilst secretly in love with me.",
	"I was abducted by fairies.",
);

print "I couldn't do my English Lit homework because...\n\n";

print form "   {>>>} {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
			   10-$_.'.',   $reason[$_],
			   ""
					for 0..$#reason;

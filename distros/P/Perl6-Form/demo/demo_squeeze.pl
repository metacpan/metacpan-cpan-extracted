use Perl6::Form;

my $eulogy = <<EOTEXT;
Friends,   Romans  , countrymen, lend me your ears;
I come to bury    Caesar   , not to praise him.
The evil that men do lives after them;
The good is oft interred with their bones;
So let it be with    Caesar    . The noble    Brutus
Hath told you     Caesar     was ambitious:
If it were so, it was a grievous fault,
And grievously hath    Caesar    answer'd it.
EOTEXT


# Default (no squeezing)...

print form
	 "| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |",
	    $eulogy, "","";


# Squeeze all whitespace...

print form
	 {ws=>qr/\s+/},
     "| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |",
	    $eulogy, "","";


# Squeeze all whitespace except newlines...

print form
	 {ws=>qr/[^\S\n]+/},
     "| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |",
	    $eulogy, "","";

# Squeeze even harder before punctuation

print form
	 {ws=>qr/[^\S\n]+ ([,.!])?/x},
     "| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |",
	    $eulogy, "","";


# Form is smart enough not to squeeze zero-width matches...

print form
	 {ws=>qr/\s*/},
     "| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |",
	    $eulogy, "","";



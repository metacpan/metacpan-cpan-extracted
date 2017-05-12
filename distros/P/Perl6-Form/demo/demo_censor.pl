use Perl6::Form;

sub obscure {
	my $hidewords = join '|', map quotemeta, @_;
	return sub {
		my ($data) = @_;
		$data =~ s/($hidewords)/'X' x length $1/egi;
		return $data;
	}
}

my $censor = obscure qw(villain plot libel treacherous murderer false deadly 'G');
my $script = do{local$/;<DATA>};

print form
	 "[Ye following tranfcript hath been cenfored by Order of ye King]\n\n",
	 "         {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
	 $censor->($script);

__DATA__
And therefore, since I cannot prove a lover,
To entertain these fair well-spoken days,
I am determined to prove a villain
And hate the idle pleasures of these days.
Plots have I laid, inductions dangerous,
By drunken prophecies, libels and dreams,
To set my brother Clarence and the king
In deadly hate the one against the other:
And if King Edward be as true and just
As I am subtle, false and treacherous,
This day should Clarence closely be mew'd up,
About a prophecy, which says that 'G'
Of Edward's heirs the murderer shall be.

use 5.010;
use warnings;

use Perl6::Form;

my $proscribed = join '|', map quotemeta,
	qw(villain plot libel treacherous murderer false deadly 'G');

sub break_and_censor {
	my ($breaker) = @_;
	return sub {
		my ($str,$rem,$ws) = @_;
		my ($nextline, $more) = $breaker->(@_);
		$nextline =~ s/($proscribed)/'X' x length $1/egi;
		return ($nextline, $more);
	}
}

sub censored() {
	return { field => [ qr/[{] (X+) [}]/x => sub {
							my ($match, $opts) = @_;
							$opts->{break} = break_and_censor($opts->{break});
							return '{[[{' . length($match->[1]) . '}[[}';
						}
			          ]
	       };
}

my $script = do{local$/;<DATA>};

print form censored,
	 "[Ye following tranfcript hath been cenfored by Order of ye King]\n\n",
	 "        {XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX}",
	           $script;

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

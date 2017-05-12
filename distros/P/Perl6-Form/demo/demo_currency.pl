use Perl6::Form;

@amounts = map {($_, -$_)} 1, 1.2, 1234.567, 1234.5678, 123456, 'six';

print form
	'{A$(]]]].[[)}',
	\@amounts;

print "\n\n";

print form
	'{kr -]]]].[[}',
	\@amounts;

print "\n\n";

print form
	'{-£]]]].[[}',
	\@amounts;

print "\n\n";

print form
	"{\x{20AC}]]]].[[-}",
	\@amounts;

print "\n\n";

print form
	'{]]]].[[}',
	\@amounts;

print "\n\n";


print form {rfill=>0},
	"{]],]],]]].[\x{20A8}}",
	\@amounts;

print "\n\n";

print form
	"{].]]],[DM}",
	\@amounts;

print "\n\n";


print form
	'{£]]]].[[}',
	\@amounts;

print "\n\n";

print form {rfill=>0},
	'{$]]].[¢}',
	\@amounts;

print "\n\n";

print form
	"{]']]],[CHF}",
	\@amounts;

print "\n\n";

print form
	'{].]]]$[ Esc.}',
	\@amounts;

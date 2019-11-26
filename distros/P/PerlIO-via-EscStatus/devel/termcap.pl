use strict;
use warnings;

use Data::Dumper;
use Term::Cap;

my @path = Term::Cap::termcap_path();
print "path: ", Dumper(\@path),"\n";
exit 0;

my $termcap = Tgetent Term::Cap { TERM => 'linux' };
print Dumper ($termcap);
#my $termcap = Term::Cap->Tgetent (TERM => 'linux');
$termcap->Trequire ('Sf');
print Dumper ($termcap->Tgoto('Sf', 1, undef));
print Dumper ($termcap->Tgoto('AF', 1, undef));
exit 0;


use Test::More tests => 2;
use String::Alignment qw(do_alignment);

BEGIN {
my $s1 = "WRITTTEEERSM";
my $s2 = "VINTTNEEERVM";
my @result = split("\t",do_alignment($s1,$s2,1));
is($result[0],"TTNEEERVM");
is($result[1],"TTTEEERSM");
}

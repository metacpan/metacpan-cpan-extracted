use Test::More tests => 2;
use String::Alignment qw(do_alignment);

BEGIN {
my $s1 = "WRIJNTTEERSM";
my $s2 = "VIKNTQTEERKM";
my @result = split("\t",do_alignment($s1,$s2,1));
is($result[1],"NT-TEERSM");
is($result[0],"NTQTEERKM");
}


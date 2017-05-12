use strict;
no warnings;

use Test;
use Term::GentooFunctions qw(:all);

plan tests => (my $tests = 5);

$SIG{PIPE} = sub { skip_all("received sig pipe") };
open PIPE, "$^X test_scripts/test_edo_returns.pl|" or skip_all("popen failure: $!");
$/ = undef; my $slurp = <PIPE>;
my $exit = close PIPE;
if( not $exit and $! == 0 ) {
    skip_all("pclose failure ($?)") if ($?>>8) != 0x65;
}

$slurp =~ s/\s+/ /g;
$slurp =~ s/\e\[[\-\d;]*[ACm]//g;
$slurp =~ s/(?:\s*\[\s+ok\s+\]\s*)//sg;
$slurp =~ s/[\s\*]+\$VAR1\s+=\s+/: /sg;
$slurp =~ s/[ \t]{2,}/ /g;

ok( $slurp =~ m/list2sclr.*\\4;/ );
ok( $slurp =~ m/list2arr.*1,.*2,.*3,.*4/ );
ok( $slurp =~ m/arr2arr.*1,.*2,.*3,.*4/ );
ok( $slurp =~ m/list2hash.*1.*=.*2.*3.*=.*4/ );
ok( $slurp =~ m/hash2hash.*1.*=.*2.*3.*=.*4/ );

sub skip_all {
    warn " $_[0], skipping tests\n";
    skip(1,1,1) for 1 .. $tests;
    exit 0;
}

__END__
result when edo fixed:
* list2sclr returns: \4;
* list2arr returns: [ 1, 2, 3, 4 ];
* arr2arr returns: [ 1, 2, 3, 4 ];
* list2hash returns: { '1' => 2, '3' => 4 };
* hash2hash returns: { '1' => 2, '3' => 4 };

result when test created:
* list2calar returns: \4;
* list2arr returns: [];
* arr2arr returns: [];
* list2hash returns: {};
* hash2hash returns: {};


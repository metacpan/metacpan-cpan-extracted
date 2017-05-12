use strict;
no warnings;

use Test;
use Term::GentooFunctions qw(:all);

plan tests => (my $tests = 3);

$SIG{PIPE} = sub { skip_all("received sig pipe") };
open PIPE, "$^X test_scripts/makefile_rmfile.pl|" or skip_all("popen failure: $!");
$/ = undef; my $slurp = <PIPE>;
my $exit = close PIPE;
if( not $exit and $! == 0 ) {
    skip_all("pclose failure ($?)") if ($?>>8) != 0x65;
}

$slurp =~ s/\e\[[\d;]*m//g;

ok( $slurp =~ m/\*\s+making.*ok/s ) or dslurp();
ok( $slurp =~ m/\*\s+rming.*ok/s ) or dslurp();
ok( $slurp =~ m/UNLINK ERROR/ ) or dslurp();

sub dslurp() {
    our $x ++;
    return unless $x == 1;
    my $s = $slurp;
       $s =~ s/([^[:print:]])/'\x' . unpack("H*", $1)/eg;
       $s =~ s/\n/\\n/g;

    warn " slrup: $s";
}

sub skip_all {
    warn " $_[0], skipping tests\n";
    skip(1,1,1) for 1 .. $tests;
    exit 0;
}

__END__
 * making file
 *   rming file
 * rming file again (fail)
 * No such file or directory at test_scripts/makefile_rmfile.pl line 15.                                                      [ !! ]

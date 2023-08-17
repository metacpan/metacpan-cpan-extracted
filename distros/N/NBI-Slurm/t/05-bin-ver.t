use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
my $PERL_INTERPRETER = $^X;
# Make a list in brackets 
my @BINARIES_NAMES = qw(lsjobs whojobs session waitjobs whojobs);

for my $prog (@BINARIES_NAMES)  {
    my $cmd = "$PERL_INTERPRETER $RealBin/../bin/$prog --version";
    my $output = `$cmd`;
    my $exit_code = $?;
    ok($exit_code == 0, "$prog: exit code is 0");
    ok($output =~ /$prog/, "$prog: version is $output");
}
done_testing();
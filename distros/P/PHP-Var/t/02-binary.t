#!perl
##!perl -T

use strict;
use warnings;

use Test::More;

use File::Temp qw/ tempfile /;
use File::Basename;
use PHP::Var;

SKIP: {
    # Skip if PHP is not installed.
    open(my $php, '-|', 'php', '-v')
        or skip('PHP is not installed.', 1);
    close($php);

    # generate binary and export
    my $bin = pack('C256', 0...255);
    my ($phpfh, $phpfile) = tempfile();
    print($phpfh PHP::Var::export('data' => {'bin' => $bin}, enclose => 1));
    close($phpfh);

    # inport and output
    my ($binfh, $binfile) = tempfile();
    close($binfh);
    (my $program = __FILE__) =~ s/\.t$/.php/;
    system("php $program $phpfile $binfile");
    my $bin2 = do{ open(my $fh, '<', $binfile); local $/; <$fh> };

    is($bin, $bin2);
}

done_testing;

1;

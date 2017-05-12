
use Exporter;

use Scriptalicious;
use vars qw(@EXPORT $testfile $pid);
BEGIN {
    @EXPORT = qw($testfile);
    $pid = $$;
}

$testfile = "/tmp/testfile.$$";

sub slurp {
    my $fn = shift;
    open X, "<$fn" or barf "failed to open $fn for slurping; $!";
    my @x = <X>;
    close X;
    return join "", @x;
}

sub slop {
    my $fn = shift;
    open X, ">$fn" or barf "failed to slop to $fn; $!";
    while ( @_ ) {
	my $l = shift;
	$l .= "\n" unless $l =~ /\n/;
	print X $l;
    }
    close X;
}

END {
    unlink($testfile) if $testfile and $$ == $pid;
}

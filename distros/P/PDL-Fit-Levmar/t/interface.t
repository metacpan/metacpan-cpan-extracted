use Data::Dumper;
use PDL;
use PDL::Fit::Levmar;
use PDL::Fit::Levmar::Func;
use PDL::NiceSlice;
use PDL::Core ':Internal'; # For topdl()
use Test::More;
use strict;

# Tests to check how the arguments are passed to the top level levmar function

#  @g is global options to levmar
my @g = (  );

sub tapprox {
        my($a,$b) = @_;
        my $c = abs(topdl($a)-topdl($b));
        my $d = max($c);
        $d < 0.0001;
}

sub deb  { print STDERR $_[0],"\n" }

#-----------------------------------------------

my $Gf = './t/simple_gaussian.lpp';
my $Gh = levmar_func(FUNC => $Gf);

sub make_gaussian_data {
    my $n = 100;
    my $p = pdl (1,1);
    my ($p0,$p1) = list $p;
    my $t = zeroes($n)->xlinvals(-5,4.9);
    my $x = $p0*exp(-$t*$t*$p1);
    return ($p,$x,$t)
}

sub t_getopts {
    my $h = levmar(GETOPTS => 1);
    ok( ref($h) =~ "HASH" , " Does GETOPTS return ref to hash?" );
#    deb Dumper($h);    
}

# Test order of args
sub t_order_args {
    my ($pc,$x,$t) = make_gaussian_data();
    my $p = $pc*1.1;
#    deb "# ordering of arguments";
#    deb '# $Gh is Func handle';
    map { ok( tapprox((eval $_)->{P},$pc), $_) }
	(
	 '  levmar($Gh,$p,$x,$t)',
	 '  levmar($p,$Gh,$x,$t)',
	 '  levmar($p,$x,$Gh,$t)',
	 '  levmar($p,$x,$t,$Gh)',
	 '  levmar($p,$x,$t, FUNC => $Gh)',
	 '  levmar($p,$x, T => $t, FUNC => $Gh)',
	 '  levmar($p,$x, T => $t, FUNC => $Gh)',
	 '  levmar($p, X => $x, T => $t, FUNC => $Gh)',
	 '  levmar(P=>$p, X => $x, T => $t, FUNC => $Gh)',
	 '  levmar($Gh, P=>$p, X => $x, T => $t)',
	 '  levmar($Gh, $p, X => $x, T => $t)',
	 '  levmar($p, $Gh, X => $x, T => $t)',
	 '  levmar($p, $Gh, COVAR=>pdl->null, X=>$x, T=>$t)',
	 );
    map { ok(not(tapprox((eval $_)->{P},$pc)), $_ . ' # Wrong order!') }
	(
	 '  levmar($Gh,$p,$t,$x)',
	 );
    unlink $Gh->{SONAME};
    foreach (
	 "  levmar(\'$Gf\',\$p,\$x,\$t)",
	 "  levmar(\$p,\'$Gf\',\$x,\$t)",
	 "  levmar(\$p,\$x,\'$Gf\',\$t)",
	 "  levmar(\$p,\$x,\$t,\'$Gf\')",
	 "  levmar(\$p,\$x,\$t, FUNC => \'$Gf\')",
	 "  levmar(\$p,\$x, T => \$t, FUNC => \'$Gf\')",
	 "  levmar(\$p,\$x, T => \$t, FUNC => \'$Gf\')",
	 "  levmar(\$p, X => \$x, T => \$t, FUNC => \'$Gf\')",
	 "  levmar(P=>\$p, X => \$x, T => \$t, FUNC => \'$Gf\')",
	 "  levmar(\'$Gf\', P=>\$p, X => \$x, T => \$t)",
	 "  levmar(\'$Gf\', \$p, X => \$x, T => \$t)",
	 "  levmar(\$p, \'$Gf\', X => \$x, T => \$t)",
	 "  levmar(\$p, \'$Gf\', COVAR=>pdl->null, X=>\$x, T=>\$t)",
	      )
    {  my $s = $_;my $h = eval $_; ok(tapprox($h->{P},$pc), $s); $h=undef}

}

t_getopts();
t_order_args();

done_testing;

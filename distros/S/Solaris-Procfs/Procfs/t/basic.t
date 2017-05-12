
my ($last_test,$loaded);

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';

BEGIN { $last_test = 21; $| = 1; print "1..$last_test\n"; }
END   { print "not ok 1  Can't load Solaris::Procfs\n" unless $loaded; }

use Solaris::Procfs qw(:procfiles);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub test;  # Predeclare the test function (defined below)

my $tcounter = 1;
my $want     = '';
my $id       = '\(0x.+\)';  # Regex to match the id of stringified refs


#------------------------------------------------------
# Test procfile functions
# 

#----------------
my $psinfo = psinfo $$;

$want = "HASH";            test q( ref $psinfo );
$want = $>;                test q( $psinfo->{pr_uid} );
$want = $<;                test q( $psinfo->{pr_euid} );

my @groups = split /\s+/, $);
$want = $groups[0];        test q( $psinfo->{pr_gid} );
$want = $$;                test q( $psinfo->{pr_pid} );
$want = getppid;           test q( $psinfo->{pr_ppid} );
$want = scalar keys %ENV;  test q( scalar @{ $psinfo->{pr_envp} } );

$want = 'perl';            test q( $psinfo->{pr_fname} );

#$want = "perl -MExtUtils::testlib $0";
#                           test q( $psinfo->{pr_psargs} );
#$want = "perl -MExtUtils::testlib $0";
#                           test q( join(" ", @{$psinfo->{pr_argv}}) );

$want =  1;                test q( $psinfo->{pr_lwp}->{pr_lwpid} );

(my $nice) = grep /^\d+$/, `/usr/bin/ps -o nice -p $$`;
chomp($nice);

$want = $nice;             test q( $psinfo->{pr_lwp}->{pr_nice} );
$want =  1;                test q( $psinfo->{pr_lwp}->{pr_pctcpu} > 0 );


#----------------
my $prcred = prcred $$;

$want = "HASH";            test q( ref $prcred );
$want = $>;                test q( $prcred->{pr_ruid} );
$want = $<;                test q( $prcred->{pr_euid} );

@groups = split /\s+/, $);
$want = $groups[0];        test q( $prcred->{pr_rgid} );
@groups = split /\s+/, $(;
$want = $groups[0];        test q( $prcred->{pr_egid} );

$want = 1;        test q( $prcred->{pr_ngroups} == scalar @{ $prcred->{pr_groups} } );
$want = 1;        test q( $prcred->{pr_ngroups} == scalar(@groups) - 1 );

#----------------
my $pcwd = pcwd $$;

chomp($want = `pwd`);      test q( $pcwd );

#----------------
my $proot = proot $$;

$want = '/';               test q( $proot );



#------------------------------------------------------
# Test function
# 
sub test {
	$tcounter++;

	my $string = shift;
	my $ret = eval $string;
	$ret = 'undef' if not defined $ret;

	if("$ret" =~ /^$want$/m) {

		print "ok $tcounter\n";

	} else {
		print "not ok $tcounter\n",
		"   -- '$string' returned '$ret'\n", 
		"   -- expected =~ /$want/\n"
	}
}



#!/usr/bin/env perl 
#
# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 600_sbalance.t`
#
# Various tests of sbalance script (using fake_sshare to get 'fixed' results)
#

use strict;
use warnings;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Slurm::Sshare;

my $testDir = dirname(abs_path($0));

our $num_tests_run = 0;


require "${testDir}/helpers/parse-help.pl";

my $DEBUG;
#$DEBUG=1;

my $BINDIR="${testDir}/../bin";
my $SBALANCE = "${BINDIR}/sbalance";
my $SSHARE = "${testDir}/helpers/fake_sshare";
my $INCDIR = "${testDir}/../lib";

my $tmp = $ENV{PERLLIB};
$ENV{PERLLIB} = $tmp?"${INCDIR}:$tmp":"$INCDIR";
$tmp = $ENV{PERL5LIB};
$ENV{PERL5LIB} = $tmp?"${INCDIR}:$tmp":"$INCDIR";


#---------------------------------------------------------
#	More helper routines
#---------------------------------------------------------

sub get_sbalance_results(@)
#Runs the specified sbalance command, sucking up output
#into a list ref of strings (representing each line of output)
{	my @args = @_;

	my ( $PIPE, $res, $err, @out);
	my $chd_excode=254;

	#Pretend we are running as 'george'
	local $ENV{USER}='george';

	if ( $res = open( $PIPE, "-|" ) )
	{	#Parent
		if ( ! defined $res )
		{	my $tmp = join ' ', $SBALANCE, @args;
			die "Pipe to '$tmp' failed: $!";
		}
		@out = <$PIPE>;
		$res = close $PIPE;
		$err = $?;
		if ( $err && ( $err >> 8 ) == $chd_excode ) 
		{	#We (probably?) got an excepting running exec in child process
			#Re-raise the exception
			my $exc = join '', @out;
			die $exc;
		}
		if ( $err )
		{	print STDERR "about to exit: output is:\n", @out, "\n\n";
			die "Child exitted with " . ( $err >> 8 ) . " at ";
		}
		unless ( $res )
		{	die "Close of pipe returned $res at ";
		}

		if ( $DEBUG )
		{	print STDERR "Results of '$SBALANCE " . (join ' ', @args) . "' is\n";
			print STDERR (join "\n", @out), "\n";
		}
		return [ @out ];
	} else
	{	#Child
		#Duplicate stderr onto stoud
		unless ( open( STDERR, '>&STDOUT') )
		{	die "Cannot dup stderr to stdout in child at ";
		}
		#Explicitly invoke the same perl we are running, instead
		#of relying on the shebang in $SBALANCE, which might be
		#different
		eval { exec $^X, $SBALANCE, @args; };
		#We only reach here if exec raised an exception
		warn "$@" if $@;
		exit $chd_excode;
	}
}
	

sub check_sbalance_results($$$)
#Test that we got the expected results from sbalance
#$results should be a list ref
#$expected can be list ref or string (which will be converted to list ref)
#Returns false if results match, else a (true) error message
{       my $results = shift || [];
        my $expected = shift || [];
        my $name = shift || 'check_sbalance_results';

	unless ( $expected && ref($expected) eq 'ARRAY' )
	{	$expected = [ split /\n/, $expected ];
	}

	my $maxlines = scalar(@$results);
	$maxlines = scalar(@$expected) if scalar(@$expected) > $maxlines;
	
        subtest $name => sub {
                plan tests => $maxlines;
		foreach my $i ( 1 .. $maxlines )
		{	my $got = $results->[$i-1];
			my $exp = $expected->[$i-1];
			chomp $got if $got;
			chomp $exp if $exp;

			is($got, $exp, "${name} [comparing line $i of output]");
		}
        };
        $num_tests_run++;
}


my ($rec, $name, @args);
my ($results, $expected);

#---------------------------------------------------------
#	Make sure version of sbalance agrees with Slurm::Sshare
#---------------------------------------------------------

$results = get_sbalance_results('--sshare-alternate-path' => $SSHARE, '--version');

my $sbalver = $results->[0];
$sbalver =~ s/^.*version //;
my $ssharev  = $results->[2];
$ssharev =~ s/^.*version //;
is( $sbalver, $ssharev, "sbalance and Slurm::Share versions agree");
$num_tests_run++;

#---------------------------------------------------------
#	Tests on sbalance
#---------------------------------------------------------

my @slurm_versions = ( '14', '15.08.2' );

my $count = scalar(@::sbalance_tests);

foreach my $vers ( @slurm_versions )
{   #Tell fake_sshare what version to emulate
    $ENV{FAKESSHARE_EMULATE_VERSION} = $vers;
    my $vstr = "(emulating $vers)";

    foreach $rec ( @::sbalance_tests )
    {	($name, $expected, @args) = @$rec;
	$results = get_sbalance_results('--sshare-alternate-path' => $SSHARE, @args);
	$name = "$name $vstr";
	check_sbalance_results($results, $expected, $name);
    }
}

#---------------------------------------------------------
#	Finish
#---------------------------------------------------------


done_testing($num_tests_run);


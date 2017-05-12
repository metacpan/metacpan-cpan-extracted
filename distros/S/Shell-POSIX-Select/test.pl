#! /usr/bin/perl
# test.pl


#########################################################
#  tim@TeachMePerl.com  (888) DOC-PERL  (888) DOC-UNIX  #
#  Copyright 2002-2003, Tim Maher. All Rights Reserved  #
#########################################################

sub get_T_files { return grep 1, get_R_files(); }

sub get_R_files {
	chdir 'Test_Progs' or die "$0: Cannot cd to Test_Progs, $!";
	@list=grep { -f and ! /^\.|\.bak$|dump$|_ref$|bogus$/ } <*>;
	chdir( updir() ) or die "Cannot cd to updir, $!";
#	print "R-files Returning @list";
	return @list;
}


# test.pl for
#	Shell::POSIX::Select 

# Tim Maher, tim@teachmeperl.com
# Sun May  4 00:30:52 PDT 2003
# Mon May  5 18:40:33 PDT 2003

use File::Spec::Functions;
use Test::Simple tests => 19 ;

# Was using Test::More, but it always exited at end with 255,
# causing "make test" to look like it failed

# two extra for the use/require_ok() tests

# NOTE: Reference-data generation is triggered through an ENV var

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'


BEGIN {
	$VERSION='0.05';

	# use Shell::POSIX::Select;	# use-ing modifies file handles, so avoid here
	# require Shell::POSIX::Select;	# modifies file handles if "reference" set
	# Was only require-ing module to get VERSION number; decided to hard-code

	$DEBUG = 4; 	# Should only be set >2 on UNIX-like OS
	$DEBUG = 1; 	# Should only be set >2 on UNIX-like OS
	$DEBUG = 0; 

	print "\tShell::POSIX::Select v$VERSION Test Script\n";
	$SCREENS = 1;	 # NOTE: Only 0 and 1 allowed, due to $num_tests
	$SCREENS = 0;	 # NOTE: Only 0 and 1 allowed, due to $num_tests

#	sub get_R_files;	# Advance declarations; did not work!
#	sub get_T_files;

	$author='yumpy@cpan.org' ;
	# must tell it where to find module, before it's installed
	unshift @INC, 'blib/lib', 'blib/arch' ;	# needed for my pre-distro testing

	$test_compile = 1;	# fails due to control-char "placeholders" in source
	$test_compile = 0;

	$ref_dir='Ref_Data';
	$cbugs_dir='Compile_Bugs';
	$rbugs_dir='Run_Bugs';
	$test_dir='Test_Progs';

	# @Testdirs=( $test_dir, $ref_dir, $cbugs_dir, $rbugs_dir );
	@testfiles=get_R_files();

	# restrict to one file, if testing the testing script
	#	$DEBUG > 2 and @testfiles = $testfiles[0];
	# @testfiles = 'arrayvar';	# FOR TESTING ONLY

	chomp @testfiles;
	
	if (! -d $ref_dir or ! -r _ or ! -w _ or ! -x _ ) {
		mkdir $ref_dir or chmod 0755, $ref_dir or
				die "$0: Failed to make $ref_dir\n";
	}
}	# end BEGIN


# MAKE THE REFERENCE FILES?

if (
	$ENV{Shell_POSIX_Select_reference}
) {
	# This branch is only run by author, so it can be UNIX/Linux-specific
	print "\nMAKING REFERENCE DATA\n";
	`uname -n` eq "guru\n"  or
		die "Hey! Generating reference data is the author's domain\n";
	
	$ENV{PERL5LIB}="/Select";	# needed for test programs
	# system 'echo PERL5LIB is: $PERL5LIB'; 
	# system 'show_pmod_locus Shell::POSIX::Select'; 
	# $? and die "$0: Couldn't locate module\n";
	# system "/local/timbin/show_pmod_version Shell::POSIX::Select\n";
	system "rm -f $ref_dir/*" ;

	# create source-code and screen-dump reference databases
	# If module generates same data on user's platform, test passes

	$counter=0;
	foreach (@testfiles) {
		++$counter;
		print STDERR "$counter $_\n";
		# Need screen names for all cases, even if $SCREENS
		$screen="$_.sdump" ;
		$screenR=catfile ($ref_dir, "${screen}_ref");
		$code="$_.cdump" ;
		$codeR=catfile ($ref_dir, "${code}_ref");

		$ENV{Shell_POSIX_Select_testmode}='make' ;
		$ENV{Shell_POSIX_Select_reference}=1 ;
		# Or maybe just eval the code?
		$script = catfile( 'Test_Progs', $_ );
		system "set -x ; perl '$script'" ;
		$err=$?>>8;
		# print "\t\t\t$script yielded $err\n";
		if (!$SCREENS) {
			unlink $screenR;	# don't distribute!
		}
		else {
			! -f $screenR and die "Sdump missing!";
		}
		if ( $err and $err ne 222 ) {	# code 222 is good exit
			warn "$0: Reference code-dump of $_ failed with code $err\n";
			system "ls -ld '$script' $codeR";
			$DEBUG >2 and system "ls -ld $script $codeR";
			$DEBUG > 2 and $SCREENS and system "ls -ld '$script' screenR";
			chmod 0644, $script; 	# just eliminate it from testing
			die "$0: Fatal Error\n";
		}
		elsif ($SCREENS) {
			$error=`egrep 'syntax | aborted|illegal ' $screenR
			`;
			$err = $?>>8;
			if ( ! $err ) {
				die "$0: Compilation failed, code $err, for '$screenR'\n\n$error\n";
				chmod 0644, $script; 
			}
			else {
				chmod 0755, $script; 
			}
		}

		# Screen file can be empty, so just check existence and perms
		if ($SCREENS) {
			check_file ($screenR) or die "$screenR is bad\n";
		}
		
		check_file ($codeR) and -s $codeR or die "$codeR is bad\n" ;
		if ( $test_compile ) {
			system "perl -wc '$codeR' 2>/tmp/$_.diag" ;
			if ($?) {
				print STDERR "$0: Reference code-dump of $_ ",
				print STDERR "failed to compile, code $?\n";
				$DEBUG >2 and system "ls -ld $_ $codeR $screenR";
				die "$0: Compilation test for $codeR failed\n";
			}
		}
		$DEBUG >2 and system "ls -l $codeR";
		$DEBUG >2 and $SCREENS and system "ls -l $screenR";
	}
	$ENV{Shell_POSIX_Select_reference} = undef;
	print "\n\n";
	# exit 0;
}

print "TESTING GENERATED CODE AGAINST REFERENCE DATA\n\n";

$ENV{PERL5LIB}="blib/lib:blib/arch:$PERL5LIB";	# needed for test programs

# Configure ENV vars so module dumps the required data
$ENV{Shell_POSIX_Select_reference}="";
$ENV{Shell_POSIX_Select_testmode}='make' ;

@testfiles = get_T_files();
$num_tests = @testfiles;

$DEBUG and
	warn "There are $num_tests test scripts, and 2 tests on each\n";

# Always shows FALSE exit code, after last test, unlike Test::Simple!
# plan tests => ( $num_tests * ($SCREENS + 1) )  + 2;

#use_ok('Shell::POSIX::Select') or
#	die "$0: Cannot load module under test\n";
#require_ok('Shell::POSIX::Select');

foreach (@testfiles) {
	$DEBUG and warn "\nDumping data for $_\n";
	if ($SCREENS) {
		$screen="$_.sdump" ;
		$screenR=catfile ($ref_dir, "${screen}_ref");
	}
	$code="$_.cdump" ;
	$codeR=catfile ($ref_dir, "${code}_ref");

	unless ( -f $codeR ) { 
			warn "$0: Reference file $codeR is missing; skipping\n";
			next;
	}
	$script = catfile( 'Test_Progs', $_ );
	# Later on, insert check for "*bogus" scripts to return error
	system "perl '$script'" ;
	$err=$?>>8;
	# print "\t\t\t$script yielded $err\n";

	$DEBUG >2 and system "echo; ls -rlt . | tail -4 ";
	if ( $err ) { $DEBUG and warn "Module returned $? for $_, $!"; }
	if ( ! -e $code  or  ! -f _  or  ! -r _  or  ! -s _ ) {
		warn "$code is bad\n";
		# system "ls -ld '$code'";
		next;
	}
	elsif ( $SCREENS and ( ! -e $screen or ! -f _ or ! -r _) ) {	# empty could be legit
		warn "Screen dump for $_ failed: $!\n";
		# Keep the evidence for investigation
		next;
	}
	# Do cheap file-size comp first; string comparison later if needed
	if (-s $code != -s $codeR) {
		warn "\t** Code dumps unequally sized for $_: ",
			-s $code,  " vs. ", -s $codeR, "\n";
		push @email_list,  "$code\n", "$codeR\n"; 
		$DEBUG >2 and system "ls -li $code $codeR";
		# fail ($code);	# force test to report failure
	}
	if ($SCREENS and -s $screen != -s $screenR) {
		warn "\t** Screen dumps unequally sized for $_: ",
			-s $screen,  " vs. ", -s $screenR, "\n";
		push @email_list,  "$screen\n", "$screenR\n"; 
		$DEBUG >2 and system "ls -li $screen $screenR";
		fail ($screen);	# force tests to report failure
	}
	else {
		# Files don't obviously differ, so next step is to compare bytes
		open C,		"$code"    or die "$0: Failed to open ${code}, $!\n";
		open C_REF,	"$codeR"   or die "$0: Failed to open ${code}_ref, $!\n";
		if ($SCREENS) {
			open S,		"$screen"  or die "$0: Failed to open ${screen}, $!\n";
			open S_REF, "$screenR" or die "$0: Failed to open ${screen}_ref, $!\n";
		}

		undef $/;	# file-slurping mode
		defined ($NEW=<C>) or die "$0: Failed to read $code, $!\n";
		defined ($REF=<C_REF>) or die "$0: Failed to read $codeR, $!\n";

		# if ($_ =~ /bug$/) { warn "BUG FILE: $_\n"; }

		$ret = ok ($NEW eq $REF, $code);  # logical and doesn't work!
		$DEBUG > 0 and system ( "ls -ld $code $codeR" ) ;
		$ret or warn "Check $code for clues\n";
		$ret and !$DEBUG and unlink $code;

		if ($SCREENS) {
			defined ($NEW=<S>) or die "$0: Failed to read $screen, $!\n";
			defined ($REF=<S_REF>) or die "$0: Failed to read $screenR, $!\n";

			$ret = ok ($NEW eq $REF, $screen);
			$DEBUG > 0 and system ( "ls -ld $screen $screenR" ) ;
			$ret or warn "Check $screen for clues\n" and exit;
			$ret and !$DEBUG and unlink $screen;
		}
	}
}
@email_list and  do {
	warn "\n** Please email the following files to $author **\n\n", @email_list;
	warn "\n** Please email the above files to $author **\n";
};

warn "Test Finished\n";
exit 0;

sub check_file {
	my $file=shift || die "check_file: No argument supplied\n";

	unless (-e $file and -f _ and -r _ ) {
		warn "$0: Reference file $codeR is bad\n"; return 0;
	}
	else { return 1; }
}

# vi:sw=2 ts=2:

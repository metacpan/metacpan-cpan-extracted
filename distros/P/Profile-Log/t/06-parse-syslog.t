#!/usr/bin/perl -w

BEGIN {
    *Profile::Log::time = sub {
	1111275599;
    };
}

use strict;
use I18N::Langinfo qw(langinfo ABMON_1 ABMON_2);
use Profile::Log;

my $real_jan = langinfo(ABMON_1);
my $real_feb = langinfo(ABMON_2);

my (@input, @expected);
while ( <DATA> ) {
    chomp;
    if ( m/INPUT/ .. m/^\s*$/ ) {
	next unless m/^XX/;
	s/XXX/$real_jan/;
	s/XX2/$real_feb/;
	push @input, $_;
    }
    if ( m/EXPECTED/ .. m/^\s*$/ ) {
	next unless m/=/;
	push @expected, $_;
    }
}

use Test::More;
plan tests => ( scalar( map { split /; / } @expected )
		+ @input * 2 );

my $year = (localtime(&Profile::Log::time))[5];
my %map = qw(y 5 m 4 d 3 H 2 M 1 S 0);
my %desc = qw(y year m month d day H hour M minute S second);

for ( my $i = 0; $i <= $#input; $i ++ ) {

    my @tests = split /; /, $expected[$i];

    my $profile = Profile::Log->new_from_syslog($input[$i]);
 SKIP:{
    isa_ok($profile, "Profile::Log", "parse - $input[$i]")
	or skip "failed to parse", scalar(@tests);
    #diag("Profile: ".$profile->logline);

    my ($time_t) = $profile->zero_t;
    my ($end_t) = $profile->end_t;
    cmp_ok($time_t, "<=", $end_t, "begins before it ends");

    my @localtime = localtime($time_t);
    for ( @tests ) {
	my ($what, $value) = split /=/;
	if ( $what eq "y" ) {
	    $value = $year + $value;
	}
	is($localtime[$map{$what}], $value, $desc{$what});
    }
}

}


__DATA__

INPUT:
XXX  1 12:34:45 myhost myproc: 0=12:32:40.000; tot=0.500; Z=0.500
XXX 12 12:34:45 myhost myproc: 0=12:34:45.000; tot=0.500; Z=0.500
# test yesterday
XXX 12 12:34:45 myhost myproc: 0=12:34:46.000; tot=0.500; Z=0.500
# test last month
XX2  1 12:34:45 myhost myproc: 0=12:32:46.000; tot=0.500; Z=0.500
XX2  1 12:34:45 myhost myproc: 0=12:34:46.000; tot=0.500; Z=0.500
# test last year
XXX  1 12:34:45 myhost myproc: 0=12:32:46.000; tot=0.500; Z=0.500
XXX  1 12:34:45 myhost myproc: 0=12:34:46.000; tot=0.500; Z=0.500

EXPECTED:
y=0; m=0; d=1; H=12; M=32; S=40
y=0; m=0; d=12; H=12; M=34; S=45
y=0; m=0; d=11; H=12; M=34; S=46
y=0; m=1; d=1; H=12; M=32; S=46
y=0; m=0; d=31; H=12; M=34; S=46
y=0; m=0; d=1; H=12; M=32; S=46
y=-1; m=11; d=31; H=12; M=34; S=46

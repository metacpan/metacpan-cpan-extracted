#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use JSON::XS qw/decode_json/;
use Pod::Usage;
use Schedule::Easing;

# todo:  expiration (need to verify this works)
# todo:  check (need a way to set the exit status on warnings, probably _failExpired versus _warnExpired)

#        (these likely all belong in Schedule::Easing::Stream)
#
# todo:  stream batching (performance)
# todo:  reduce the number of calls to time(), maybe via alarm()?
#        timecheck=lines,##,sleep,##,clock,##,regexp,string
#        where lines=## would update the time every ## lines
#        where sleep=## if there is no input, wait ##sec before checking (might block fifo) (but will be interrupted by clock/alarm())
#        where clock=## uses alarm(##) to uptime the time every ## seconds
#        where regexp=string would use the pattern to get the time from the lines (but this requires epoch time)
# todo:  support historical checking, pulling the timestamp from the line itself

sub load {
	my ($fn)=@_;
	my $t;
	if(!-e $fn) { die "No such file:  $fn" }
	open(my $fh,'<',$fn) or die "Unable to read configuration from $fn:  $@";
	{local($/); $t=<$fh>};
	close($fh);
	return $t;
}

sub loadeval {
	my ($fn)=@_;
	my $t=load($fn);
	$t=~s/^\s*[^@$][A-Za-z_]\w+\s*=\s*//s;
	my @res;
	if($t=~/^[(]/)     { eval "\@res=$t;";       if($@) { die "$@" } } # )
	elsif($t=~/^[\[]/) { eval "\@res=\@{ $t };"; if($@) { die "$@" } } # )
	else               { die "$fn does not contain a valid configuration" }
	return @res;
}

sub loadjson {
	my ($fn)=@_;
	my $t=load($fn);
	my @res=@{ decode_json($t) };
	foreach my $E (@res) { $$E{match}//=''; $$E{match}=qr/$$E{match}/ }
	return @res;
}

my %opt=(
	schedule  =>undef,
	json      =>undef,
	timestamps=>0,
	expiration=>0,
	check     =>0,
	help      =>0,
	time      =>undef,
);

GetOptions(
	'schedule=s'=>\$opt{schedule},
	'json=s'    =>\$opt{json},
	'timestamps'=>\$opt{expiration},
	'expiration'=>\$opt{expiration},
	'check'     =>\$opt{check},
	'help'      =>\$opt{help},
	'time=i'    =>\$opt{time},    # undocumented
);
if($opt{help}) { pod2usage(-verbose=>2,-exitval=>2) }

if($opt{expiration}) { die 'expiration not yet supported' }
if($opt{check})      { die 'check not yet supported' }

my @schedule=
	$opt{schedule} ? loadeval($opt{schedule}) :
	$opt{json}     ? loadjson($opt{json}) :
	die 'Configuration is required';

# Needs updated to support stream options.

my $easing=Schedule::Easing->new(
	warnExpired=>$opt{expiration},
	schedule=>\@schedule,
);
if(!$easing) { exit(1) }

while(<>) {
	if($opt{timestamps}) { foreach my $sched ($easing->schedule(events=>[$_])) {
		# UNTESTED
		$$sched[0]//=9999999999;
		print "$$sched[0] $_\n";
	} }
	else {
		print $easing->matches(ts=>$opt{time},events=>[$_]);
	}
}

__END__

=pod

=head1 NAME

schedule-easing.pl - Filter messages based on a schedule.

=head1 SYNOPSIS

	schedule-easing.pl [options] [--schedule=file | --json=file] [file ...]
	
	options:
		--timestamps:  (not yet available) for every event, compute the timestamp it would become active
		               (epoch seconds, or 0="always", or 9999999999="never")
		--expiration:  warn on startup if schedule entries have expired (default=false)
		               (currently 0/1, but may support flagged options in the future)
		--check:       verify the schedule configuration, non-zero exit on any warnings
		--help
	
	The format of the scheduling file is described in Schedule::Easing.

=cut

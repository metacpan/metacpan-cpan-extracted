#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use JSON::XS qw/decode_json/;
use Pod::Usage;
use Schedule::Easing;
use Schedule::Easing::Stream;

# todo:  replay mode, historical checking, pulling the timestamp from the line itself?

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
	stream    =>'lines=>1',
	help      =>0,
	time      =>undef,
);

GetOptions(
	'schedule=s'=>\$opt{schedule},
	'json=s'    =>\$opt{json},
	'timestamps'=>\$opt{timestamps},
	'expiration'=>\$opt{expiration},
	'check'     =>\$opt{check},
	'stream=s'  =>\$opt{stream},
	'help'      =>\$opt{help},
	'time=i'    =>\$opt{time},    # undocumented
);
if($opt{help}) { pod2usage(-verbose=>2,-exitval=>2) }

my @schedule=
	$opt{schedule} ? loadeval($opt{schedule}) :
	$opt{json}     ? loadjson($opt{json}) :
	die 'Configuration is required';

my $easing=Schedule::Easing->new(
	schedule=>\@schedule,
	warnExpired=>$opt{expiration}||$opt{check},
);
if(!$easing)    { exit(1) }
if($opt{check}) { exit(0+!!$$easing{_err}) }

my ($inputcb,$updatecb,%streamopt);
eval "\%streamopt=($opt{stream});";
if($@) { die "Stream options error:  $@" }

if($opt{timestamps}) {
	$inputcb=sub {
		foreach my $sched ($easing->schedule(events=>[@_])) {
			$$sched[0]//=9999999999; print join(' ',@$sched); } };
	$updatecb=undef;
}
else {
	my $currentts;
	$inputcb=sub { print $easing->matches(ts=>$currentts,events=>[@_]) };
	if($opt{time}) { $currentts=$opt{time}; $updatecb=undef }
	else { $updatecb=sub { $currentts=time() } }
}

my $stream=Schedule::Easing::Stream->new(fh=>\*STDIN,input=>$inputcb,update=>$updatecb,%streamopt);
$stream->read();


__END__

=pod

=head1 NAME

schedule-easing.pl - Filter messages based on a schedule.

=head1 SYNOPSIS

	schedule-easing.pl [options] [--schedule=file | --json=file] [file ...]
	
	options:
		--timestamps:  for every event, compute the timestamp it would become active
		               (epoch seconds, or 0="always", or 9999999999="never")
		--expiration:  warn on startup if schedule entries have expired (default=false)
		               (currently 0/1, but may support flagged options in the future)
		--check:       verify the schedule configuration, non-zero exit on any warnings
		--stream:      stream options as a Perl hash declaration:
		               "sleep=>N,clock=>N,batch=>N,lines=>N,regexp=>qr/.../"
		--help
	
	The format of the scheduling file is described in Schedule::Easing.

=cut

#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use JSON::XS qw/decode_json/;
use Pod::Usage;
use Schedule::Activity;

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
	my %res;
	if($t=~/^[(]/)    { eval "\%res=$t;";       if($@) { die "$@" } } # )
	elsif($t=~/^[{]/) { eval "\%res=\%{ $t };"; if($@) { die "$@" } } # }
	else              { die "$fn does not contain a valid configuration" }
	return %res;
}

sub loadjson {
	my ($fn)=@_;
	my $t=load($fn);
	my %res=%{ decode_json($t) };
	return %res;
}

my %opt=(
	schedule  =>undef,
	json      =>undef,
	unsafe    =>undef,
	check     =>undef,
	help      =>0,
	activity  =>[],
	activities=>undef,
	tslack    =>undef,
	tbuffer   =>undef,
);

GetOptions(
	'schedule=s'  =>\$opt{schedule},
	'json=s'      =>\$opt{json},
	'check'       =>\$opt{check},
	'unsafe!'     =>\$opt{unsafe},
	'activity=s'  =>\@{$opt{activity}},
	'activities=s'=>\$opt{activities},
	'tslack=f'    =>\$opt{tslack},
	'tbuffer=f'   =>\$opt{tbuffer},
	'help'        =>\$opt{help},
);
if($opt{help}) { pod2usage(-verbose=>2,-exitval=>2) }

my %configuration=
	$opt{schedule} ? loadeval($opt{schedule}) :
	$opt{json}     ? loadjson($opt{json}) :
	die 'Configuration is required';

my $scheduler=Schedule::Activity->new(unsafe=>$opt{unsafe},configuration=>\%configuration);
my %check=$scheduler->compile();
if($opt{check}) {
	if($check{error}) { print STDERR join("\n",@{$check{error}}),"\n"; exit(@{$check{error}}?1:0) }
	exit(0);
}

if($opt{activities}) { foreach my $pair (split(/;/,$opt{activities})) { push @{$opt{activity}},$pair } }
if(!@{$opt{activity}}) { die 'Activities are required' }
for(my $i=0;$i<=$#{$opt{activity}};$i++) { $opt{activity}[$i]=[split(/,/,$opt{activity}[$i],2)] }

my %schedule=$scheduler->schedule(activities=>$opt{activity},tensionslack=>$opt{tslack},tensionbuffer=>$opt{tbuffer});
if($schedule{error}) { print STDERR join("\n",@{$schedule{error}}),"\n"; exit(1) }

my @materialized;
foreach my $entry (@{$schedule{activities}}) {
	my $tm=int(0.5+$$entry[0]);
	if($$entry[1]{message}) {
		push @materialized,[
			sprintf('%02d:%02d:%02d'
				,int($tm/3600)
				,int(($tm%3600)/60)
				,($tm%60))
			,$$entry[1]{message}
		];
	}
}
foreach my $entry (@materialized) { print join(' ',@$entry),"\n" }


__END__

=pod

=head1 NAME

schedule-activity.pl - Build activity schedules.

=head1 SYNOPSIS

  schedule-activity.pl [options] configuration activities

    configuration:  [--schedule=file | --json=file]
    activities:     [--activity=time,name ... | --activities='time,name;time,name;...']

  options:
    --check=0/1:      compile the schedule and report any errors
    --unsafe=0/1:     skip safety checks (cycles, non-termination, etc.)
    --tslack=[0,1]:   slack tension from 0.0 to 1.0
    --tbuffer=[0,1]:  buffer tension from 0.0 to 1.0
    --help

  The format of the schedule configuration is described in Schedule::Activity.
  Annotations are not part of the output in this version.

=cut

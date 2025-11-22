#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
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
	$t=~s/^\s*[\%\$]?[A-Za-z_]\w+\s*=\s*//s;
	my %res;
	if($t=~/^[(]/)    { eval "\%res=$t;";       if($@) { die "$@" } } # )
	elsif($t=~/^[{]/) { eval "\%res=\%{ $t };"; if($@) { die "$@" } } # }
	else              { die "$fn does not contain a valid configuration" }
	return %res;
}

sub loadafter {
	my ($fn)=@_;
	my $t=load($fn);
	my $previous;
	eval $t;
	if($@) { die "Loading after file failed:  $@" }
	return %$previous;
}

sub saveafter {
	my ($fn,$config,$schedule)=@_;
	open(my $fh,'>',$fn);
	print $fh Data::Dumper->new([{configuration=>$config,schedule=>$schedule}],['previous'])->Indent(0)->Purity(1)->Dump();
	close($fh);
}

sub loadjson {
	my ($fn)=@_;
	my $t=load($fn);
	my %res=%{ decode_json($t) };
	return %res;
}

sub materialize {
	my (%schedule)=@_;
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
}

sub attrgrid {
	my (%schedule)=@_;
	my $tmmax=$schedule{_tmmax};
	my $tmstep=int(0.5+$tmmax/10);
	print "\n";
	for(my $tm=0;$tm<=$tmmax;$tm+=$tmstep) { print "$tm\t" }; print "avg\tAttribute\n";
	foreach my $name (sort keys %{$schedule{attributes}}) {
		my $attr=$schedule{attributes}{$name}{xy};
		my ($i,$y)=(-1);
		for(my $tm=0;$tm<=$tmmax;$tm+=$tmstep) {
			while(($i<$#$attr)&&($tm>=$$attr[$i+1][0])) { $i++ }
			if($i<0)           { $y=0 }
			elsif($i>=$#$attr) { $y=$$attr[$i][1] }
			elsif($i==0)       { $y=$$attr[0][1] }
			else {
				my $p=($tm-$$attr[$i][0])/($$attr[$i+1][0]-$$attr[$i][0]);
				$y=(1-$p)*$$attr[$i][1]+$p*$$attr[$i+1][1];
			}
			print sprintf("%0.4g\t",$y);
		}
		print sprintf('%0.4g',$schedule{attributes}{$name}{avg}//0),"\t$name\n";
	}
}

my %opt=(
	schedule  =>undef,
	json      =>undef,
	unsafe    =>undef,
	check     =>undef,
	help      =>0,
	manpage   =>0,
	activity  =>[],
	activities=>undef,
	notemerge =>1,
	noteorder =>undef,
	attribute =>'',
	tslack    =>undef,
	tbuffer   =>undef,
	after     =>undef,
	save      =>undef,
);

GetOptions(
	'schedule=s'  =>\$opt{schedule},
	'json=s'      =>\$opt{json},
	'check'       =>\$opt{check},
	'unsafe!'     =>\$opt{unsafe},
	'activity=s'  =>\@{$opt{activity}},
	'activities=s'=>\$opt{activities},
	'notemerge!'  =>\$opt{notemerge},
	'noteorder=s' =>\$opt{noteorder},
	'attribute=s' =>\$opt{attribute},
	'tslack=f'    =>\$opt{tslack},
	'tbuffer=f'   =>\$opt{tbuffer},
	'after=s'     =>\$opt{after},
	'save=s'      =>\$opt{save},
	'help'        =>\$opt{help},
	'man'         =>\$opt{man},
);
if($opt{man})  { pod2usage(-verbose=>2,-exitval=>2) }
if($opt{help}) { pod2usage(-verbose=>1,-exitval=>2) }

my (%configuration,%after);
if($opt{after}) {
	%after=loadafter($opt{after});
	%configuration=%{$after{configuration}};
	%after=(after=>$after{schedule});
}
else { %configuration=
	$opt{schedule} ? loadeval($opt{schedule}) :
	$opt{json}     ? loadjson($opt{json}) :
	die 'Configuration is required';
}

my $scheduler=Schedule::Activity->new(unsafe=>$opt{unsafe},configuration=>\%configuration);
my %check=$scheduler->compile();
if($opt{check}) {
	if($check{error}) { print STDERR join("\n",@{$check{error}}),"\n"; exit(@{$check{error}}?1:0) }
	exit(0);
}

if($opt{activities}) { foreach my $pair (split(/;/,$opt{activities})) { push @{$opt{activity}},$pair } }
if(!@{$opt{activity}}&&!$opt{after}) { die 'Activities are required' }
for(my $i=0;$i<=$#{$opt{activity}};$i++) { $opt{activity}[$i]=[split(/,/,$opt{activity}[$i],2)] }

my %schedule=$scheduler->schedule(%after,activities=>$opt{activity},tensionslack=>$opt{tslack},tensionbuffer=>$opt{tbuffer});
if($schedule{error}) { print STDERR join("\n",@{$schedule{error}}),"\n"; exit(1) }

# Workaround.  Until other options are available, annotations canNOT be
# materialized into the activity schedule.  Such nodes are unexpected
# during subsequent annotation runs, and will need to be stashed/restored
# if we want to support saving annotations incrementally.
if($opt{save}) { saveafter($opt{save},\%configuration,\%schedule) }

if($opt{notemerge}) {
	my %seen;
	my @order;
	if($opt{noteorder}) { @order=split(/;/,$opt{noteorder}) }
	else                { @order=sort {$a cmp $b} keys(%{$schedule{annotations}}) }
	foreach my $group (@order) {
		if($seen{$group}) { next }
		if(!defined($schedule{annotations}{$group})) { next }
		push @{$schedule{activities}},@{$schedule{annotations}{$group}{events}};
		$seen{$group}=1;
	}
	if(%seen) {
		@{$schedule{activities}}=sort {$$a[0]<=>$$b[0]} @{$schedule{activities}};
		%{$schedule{attributes}}=$scheduler->computeAttributes(@{$schedule{activities}});
	}
}

materialize(%schedule);

if($opt{attribute} eq 'grid') { attrgrid(%schedule) }

__END__

=pod

=head1 NAME

schedule-activity.pl - Build activity schedules.

=head1 SYNOPSIS

  schedule-activity.pl [options] configuration activities

    configuration:  [--schedule=file | --json=file]
    activities:     [--activity=time,name ... | --activities='time,name;time,name;...']

The C<--schedule> file should be a non-cyclic Perl evaluable hash or hash reference.  A C<--json> file should be a hash reference.  The format of the schedule configuration is described in L<Schedule::Activity>.

=head1 OPTIONS

=head2 --check

Compile the schedule and report any errors.

=head2 --tslack=I<number> and --tbuffer=I<number>

Set the slack or buffer tension.  Values should be from 0.0 to 1.0.

=head2 --noteorder=name;name;...

Only merge the annotation groups specified by the names.  Default is all, alphabetical.

=head2 --nonotemerge

Do not merge annotation messages into the final schedule.

=head2 --attribute=grid

Display all attributes, their values over time, and averages.  (No other output formats are supported at this time)

=head2 --unsafe

Skip safety checks, allowing the schedule to contain cycles, non-terminating nodes, etcetera.  Useful during debugging and development.

=head2 --after and --save

Run with C<--man> or C<perldoc schedule-activity.pl> for details on these options.

=head1 INCREMENTAL BUILDS

Schedules can be incrementally constructed from a starting configuration as follows:

  schedule-activity.pl --schedule=config.dump --activity=time,name --save=file1a.dat
  schedule-activity.pl --after=file1a.dat --activity=time,name --save=file2a.dat
  schedule-activity.pl --after=file2a.dat --nonotemerge

The C<schedule> must be provided initially, and the C<activity> or C<activities> will be built into the list of scheduled activities normally.  Results are stored in the C<save> filename.  Use C<after> to specify a savefile as a starting point for scheduling.  As a special case, omitting an C<activity> list is permitted with an C<after> file, and the saved schedule will be shown on stdout.  The configuration does not need to be indicated after the bootstrapping step.

This permits buliding multiple, randomized schedules from the configuration into separate files for comparison and selection.  Subsequent activities can be built incrementally to achieve targets not specified within the configuration (attribute goals, etc.).

At each step, the schedule is output normally, including annotations unless C<nonotemerge> has been specified.

Annotations are I<not> saved.  Annotations apply generally to all actions in a schedule, so incremental builds are not equivalent to a full schedule build.  While the annotations are shown with the output at each stage of construction, they are recomputed each time.

=head1 NOTES

Unhandled failures in C<Schedule::Activity> are not trapped.  This script may die, and may run unbounded if the schedule contains infinite cycles.

=cut

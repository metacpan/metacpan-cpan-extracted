#!/bin/perl -w

#		Create an events calendar
#
#	events_calendar.pl -mon month -yr year <-reg \@reg> <-spec \@spec>
#
#	To run this as a test demo, type :
#	events_calendar.pl  -mon 7 -yr 1999 -reg y -spec y > events.html
#
#
#			Alan Jackson 3/99

BEGIN {
	push (@INC, '/home/ajackson/bin/lib'); # include my personal modules
}

use strict;
use POSIX;

require PlotCalendar::Month;
require PlotCalendar::DateDesc;

#-------- Read arguments

sub usage { "Usage: $0 -mon <month, 1-12> -yr <4 digit year> <-reg y/n regular events?> <-spec y/n special events?>  \n" }

$0 =~ s!^.*/!!;
die usage unless @ARGV;

my %args = @ARGV;
my ($mon,$yr,$reg,$spec) = ('1','1999','','');

$mon = $args{"-mon"};
$yr = $args{"-yr"};
$reg = $args{"-reg"};
$spec = $args{"-spec"};

@ARGV = ();

#-------- set calendar parameters

my $month = PlotCalendar::Month->new($mon, $yr);

#	 These are values with default settings, so these are optional

# global values, to be applied to all cells

$month -> size(700,700); # height, width in pixels
$month -> font('14','10','8');
$month -> cliptext('no');
$month -> firstday('Mon'); # First column is Monday

my @text;
my @daynames;
my @bgcolor;
my @fgcolor;
my @textcolor;
my @textstyle;
my %regdates;
my %regcal;


#	read in regular events file, and convert day descriptors to dates
if ( $reg eq 'y') {
	 open (REG,"<regular_calendar") || die "Can't open regular_calendar, $!\n";
	 my @regcal = <REG>;
	 close REG;
			 # build hash of descriptors pointing to array pointers of dates
	 my $trans = PlotCalendar::DateDesc->new($mon, $yr);
	 my $desc;
	 foreach (@regcal) {
		 if (!/^%/) { # must be an event
			 push @{$regcal{$desc}},$_;
		 }
		 else { # must be a date description
			  s/^%//;
			  chomp;
			  $desc = $_;
			  my $dates = $trans->getdom($_); # return days-of-month
			  $regdates{$_} = $dates;
		  }
	 }
}
#------------ walk through days of month to build arrays for month routine.

for (my $i=1;$i<=31;$i++) {
  $bgcolor[$i] = 'WHITE';
  $fgcolor[$i] = 'BLACK';
  $daynames[$i] = '';
}
#		a kludge, this could be done *much* better - and has 8-)
if ($mon == 1) {$daynames[1]="New Year's Day";$bgcolor[1]='YELLOW';}
if ($mon == 7) {$daynames[4]="Independence Day";$bgcolor[4]='YELLOW';}
if ($mon == 12) {$daynames[25]="Christmas Day";$bgcolor[25]='YELLOW';}
#------------------- regular events
if ($reg eq 'y') {
  foreach my $desc (keys %regcal) {
	  my $doms = $regdates{$desc};
	  my @txt = @{$regcal{$desc}};
	  foreach my $dom (@{$doms}) {
		  push @{$text[$dom]},@txt;
		  push @{$textcolor[$dom]},('BLUE') x scalar(@txt);
		  push @{$textstyle[$dom]},('n') x scalar(@txt);
	  }
  }
}

#	read in special events file, and put onto calendar
if ( $spec eq 'y') {
	 open (SPEC,"<special_calendar") || die "Can't open special_calendar, $!\n";
	 my @specal = <SPEC>;
	 close SPEC;
			 # loop through file, select dates in current month, and add to text
	 foreach (@specal) {
	 	my ($date,$event) = split('\t',$_);
		next if $mon != (split('/',$date))[0]; # skip if not this month
		next if $yr != (split('/',$date))[2]; # skip if not this year
		my $dom = (split('/',$date))[1];
		push @{$text[$dom]},$event;
		push @{$textcolor[$dom]},'RED';
		push @{$textstyle[$dom]},'b';
	 }
}

$month -> fgcolor(@fgcolor); 
$month -> bgcolor(@bgcolor);
$month -> dayname(@daynames);
$month -> text(@text);
$month -> textcolor(@textcolor);
$month -> textstyle(@textstyle);

#	go get the html...

my $html = $month -> gethtml;


print $html;


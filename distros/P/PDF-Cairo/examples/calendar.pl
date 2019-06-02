#!/usr/bin/env perl
# create a progressive/gapless calendar, as per
# http://wondermark.com/free-calendar-2019/

use 5.016;
use utf8;
use strict;
use warnings;
use POSIX qw(ceil floor fmin);
use Getopt::Long qw(:config no_ignore_case bundling);
use DateTime;
use PDF::Cairo qw(in);
use PDF::Cairo::Box;

my $opt = {};
get_options($opt);

# TODO: make these configurable
my @weekday = ("white", "darkgray");
my @weekend = ("lightgray", "gray");
my @textcolor = ("black", "white");

my $num_weeks;
if (my ($n,$unit) = $opt->{num_years} =~ /^(\d+)([ymwd])$/) {
	if ($unit eq "y") {
		$num_weeks = ceil($n * 53);
	}elsif ($unit eq "m") {
		$num_weeks = ceil($n * 31 / 7);
	}elsif ($unit eq "d") {
		$num_weeks = ceil($n / 7);
	}else{
		$num_weeks = $n;
	}
}else{
	$num_weeks = ceil($opt->{num_years} * 53);
}
my $columns = $opt->{double} ? 14 : 7;

# set start colors
my $evenodd = 0;

# find January 1st
my $current_day = DateTime->new(year => $opt->{year},
	month => $opt->{start_month}, day => 1, hour => 0, minute => 0,
	second => 1, locale => $opt->{locale});
if ($opt->{current}) {
	my @tmp = localtime();
	$current_day->set(year => 1900 + $tmp[5], month => $tmp[4] + 1);
}
my $current_month = $current_day->month;

# find the start day of the first week
if ($current_day->day_of_week != $opt->{startday}) {
	# start in last week of previous year
	my $diff = $current_day->day_of_week - $opt->{startday};
	if ($diff > 0) {
		$current_day->subtract(days => $diff);
	}else{
		$current_day->subtract(days => 7 + $diff);
	}
}

# find the names of days in the current locale, shifted
# by the current start day
my @day_name = (undef);
my $tmpdate = $current_day->clone;
for my $delta (1..7) {
	if ($opt->{fullnames}) {
		push(@day_name,$tmpdate->day_name);
	}else{
		push(@day_name,$tmpdate->day_abbr);
	}
	$tmpdate->add(days => 1);
}

if (!defined $opt->{outfile}) {
	$opt->{outfile} = "$opt->{year}-$opt->{papersize}";
	$opt->{outfile} .= "-double" if $opt->{double};
	$opt->{outfile} .= "-wide" if $opt->{landscape};
}
$opt->{outfile} .= ".pdf" unless $opt->{outfile} =~ /\.pdf$/;

my $pdf = PDF::Cairo->new(
	paper => $opt->{papersize},
	landscape => $opt->{landscape},
	file => $opt->{outfile},
);

my $paper = $pdf->pagebox;
die "$0: unknown paper size '$opt->{papersize}'\n"
	unless defined $paper;
my $cal = $paper->copy->shrink(all => in($opt->{margin}));

my $font = $pdf->loadfont($opt->{textfont});
my $font_height = $font->ascender(1);

my $header_size = 14;
my $header_height = $font_height * $header_size + 2;

my ($header, $body) = $cal->split(height => $header_height);
my @headers = $header->slice(columns => $columns);

my $cellwidth = $headers[0]->width;
my $rows = floor($body->height / ($cellwidth * $opt->{ratio}));
$rows = 1 if $rows < 1;
my $cellheight = $body->height / $rows;

my $date_size = fmin($cellwidth, $cellheight) / 2.5;
my $text_size = $date_size * 2/3;

# adjust header/text font sizes based on longest day/month name,
# leaving 1 point of space on left and right
if ($opt->{fullnames}) {
	my $width = 0;
	foreach (@day_name) {
		$width = $font->width($_) if $font->width($_) > $width;
	}
	if ($width * $header_size >= $cellwidth - 2) {
		$header_size *= ($cellwidth - 2) / ($width * $header_size);
	}
	my $tmpdate = $current_day->clone;
	$width = 0;
	foreach (1..12) {
		my $name = $tmpdate->month_name;
		$width = $font->width($name) if $font->width($name) > $width;
		$tmpdate->add(months => 1);
	}
	if ($width * $text_size >= $cellwidth - 2) {
		$text_size *= ($cellwidth - 2) / ($width * $text_size);
	}
}

my @rows = $body->grid(columns => $columns, height => $cellheight);

# copy the first cell and use it to calculate the x,y offsets
# of all body text
#
my $cell0 = $rows[0]->[0]->copy->move(0, 0);
my ($day_pos, $rest) = $cell0->split(height => $font_height * $date_size + 2);
$day_pos->shrink(all => 1);

my @text_pos = $rest->slice(height => $font_height * $text_size + 2);

die "$0: cell height too small to print month and year\n"
	unless defined $text_pos[1];

my $month_pos = $text_pos[0]->shrink(all => 1);
my $year_pos = $text_pos[1]->shrink(all => 1);

my $pages = ceil($num_weeks / $rows / ($opt->{double} ? 2 : 1));

if ($opt->{verbose}) {
	my $weeks = $pages * $rows * ($opt->{double} ? 2 : 1);
	my $days = $weeks * 7 -1;
	print "Start ",$current_day->ymd,", End ",
		$current_day->add(days => $days)->ymd,", $pages Pages\n";
	exit 0;
}

foreach my $page (1..$pages) {
	$pdf->newpage if $page > 1;
	$pdf->linewidth(0.25);
	foreach my $r (@rows) {
		my @row = @$r;
		foreach my $i (0..$#row) {
			my $c = $row[$i];
			if ($current_month != $current_day->month) {
				$evenodd = 1 - $evenodd;
				$current_month = $current_day->month;
			}
			cellcolor($pdf, $current_day, $evenodd);
			$pdf->rect($c->x, $c->y, $c->width, $c->height);
			$pdf->fillstroke;
			$pdf->setfont($font, $date_size);
			$pdf->move($c->x + $day_pos->x, $c->y + $day_pos->y);
			textcolor($pdf, $current_day, $evenodd);
			$pdf->print($current_day->day);
			if ($current_day->day == 1) {
				my $month_name = $current_day->month_abbr;
				$month_name = $current_day->month_name if $opt->{fullnames};
				$pdf->setfont($font, $text_size);
				$pdf->move($c->x + $month_pos->x, $c->y + $month_pos->y);
				$pdf->print($month_name);
			}
			if (($opt->{always} or $current_day->month == 1)
					and $current_day->day == 1) {
				$pdf->setfont($font, $text_size);
				$pdf->move($c->x + $year_pos->x, $c->y + $year_pos->y);
				$pdf->print($current_day->year);
			}
			$current_day->add(days => 1);
		}
	}
	$pdf->fillcolor("black");
	$pdf->setfont($font, $header_size);
	foreach my $i (1..@headers) {
		my $c = $headers[$i - 1];
		$pdf->rect($c->x, $c->y, $c->width, $c->height);
		$pdf->stroke;
		$pdf->move($c->x + 1, $c->y + 1);
		$pdf->print($day_name[$i>7 ? $i - 7 : $i]);
	}
}
$pdf->write;
exit 0;

sub get_options {
	my ($opt) = @_;
	%$opt = (
		always => 0,
		current => 0,
		double => 0,
		fullnames => 0,
		landscape => 0,
		locale => "en_US",
		margin => 0.5,
		verbose => 0,
		num_years => "1y",
		outfile => undef,
		papersize => "usletter",
		ratio => 1,
		scaling => 100,
		startday => 1,
		start_month => 1,
		textfont => "Verdana",
		year => 1900 + (localtime())[5],
	);
	my $usage = <<EOF;
Usage: $0 [options] [startyear] [startmonth]
    -a always print year
    -c start with current month
    -d double-week calendar
    -f font ("$opt->{textfont}"; supports most TTF/OTF files)
    -F use full month/day names
    -l locale ("$opt->{locale}"; ja_JP|ru_RU|ko_KR|etc require specific font)
    -m margin ("$opt->{margin}" (inches))
    -n years/weeks/days ("$opt->{num_years}" (ex: 3y, 5w, 30d))
    -o output filename ("$opt->{year}-$opt->{papersize}.pdf")
    -p papersize ("$opt->{papersize}")
    -r ratio ("1"; smaller for shorter boxes)
    -s start week on day ("$opt->{startday}" (Mon=1, Sun=7))
    -v just report number of pages and date range
    -w rotate the paper to print a landscape calendar
EOF
	GetOptions($opt,
		"always|a",
		"current|c",
		"double|d",
		"textfont|font|f=s",
		"fullnames|F",
		"landscape|wide|w",
		"locale|l=s",
		"margin|m=f",
		"num_years|number|n=s",
		"outfile|output|o=s",
		"papersize|paper|p=s",
		"ratio|r=f",
		"scaling|y=i",
		"startday|start|s=i",
		"verbose|v",
	) or die $usage;
	$opt->{year} = shift(@ARGV) if @ARGV;
	$opt->{start_month} = shift(@ARGV) if @ARGV;
	$opt->{locale} .= '.UTF-8' unless $opt->{locale} =~ /\.UTF-8$/;
}

sub textcolor {
	my ($pdf, $day, $evenodd) = @_;
	my $date = $day->ymd;
	my $color;
	$color = $textcolor[$evenodd] unless defined $color;
	$pdf->fillcolor($color);
}

sub cellcolor {
	my ($pdf, $day, $evenodd) = @_;
	my $date = $day->ymd;
	my $color;
	if (! defined $color) {
		if ($current_day->day_of_week > 5) {
			$color = $weekend[$evenodd];
		}else{
			$color = $weekday[$evenodd];
		}
	}
	$pdf->fillcolor($color);
}

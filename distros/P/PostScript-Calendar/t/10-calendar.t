#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 12 Mar 2010
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test the content of generated PostScript calendars
#---------------------------------------------------------------------

BEGIN {$ENV{TZ} = 'CST6'} # For consistent phase-of-moon calculations

use strict;
use warnings;

use Test::More;

# Load Test::Differences, if available:
BEGIN {
  # RECOMMEND PREREQ: Test::Differences
  if (eval "use Test::Differences; 1") {
    # Not all versions of Test::Differences support changing the style:
    eval { Test::Differences::unified_diff() }
  } else {
    eval '*eq_or_diff = \&is;'; # Just use "is" instead
  }
} # end BEGIN

my $skipAstro;
$skipAstro = 'Astro::MoonPhase 0.60 not installed'
    unless eval 'use Astro::MoonPhase 0.60; 1';

unless (localtime(1262325600) eq 'Fri Jan  1 00:00:00 2010') {
  # Try restarting the script:
  #  (Windows doesn't let you change timezones after the program starts)
  unless (grep { $_ eq 'restarted' } @ARGV) {
    diag("Restarting to pick up timezone change...");
    exec $^X, $0, 'restarted';
  }
  # If that doesn't work, just skip the phase-of-moon tests:
  $skipAstro ||= "Unable to set CST6 timezone";
} # end unless we're in CST6 timezone

use FindBin '$Bin';
chdir $Bin or die "Unable to cd $Bin: $!";

my $generateResults;

if (@ARGV and $ARGV[0] eq 'gen') {
  # Just output the actual results, so they can be diffed against this file
  die "Can't skip moon tests when generating results\n" if $skipAstro;
  $generateResults = 1;
  open(OUT, '>', '/tmp/10-calendar.t') or die $!;
  printf OUT "#%s\n\n__DATA__\n", '=' x 69;
} else {
  plan tests => 6 * 2 + 1;
}

require PostScript::Calendar;
ok(1, 'loaded PostScript::Calendar') unless $generateResults;

my ($year, $month, $name, %param, @methods);

while (<DATA>) {

  print OUT $_ if $generateResults;

  if (/^(\w+):(.+)/) {
    $param{$1} = eval $2;
    die $@ if $@;
  } # end if constructor parameter (key: value)
  elsif (/^(->.+)/) {
    push @methods, $1;
  } # end if method to call (->method(param))
  elsif ($_ eq "===\n") {
    # Read the expected results:
    my $expected = '';
    while (<DATA>) {
      last if $_ eq "---\n";
      $expected .= $_;
    }

  SKIP: {
      skip $skipAstro, 2 if $param{phases} and $skipAstro;

      # Run the test:
      my $cal = PostScript::Calendar->new($year, $month, %param);
      isa_ok($cal, "PostScript::Calendar", $name) unless $generateResults;

      foreach my $call (@methods) {
        eval '$cal' . $call;
        die $@ if $@;
      } # end foreach $call in @methods

      $cal->generate;
      my $got = $cal->ps_file->testable_output;

      # Remove version number:
      $got =~ s/^%%Creator: PostScript::Calendar.+\n//m;

      if ($generateResults) {
        print OUT "$got---\n";
      } else {
        eq_or_diff($got, $expected, $name);
      }
    } # end SKIP

    # Clean up:
    @methods = ();
    %param = ();
    undef $year;
    undef $month;
    undef $name;
  } # end elsif expected contents (=== ... ---)
  elsif (/^::\s*((\d{4})-(\d{2})(?!\d).*)/) {
    $name  = $1;
    $year  = $2;
    $month = $3;
  } # end elsif test name (:: name)
  else {
    die "Unrecognized line $_" if /\S/ and not /^# /;
  }
} # end while <DATA>

#=====================================================================

__DATA__

:: 2010-02 no parameters
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Oblique
%%DocumentSuppliedResources:
%%+ procset PostScript_Calendar 0 0
%%Title: (February 2010)
%%EndComments
%%BeginProlog
%%BeginResource: procset PostScript_Calendar 0 0
/pixel {72 mul 300 div} bind def
/Events
{
EventFont setfont
EventSpacing /showLeft showLines
} bind def
/FillDay
{
newpath
0 0 moveto
DayWidth 0 lineto
DayWidth DayHeight lineto
0 DayHeight lineto
closepath
fill
} bind def
/ShadeDay
{
gsave
DayBackground setColor
FillDay
grestore
} bind def
%%EndResource
%%EndProlog
%%BeginSetup
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 138 def
/DayWidth 80 def
/DayBackground 0.85 def
/TitleSize 14 def
/TitleFont /Helvetica-iso findfont TitleSize scalefont def
/LabelSize 14 def
/LabelFont /Helvetica-iso findfont LabelSize scalefont def
/DateSize 14 def
/DateFont /Helvetica-Oblique-iso findfont DateSize scalefont def
/EventSize 8 def
/EventFont /Helvetica-iso findfont EventSize scalefont def
/EventSpacing 10 def
/MiniSize 6 def
/MiniFont /Helvetica-iso findfont MiniSize scalefont def
TitleFont setfont
306 742 (February 2010) showCenter
LabelFont setfont
64 723 (Sunday) showCenter
144 723 (Monday) showCenter
224 723 (Tuesday) showCenter
304 723 (Wednesday) showCenter
384 723 (Thursday) showCenter
464 723 (Friday) showCenter
544 723 (Saturday) showCenter
DateFont setfont
180 702 (1) showRight
260 702 (2) showRight
340 702 (3) showRight
420 702 (4) showRight
500 702 (5) showRight
580 702 (6) showRight
100 564 (7) showRight
180 564 (8) showRight
260 564 (9) showRight
340 564 (10) showRight
420 564 (11) showRight
500 564 (12) showRight
580 564 (13) showRight
100 426 (14) showRight
180 426 (15) showRight
260 426 (16) showRight
340 426 (17) showRight
420 426 (18) showRight
500 426 (19) showRight
580 426 (20) showRight
100 288 (21) showRight
180 288 (22) showRight
260 288 (23) showRight
340 288 (24) showRight
420 288 (25) showRight
500 288 (26) showRight
580 288 (27) showRight
100 150 (28) showRight
0.72 setlinewidth
166 138 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
709 exch 28 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -709 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---


:: 2000-02 no parameters
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Oblique
%%DocumentSuppliedResources:
%%+ procset PostScript_Calendar 0 0
%%Title: (February 2000)
%%EndComments
%%BeginProlog
%%BeginResource: procset PostScript_Calendar 0 0
/pixel {72 mul 300 div} bind def
/Events
{
EventFont setfont
EventSpacing /showLeft showLines
} bind def
/FillDay
{
newpath
0 0 moveto
DayWidth 0 lineto
DayWidth DayHeight lineto
0 DayHeight lineto
closepath
fill
} bind def
/ShadeDay
{
gsave
DayBackground setColor
FillDay
grestore
} bind def
%%EndResource
%%EndProlog
%%BeginSetup
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 138 def
/DayWidth 80 def
/DayBackground 0.85 def
/TitleSize 14 def
/TitleFont /Helvetica-iso findfont TitleSize scalefont def
/LabelSize 14 def
/LabelFont /Helvetica-iso findfont LabelSize scalefont def
/DateSize 14 def
/DateFont /Helvetica-Oblique-iso findfont DateSize scalefont def
/EventSize 8 def
/EventFont /Helvetica-iso findfont EventSize scalefont def
/EventSpacing 10 def
/MiniSize 6 def
/MiniFont /Helvetica-iso findfont MiniSize scalefont def
TitleFont setfont
306 742 (February 2000) showCenter
LabelFont setfont
64 723 (Sunday) showCenter
144 723 (Monday) showCenter
224 723 (Tuesday) showCenter
304 723 (Wednesday) showCenter
384 723 (Thursday) showCenter
464 723 (Friday) showCenter
544 723 (Saturday) showCenter
DateFont setfont
260 702 (1) showRight
340 702 (2) showRight
420 702 (3) showRight
500 702 (4) showRight
580 702 (5) showRight
100 564 (6) showRight
180 564 (7) showRight
260 564 (8) showRight
340 564 (9) showRight
420 564 (10) showRight
500 564 (11) showRight
580 564 (12) showRight
100 426 (13) showRight
180 426 (14) showRight
260 426 (15) showRight
340 426 (16) showRight
420 426 (17) showRight
500 426 (18) showRight
580 426 (19) showRight
100 288 (20) showRight
180 288 (21) showRight
260 288 (22) showRight
340 288 (23) showRight
420 288 (24) showRight
500 288 (25) showRight
580 288 (26) showRight
100 150 (27) showRight
180 150 (28) showRight
260 150 (29) showRight
0.72 setlinewidth
166 138 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
709 exch 28 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -709 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---

:: 2008-07 holiday
shade_days_of_week: [ 0, 6 ]
->add_event(4, 'Independence day');
->shade(4);
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Oblique
%%DocumentSuppliedResources:
%%+ procset PostScript_Calendar 0 0
%%Title: (July 2008)
%%EndComments
%%BeginProlog
%%BeginResource: procset PostScript_Calendar 0 0
/pixel {72 mul 300 div} bind def
/Events
{
EventFont setfont
EventSpacing /showLeft showLines
} bind def
/FillDay
{
newpath
0 0 moveto
DayWidth 0 lineto
DayWidth DayHeight lineto
0 DayHeight lineto
closepath
fill
} bind def
/ShadeDay
{
gsave
DayBackground setColor
FillDay
grestore
} bind def
%%EndResource
%%EndProlog
%%BeginSetup
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 138 def
/DayWidth 80 def
/DayBackground 0.85 def
/TitleSize 14 def
/TitleFont /Helvetica-iso findfont TitleSize scalefont def
/LabelSize 14 def
/LabelFont /Helvetica-iso findfont LabelSize scalefont def
/DateSize 14 def
/DateFont /Helvetica-Oblique-iso findfont DateSize scalefont def
/EventSize 8 def
/EventFont /Helvetica-iso findfont EventSize scalefont def
/EventSpacing 10 def
/MiniSize 6 def
/MiniFont /Helvetica-iso findfont MiniSize scalefont def
gsave
424 580 translate
ShadeDay
grestore
427 708 [(Independence)
(day)] Events
gsave
504 580 translate
ShadeDay
grestore
gsave
24 442 translate
ShadeDay
grestore
gsave
504 442 translate
ShadeDay
grestore
gsave
24 304 translate
ShadeDay
grestore
gsave
504 304 translate
ShadeDay
grestore
gsave
24 166 translate
ShadeDay
grestore
gsave
504 166 translate
ShadeDay
grestore
gsave
24 28 translate
ShadeDay
grestore
TitleFont setfont
306 742 (July 2008) showCenter
LabelFont setfont
64 723 (Sunday) showCenter
144 723 (Monday) showCenter
224 723 (Tuesday) showCenter
304 723 (Wednesday) showCenter
384 723 (Thursday) showCenter
464 723 (Friday) showCenter
544 723 (Saturday) showCenter
DateFont setfont
260 702 (1) showRight
340 702 (2) showRight
420 702 (3) showRight
500 702 (4) showRight
580 702 (5) showRight
100 564 (6) showRight
180 564 (7) showRight
260 564 (8) showRight
340 564 (9) showRight
420 564 (10) showRight
500 564 (11) showRight
580 564 (12) showRight
100 426 (13) showRight
180 426 (14) showRight
260 426 (15) showRight
340 426 (16) showRight
420 426 (17) showRight
500 426 (18) showRight
580 426 (19) showRight
100 288 (20) showRight
180 288 (21) showRight
260 288 (22) showRight
340 288 (23) showRight
420 288 (24) showRight
500 288 (25) showRight
580 288 (26) showRight
100 150 (27) showRight
180 150 (28) showRight
260 150 (29) showRight
340 150 (30) showRight
420 150 (31) showRight
0.72 setlinewidth
166 138 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
709 exch 28 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -709 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---

:: 2010-11 moon phases
phases: 1
->add_event(25, "Thanksgiving");
->add_event(11, "Veteran\'s Day");
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Oblique
%%DocumentSuppliedResources:
%%+ procset PostScript_Calendar 0 0
%%+ procset PostScript_Calendar_Moon 0 0
%%Title: (November 2010)
%%EndComments
%%BeginProlog
%%BeginResource: procset PostScript_Calendar 0 0
/pixel {72 mul 300 div} bind def
/Events
{
EventFont setfont
EventSpacing /showLeft showLines
} bind def
/FillDay
{
newpath
0 0 moveto
DayWidth 0 lineto
DayWidth DayHeight lineto
0 DayHeight lineto
closepath
fill
} bind def
/ShadeDay
{
gsave
DayBackground setColor
FillDay
grestore
} bind def
%%EndResource
%%BeginResource: procset PostScript_Calendar_Moon 0 0
/ShowPhase
{
gsave
3 pixel setlinewidth
newpath
MoonMargin DateSize 2 div add
DayHeight MoonMargin sub
DateSize 2 div sub
DateSize 2 div
0 360 arc
closepath
cvx exec
grestore
} bind def
/NewMoon { MoonDark setColor fill } bind def
/FullMoon {
gsave MoonLight setColor fill grestore
MoonDark setColor stroke
} bind def
/FirstQuarter
{
FullMoon
newpath
MoonMargin DateSize 2 div add
DayHeight MoonMargin sub DateSize 2 div sub
DateSize 2 div
90 270 arc
closepath fill
} bind def
/LastQuarter
{
FullMoon
newpath
MoonMargin DateSize 2 div add
DayHeight MoonMargin sub DateSize 2 div sub
DateSize 2 div
270 90 arc
closepath fill
} bind def
%%EndResource
%%EndProlog
%%BeginSetup
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 138 def
/DayWidth 80 def
/DayBackground 0.85 def
/TitleSize 14 def
/TitleFont /Helvetica-iso findfont TitleSize scalefont def
/LabelSize 14 def
/LabelFont /Helvetica-iso findfont LabelSize scalefont def
/DateSize 14 def
/DateFont /Helvetica-Oblique-iso findfont DateSize scalefont def
/EventSize 8 def
/EventFont /Helvetica-iso findfont EventSize scalefont def
/EventSpacing 10 def
/MiniSize 6 def
/MiniFont /Helvetica-iso findfont MiniSize scalefont def
/MoonDark 0 def
/MoonLight 1 def
/MoonMargin 6 def
gsave
424 580 translate
/NewMoon ShowPhase
grestore
347 570 [(Veteran's Day)] Events
gsave
504 442 translate
/FirstQuarter ShowPhase
grestore
gsave
24 166 translate
/FullMoon ShowPhase
grestore
347 294 [(Thanksgiving)] Events
gsave
24 28 translate
/LastQuarter ShowPhase
grestore
TitleFont setfont
306 742 (November 2010) showCenter
LabelFont setfont
64 723 (Sunday) showCenter
144 723 (Monday) showCenter
224 723 (Tuesday) showCenter
304 723 (Wednesday) showCenter
384 723 (Thursday) showCenter
464 723 (Friday) showCenter
544 723 (Saturday) showCenter
DateFont setfont
180 702 (1) showRight
260 702 (2) showRight
340 702 (3) showRight
420 702 (4) showRight
500 702 (5) showRight
580 702 (6) showRight
100 564 (7) showRight
180 564 (8) showRight
260 564 (9) showRight
340 564 (10) showRight
420 564 (11) showRight
500 564 (12) showRight
580 564 (13) showRight
100 426 (14) showRight
180 426 (15) showRight
260 426 (16) showRight
340 426 (17) showRight
420 426 (18) showRight
500 426 (19) showRight
580 426 (20) showRight
100 288 (21) showRight
180 288 (22) showRight
260 288 (23) showRight
340 288 (24) showRight
420 288 (25) showRight
500 288 (26) showRight
580 288 (27) showRight
100 150 (28) showRight
180 150 (29) showRight
260 150 (30) showRight
0.72 setlinewidth
166 138 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
709 exch 28 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -709 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---

:: 2010-11 custom colors
shade_color: [1, 0, 0]
shade_days_of_week: [0, 6]
->shade( {shade_color => 0.5}, 6 );
->shade( 5 );
->shade( {shade_color => [0, 1, 0]}, 12 );
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Oblique
%%DocumentSuppliedResources:
%%+ procset PostScript_Calendar 0 0
%%Title: (November 2010)
%%LanguageLevel: 2
%%EndComments
%%BeginProlog
%%BeginResource: procset PostScript_Calendar 0 0
/pixel {72 mul 300 div} bind def
/Events
{
EventFont setfont
EventSpacing /showLeft showLines
} bind def
/FillDay
{
newpath
0 0 moveto
DayWidth 0 lineto
DayWidth DayHeight lineto
0 DayHeight lineto
closepath
fill
} bind def
/ShadeDay
{
gsave
DayBackground setColor
FillDay
grestore
} bind def
%%EndResource
%%EndProlog
%%BeginSetup
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 138 def
/DayWidth 80 def
/DayBackground [ 1 0 0 ] def
/TitleSize 14 def
/TitleFont /Helvetica-iso findfont TitleSize scalefont def
/LabelSize 14 def
/LabelFont /Helvetica-iso findfont LabelSize scalefont def
/DateSize 14 def
/DateFont /Helvetica-Oblique-iso findfont DateSize scalefont def
/EventSize 8 def
/EventFont /Helvetica-iso findfont EventSize scalefont def
/EventSpacing 10 def
/MiniSize 6 def
/MiniFont /Helvetica-iso findfont MiniSize scalefont def
gsave
424 580 translate
ShadeDay
grestore
<<
/DayBackground 0.5
>> begin
gsave
504 580 translate
ShadeDay
grestore
end
gsave
24 442 translate
ShadeDay
grestore
<<
/DayBackground [ 0 1 0 ]
>> begin
gsave
424 442 translate
ShadeDay
grestore
end
gsave
504 442 translate
ShadeDay
grestore
gsave
24 304 translate
ShadeDay
grestore
gsave
504 304 translate
ShadeDay
grestore
gsave
24 166 translate
ShadeDay
grestore
gsave
504 166 translate
ShadeDay
grestore
gsave
24 28 translate
ShadeDay
grestore
TitleFont setfont
306 742 (November 2010) showCenter
LabelFont setfont
64 723 (Sunday) showCenter
144 723 (Monday) showCenter
224 723 (Tuesday) showCenter
304 723 (Wednesday) showCenter
384 723 (Thursday) showCenter
464 723 (Friday) showCenter
544 723 (Saturday) showCenter
DateFont setfont
180 702 (1) showRight
260 702 (2) showRight
340 702 (3) showRight
420 702 (4) showRight
500 702 (5) showRight
580 702 (6) showRight
100 564 (7) showRight
180 564 (8) showRight
260 564 (9) showRight
340 564 (10) showRight
420 564 (11) showRight
500 564 (12) showRight
580 564 (13) showRight
100 426 (14) showRight
180 426 (15) showRight
260 426 (16) showRight
340 426 (17) showRight
420 426 (18) showRight
500 426 (19) showRight
580 426 (20) showRight
100 288 (21) showRight
180 288 (22) showRight
260 288 (23) showRight
340 288 (24) showRight
420 288 (25) showRight
500 288 (26) showRight
580 288 (27) showRight
100 150 (28) showRight
180 150 (29) showRight
260 150 (30) showRight
0.72 setlinewidth
166 138 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
709 exch 28 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -709 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---

:: 2010-11 custom moon colors
shade_days_of_week: [0, 6]
moon_dark: 0.25
moon_light: 0.75
->shade( {shade_color => 0.5, moon_dark => [1,0,0], moon_light => [0,1,0]}, 6 );
->shade( {shade_color => [0, 1, 0], moon_light => 0.875 }, 12 );
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Oblique
%%DocumentSuppliedResources:
%%+ procset PostScript_Calendar 0 0
%%Title: (November 2010)
%%LanguageLevel: 2
%%EndComments
%%BeginProlog
%%BeginResource: procset PostScript_Calendar 0 0
/pixel {72 mul 300 div} bind def
/Events
{
EventFont setfont
EventSpacing /showLeft showLines
} bind def
/FillDay
{
newpath
0 0 moveto
DayWidth 0 lineto
DayWidth DayHeight lineto
0 DayHeight lineto
closepath
fill
} bind def
/ShadeDay
{
gsave
DayBackground setColor
FillDay
grestore
} bind def
%%EndResource
%%EndProlog
%%BeginSetup
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 138 def
/DayWidth 80 def
/DayBackground 0.85 def
/TitleSize 14 def
/TitleFont /Helvetica-iso findfont TitleSize scalefont def
/LabelSize 14 def
/LabelFont /Helvetica-iso findfont LabelSize scalefont def
/DateSize 14 def
/DateFont /Helvetica-Oblique-iso findfont DateSize scalefont def
/EventSize 8 def
/EventFont /Helvetica-iso findfont EventSize scalefont def
/EventSpacing 10 def
/MiniSize 6 def
/MiniFont /Helvetica-iso findfont MiniSize scalefont def
<<
/DayBackground 0.5
/MoonDark [ 1 0 0 ]
/MoonLight [ 0 1 0 ]
>> begin
gsave
504 580 translate
ShadeDay
grestore
end
gsave
24 442 translate
ShadeDay
grestore
<<
/DayBackground [ 0 1 0 ]
/MoonLight 0.875
>> begin
gsave
424 442 translate
ShadeDay
grestore
end
gsave
504 442 translate
ShadeDay
grestore
gsave
24 304 translate
ShadeDay
grestore
gsave
504 304 translate
ShadeDay
grestore
gsave
24 166 translate
ShadeDay
grestore
gsave
504 166 translate
ShadeDay
grestore
gsave
24 28 translate
ShadeDay
grestore
TitleFont setfont
306 742 (November 2010) showCenter
LabelFont setfont
64 723 (Sunday) showCenter
144 723 (Monday) showCenter
224 723 (Tuesday) showCenter
304 723 (Wednesday) showCenter
384 723 (Thursday) showCenter
464 723 (Friday) showCenter
544 723 (Saturday) showCenter
DateFont setfont
180 702 (1) showRight
260 702 (2) showRight
340 702 (3) showRight
420 702 (4) showRight
500 702 (5) showRight
580 702 (6) showRight
100 564 (7) showRight
180 564 (8) showRight
260 564 (9) showRight
340 564 (10) showRight
420 564 (11) showRight
500 564 (12) showRight
580 564 (13) showRight
100 426 (14) showRight
180 426 (15) showRight
260 426 (16) showRight
340 426 (17) showRight
420 426 (18) showRight
500 426 (19) showRight
580 426 (20) showRight
100 288 (21) showRight
180 288 (22) showRight
260 288 (23) showRight
340 288 (24) showRight
420 288 (25) showRight
500 288 (26) showRight
580 288 (27) showRight
100 150 (28) showRight
180 150 (29) showRight
260 150 (30) showRight
0.72 setlinewidth
166 138 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
709 exch 28 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -709 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---

# Local Variables:
# compile-command: "perl 10-calendar.t gen"
# End:

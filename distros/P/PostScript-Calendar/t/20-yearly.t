#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 27 Sep 2010
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test creating a single file with an entire year's calendar pages
#---------------------------------------------------------------------

use strict;
use warnings;

use Test::More 0.88;            # done_testing

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

my $generateResults = '';

if (@ARGV and $ARGV[0] eq 'gen') {
  # Just output the actual results, so they can be diffed against this file
  $generateResults = 1;
  open(OUT, '>', '/tmp/20-yearly.t') or die $!;
} elsif (@ARGV and $ARGV[0] eq 'ps') {
  $generateResults = 'ps';
  open(OUT, '>', '/tmp/20-yearly.ps') or die $!;
} else {
  plan tests => 14;
}

#---------------------------------------------------------------------
require PostScript::Calendar;

my $ps;
for my $month (1 .. 12) {
  $ps->newpage if $ps;
  my $cal = PostScript::Calendar->new(2010, $month, ps_file => $ps,
                                      day_height => 96,
                                      mini_calendars => 'before');
  isa_ok($cal, 'PostScript::Calendar') unless $generateResults;
  $cal->generate;
  # We get the PostScript::File from the first calendar,
  # and pass that to the remaining calendars:
  $ps ||= $cal->ps_file;
} # end for $month 1 to 12

isa_ok($ps, 'PostScript::File') unless $generateResults;

# Use sanitized output (unless $generateResults eq 'ps'):
my $out = $ps->testable_output($generateResults eq 'ps');

$out =~ s/(?<=^%%Creator: PostScript::Calendar).+(?=\n)//m;

if ($generateResults) {
  print OUT $out;
} else {
  eq_or_diff($out, <<'END CALENDAR', 'generated PostScript');
%!PS-Adobe-3.0
%%Creator: PostScript::Calendar
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Oblique
%%DocumentSuppliedResources:
%%+ procset PostScript_Calendar 0 0
%%Title: (January 2010)
%%Pages: 12
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
/DayHeight 96 def
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
MiniFont setfont
64 708 (December) showCenter
31.25 699 (S) showCenter
42.125 699 (M) showCenter
53 699 (T) showCenter
63.875 699 (W) showCenter
74.75 699 (T) showCenter
85.625 699 (F) showCenter
96.5 699 (S) showCenter
53 690 (1) showCenter
63.875 690 (2) showCenter
74.75 690 (3) showCenter
85.625 690 (4) showCenter
96.5 690 (5) showCenter
31.25 681 (6) showCenter
42.125 681 (7) showCenter
53 681 (8) showCenter
63.875 681 (9) showCenter
74.75 681 (10) showCenter
85.625 681 (11) showCenter
96.5 681 (12) showCenter
31.25 672 (13) showCenter
42.125 672 (14) showCenter
53 672 (15) showCenter
63.875 672 (16) showCenter
74.75 672 (17) showCenter
85.625 672 (18) showCenter
96.5 672 (19) showCenter
31.25 663 (20) showCenter
42.125 663 (21) showCenter
53 663 (22) showCenter
63.875 663 (23) showCenter
74.75 663 (24) showCenter
85.625 663 (25) showCenter
96.5 663 (26) showCenter
31.25 654 (27) showCenter
42.125 654 (28) showCenter
53 654 (29) showCenter
63.875 654 (30) showCenter
74.75 654 (31) showCenter
MiniFont setfont
144 708 (February) showCenter
111.25 699 (S) showCenter
122.125 699 (M) showCenter
133 699 (T) showCenter
143.875 699 (W) showCenter
154.75 699 (T) showCenter
165.625 699 (F) showCenter
176.5 699 (S) showCenter
122.125 690 (1) showCenter
133 690 (2) showCenter
143.875 690 (3) showCenter
154.75 690 (4) showCenter
165.625 690 (5) showCenter
176.5 690 (6) showCenter
111.25 681 (7) showCenter
122.125 681 (8) showCenter
133 681 (9) showCenter
143.875 681 (10) showCenter
154.75 681 (11) showCenter
165.625 681 (12) showCenter
176.5 681 (13) showCenter
111.25 672 (14) showCenter
122.125 672 (15) showCenter
133 672 (16) showCenter
143.875 672 (17) showCenter
154.75 672 (18) showCenter
165.625 672 (19) showCenter
176.5 672 (20) showCenter
111.25 663 (21) showCenter
122.125 663 (22) showCenter
133 663 (23) showCenter
143.875 663 (24) showCenter
154.75 663 (25) showCenter
165.625 663 (26) showCenter
176.5 663 (27) showCenter
111.25 654 (28) showCenter
TitleFont setfont
306 742 (January 2010) showCenter
LabelFont setfont
64 723 (Sunday) showCenter
144 723 (Monday) showCenter
224 723 (Tuesday) showCenter
304 723 (Wednesday) showCenter
384 723 (Thursday) showCenter
464 723 (Friday) showCenter
544 723 (Saturday) showCenter
DateFont setfont
500 702 (1) showRight
580 702 (2) showRight
100 606 (3) showRight
180 606 (4) showRight
260 606 (5) showRight
340 606 (6) showRight
420 606 (7) showRight
500 606 (8) showRight
580 606 (9) showRight
100 510 (10) showRight
180 510 (11) showRight
260 510 (12) showRight
340 510 (13) showRight
420 510 (14) showRight
500 510 (15) showRight
580 510 (16) showRight
100 414 (17) showRight
180 414 (18) showRight
260 414 (19) showRight
340 414 (20) showRight
420 414 (21) showRight
500 414 (22) showRight
580 414 (23) showRight
100 318 (24) showRight
180 318 (25) showRight
260 318 (26) showRight
340 318 (27) showRight
420 318 (28) showRight
500 318 (29) showRight
580 318 (30) showRight
100 222 (31) showRight
0.72 setlinewidth
238 96 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
595 exch 142 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -595 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 2 2
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 96 def
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
MiniFont setfont
464 324 (January) showCenter
431.25 315 (S) showCenter
442.125 315 (M) showCenter
453 315 (T) showCenter
463.875 315 (W) showCenter
474.75 315 (T) showCenter
485.625 315 (F) showCenter
496.5 315 (S) showCenter
485.625 306 (1) showCenter
496.5 306 (2) showCenter
431.25 297 (3) showCenter
442.125 297 (4) showCenter
453 297 (5) showCenter
463.875 297 (6) showCenter
474.75 297 (7) showCenter
485.625 297 (8) showCenter
496.5 297 (9) showCenter
431.25 288 (10) showCenter
442.125 288 (11) showCenter
453 288 (12) showCenter
463.875 288 (13) showCenter
474.75 288 (14) showCenter
485.625 288 (15) showCenter
496.5 288 (16) showCenter
431.25 279 (17) showCenter
442.125 279 (18) showCenter
453 279 (19) showCenter
463.875 279 (20) showCenter
474.75 279 (21) showCenter
485.625 279 (22) showCenter
496.5 279 (23) showCenter
431.25 270 (24) showCenter
442.125 270 (25) showCenter
453 270 (26) showCenter
463.875 270 (27) showCenter
474.75 270 (28) showCenter
485.625 270 (29) showCenter
496.5 270 (30) showCenter
431.25 261 (31) showCenter
MiniFont setfont
544 324 (March) showCenter
511.25 315 (S) showCenter
522.125 315 (M) showCenter
533 315 (T) showCenter
543.875 315 (W) showCenter
554.75 315 (T) showCenter
565.625 315 (F) showCenter
576.5 315 (S) showCenter
522.125 306 (1) showCenter
533 306 (2) showCenter
543.875 306 (3) showCenter
554.75 306 (4) showCenter
565.625 306 (5) showCenter
576.5 306 (6) showCenter
511.25 297 (7) showCenter
522.125 297 (8) showCenter
533 297 (9) showCenter
543.875 297 (10) showCenter
554.75 297 (11) showCenter
565.625 297 (12) showCenter
576.5 297 (13) showCenter
511.25 288 (14) showCenter
522.125 288 (15) showCenter
533 288 (16) showCenter
543.875 288 (17) showCenter
554.75 288 (18) showCenter
565.625 288 (19) showCenter
576.5 288 (20) showCenter
511.25 279 (21) showCenter
522.125 279 (22) showCenter
533 279 (23) showCenter
543.875 279 (24) showCenter
554.75 279 (25) showCenter
565.625 279 (26) showCenter
576.5 279 (27) showCenter
511.25 270 (28) showCenter
522.125 270 (29) showCenter
533 270 (30) showCenter
543.875 270 (31) showCenter
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
100 606 (7) showRight
180 606 (8) showRight
260 606 (9) showRight
340 606 (10) showRight
420 606 (11) showRight
500 606 (12) showRight
580 606 (13) showRight
100 510 (14) showRight
180 510 (15) showRight
260 510 (16) showRight
340 510 (17) showRight
420 510 (18) showRight
500 510 (19) showRight
580 510 (20) showRight
100 414 (21) showRight
180 414 (22) showRight
260 414 (23) showRight
340 414 (24) showRight
420 414 (25) showRight
500 414 (26) showRight
580 414 (27) showRight
100 318 (28) showRight
0.72 setlinewidth
334 96 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
499 exch 238 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 3 3
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 96 def
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
MiniFont setfont
464 324 (February) showCenter
431.25 315 (S) showCenter
442.125 315 (M) showCenter
453 315 (T) showCenter
463.875 315 (W) showCenter
474.75 315 (T) showCenter
485.625 315 (F) showCenter
496.5 315 (S) showCenter
442.125 306 (1) showCenter
453 306 (2) showCenter
463.875 306 (3) showCenter
474.75 306 (4) showCenter
485.625 306 (5) showCenter
496.5 306 (6) showCenter
431.25 297 (7) showCenter
442.125 297 (8) showCenter
453 297 (9) showCenter
463.875 297 (10) showCenter
474.75 297 (11) showCenter
485.625 297 (12) showCenter
496.5 297 (13) showCenter
431.25 288 (14) showCenter
442.125 288 (15) showCenter
453 288 (16) showCenter
463.875 288 (17) showCenter
474.75 288 (18) showCenter
485.625 288 (19) showCenter
496.5 288 (20) showCenter
431.25 279 (21) showCenter
442.125 279 (22) showCenter
453 279 (23) showCenter
463.875 279 (24) showCenter
474.75 279 (25) showCenter
485.625 279 (26) showCenter
496.5 279 (27) showCenter
431.25 270 (28) showCenter
MiniFont setfont
544 324 (April) showCenter
511.25 315 (S) showCenter
522.125 315 (M) showCenter
533 315 (T) showCenter
543.875 315 (W) showCenter
554.75 315 (T) showCenter
565.625 315 (F) showCenter
576.5 315 (S) showCenter
554.75 306 (1) showCenter
565.625 306 (2) showCenter
576.5 306 (3) showCenter
511.25 297 (4) showCenter
522.125 297 (5) showCenter
533 297 (6) showCenter
543.875 297 (7) showCenter
554.75 297 (8) showCenter
565.625 297 (9) showCenter
576.5 297 (10) showCenter
511.25 288 (11) showCenter
522.125 288 (12) showCenter
533 288 (13) showCenter
543.875 288 (14) showCenter
554.75 288 (15) showCenter
565.625 288 (16) showCenter
576.5 288 (17) showCenter
511.25 279 (18) showCenter
522.125 279 (19) showCenter
533 279 (20) showCenter
543.875 279 (21) showCenter
554.75 279 (22) showCenter
565.625 279 (23) showCenter
576.5 279 (24) showCenter
511.25 270 (25) showCenter
522.125 270 (26) showCenter
533 270 (27) showCenter
543.875 270 (28) showCenter
554.75 270 (29) showCenter
565.625 270 (30) showCenter
TitleFont setfont
306 742 (March 2010) showCenter
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
100 606 (7) showRight
180 606 (8) showRight
260 606 (9) showRight
340 606 (10) showRight
420 606 (11) showRight
500 606 (12) showRight
580 606 (13) showRight
100 510 (14) showRight
180 510 (15) showRight
260 510 (16) showRight
340 510 (17) showRight
420 510 (18) showRight
500 510 (19) showRight
580 510 (20) showRight
100 414 (21) showRight
180 414 (22) showRight
260 414 (23) showRight
340 414 (24) showRight
420 414 (25) showRight
500 414 (26) showRight
580 414 (27) showRight
100 318 (28) showRight
180 318 (29) showRight
260 318 (30) showRight
340 318 (31) showRight
0.72 setlinewidth
334 96 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
499 exch 238 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 4 4
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 96 def
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
MiniFont setfont
64 708 (March) showCenter
31.25 699 (S) showCenter
42.125 699 (M) showCenter
53 699 (T) showCenter
63.875 699 (W) showCenter
74.75 699 (T) showCenter
85.625 699 (F) showCenter
96.5 699 (S) showCenter
42.125 690 (1) showCenter
53 690 (2) showCenter
63.875 690 (3) showCenter
74.75 690 (4) showCenter
85.625 690 (5) showCenter
96.5 690 (6) showCenter
31.25 681 (7) showCenter
42.125 681 (8) showCenter
53 681 (9) showCenter
63.875 681 (10) showCenter
74.75 681 (11) showCenter
85.625 681 (12) showCenter
96.5 681 (13) showCenter
31.25 672 (14) showCenter
42.125 672 (15) showCenter
53 672 (16) showCenter
63.875 672 (17) showCenter
74.75 672 (18) showCenter
85.625 672 (19) showCenter
96.5 672 (20) showCenter
31.25 663 (21) showCenter
42.125 663 (22) showCenter
53 663 (23) showCenter
63.875 663 (24) showCenter
74.75 663 (25) showCenter
85.625 663 (26) showCenter
96.5 663 (27) showCenter
31.25 654 (28) showCenter
42.125 654 (29) showCenter
53 654 (30) showCenter
63.875 654 (31) showCenter
MiniFont setfont
144 708 (May) showCenter
111.25 699 (S) showCenter
122.125 699 (M) showCenter
133 699 (T) showCenter
143.875 699 (W) showCenter
154.75 699 (T) showCenter
165.625 699 (F) showCenter
176.5 699 (S) showCenter
176.5 690 (1) showCenter
111.25 681 (2) showCenter
122.125 681 (3) showCenter
133 681 (4) showCenter
143.875 681 (5) showCenter
154.75 681 (6) showCenter
165.625 681 (7) showCenter
176.5 681 (8) showCenter
111.25 672 (9) showCenter
122.125 672 (10) showCenter
133 672 (11) showCenter
143.875 672 (12) showCenter
154.75 672 (13) showCenter
165.625 672 (14) showCenter
176.5 672 (15) showCenter
111.25 663 (16) showCenter
122.125 663 (17) showCenter
133 663 (18) showCenter
143.875 663 (19) showCenter
154.75 663 (20) showCenter
165.625 663 (21) showCenter
176.5 663 (22) showCenter
111.25 654 (23) showCenter
122.125 654 (24) showCenter
133 654 (25) showCenter
143.875 654 (26) showCenter
154.75 654 (27) showCenter
165.625 654 (28) showCenter
176.5 654 (29) showCenter
111.25 645 (30) showCenter
122.125 645 (31) showCenter
TitleFont setfont
306 742 (April 2010) showCenter
LabelFont setfont
64 723 (Sunday) showCenter
144 723 (Monday) showCenter
224 723 (Tuesday) showCenter
304 723 (Wednesday) showCenter
384 723 (Thursday) showCenter
464 723 (Friday) showCenter
544 723 (Saturday) showCenter
DateFont setfont
420 702 (1) showRight
500 702 (2) showRight
580 702 (3) showRight
100 606 (4) showRight
180 606 (5) showRight
260 606 (6) showRight
340 606 (7) showRight
420 606 (8) showRight
500 606 (9) showRight
580 606 (10) showRight
100 510 (11) showRight
180 510 (12) showRight
260 510 (13) showRight
340 510 (14) showRight
420 510 (15) showRight
500 510 (16) showRight
580 510 (17) showRight
100 414 (18) showRight
180 414 (19) showRight
260 414 (20) showRight
340 414 (21) showRight
420 414 (22) showRight
500 414 (23) showRight
580 414 (24) showRight
100 318 (25) showRight
180 318 (26) showRight
260 318 (27) showRight
340 318 (28) showRight
420 318 (29) showRight
500 318 (30) showRight
0.72 setlinewidth
334 96 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
499 exch 238 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 5 5
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 96 def
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
MiniFont setfont
64 708 (April) showCenter
31.25 699 (S) showCenter
42.125 699 (M) showCenter
53 699 (T) showCenter
63.875 699 (W) showCenter
74.75 699 (T) showCenter
85.625 699 (F) showCenter
96.5 699 (S) showCenter
74.75 690 (1) showCenter
85.625 690 (2) showCenter
96.5 690 (3) showCenter
31.25 681 (4) showCenter
42.125 681 (5) showCenter
53 681 (6) showCenter
63.875 681 (7) showCenter
74.75 681 (8) showCenter
85.625 681 (9) showCenter
96.5 681 (10) showCenter
31.25 672 (11) showCenter
42.125 672 (12) showCenter
53 672 (13) showCenter
63.875 672 (14) showCenter
74.75 672 (15) showCenter
85.625 672 (16) showCenter
96.5 672 (17) showCenter
31.25 663 (18) showCenter
42.125 663 (19) showCenter
53 663 (20) showCenter
63.875 663 (21) showCenter
74.75 663 (22) showCenter
85.625 663 (23) showCenter
96.5 663 (24) showCenter
31.25 654 (25) showCenter
42.125 654 (26) showCenter
53 654 (27) showCenter
63.875 654 (28) showCenter
74.75 654 (29) showCenter
85.625 654 (30) showCenter
MiniFont setfont
144 708 (June) showCenter
111.25 699 (S) showCenter
122.125 699 (M) showCenter
133 699 (T) showCenter
143.875 699 (W) showCenter
154.75 699 (T) showCenter
165.625 699 (F) showCenter
176.5 699 (S) showCenter
133 690 (1) showCenter
143.875 690 (2) showCenter
154.75 690 (3) showCenter
165.625 690 (4) showCenter
176.5 690 (5) showCenter
111.25 681 (6) showCenter
122.125 681 (7) showCenter
133 681 (8) showCenter
143.875 681 (9) showCenter
154.75 681 (10) showCenter
165.625 681 (11) showCenter
176.5 681 (12) showCenter
111.25 672 (13) showCenter
122.125 672 (14) showCenter
133 672 (15) showCenter
143.875 672 (16) showCenter
154.75 672 (17) showCenter
165.625 672 (18) showCenter
176.5 672 (19) showCenter
111.25 663 (20) showCenter
122.125 663 (21) showCenter
133 663 (22) showCenter
143.875 663 (23) showCenter
154.75 663 (24) showCenter
165.625 663 (25) showCenter
176.5 663 (26) showCenter
111.25 654 (27) showCenter
122.125 654 (28) showCenter
133 654 (29) showCenter
143.875 654 (30) showCenter
TitleFont setfont
306 742 (May 2010) showCenter
LabelFont setfont
64 723 (Sunday) showCenter
144 723 (Monday) showCenter
224 723 (Tuesday) showCenter
304 723 (Wednesday) showCenter
384 723 (Thursday) showCenter
464 723 (Friday) showCenter
544 723 (Saturday) showCenter
DateFont setfont
580 702 (1) showRight
100 606 (2) showRight
180 606 (3) showRight
260 606 (4) showRight
340 606 (5) showRight
420 606 (6) showRight
500 606 (7) showRight
580 606 (8) showRight
100 510 (9) showRight
180 510 (10) showRight
260 510 (11) showRight
340 510 (12) showRight
420 510 (13) showRight
500 510 (14) showRight
580 510 (15) showRight
100 414 (16) showRight
180 414 (17) showRight
260 414 (18) showRight
340 414 (19) showRight
420 414 (20) showRight
500 414 (21) showRight
580 414 (22) showRight
100 318 (23) showRight
180 318 (24) showRight
260 318 (25) showRight
340 318 (26) showRight
420 318 (27) showRight
500 318 (28) showRight
580 318 (29) showRight
100 222 (30) showRight
180 222 (31) showRight
0.72 setlinewidth
238 96 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
595 exch 142 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -595 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 6 6
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 96 def
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
MiniFont setfont
64 708 (May) showCenter
31.25 699 (S) showCenter
42.125 699 (M) showCenter
53 699 (T) showCenter
63.875 699 (W) showCenter
74.75 699 (T) showCenter
85.625 699 (F) showCenter
96.5 699 (S) showCenter
96.5 690 (1) showCenter
31.25 681 (2) showCenter
42.125 681 (3) showCenter
53 681 (4) showCenter
63.875 681 (5) showCenter
74.75 681 (6) showCenter
85.625 681 (7) showCenter
96.5 681 (8) showCenter
31.25 672 (9) showCenter
42.125 672 (10) showCenter
53 672 (11) showCenter
63.875 672 (12) showCenter
74.75 672 (13) showCenter
85.625 672 (14) showCenter
96.5 672 (15) showCenter
31.25 663 (16) showCenter
42.125 663 (17) showCenter
53 663 (18) showCenter
63.875 663 (19) showCenter
74.75 663 (20) showCenter
85.625 663 (21) showCenter
96.5 663 (22) showCenter
31.25 654 (23) showCenter
42.125 654 (24) showCenter
53 654 (25) showCenter
63.875 654 (26) showCenter
74.75 654 (27) showCenter
85.625 654 (28) showCenter
96.5 654 (29) showCenter
31.25 645 (30) showCenter
42.125 645 (31) showCenter
MiniFont setfont
144 708 (July) showCenter
111.25 699 (S) showCenter
122.125 699 (M) showCenter
133 699 (T) showCenter
143.875 699 (W) showCenter
154.75 699 (T) showCenter
165.625 699 (F) showCenter
176.5 699 (S) showCenter
154.75 690 (1) showCenter
165.625 690 (2) showCenter
176.5 690 (3) showCenter
111.25 681 (4) showCenter
122.125 681 (5) showCenter
133 681 (6) showCenter
143.875 681 (7) showCenter
154.75 681 (8) showCenter
165.625 681 (9) showCenter
176.5 681 (10) showCenter
111.25 672 (11) showCenter
122.125 672 (12) showCenter
133 672 (13) showCenter
143.875 672 (14) showCenter
154.75 672 (15) showCenter
165.625 672 (16) showCenter
176.5 672 (17) showCenter
111.25 663 (18) showCenter
122.125 663 (19) showCenter
133 663 (20) showCenter
143.875 663 (21) showCenter
154.75 663 (22) showCenter
165.625 663 (23) showCenter
176.5 663 (24) showCenter
111.25 654 (25) showCenter
122.125 654 (26) showCenter
133 654 (27) showCenter
143.875 654 (28) showCenter
154.75 654 (29) showCenter
165.625 654 (30) showCenter
176.5 654 (31) showCenter
TitleFont setfont
306 742 (June 2010) showCenter
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
100 606 (6) showRight
180 606 (7) showRight
260 606 (8) showRight
340 606 (9) showRight
420 606 (10) showRight
500 606 (11) showRight
580 606 (12) showRight
100 510 (13) showRight
180 510 (14) showRight
260 510 (15) showRight
340 510 (16) showRight
420 510 (17) showRight
500 510 (18) showRight
580 510 (19) showRight
100 414 (20) showRight
180 414 (21) showRight
260 414 (22) showRight
340 414 (23) showRight
420 414 (24) showRight
500 414 (25) showRight
580 414 (26) showRight
100 318 (27) showRight
180 318 (28) showRight
260 318 (29) showRight
340 318 (30) showRight
0.72 setlinewidth
334 96 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
499 exch 238 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 7 7
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 96 def
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
MiniFont setfont
64 708 (June) showCenter
31.25 699 (S) showCenter
42.125 699 (M) showCenter
53 699 (T) showCenter
63.875 699 (W) showCenter
74.75 699 (T) showCenter
85.625 699 (F) showCenter
96.5 699 (S) showCenter
53 690 (1) showCenter
63.875 690 (2) showCenter
74.75 690 (3) showCenter
85.625 690 (4) showCenter
96.5 690 (5) showCenter
31.25 681 (6) showCenter
42.125 681 (7) showCenter
53 681 (8) showCenter
63.875 681 (9) showCenter
74.75 681 (10) showCenter
85.625 681 (11) showCenter
96.5 681 (12) showCenter
31.25 672 (13) showCenter
42.125 672 (14) showCenter
53 672 (15) showCenter
63.875 672 (16) showCenter
74.75 672 (17) showCenter
85.625 672 (18) showCenter
96.5 672 (19) showCenter
31.25 663 (20) showCenter
42.125 663 (21) showCenter
53 663 (22) showCenter
63.875 663 (23) showCenter
74.75 663 (24) showCenter
85.625 663 (25) showCenter
96.5 663 (26) showCenter
31.25 654 (27) showCenter
42.125 654 (28) showCenter
53 654 (29) showCenter
63.875 654 (30) showCenter
MiniFont setfont
144 708 (August) showCenter
111.25 699 (S) showCenter
122.125 699 (M) showCenter
133 699 (T) showCenter
143.875 699 (W) showCenter
154.75 699 (T) showCenter
165.625 699 (F) showCenter
176.5 699 (S) showCenter
111.25 690 (1) showCenter
122.125 690 (2) showCenter
133 690 (3) showCenter
143.875 690 (4) showCenter
154.75 690 (5) showCenter
165.625 690 (6) showCenter
176.5 690 (7) showCenter
111.25 681 (8) showCenter
122.125 681 (9) showCenter
133 681 (10) showCenter
143.875 681 (11) showCenter
154.75 681 (12) showCenter
165.625 681 (13) showCenter
176.5 681 (14) showCenter
111.25 672 (15) showCenter
122.125 672 (16) showCenter
133 672 (17) showCenter
143.875 672 (18) showCenter
154.75 672 (19) showCenter
165.625 672 (20) showCenter
176.5 672 (21) showCenter
111.25 663 (22) showCenter
122.125 663 (23) showCenter
133 663 (24) showCenter
143.875 663 (25) showCenter
154.75 663 (26) showCenter
165.625 663 (27) showCenter
176.5 663 (28) showCenter
111.25 654 (29) showCenter
122.125 654 (30) showCenter
133 654 (31) showCenter
TitleFont setfont
306 742 (July 2010) showCenter
LabelFont setfont
64 723 (Sunday) showCenter
144 723 (Monday) showCenter
224 723 (Tuesday) showCenter
304 723 (Wednesday) showCenter
384 723 (Thursday) showCenter
464 723 (Friday) showCenter
544 723 (Saturday) showCenter
DateFont setfont
420 702 (1) showRight
500 702 (2) showRight
580 702 (3) showRight
100 606 (4) showRight
180 606 (5) showRight
260 606 (6) showRight
340 606 (7) showRight
420 606 (8) showRight
500 606 (9) showRight
580 606 (10) showRight
100 510 (11) showRight
180 510 (12) showRight
260 510 (13) showRight
340 510 (14) showRight
420 510 (15) showRight
500 510 (16) showRight
580 510 (17) showRight
100 414 (18) showRight
180 414 (19) showRight
260 414 (20) showRight
340 414 (21) showRight
420 414 (22) showRight
500 414 (23) showRight
580 414 (24) showRight
100 318 (25) showRight
180 318 (26) showRight
260 318 (27) showRight
340 318 (28) showRight
420 318 (29) showRight
500 318 (30) showRight
580 318 (31) showRight
0.72 setlinewidth
334 96 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
499 exch 238 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 8 8
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 96 def
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
MiniFont setfont
464 324 (July) showCenter
431.25 315 (S) showCenter
442.125 315 (M) showCenter
453 315 (T) showCenter
463.875 315 (W) showCenter
474.75 315 (T) showCenter
485.625 315 (F) showCenter
496.5 315 (S) showCenter
474.75 306 (1) showCenter
485.625 306 (2) showCenter
496.5 306 (3) showCenter
431.25 297 (4) showCenter
442.125 297 (5) showCenter
453 297 (6) showCenter
463.875 297 (7) showCenter
474.75 297 (8) showCenter
485.625 297 (9) showCenter
496.5 297 (10) showCenter
431.25 288 (11) showCenter
442.125 288 (12) showCenter
453 288 (13) showCenter
463.875 288 (14) showCenter
474.75 288 (15) showCenter
485.625 288 (16) showCenter
496.5 288 (17) showCenter
431.25 279 (18) showCenter
442.125 279 (19) showCenter
453 279 (20) showCenter
463.875 279 (21) showCenter
474.75 279 (22) showCenter
485.625 279 (23) showCenter
496.5 279 (24) showCenter
431.25 270 (25) showCenter
442.125 270 (26) showCenter
453 270 (27) showCenter
463.875 270 (28) showCenter
474.75 270 (29) showCenter
485.625 270 (30) showCenter
496.5 270 (31) showCenter
MiniFont setfont
544 324 (September) showCenter
511.25 315 (S) showCenter
522.125 315 (M) showCenter
533 315 (T) showCenter
543.875 315 (W) showCenter
554.75 315 (T) showCenter
565.625 315 (F) showCenter
576.5 315 (S) showCenter
543.875 306 (1) showCenter
554.75 306 (2) showCenter
565.625 306 (3) showCenter
576.5 306 (4) showCenter
511.25 297 (5) showCenter
522.125 297 (6) showCenter
533 297 (7) showCenter
543.875 297 (8) showCenter
554.75 297 (9) showCenter
565.625 297 (10) showCenter
576.5 297 (11) showCenter
511.25 288 (12) showCenter
522.125 288 (13) showCenter
533 288 (14) showCenter
543.875 288 (15) showCenter
554.75 288 (16) showCenter
565.625 288 (17) showCenter
576.5 288 (18) showCenter
511.25 279 (19) showCenter
522.125 279 (20) showCenter
533 279 (21) showCenter
543.875 279 (22) showCenter
554.75 279 (23) showCenter
565.625 279 (24) showCenter
576.5 279 (25) showCenter
511.25 270 (26) showCenter
522.125 270 (27) showCenter
533 270 (28) showCenter
543.875 270 (29) showCenter
554.75 270 (30) showCenter
TitleFont setfont
306 742 (August 2010) showCenter
LabelFont setfont
64 723 (Sunday) showCenter
144 723 (Monday) showCenter
224 723 (Tuesday) showCenter
304 723 (Wednesday) showCenter
384 723 (Thursday) showCenter
464 723 (Friday) showCenter
544 723 (Saturday) showCenter
DateFont setfont
100 702 (1) showRight
180 702 (2) showRight
260 702 (3) showRight
340 702 (4) showRight
420 702 (5) showRight
500 702 (6) showRight
580 702 (7) showRight
100 606 (8) showRight
180 606 (9) showRight
260 606 (10) showRight
340 606 (11) showRight
420 606 (12) showRight
500 606 (13) showRight
580 606 (14) showRight
100 510 (15) showRight
180 510 (16) showRight
260 510 (17) showRight
340 510 (18) showRight
420 510 (19) showRight
500 510 (20) showRight
580 510 (21) showRight
100 414 (22) showRight
180 414 (23) showRight
260 414 (24) showRight
340 414 (25) showRight
420 414 (26) showRight
500 414 (27) showRight
580 414 (28) showRight
100 318 (29) showRight
180 318 (30) showRight
260 318 (31) showRight
0.72 setlinewidth
334 96 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
499 exch 238 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 9 9
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 96 def
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
MiniFont setfont
64 708 (August) showCenter
31.25 699 (S) showCenter
42.125 699 (M) showCenter
53 699 (T) showCenter
63.875 699 (W) showCenter
74.75 699 (T) showCenter
85.625 699 (F) showCenter
96.5 699 (S) showCenter
31.25 690 (1) showCenter
42.125 690 (2) showCenter
53 690 (3) showCenter
63.875 690 (4) showCenter
74.75 690 (5) showCenter
85.625 690 (6) showCenter
96.5 690 (7) showCenter
31.25 681 (8) showCenter
42.125 681 (9) showCenter
53 681 (10) showCenter
63.875 681 (11) showCenter
74.75 681 (12) showCenter
85.625 681 (13) showCenter
96.5 681 (14) showCenter
31.25 672 (15) showCenter
42.125 672 (16) showCenter
53 672 (17) showCenter
63.875 672 (18) showCenter
74.75 672 (19) showCenter
85.625 672 (20) showCenter
96.5 672 (21) showCenter
31.25 663 (22) showCenter
42.125 663 (23) showCenter
53 663 (24) showCenter
63.875 663 (25) showCenter
74.75 663 (26) showCenter
85.625 663 (27) showCenter
96.5 663 (28) showCenter
31.25 654 (29) showCenter
42.125 654 (30) showCenter
53 654 (31) showCenter
MiniFont setfont
144 708 (October) showCenter
111.25 699 (S) showCenter
122.125 699 (M) showCenter
133 699 (T) showCenter
143.875 699 (W) showCenter
154.75 699 (T) showCenter
165.625 699 (F) showCenter
176.5 699 (S) showCenter
165.625 690 (1) showCenter
176.5 690 (2) showCenter
111.25 681 (3) showCenter
122.125 681 (4) showCenter
133 681 (5) showCenter
143.875 681 (6) showCenter
154.75 681 (7) showCenter
165.625 681 (8) showCenter
176.5 681 (9) showCenter
111.25 672 (10) showCenter
122.125 672 (11) showCenter
133 672 (12) showCenter
143.875 672 (13) showCenter
154.75 672 (14) showCenter
165.625 672 (15) showCenter
176.5 672 (16) showCenter
111.25 663 (17) showCenter
122.125 663 (18) showCenter
133 663 (19) showCenter
143.875 663 (20) showCenter
154.75 663 (21) showCenter
165.625 663 (22) showCenter
176.5 663 (23) showCenter
111.25 654 (24) showCenter
122.125 654 (25) showCenter
133 654 (26) showCenter
143.875 654 (27) showCenter
154.75 654 (28) showCenter
165.625 654 (29) showCenter
176.5 654 (30) showCenter
111.25 645 (31) showCenter
TitleFont setfont
306 742 (September 2010) showCenter
LabelFont setfont
64 723 (Sunday) showCenter
144 723 (Monday) showCenter
224 723 (Tuesday) showCenter
304 723 (Wednesday) showCenter
384 723 (Thursday) showCenter
464 723 (Friday) showCenter
544 723 (Saturday) showCenter
DateFont setfont
340 702 (1) showRight
420 702 (2) showRight
500 702 (3) showRight
580 702 (4) showRight
100 606 (5) showRight
180 606 (6) showRight
260 606 (7) showRight
340 606 (8) showRight
420 606 (9) showRight
500 606 (10) showRight
580 606 (11) showRight
100 510 (12) showRight
180 510 (13) showRight
260 510 (14) showRight
340 510 (15) showRight
420 510 (16) showRight
500 510 (17) showRight
580 510 (18) showRight
100 414 (19) showRight
180 414 (20) showRight
260 414 (21) showRight
340 414 (22) showRight
420 414 (23) showRight
500 414 (24) showRight
580 414 (25) showRight
100 318 (26) showRight
180 318 (27) showRight
260 318 (28) showRight
340 318 (29) showRight
420 318 (30) showRight
0.72 setlinewidth
334 96 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
499 exch 238 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 10 10
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 96 def
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
MiniFont setfont
64 708 (September) showCenter
31.25 699 (S) showCenter
42.125 699 (M) showCenter
53 699 (T) showCenter
63.875 699 (W) showCenter
74.75 699 (T) showCenter
85.625 699 (F) showCenter
96.5 699 (S) showCenter
63.875 690 (1) showCenter
74.75 690 (2) showCenter
85.625 690 (3) showCenter
96.5 690 (4) showCenter
31.25 681 (5) showCenter
42.125 681 (6) showCenter
53 681 (7) showCenter
63.875 681 (8) showCenter
74.75 681 (9) showCenter
85.625 681 (10) showCenter
96.5 681 (11) showCenter
31.25 672 (12) showCenter
42.125 672 (13) showCenter
53 672 (14) showCenter
63.875 672 (15) showCenter
74.75 672 (16) showCenter
85.625 672 (17) showCenter
96.5 672 (18) showCenter
31.25 663 (19) showCenter
42.125 663 (20) showCenter
53 663 (21) showCenter
63.875 663 (22) showCenter
74.75 663 (23) showCenter
85.625 663 (24) showCenter
96.5 663 (25) showCenter
31.25 654 (26) showCenter
42.125 654 (27) showCenter
53 654 (28) showCenter
63.875 654 (29) showCenter
74.75 654 (30) showCenter
MiniFont setfont
144 708 (November) showCenter
111.25 699 (S) showCenter
122.125 699 (M) showCenter
133 699 (T) showCenter
143.875 699 (W) showCenter
154.75 699 (T) showCenter
165.625 699 (F) showCenter
176.5 699 (S) showCenter
122.125 690 (1) showCenter
133 690 (2) showCenter
143.875 690 (3) showCenter
154.75 690 (4) showCenter
165.625 690 (5) showCenter
176.5 690 (6) showCenter
111.25 681 (7) showCenter
122.125 681 (8) showCenter
133 681 (9) showCenter
143.875 681 (10) showCenter
154.75 681 (11) showCenter
165.625 681 (12) showCenter
176.5 681 (13) showCenter
111.25 672 (14) showCenter
122.125 672 (15) showCenter
133 672 (16) showCenter
143.875 672 (17) showCenter
154.75 672 (18) showCenter
165.625 672 (19) showCenter
176.5 672 (20) showCenter
111.25 663 (21) showCenter
122.125 663 (22) showCenter
133 663 (23) showCenter
143.875 663 (24) showCenter
154.75 663 (25) showCenter
165.625 663 (26) showCenter
176.5 663 (27) showCenter
111.25 654 (28) showCenter
122.125 654 (29) showCenter
133 654 (30) showCenter
TitleFont setfont
306 742 (October 2010) showCenter
LabelFont setfont
64 723 (Sunday) showCenter
144 723 (Monday) showCenter
224 723 (Tuesday) showCenter
304 723 (Wednesday) showCenter
384 723 (Thursday) showCenter
464 723 (Friday) showCenter
544 723 (Saturday) showCenter
DateFont setfont
500 702 (1) showRight
580 702 (2) showRight
100 606 (3) showRight
180 606 (4) showRight
260 606 (5) showRight
340 606 (6) showRight
420 606 (7) showRight
500 606 (8) showRight
580 606 (9) showRight
100 510 (10) showRight
180 510 (11) showRight
260 510 (12) showRight
340 510 (13) showRight
420 510 (14) showRight
500 510 (15) showRight
580 510 (16) showRight
100 414 (17) showRight
180 414 (18) showRight
260 414 (19) showRight
340 414 (20) showRight
420 414 (21) showRight
500 414 (22) showRight
580 414 (23) showRight
100 318 (24) showRight
180 318 (25) showRight
260 318 (26) showRight
340 318 (27) showRight
420 318 (28) showRight
500 318 (29) showRight
580 318 (30) showRight
100 222 (31) showRight
0.72 setlinewidth
238 96 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
595 exch 142 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -595 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 11 11
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 96 def
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
MiniFont setfont
464 324 (October) showCenter
431.25 315 (S) showCenter
442.125 315 (M) showCenter
453 315 (T) showCenter
463.875 315 (W) showCenter
474.75 315 (T) showCenter
485.625 315 (F) showCenter
496.5 315 (S) showCenter
485.625 306 (1) showCenter
496.5 306 (2) showCenter
431.25 297 (3) showCenter
442.125 297 (4) showCenter
453 297 (5) showCenter
463.875 297 (6) showCenter
474.75 297 (7) showCenter
485.625 297 (8) showCenter
496.5 297 (9) showCenter
431.25 288 (10) showCenter
442.125 288 (11) showCenter
453 288 (12) showCenter
463.875 288 (13) showCenter
474.75 288 (14) showCenter
485.625 288 (15) showCenter
496.5 288 (16) showCenter
431.25 279 (17) showCenter
442.125 279 (18) showCenter
453 279 (19) showCenter
463.875 279 (20) showCenter
474.75 279 (21) showCenter
485.625 279 (22) showCenter
496.5 279 (23) showCenter
431.25 270 (24) showCenter
442.125 270 (25) showCenter
453 270 (26) showCenter
463.875 270 (27) showCenter
474.75 270 (28) showCenter
485.625 270 (29) showCenter
496.5 270 (30) showCenter
431.25 261 (31) showCenter
MiniFont setfont
544 324 (December) showCenter
511.25 315 (S) showCenter
522.125 315 (M) showCenter
533 315 (T) showCenter
543.875 315 (W) showCenter
554.75 315 (T) showCenter
565.625 315 (F) showCenter
576.5 315 (S) showCenter
543.875 306 (1) showCenter
554.75 306 (2) showCenter
565.625 306 (3) showCenter
576.5 306 (4) showCenter
511.25 297 (5) showCenter
522.125 297 (6) showCenter
533 297 (7) showCenter
543.875 297 (8) showCenter
554.75 297 (9) showCenter
565.625 297 (10) showCenter
576.5 297 (11) showCenter
511.25 288 (12) showCenter
522.125 288 (13) showCenter
533 288 (14) showCenter
543.875 288 (15) showCenter
554.75 288 (16) showCenter
565.625 288 (17) showCenter
576.5 288 (18) showCenter
511.25 279 (19) showCenter
522.125 279 (20) showCenter
533 279 (21) showCenter
543.875 279 (22) showCenter
554.75 279 (23) showCenter
565.625 279 (24) showCenter
576.5 279 (25) showCenter
511.25 270 (26) showCenter
522.125 270 (27) showCenter
533 270 (28) showCenter
543.875 270 (29) showCenter
554.75 270 (30) showCenter
565.625 270 (31) showCenter
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
100 606 (7) showRight
180 606 (8) showRight
260 606 (9) showRight
340 606 (10) showRight
420 606 (11) showRight
500 606 (12) showRight
580 606 (13) showRight
100 510 (14) showRight
180 510 (15) showRight
260 510 (16) showRight
340 510 (17) showRight
420 510 (18) showRight
500 510 (19) showRight
580 510 (20) showRight
100 414 (21) showRight
180 414 (22) showRight
260 414 (23) showRight
340 414 (24) showRight
420 414 (25) showRight
500 414 (26) showRight
580 414 (27) showRight
100 318 (28) showRight
180 318 (29) showRight
260 318 (30) showRight
0.72 setlinewidth
334 96 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
499 exch 238 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 12 12
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
/DayHeight 96 def
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
MiniFont setfont
64 708 (November) showCenter
31.25 699 (S) showCenter
42.125 699 (M) showCenter
53 699 (T) showCenter
63.875 699 (W) showCenter
74.75 699 (T) showCenter
85.625 699 (F) showCenter
96.5 699 (S) showCenter
42.125 690 (1) showCenter
53 690 (2) showCenter
63.875 690 (3) showCenter
74.75 690 (4) showCenter
85.625 690 (5) showCenter
96.5 690 (6) showCenter
31.25 681 (7) showCenter
42.125 681 (8) showCenter
53 681 (9) showCenter
63.875 681 (10) showCenter
74.75 681 (11) showCenter
85.625 681 (12) showCenter
96.5 681 (13) showCenter
31.25 672 (14) showCenter
42.125 672 (15) showCenter
53 672 (16) showCenter
63.875 672 (17) showCenter
74.75 672 (18) showCenter
85.625 672 (19) showCenter
96.5 672 (20) showCenter
31.25 663 (21) showCenter
42.125 663 (22) showCenter
53 663 (23) showCenter
63.875 663 (24) showCenter
74.75 663 (25) showCenter
85.625 663 (26) showCenter
96.5 663 (27) showCenter
31.25 654 (28) showCenter
42.125 654 (29) showCenter
53 654 (30) showCenter
MiniFont setfont
144 708 (January) showCenter
111.25 699 (S) showCenter
122.125 699 (M) showCenter
133 699 (T) showCenter
143.875 699 (W) showCenter
154.75 699 (T) showCenter
165.625 699 (F) showCenter
176.5 699 (S) showCenter
176.5 690 (1) showCenter
111.25 681 (2) showCenter
122.125 681 (3) showCenter
133 681 (4) showCenter
143.875 681 (5) showCenter
154.75 681 (6) showCenter
165.625 681 (7) showCenter
176.5 681 (8) showCenter
111.25 672 (9) showCenter
122.125 672 (10) showCenter
133 672 (11) showCenter
143.875 672 (12) showCenter
154.75 672 (13) showCenter
165.625 672 (14) showCenter
176.5 672 (15) showCenter
111.25 663 (16) showCenter
122.125 663 (17) showCenter
133 663 (18) showCenter
143.875 663 (19) showCenter
154.75 663 (20) showCenter
165.625 663 (21) showCenter
176.5 663 (22) showCenter
111.25 654 (23) showCenter
122.125 654 (24) showCenter
133 654 (25) showCenter
143.875 654 (26) showCenter
154.75 654 (27) showCenter
165.625 654 (28) showCenter
176.5 654 (29) showCenter
111.25 645 (30) showCenter
122.125 645 (31) showCenter
TitleFont setfont
306 742 (December 2010) showCenter
LabelFont setfont
64 723 (Sunday) showCenter
144 723 (Monday) showCenter
224 723 (Tuesday) showCenter
304 723 (Wednesday) showCenter
384 723 (Thursday) showCenter
464 723 (Friday) showCenter
544 723 (Saturday) showCenter
DateFont setfont
340 702 (1) showRight
420 702 (2) showRight
500 702 (3) showRight
580 702 (4) showRight
100 606 (5) showRight
180 606 (6) showRight
260 606 (7) showRight
340 606 (8) showRight
420 606 (9) showRight
500 606 (10) showRight
580 606 (11) showRight
100 510 (12) showRight
180 510 (13) showRight
260 510 (14) showRight
340 510 (15) showRight
420 510 (16) showRight
500 510 (17) showRight
580 510 (18) showRight
100 414 (19) showRight
180 414 (20) showRight
260 414 (21) showRight
340 414 (22) showRight
420 414 (23) showRight
500 414 (24) showRight
580 414 (25) showRight
100 318 (26) showRight
180 318 (27) showRight
260 318 (28) showRight
340 318 (29) showRight
420 318 (30) showRight
500 318 (31) showRight
0.72 setlinewidth
334 96 718 {
560 24 3 -1 roll hLine
} for
104 80 544 {
499 exch 238 vLine
} for
0.72 setlinewidth
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
END CALENDAR

  done_testing();
} # end else running the test

# Local Variables:
# compile-command: "perl 20-yearly.t gen"
# End:

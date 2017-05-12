#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2011 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 5 Oct 2011
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test the content of generated PostScript grids
#---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

use Test::More 0.88;            # want done_testing

# SUGGEST PREREQ: Test::Differences 0 (better output for failures)
# Load Test::Differences, if available:
BEGIN {
  if (eval "use Test::Differences; 1") {
    # Not all versions of Test::Differences support changing the style:
    eval { Test::Differences::unified_diff() }
  } else {
    eval '*eq_or_diff = \&is;'; # Just use "is" instead
  }
} # end BEGIN

use DateTime ();
use PostScript::ScheduleGrid ();

#---------------------------------------------------------------------
sub dt # Trivial parser to create DateTime objects
{
  my %dt = qw(time_zone local);
  @dt{qw( year month day hour minute )} = split /\D+/, $_[0];
  while (my ($k, $v) = each %dt) { delete $dt{$k} unless defined $v }
  DateTime->new(\%dt);
} # end dt

#=====================================================================
my $generateResults;

if (@ARGV and $ARGV[0] eq 'gen') {
  # Just output the actual results, so they can be diffed against this file
  $generateResults = 1;
  open(OUT, '>', '/tmp/10-content.t') or die $!;
  printf OUT "#%s\n\n__DATA__\n", '=' x 69;
} else {
  plan tests => 3 * 2;
}

while (<DATA>) {
  print OUT $_ if $generateResults;

  next if /^#[^#]/ or not /\S/;

  /^##\s*(.+)/ or die "Expected test name, got $_";
  my $name = $1;

  # Read the constructor parameters:
  my $param = '';
  while (<DATA>) {
    print OUT $_ if $generateResults;
    last if $_ eq "<<'---END---';\n";
    $param .= $_;
  } # end while <DATA>

  die "Expected <<'---END---';" unless defined $_;

  # Read the expected results:
  my $expected = '';
  while (<DATA>) {
    last if $_ eq "---END---\n";
    $expected .= $_;
  }

  # Run the test:
  my $hash = eval $param;
  die $@ unless ref $hash;

  my $grid = PostScript::ScheduleGrid->new($hash);
  isa_ok($grid, 'PostScript::ScheduleGrid', $name)
      unless $generateResults;

  my $got = $grid->ps->testable_output;

  # Clean up version numbers in the output:
  $got =~ s/( procset PostScript_ScheduleGrid_\w+) [0-9. ]+/$1 0 0/g;
  $got =~ s/( procset PostScript_ScheduleGrid)_\d+_\d+ /$1 /g;

  # Either print the actual results, or compare to expected results:
  if ($generateResults) {
    print OUT "$got---END---\n";
  } else {
    eq_or_diff($got, $expected, "$name output");
  }
} # end while <DATA>

done_testing unless $generateResults;

#=====================================================================
sub simple_resources
{
  my @c = @_;

  no warnings 'syntax'; # I really do intend to use single element slices

  for (@c) { undef $_ if $_ eq '.' }

  [
   { name => '2 FOO',
     schedule => [
       [ dt('2011-10-02 18'),dt('2011-10-02 19'), 'First show', @c[0]],
       [ dt('2011-10-02 19'),dt('2011-10-02 20'), 'Second show', @c[1]],
       [ dt('2011-10-02 20'),dt('2011-10-02 20:30'), 'First 1/2 show', @c[2]],
       [ dt('2011-10-02 21'),dt('2011-10-02 22'), 'Last show', @c[3]],
       [ dt('2011-10-02 20:30'),dt('2011-10-02 21'), 'Second 1/2', @c[4]],
     ],
   }, # end channel 2 FOO
   { name => '1 Channel',
     schedule => [
       [ dt('2011-10-02 18'), dt('2011-10-02 22'), 'Long show.', @c[5]],
     ],
   }, # end channel 1 Channel
  ]
} # end simple_resources

#=====================================================================

__DATA__

## simplest
{
  start_date => dt('2011-10-02 18'),
  end_date   => dt('2011-10-02 22'),
  resources => simple_resources,
}
<<'---END---';
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Bold
%%DocumentSuppliedResources:
%%+ procset PostScript_ScheduleGrid 0 0
%%Title: TV Grid
%%PageOrder: Ascend
%%EndComments
%%BeginProlog
%%BeginResource: procset PostScript_ScheduleGrid 0 0
/pixel {72 mul 300 div} def % 300 dpi only
/C                             % HEIGHT WIDTH LEFT VPOS C
{
gsave
newpath moveto                % HEIGHT WIDTH
dup 0 rlineto                 % HEIGHT WIDTH
0 3 -1 roll rlineto           % WIDTH
-1 mul 0 rlineto
closepath clip
} def
/R {grestore} def
/H                             % YPOS H
{
newpath
0 exch moveto
567.8125 0 rlineto
stroke
} def
/P1 {1 pixel setlinewidth} def
/P2 {2 pixel setlinewidth} def
/S                             % STRING X Y S
{
newpath moveto show
} def
/V                             % XPOS YPOS HEIGHT V
{
newpath
3 1 roll
moveto
0 exch rlineto
stroke
} def
%---------------------------------------------------------------------
% Print the date, times, resource names, & exterior grid:
%
% HEADER TIME1 TIME2 ... TIME12
%
% Enter with CellFont selected
% Leaves the linewidth set to 2 pixels
/prg
{
ResourceTitle 1.40625 32.5 S
ResourceTitle 1.40625 2.5 S
TitleFont setfont
535.1875
-65.25 45.8125
% stack (TIME XPOS)
{
dup 31.6875 3 index showCenter
1.6875 3 -1 roll showCenter
} for
(2 FOO)21.6875(1 Channel)11.6875
2 {1.40625 exch S} repeat
HeadFont setfont
45.8125 43 S
P1
newpath
0 0 moveto
567.8125 0 rlineto
567.8125 40 lineto
0 40 lineto
closepath stroke
111.0625 130.5 556.9375
{dup 30 10 V 0 10 V} for
30 20 10
3 {H} repeat
P2
176.3125 130.5 566.8125
{dup 30 10 V 0 10 V} for
45.8125 0 40 V
} def
%%EndResource
%%EndProlog
%%BeginSetup
/CellFont   /Helvetica-iso    findfont  7    scalefont  def
/HeadFont   /Helvetica-Bold-iso findfont  12 scalefont  def
/TitleFont  /Helvetica-Bold-iso   findfont  9   scalefont  def
/ResourceTitle () def
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 22 36 590 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
22 0 translate
0 701 translate
CellFont setfont
0 setlinecap
10 130.5 45.8125 20 C
(First show) 47.21875 22.5 S
R
10 130.5 176.3125 20 C
(Second show) 177.71875 22.5 S
R
10 65.25 306.8125 20 C
(First 1/2 show) 308.21875 22.5 S
R
10 65.25 372.0625 20 C
(Second 1/2) 373.46875 22.5 S
R
10 130.5 437.3125 20 C
(Last show) 438.71875 22.5 S
R
10 522 45.8125 10 C
(Long show.) 47.21875 12.5 S
R
(Sunday, October 2, 2011)(6 PM)(6:30)(7 PM)(7:30)(8 PM)(8:30)(9 PM)(9:30)prg
176.3125 20 306.8125 20 437.3125 20
3 {10 V} repeat
P1
372.0625 20
1 {10 V} repeat
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---END---

## fancier
{
  start_date => dt('2011-10-02 18'),
  end_date   => dt('2011-10-02 22'),
  resource_title => 'Channel',
  time_headers => ['h:mm a', 'h:mm a'],
  categories => { GR => [qw(Stripe direction right)],
                  GL => 'Stripe',
                  G => 'Solid' },
  resources => simple_resources(qw(G . GR . GR GL)),
}
<<'---END---';
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Bold
%%DocumentSuppliedResources:
%%+ procset PostScript_ScheduleGrid_Style_Stripe 0 0
%%+ procset PostScript_ScheduleGrid 0 0
%%Title: TV Grid
%%PageOrder: Ascend
%%EndComments
%%BeginProlog
%%BeginResource: procset PostScript_ScheduleGrid_Style_Stripe 0 0
/sStripe-R % round X down to a multiple of N
{				% X N
exch	1 index			% N X N
div  truncate  mul
} bind def
/sStripe-P % common prep
{
setColor
6 setlinewidth
2 setlinecap
clippath pathbbox newpath     % (LLX LLY URX URY)
4 2 roll                      % (URX URY LLX LLY)
18 sStripe-R                  % (URX URY LLX LLY1)
4 1 roll                      % (LLY1 URX URY LLX)
18 sStripe-R                  % (LLY1 URX URY LLX1)
4 1 roll                      % (LLX1 LLY1 URX URY)
2 index                       % (LLX Bot URX URY LLY)
sub                           % (LLX Bot URX Height)
} def
%%EndResource
%%BeginResource: procset PostScript_ScheduleGrid 0 0
/pixel {72 mul 300 div} def % 300 dpi only
/C                             % HEIGHT WIDTH LEFT VPOS C
{
gsave
newpath moveto                % HEIGHT WIDTH
dup 0 rlineto                 % HEIGHT WIDTH
0 3 -1 roll rlineto           % WIDTH
-1 mul 0 rlineto
closepath clip
} def
/R {grestore} def
/H                             % YPOS H
{
newpath
0 exch moveto
567.8125 0 rlineto
stroke
} def
/P1 {1 pixel setlinewidth} def
/P2 {2 pixel setlinewidth} def
/S                             % STRING X Y S
{
newpath moveto show
} def
/V                             % XPOS YPOS HEIGHT V
{
newpath
3 1 roll
moveto
0 exch rlineto
stroke
} def
%---------------------------------------------------------------------
% Print the date, times, resource names, & exterior grid:
%
% HEADER TIME1 TIME2 ... TIME12
%
% Enter with CellFont selected
% Leaves the linewidth set to 2 pixels
/prg
{
ResourceTitle 1.40625 32.5 S
ResourceTitle 1.40625 2.5 S
TitleFont setfont
535.1875
-65.25 45.8125
% stack (TIME XPOS)
{
dup 31.6875 3 index showCenter
1.6875 3 -1 roll showCenter
} for
(2 FOO)21.6875(1 Channel)11.6875
2 {1.40625 exch S} repeat
HeadFont setfont
45.8125 43 S
P1
newpath
0 0 moveto
567.8125 0 rlineto
567.8125 40 lineto
0 40 lineto
closepath stroke
111.0625 130.5 556.9375
{dup 30 10 V 0 10 V} for
30 20 10
3 {H} repeat
P2
176.3125 130.5 566.8125
{dup 30 10 V 0 10 V} for
45.8125 0 40 V
} def
/SA
{
0.85 setColor
clippath fill
0 setColor
} def
/SB
{
0.85 sStripe-P              % (LLX Bot URX Height)
neg dup neg 3 -1 roll add     % (Left Bot -Height Right)
4 -1 roll                     % (Bot -Height Right Left)
18   3 -1 roll                % (Bot Height Left 18 Right)
% stack in FOR: (Bot Height X)
{
2 index moveto              % (Bot Height)
dup dup neg rlineto stroke
} for
pop pop
0 setColor
} def
/SC
{
0.85 sStripe-P              % (LLX Bot URX Height)
dup neg 5 -1 roll add         % (Bot URX Height Left)
18   4 -1 roll                % (Bot Height Left 18 Right)
% stack in FOR: (Bot Height X)
{
2 index moveto              % (Bot Height)
dup dup rlineto stroke
} for
pop pop
0 setColor
} def
%%EndResource
%%EndProlog
%%BeginSetup
/CellFont   /Helvetica-iso    findfont  7    scalefont  def
/HeadFont   /Helvetica-Bold-iso findfont  12 scalefont  def
/TitleFont  /Helvetica-Bold-iso   findfont  9   scalefont  def
/ResourceTitle (Channel) def
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 22 36 590 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
22 0 translate
0 701 translate
CellFont setfont
0 setlinecap
10 130.5 45.8125 20 C
SA
(First show) 47.21875 22.5 S
R
10 130.5 176.3125 20 C
(Second show) 177.71875 22.5 S
R
10 65.25 306.8125 20 C
SC
(First 1/2 show) 308.21875 22.5 S
R
10 65.25 372.0625 20 C
SC
(Second 1/2) 373.46875 22.5 S
R
10 130.5 437.3125 20 C
(Last show) 438.71875 22.5 S
R
10 522 45.8125 10 C
SB
(Long show.) 47.21875 12.5 S
R
(Sunday, October 2, 2011)(6:00 PM)(6:30 PM)(7:00 PM)(7:30 PM)(8:00 PM)(8:30 PM)(9:00 PM)(9:30 PM)prg
176.3125 20 306.8125 20 437.3125 20
3 {10 V} repeat
P1
372.0625 20
1 {10 V} repeat
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---END---

## duplicate categories
{
  start_date => dt('2011-10-02 18'),
  end_date   => dt('2011-10-02 22'),
  resource_title => 'Channel',
  time_headers => ['h:mm a', 'h:mm a'],
  categories => { GR => [qw(Stripe direction right)],
                  GL => 'Stripe',
                  G => 'Solid',
                  repeatAR => [qw(Stripe direction right)],
                  repeatBL => 'Stripe',
                  repeatCG => 'Solid' },
  resources => simple_resources(qw(G . GR . repeatAR GL)),
}
<<'---END---';
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Bold
%%DocumentSuppliedResources:
%%+ procset PostScript_ScheduleGrid_Style_Stripe 0 0
%%+ procset PostScript_ScheduleGrid 0 0
%%Title: TV Grid
%%PageOrder: Ascend
%%EndComments
%%BeginProlog
%%BeginResource: procset PostScript_ScheduleGrid_Style_Stripe 0 0
/sStripe-R % round X down to a multiple of N
{				% X N
exch	1 index			% N X N
div  truncate  mul
} bind def
/sStripe-P % common prep
{
setColor
6 setlinewidth
2 setlinecap
clippath pathbbox newpath     % (LLX LLY URX URY)
4 2 roll                      % (URX URY LLX LLY)
18 sStripe-R                  % (URX URY LLX LLY1)
4 1 roll                      % (LLY1 URX URY LLX)
18 sStripe-R                  % (LLY1 URX URY LLX1)
4 1 roll                      % (LLX1 LLY1 URX URY)
2 index                       % (LLX Bot URX URY LLY)
sub                           % (LLX Bot URX Height)
} def
%%EndResource
%%BeginResource: procset PostScript_ScheduleGrid 0 0
/pixel {72 mul 300 div} def % 300 dpi only
/C                             % HEIGHT WIDTH LEFT VPOS C
{
gsave
newpath moveto                % HEIGHT WIDTH
dup 0 rlineto                 % HEIGHT WIDTH
0 3 -1 roll rlineto           % WIDTH
-1 mul 0 rlineto
closepath clip
} def
/R {grestore} def
/H                             % YPOS H
{
newpath
0 exch moveto
567.8125 0 rlineto
stroke
} def
/P1 {1 pixel setlinewidth} def
/P2 {2 pixel setlinewidth} def
/S                             % STRING X Y S
{
newpath moveto show
} def
/V                             % XPOS YPOS HEIGHT V
{
newpath
3 1 roll
moveto
0 exch rlineto
stroke
} def
%---------------------------------------------------------------------
% Print the date, times, resource names, & exterior grid:
%
% HEADER TIME1 TIME2 ... TIME12
%
% Enter with CellFont selected
% Leaves the linewidth set to 2 pixels
/prg
{
ResourceTitle 1.40625 32.5 S
ResourceTitle 1.40625 2.5 S
TitleFont setfont
535.1875
-65.25 45.8125
% stack (TIME XPOS)
{
dup 31.6875 3 index showCenter
1.6875 3 -1 roll showCenter
} for
(2 FOO)21.6875(1 Channel)11.6875
2 {1.40625 exch S} repeat
HeadFont setfont
45.8125 43 S
P1
newpath
0 0 moveto
567.8125 0 rlineto
567.8125 40 lineto
0 40 lineto
closepath stroke
111.0625 130.5 556.9375
{dup 30 10 V 0 10 V} for
30 20 10
3 {H} repeat
P2
176.3125 130.5 566.8125
{dup 30 10 V 0 10 V} for
45.8125 0 40 V
} def
/SA
{
0.85 setColor
clippath fill
0 setColor
} def
/SB
{
0.85 sStripe-P              % (LLX Bot URX Height)
neg dup neg 3 -1 roll add     % (Left Bot -Height Right)
4 -1 roll                     % (Bot -Height Right Left)
18   3 -1 roll                % (Bot Height Left 18 Right)
% stack in FOR: (Bot Height X)
{
2 index moveto              % (Bot Height)
dup dup neg rlineto stroke
} for
pop pop
0 setColor
} def
/SC
{
0.85 sStripe-P              % (LLX Bot URX Height)
dup neg 5 -1 roll add         % (Bot URX Height Left)
18   4 -1 roll                % (Bot Height Left 18 Right)
% stack in FOR: (Bot Height X)
{
2 index moveto              % (Bot Height)
dup dup rlineto stroke
} for
pop pop
0 setColor
} def
%%EndResource
%%EndProlog
%%BeginSetup
/CellFont   /Helvetica-iso    findfont  7    scalefont  def
/HeadFont   /Helvetica-Bold-iso findfont  12 scalefont  def
/TitleFont  /Helvetica-Bold-iso   findfont  9   scalefont  def
/ResourceTitle (Channel) def
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 22 36 590 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
22 0 translate
0 701 translate
CellFont setfont
0 setlinecap
10 130.5 45.8125 20 C
SA
(First show) 47.21875 22.5 S
R
10 130.5 176.3125 20 C
(Second show) 177.71875 22.5 S
R
10 65.25 306.8125 20 C
SC
(First 1/2 show) 308.21875 22.5 S
R
10 65.25 372.0625 20 C
SC
(Second 1/2) 373.46875 22.5 S
R
10 130.5 437.3125 20 C
(Last show) 438.71875 22.5 S
R
10 522 45.8125 10 C
SB
(Long show.) 47.21875 12.5 S
R
(Sunday, October 2, 2011)(6:00 PM)(6:30 PM)(7:00 PM)(7:30 PM)(8:00 PM)(8:30 PM)(9:00 PM)(9:30 PM)prg
176.3125 20 306.8125 20 437.3125 20
3 {10 V} repeat
P1
372.0625 20
1 {10 V} repeat
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---END---

# Local Variables:
# compile-command: "perl 10-content.t gen"
# End:

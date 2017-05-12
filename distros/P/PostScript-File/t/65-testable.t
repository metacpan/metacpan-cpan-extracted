#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 26 Feb 2010
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test the testable_output method
#---------------------------------------------------------------------

use strict;
use warnings;

use FindBin '$Bin';
chdir $Bin or die "Unable to cd $Bin: $!";

use Test::More;

# Load Test::Differences, if available:
BEGIN {
  # SUGGEST PREREQ: Test::Differences
  if (eval "use Test::Differences; 1") {
    # Not all versions of Test::Differences support changing the style:
    eval { Test::Differences::unified_diff() }
  } else {
    *eq_or_diff = \&is;         # Just use "is" instead
  }
} # end BEGIN

use PostScript::File ();

my $psVer = PostScript::File->VERSION;

my $generateResults;

if (@ARGV and $ARGV[0] eq 'gen') {
  # Just output the actual results, so they can be diffed against this file
  $generateResults = 1;
  open(OUT, '>', '/tmp/65-testable.t') or die $!;
  printf OUT "#%s\n\n__DATA__\n", '=' x 69;
} else {
  plan tests => 14 * 2;
}

my ($name, %param, @methods);
my $builder = Test::More->builder;

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

    # Run the test:
    my $ps = PostScript::File->new(%param);

    foreach my $call (@methods) {
      eval '$ps' . $call;
      die $@ if $@;
    } # end foreach $call in @methods

    if ($generateResults) {
      $expected = $ps->testable_output;

      print OUT "$expected---\n";
    } else {
      my $todo = ($name =~ s/^TODO +//);
      $builder->todo_start('') if $todo;

      eq_or_diff($ps->testable_output, $expected, $name);
      # Calling output again should produce exactly the same output:
      eq_or_diff($ps->testable_output, $expected, "repeat $name");

      $builder->todo_end if $todo;
    } # end else running tests

    # Clean up:
    @methods = ();
    %param = ();
    undef $name;
  } # end elsif expected contents (=== ... ---)
  elsif (/^::\s*(.+)/) {
    $name = $1;
  } # end elsif test name (:: name)
  else {
    die "Unrecognized line $_" if /\S/ and not /^# /;
  }
} # end while <DATA>

#=====================================================================

__DATA__

:: no parameters
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold
%%DocumentSuppliedResources:
%%EndComments
%%BeginProlog
%%EndProlog
%%Page: 1 1
%%PageBoundingBox: 28 28 568 814
%%PageHiResBoundingBox: 28 28 567.27559 813.88976
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---


:: strip none
strip: 'none'
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold
%%DocumentSuppliedResources:
%%EndComments
%%BeginProlog


%%EndProlog
%%Page: 1 1
%%PageBoundingBox: 28 28 568 814
%%PageHiResBoundingBox: 28 28 567.27559 813.88976
%%BeginPageSetup
    /pagelevel save def


    userdict begin

%%EndPageSetup
%%PageTrailer

    end
    pagelevel restore
    showpage
%%EOF
---


:: strip comments
strip: 'comments'
paper: 'US-Letter'
->add_to_page("% strip this\n");
->add_to_page("%%%%%%%%%%%%%\n");
->add_to_page("%------------\n");
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold
%%DocumentSuppliedResources:
%%EndComments
%%BeginProlog
%%EndProlog
%%Page: 1 1
%%PageBoundingBox: 28 28 584 764
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
%%%%%%%%%%%%%
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---


:: custom paper
paper: '123x456'
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold
%%DocumentSuppliedResources:
%%EndComments
%%BeginProlog
%%EndProlog
%%Page: 1 1
%%PageBoundingBox: 28 28 95 428
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---


:: multiple comments
paper: 'Letter'
order: 'ascend'
need_fonts: [qw( Paladin Paladin-Bold )]
->add_comment("ProofMode: NotifyMe");
->add_comment("Requirements: manualfeed");
->add_default("PageResources: font Paladin");
->add_default("+ font Paladin-Bold");
===
%!PS-Adobe-3.0
%%ProofMode: NotifyMe
%%Requirements: manualfeed
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Paladin Paladin-Bold
%%DocumentSuppliedResources:
%%PageOrder: Ascend
%%EndComments
%%BeginDefaults
%%PageResources: font Paladin
%%+ font Paladin-Bold
%%EndDefaults
%%BeginProlog
%%EndProlog
%%Page: 1 1
%%PageBoundingBox: 28 28 584 764
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---


:: cp1252
strip: 'comments'
paper: 'US-Letter'
reencode: 'cp1252'
->add_to_page("(\x{201C}Hello, world.\x{201D}) show\n");
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier Courier-Bold Courier-BoldOblique Courier-Oblique Helvetica
%%+ font Helvetica-Bold Helvetica-BoldOblique Helvetica-Oblique Symbol
%%+ font Times-Bold Times-BoldItalic Times-Italic Times-Roman
%%DocumentSuppliedResources:
%%EndComments
%%BeginProlog
%%EndProlog
%%BeginSetup
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 28 28 584 764
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
(“Hello, world.”) show
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---


:: multiple resources
paper: 'Letter'
->add_resource(Font => 'Random', '', "% The Random font would go here\n");
->add_resource(File => 'SomeFile', '', "% SomeFile would go here\n");
->need_resource(pattern => qw(Pattern1 Pattern2));
->need_resource(procset => [qw(SomeProcset 1.2 0)]);
->need_resource(font => qw(SomeFont OtherFont));
->need_resource(file => 'AFile', 'filename with spaces.txt');
->need_resource(form => qw(SomeForm));
->need_resource(encoding => qw(SomeEncoding));
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ encoding SomeEncoding
%%+ file (filename with spaces.txt) AFile
%%+ font Courier-Bold OtherFont SomeFont
%%+ form SomeForm
%%+ pattern Pattern1 Pattern2
%%+ procset SomeProcset 1.2 0
%%DocumentSuppliedResources:
%%+ font Random
%%+ file SomeFile
%%EndComments
%%BeginProlog
%%EndProlog
%%BeginSetup
%%BeginResource: font Random
% The Random font would go here
%%EndResource
%%BeginResource: file SomeFile
% SomeFile would go here
%%EndResource
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 28 28 584 764
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---


:: setup & trailers
paper: 'Letter'
->add_setup("% Setup line 1\n");
->add_setup("% Setup line 2\n");
->add_page_setup("% Page Setup line 1\n");
->add_page_setup("% Page Setup line 2\n");
->add_page_trailer("% Page Trailer line 1\n");
->add_page_trailer("% Page Trailer line 2\n");
->add_trailer("% Trailer line 1\n");
->add_trailer("% Trailer line 2\n");
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold
%%DocumentSuppliedResources:
%%EndComments
%%BeginProlog
%%EndProlog
%%BeginSetup
% Setup line 1
% Setup line 2
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 28 28 584 764
%%BeginPageSetup
/pagelevel save def
userdict begin
% Page Setup line 1
% Page Setup line 2
%%EndPageSetup
%%PageTrailer
% Page Trailer line 1
% Page Trailer line 2
end
pagelevel restore
showpage
%%Trailer
% Trailer line 1
% Trailer line 2
%%EOF
---


:: embed recycle.eps
strip: 'comments'
paper: 'US-Letter'
->add_to_page($ps->embed_document("recycle.eps"));
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold
%%DocumentSuppliedResources:
%%+ file recycle.eps
%%EndComments
%%BeginProlog
%%EndProlog
%%Page: 1 1
%%PageBoundingBox: 28 28 584 764
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
%%BeginDocument: recycle.eps
%!PS-Adobe-3.0 EPSF-3.0
%%Creator: inkscape 0.46
%%Pages: 1
%%Orientation: Portrait
%%BoundingBox: 1 0 64 63
%%HiResBoundingBox: 1.0000001 0.99999201 63.000026 63
%%EndComments
%%Page: 1 1
0 64 translate
0.8 -0.8 scale
0 setgray
[] 0 setdash
1 setlinewidth
0 setlinejoin
0 setlinecap
gsave [1 0 0 1 0 0] concat
gsave [0.968751 0 0 0.98751 1.250108 -0.250791] concat
gsave
newpath
54.962334 37.280594 moveto
72.099779 27.019014 lineto
79.778255 41.853688 lineto
81.632958 49.958845 71.469188 52.933218 63.308493 52.449886 curveto
54.962334 37.280594 lineto
closepath
eofill
grestore
gsave
newpath
51.067463 47.876791 moveto
42.053608 63.826855 lineto
51.067463 80.000001 lineto
51.29002 73.530745 lineto
59.524901 73.530745 lineto
62.529519 73.790994 66.42439 71.820476 67.87106 68.95765 curveto
78.442863 49.549882 lineto
74.956026 53.007587 70.472444 53.899894 65.311568 53.899894 curveto
51.401311 53.899894 lineto
51.067463 47.876791 lineto
closepath
eofill
grestore
gsave
newpath
30.928372 28.211849 moveto
13.659051 18.174838 lineto
22.872119 4.2455192 lineto
29.041895 -1.3139163 36.569755 6.1490507 40.109239 13.53501 curveto
30.928372 28.211849 lineto
closepath
eofill
grestore
gsave
newpath
42.061814 26.481749 moveto
60.350049 26.63881 lineto
70.082475 10.889601 lineto
64.3314 13.834655 lineto
60.334303 6.6182881 lineto
59.102915 3.8589686 55.493541 1.4022881 52.294142 1.5241211 curveto
30.23359 1.680123 lineto
34.942164 3.0573777 37.89678 6.5533043 40.401797 11.075868 curveto
47.153644 23.265664 lineto
42.061814 26.481749 lineto
closepath
eofill
grestore
gsave
newpath
0.44400982 27.380869 moveto
5.7948147 31.482111 lineto
0.75876087 40.946493 lineto
-1.7592722 45.310624 2.5665138 49.562043 5.3226757 51.041841 curveto
8.0359564 52.498618 12.247261 52.671816 16.181673 52.61924 curveto
23.263621 41.26197 lineto
28.614426 44.101291 lineto
19.329208 27.22313 lineto
0.44400982 27.380869 lineto
closepath
eofill
grestore
gsave
newpath
1.2308874 49.306704 moveto
12.719387 70.128368 lineto
15.027578 73.020264 19.381675 73.703806 23.893136 73.598643 curveto
36.011137 73.598643 lineto
36.011137 53.881162 lineto
13.034138 53.723423 lineto
9.4669308 53.933737 4.7980948 53.197619 1.2308874 49.306704 curveto
closepath
eofill
grestore
grestore
grestore
showpage
%%EOF
%%EndDocument
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---


:: embed recycle-i.epsi
strip: 'comments'
paper: 'US-Letter'
->add_to_page($ps->embed_document("recycle-i.epsi"));
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold
%%DocumentSuppliedResources:
%%+ file recycle-i.epsi
%%EndComments
%%BeginProlog
%%EndProlog
%%Page: 1 1
%%PageBoundingBox: 28 28 584 764
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
%%BeginDocument: recycle-i.epsi
%!PS-Adobe-3.0 EPSF-3.0
%%Creator: inkscape 0.46
%%Pages: 1
%%Orientation: Portrait
%%BoundingBox: 1 0 64 63
%%HiResBoundingBox: 1.0000001 0.99999201 63.000026 63
%%EndComments
%%Page: 1 1
0 64 translate
0.8 -0.8 scale
0 setgray
[] 0 setdash
1 setlinewidth
0 setlinejoin
0 setlinecap
gsave [1 0 0 1 0 0] concat
gsave [0.968751 0 0 0.98751 1.250108 -0.250791] concat
gsave
newpath
54.962334 37.280594 moveto
72.099779 27.019014 lineto
79.778255 41.853688 lineto
81.632958 49.958845 71.469188 52.933218 63.308493 52.449886 curveto
54.962334 37.280594 lineto
closepath
eofill
grestore
gsave
newpath
51.067463 47.876791 moveto
42.053608 63.826855 lineto
51.067463 80.000001 lineto
51.29002 73.530745 lineto
59.524901 73.530745 lineto
62.529519 73.790994 66.42439 71.820476 67.87106 68.95765 curveto
78.442863 49.549882 lineto
74.956026 53.007587 70.472444 53.899894 65.311568 53.899894 curveto
51.401311 53.899894 lineto
51.067463 47.876791 lineto
closepath
eofill
grestore
gsave
newpath
30.928372 28.211849 moveto
13.659051 18.174838 lineto
22.872119 4.2455192 lineto
29.041895 -1.3139163 36.569755 6.1490507 40.109239 13.53501 curveto
30.928372 28.211849 lineto
closepath
eofill
grestore
gsave
newpath
42.061814 26.481749 moveto
60.350049 26.63881 lineto
70.082475 10.889601 lineto
64.3314 13.834655 lineto
60.334303 6.6182881 lineto
59.102915 3.8589686 55.493541 1.4022881 52.294142 1.5241211 curveto
30.23359 1.680123 lineto
34.942164 3.0573777 37.89678 6.5533043 40.401797 11.075868 curveto
47.153644 23.265664 lineto
42.061814 26.481749 lineto
closepath
eofill
grestore
gsave
newpath
0.44400982 27.380869 moveto
5.7948147 31.482111 lineto
0.75876087 40.946493 lineto
-1.7592722 45.310624 2.5665138 49.562043 5.3226757 51.041841 curveto
8.0359564 52.498618 12.247261 52.671816 16.181673 52.61924 curveto
23.263621 41.26197 lineto
28.614426 44.101291 lineto
19.329208 27.22313 lineto
0.44400982 27.380869 lineto
closepath
eofill
grestore
gsave
newpath
1.2308874 49.306704 moveto
12.719387 70.128368 lineto
15.027578 73.020264 19.381675 73.703806 23.893136 73.598643 curveto
36.011137 73.598643 lineto
36.011137 53.881162 lineto
13.034138 53.723423 lineto
9.4669308 53.933737 4.7980948 53.197619 1.2308874 49.306704 curveto
closepath
eofill
grestore
grestore
grestore
showpage
%%EOF
%%EndDocument
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---


:: embed recycle-tiff4.eps
strip: 'comments'
paper: 'US-Letter'
->add_to_page($ps->embed_document("recycle-tiff4.eps"));
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold
%%DocumentSuppliedResources:
%%+ file recycle-tiff4.eps
%%EndComments
%%BeginProlog
%%EndProlog
%%Page: 1 1
%%PageBoundingBox: 28 28 584 764
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
%%BeginDocument: recycle-tiff4.eps
%!PS-Adobe-3.0 EPSF-3.0
%%Creator: inkscape 0.46
%%Pages: 1
%%Orientation: Portrait
%%BoundingBox: 1 0 64 63
%%HiResBoundingBox: 1.0000001 0.99999201 63.000026 63
%%EndComments
%%Page: 1 1
0 64 translate
0.8 -0.8 scale
0 setgray
[] 0 setdash
1 setlinewidth
0 setlinejoin
0 setlinecap
gsave [1 0 0 1 0 0] concat
gsave [0.968751 0 0 0.98751 1.250108 -0.250791] concat
gsave
newpath
54.962334 37.280594 moveto
72.099779 27.019014 lineto
79.778255 41.853688 lineto
81.632958 49.958845 71.469188 52.933218 63.308493 52.449886 curveto
54.962334 37.280594 lineto
closepath
eofill
grestore
gsave
newpath
51.067463 47.876791 moveto
42.053608 63.826855 lineto
51.067463 80.000001 lineto
51.29002 73.530745 lineto
59.524901 73.530745 lineto
62.529519 73.790994 66.42439 71.820476 67.87106 68.95765 curveto
78.442863 49.549882 lineto
74.956026 53.007587 70.472444 53.899894 65.311568 53.899894 curveto
51.401311 53.899894 lineto
51.067463 47.876791 lineto
closepath
eofill
grestore
gsave
newpath
30.928372 28.211849 moveto
13.659051 18.174838 lineto
22.872119 4.2455192 lineto
29.041895 -1.3139163 36.569755 6.1490507 40.109239 13.53501 curveto
30.928372 28.211849 lineto
closepath
eofill
grestore
gsave
newpath
42.061814 26.481749 moveto
60.350049 26.63881 lineto
70.082475 10.889601 lineto
64.3314 13.834655 lineto
60.334303 6.6182881 lineto
59.102915 3.8589686 55.493541 1.4022881 52.294142 1.5241211 curveto
30.23359 1.680123 lineto
34.942164 3.0573777 37.89678 6.5533043 40.401797 11.075868 curveto
47.153644 23.265664 lineto
42.061814 26.481749 lineto
closepath
eofill
grestore
gsave
newpath
0.44400982 27.380869 moveto
5.7948147 31.482111 lineto
0.75876087 40.946493 lineto
-1.7592722 45.310624 2.5665138 49.562043 5.3226757 51.041841 curveto
8.0359564 52.498618 12.247261 52.671816 16.181673 52.61924 curveto
23.263621 41.26197 lineto
28.614426 44.101291 lineto
19.329208 27.22313 lineto
0.44400982 27.380869 lineto
closepath
eofill
grestore
gsave
newpath
1.2308874 49.306704 moveto
12.719387 70.128368 lineto
15.027578 73.020264 19.381675 73.703806 23.893136 73.598643 curveto
36.011137 73.598643 lineto
36.011137 53.881162 lineto
13.034138 53.723423 lineto
9.4669308 53.933737 4.7980948 53.197619 1.2308874 49.306704 curveto
closepath
eofill
grestore
grestore
grestore
showpage
%%EOF
%%EndDocument
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---


:: embed recycle-wmf.epsf
strip: 'comments'
paper: 'US-Letter'
->add_to_page($ps->embed_document("recycle-wmf.epsf"));
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold
%%DocumentSuppliedResources:
%%+ file recycle-wmf.epsf
%%EndComments
%%BeginProlog
%%EndProlog
%%Page: 1 1
%%PageBoundingBox: 28 28 584 764
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
%%BeginDocument: recycle-wmf.epsf
%!PS-Adobe-3.0 EPSF-3.0
%%Creator: inkscape 0.46
%%Pages: 1
%%Orientation: Portrait
%%BoundingBox: 1 0 64 63
%%HiResBoundingBox: 1.0000001 0.99999201 63.000026 63
%%EndComments
%%Page: 1 1
0 64 translate
0.8 -0.8 scale
0 setgray
[] 0 setdash
1 setlinewidth
0 setlinejoin
0 setlinecap
gsave [1 0 0 1 0 0] concat
gsave [0.968751 0 0 0.98751 1.250108 -0.250791] concat
gsave
newpath
54.962334 37.280594 moveto
72.099779 27.019014 lineto
79.778255 41.853688 lineto
81.632958 49.958845 71.469188 52.933218 63.308493 52.449886 curveto
54.962334 37.280594 lineto
closepath
eofill
grestore
gsave
newpath
51.067463 47.876791 moveto
42.053608 63.826855 lineto
51.067463 80.000001 lineto
51.29002 73.530745 lineto
59.524901 73.530745 lineto
62.529519 73.790994 66.42439 71.820476 67.87106 68.95765 curveto
78.442863 49.549882 lineto
74.956026 53.007587 70.472444 53.899894 65.311568 53.899894 curveto
51.401311 53.899894 lineto
51.067463 47.876791 lineto
closepath
eofill
grestore
gsave
newpath
30.928372 28.211849 moveto
13.659051 18.174838 lineto
22.872119 4.2455192 lineto
29.041895 -1.3139163 36.569755 6.1490507 40.109239 13.53501 curveto
30.928372 28.211849 lineto
closepath
eofill
grestore
gsave
newpath
42.061814 26.481749 moveto
60.350049 26.63881 lineto
70.082475 10.889601 lineto
64.3314 13.834655 lineto
60.334303 6.6182881 lineto
59.102915 3.8589686 55.493541 1.4022881 52.294142 1.5241211 curveto
30.23359 1.680123 lineto
34.942164 3.0573777 37.89678 6.5533043 40.401797 11.075868 curveto
47.153644 23.265664 lineto
42.061814 26.481749 lineto
closepath
eofill
grestore
gsave
newpath
0.44400982 27.380869 moveto
5.7948147 31.482111 lineto
0.75876087 40.946493 lineto
-1.7592722 45.310624 2.5665138 49.562043 5.3226757 51.041841 curveto
8.0359564 52.498618 12.247261 52.671816 16.181673 52.61924 curveto
23.263621 41.26197 lineto
28.614426 44.101291 lineto
19.329208 27.22313 lineto
0.44400982 27.380869 lineto
closepath
eofill
grestore
gsave
newpath
1.2308874 49.306704 moveto
12.719387 70.128368 lineto
15.027578 73.020264 19.381675 73.703806 23.893136 73.598643 curveto
36.011137 73.598643 lineto
36.011137 53.881162 lineto
13.034138 53.723423 lineto
9.4669308 53.933737 4.7980948 53.197619 1.2308874 49.306704 curveto
closepath
eofill
grestore
grestore
grestore
showpage
%%EOF
%%EndDocument
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---


:: do not strip whitespace in strings
paper: 'US-Letter'
->add_to_page("(  don't strip this\n    4 spaces\n)\n  do strip this\n");
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold
%%DocumentSuppliedResources:
%%EndComments
%%BeginProlog
%%EndProlog
%%Page: 1 1
%%PageBoundingBox: 28 28 584 764
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
(  don't strip this
    4 spaces
)
do strip this
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---


:: do not strip comments in strings
strip: 'comments'
paper: 'US-Letter'
->add_to_page("(% don't strip this\n % not this either\n% nor this)\n% do strip this\n");
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold
%%DocumentSuppliedResources:
%%EndComments
%%BeginProlog
%%EndProlog
%%Page: 1 1
%%PageBoundingBox: 28 28 584 764
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
(% don't strip this
 % not this either
% nor this)
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---

# Local Variables:
# compile-command: "perl 65-testable.t gen"
# End:

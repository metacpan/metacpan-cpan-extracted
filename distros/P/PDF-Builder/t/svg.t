#!/usr/bin/perl
use warnings;
use strict;
use English qw( -no_match_vars );
use IPC::Cmd qw(can_run run);
use File::Spec;
use File::Temp;
use version;
use Test::More tests => 4;

use PDF::Builder;
my $diag = '';
my $failed;

my $pdf = PDF::Builder->new('-compress' => 'none'); # common $pdf all tests
my $has_SVG = 0; # global flag for all tests that need to know if SVGPDF
my ($page, $img, $example, $expected);
$has_SVG = $pdf->LA_SVG();

# a simple SVG to test image_svg()
my $input = <<"END_OF_CONTENT";
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN"
 "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
<svg height="512" width="575" xmlns="http://www.w3.org/2000/svg" 
 xmlns:svg="http://www.w3.org/2000/svg" 
 xmlns:xlink="http://www.w3.org/1999/xlink">
<style type="text/css">
  <!-- lowest priority -->
  circle { fill: red; }
  .myclass { fill: pink; } <!-- after tag style= -->
  #myid { fill: yellow; }  <!-- after tag style, before class -->
</style>
<!-- g is third active (after style, tag fill) -->
<g fill="blue" >
<!-- style= is active, then fill= -->
<circle id="myid" class="myclass" cx="100" cy="100" r="50" fill="green" 
style="fill: gray;" />
<!-- default IS to fill -->
<polyline points="229,150, 260,150, 290,103" style="stroke:black;stroke-width:5;" />
</g>
</svg>
END_OF_CONTENT

$img = $pdf->image_svg(\$input, 'compress'=>0); # use defaults except no compression

# 1 only one element produced?
SKIP: {
    skip "SVGPDF is not available.", 1 unless $has_SVG;

is(scalar(@$img), 1, 'only one <svg>, as expected');
}

# 2 XO is of proper type?
SKIP: {
    skip "SVGPDF is not available.", 1 unless $has_SVG;

isa_ok($img->[0]->{'xo'}, "PDF::Builder::Resource::XObject::Form::Hybrid",
	q{$pdf->image_svg(input)});
}

# 3 XO contains expected content?
SKIP: {
    skip "SVGPDF is not available.", 1 unless $has_SVG;

my $xo = $img->[0]->{'xo'};
my $gfx = $pdf->page()->gfx();
$gfx->object($xo);
like($pdf->to_string(), qr/ 1 0 0 -1 0 0 cm 0 0 0 rg q q 0.498039 0.498039 0.498039 rg 150 100 m 150 106.57 148.71 113.07 146.19 119.13 c 143.68 125.2 140 130.71 135.36 135.36 c 130.71 140 125.2 143.68 119.13 146.19 c 113.07 148.71 106.57 150 100 150 c 93.434 150 86.932 148.71 80.866 146.19 c 74.8 143.68 69.288 140 64.645 135.36 c 60.002 130.71 56.319 125.2 53.806 119.13 c 51.293 113.07 50 106.57 50 100 c 50 93.434 51.293 86.932 53.806 80.866 c 56.319 74.8 60.002 69.288 64.645 64.645 c 69.288 60.002 74.8 56.319 80.866 53.806 c 86.932 51.293 93.434 50 100 50 c 106.57 50 113.07 51.293 119.13 53.806 c 125.2 56.319 130.71 60.002 135.36 64.645 c 140 69.288 143.68 74.8 146.19 80.866 c 148.71 86.932 150 93.434 150 100 c h f Q q 5 w 0 0 0 RG 0 0 1 rg 229 150 m 260 150 l 290 103 l B Q Q/,
    q{PDF output has expected output});
}

#width, vwidth, height, vheight, bb etc. check
#img->[0]->{width} etc.?

# 4 [v]width, [v]height, vbox, etc. correct?
SKIP: {
    skip "SVGPDF is not available.", 1 unless $has_SVG;

my $i  = $img->[0];
my $xo = $img->[0]->{'xo'};
# might need to round any floating point values
$example = 1;
$example &&= $i->{'width'} == 575;
$example &&= $i->{'vwidth'} == 575;
$example &&= $i->{'height'} == 512;
$example &&= $i->{'vheight'} == 512;
my @vb = @{$i->{'vbox'}};
$example &&= $vb[0] == 0;
$example &&= $vb[1] == 0;
$example &&= $vb[2] == 575;
$example &&= $vb[3] == 512;

is($example, 1, "internal values as expected");
}
##############################################################
# cleanup. all tests involving these files skipped?

# check non-Perl utility versions
sub check_version {
    my ($cmd, $arg, $regex, $min_ver) = @_;

    # was the check routine already defined (installed)?
    if (defined $cmd) {
	# should match dotted version number
        my $output = `$cmd $arg`;
        $diag .= $output;
	if ($output =~ m/$regex/) {
	    if (version->parse($1) >= version->parse($min_ver)) {
		return $cmd;
	    }
	}
    }
    return; # cmd not defined (not installed) so return undef
}

# exclude specified non-Perl utility versions
# do not call if don't have one or more exclusion ranges
sub exclude_version {
    my ($cmd, $arg, $regex, $ex_ver_r) = @_;

    my (@ex_ver, $my_ver);
    if (defined $ex_ver_r) {
	@ex_ver = @$ex_ver_r;
    } else {
	return; # called w/o exclusion list: fail
    }
    # need 2, 4, 6,... dotted versions
    if (!scalar(@ex_ver) || scalar(@ex_ver)%2) {
	return; # called with zero or odd number of elements: fail
    }

    if (defined $cmd) {
	# dotted version number should not fall into an excluded range
        my $output = `$cmd $arg`;
        $diag .= $output;
	if ($output =~ m/$regex/) {
	    $my_ver = version->parse($1);
	    for (my $i=0; $i<scalar(@ex_ver); $i+=2) {
	        if ($my_ver >= version->parse($ex_ver[$i  ]) &&
		    $my_ver <= version->parse($ex_ver[$i+1])) {
		    return; # fell into one of the exclusion ranges
	        }
	    }
	    return $cmd; # didn't hit any exclusions, so OK
	}
    }
    return; # cmd not defined (not installed) so return undef
}

sub show_diag { 
   #$failed = 0;
    $failed = 1;
    return;
}

if ($failed) { diag($diag) }

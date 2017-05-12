#!/usr/bin/env perl

use strict;
use warnings;

# these files are for my usage, but can be used as examples.
# from a single latex file with a cover, create a sheet

use PDF::API2;
use PDF::Cropmarks;
use PDF::Imposition;
use Path::Tiny;

# first compile

my ($input) = @ARGV;
die "Missing input tex file" unless $input;
die "input is not a tex file" unless $input =~ m/\.tex$/ && -f $input;

for (1..3) {
    system(xelatex => '-halt-on-error', $input) == 0 or die "Failure to compile $input";
}
my $pdf = $input;
$pdf =~ s/\.tex$/.pdf/;
die "Cannot find $pdf" unless -f $pdf;

# create the file with the same page repeated.
my $temp = Path::Tiny->tempdir(CLEANUP => 0);
my $out = impose(add_cropmarks(create_working_copy($pdf)));
my $outfile = $input;
$outfile =~ s/tex$/crop-imposed.pdf/;
$out->copy($outfile);
print "Created $outfile\n";


sub create_working_copy {
    my $pdf = shift;
    my $in = PDF::API2->open($pdf);
    my $work = PDF::API2->new;
    for my $page (1..16) {
        $work->import_page($in, 1, $page);
    }
    my $wc = $temp->child('working.pdf');
    $work->saveas("$wc");
    $work->end;
    return $wc;
}

sub add_cropmarks {
    my $pdf = shift;
    my $out = $temp->child('crops.pdf');
    PDF::Cropmarks->new(
                        input => "$pdf",
                        output => "$out",
                        paper => 'a6',
                        top => 1,
                        bottom => 0,
                        inner => 1,
                        outer => 0,
                        twoside => 1,
                       )->add_cropmarks;
    return $out;
}

sub impose {
    my $pdf = shift;
    my $out = $temp->child('out.pdf');
    PDF::Imposition->new(file => "$pdf",
                         outfile => "$out",
                         cover => 0,
                         schema => '2x4x2')->impose;
    return $out;
}

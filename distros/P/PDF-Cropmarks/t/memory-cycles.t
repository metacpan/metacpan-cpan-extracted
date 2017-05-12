#!perl

use strict;
use warnings;

use Test::More;
use File::Spec::Functions;
use File::Temp;
use PDF::Cropmarks;
eval "use Test::Memory::Cycle";

if ($ENV{RELEASE_TESTING} && !$@) {
    plan tests => 3;
}
else {
    plan skip_all => "No release testing, skipping";
}

my $wd = File::Temp->newdir(CLEANUP => !$ENV{AMW_NOCLEANUP});
my $input = catfile(qw/t test-input.pdf/);
my $output = catfile($wd, 'out.pdf');
{
    unlink $output if -f $output;
    ok (! -f $output, "No $output found");
    my $cropper = PDF::Cropmarks->new({
                                       input => $input,
                                       output => $output,
                                       signature => 20,
                                       twoside => 1,
                                       cover => 1,
                                       paper => '400pt:500pt',
                                       paper_thickness => '5mm',
                                      });
    $cropper->add_cropmarks;
    ok (-f $output, "Found $output");
    memory_cycle_ok($cropper, "No memory cycles found after cropping");
}

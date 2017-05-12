#!/usr/bin/perl -w

use strict;
use Test::More;
use lib "t";
BEGIN {
    if (not eval "use XMLCompare qw(file_ok); 1") {
        plan skip_all => "module required for testing did not load ($@)";
    }
    else {
        plan tests => 3;
    } 
}
use XMLCompare qw(xml_ok $show_lines xmltidy);
use YAML qw(LoadFile);
use Template;
use Getopt::Long qw(:config bundling);
use Profile::Log;

my $save;

GetOptions("v" => sub { $show_lines += 40 },
           "a" => sub { $show_lines = 1e6 },
           "s" => \$save,
	);

my @output;

my $tt = Template->new({ INCLUDE_PATH => 'templates',
			 OUTPUT => sub { push @output, (shift) },
		       });

my $input_data = LoadFile "t/testdata.yml";
my $log_data = LoadFile "t/onetime.yml";

$input_data->{data}{log} = $log_data;

$tt->process("profile.svg.tt", $input_data );
is($tt->error, undef, "TT succeeded");

my $output_data = join "", @output;

if ($save) {

   open(OUT, ">t/testdata.svg") or die $!;
   print OUT xmltidy($output_data);
   close OUT;
 SKIP: {
       skip "SVG saved to t/testdata.svg", 2;
   }

} else {
 
   xml_ok($output_data, "t/testdata.svg", "bootchart.svg.tt test");

}

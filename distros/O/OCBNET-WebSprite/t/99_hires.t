# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 21;
BEGIN { use_ok('File::Slurp') };
BEGIN { use_ok('OCBNET::Image') };
BEGIN { use_ok('OCBNET::WebSprite') };

use OCBNET::CSS3::Styles::WebSprite;

# change directory into css location
ok chdir('t/hires/css'), "chdir";

# remove previousely generated files (keep them for inspection)
unlink "../result/generated-lores.png" if -e "../result/generated-lores.png";
unlink "../result/generated-hires.png" if -e "../result/generated-hires.png";

# create new spriteset object
my $spriteset = OCBNET::WebSprite->new;

$spriteset->{'config'}->{'debug'} = 1;

# check for valid object
ok $spriteset, "instantiate";

# read in data from css file
my $data = read_file('sprites.css');

# check for valid object
ok $data, "read hires.css";

# empty hash
my $opt = {};

# start the main process for creation
# opt will be shared with writer and reader
# can be used to keep spritesets in memory
ok my $rv = $spriteset->create(\$data, $opt), "create spriteset";

ok -f '../result/expected-lores.png', "expected-lores.png exists";
ok -f '../result/expected-hires.png', "expected-hires.png exists";
ok -f '../result/generated-lores.png', "generated-lores.png exists";
ok -f '../result/generated-hires.png', "generated-hires.png exists";
ok my $expected_lores = OCBNET::Image->new, "instantiates expected_lores";
ok my $expected_hires = OCBNET::Image->new, "instantiates expected_hires";
ok my $generated_lores = OCBNET::Image->new, "instantiates generated_lores";
ok my $generated_hires = OCBNET::Image->new, "instantiates generated_hires";
is $expected_lores->Read('../result/expected-lores.png'), '', "read expected-lores.png";
is $expected_hires->Read('../result/expected-hires.png'), '', "read expected-hires.png";
is $generated_hires->Read('../result/generated-hires.png'), '', "read generated-hires.png";
is $generated_hires->Read('../result/generated-hires.png'), '', "read generated-hires.png";

use File::Which;

my $cmp = which('gms') ? 'gm' : which('im') ? 'im' : undef;

if ($cmp)
{
	# use gm compare to create equality metrics to check if generated image is correct
	my $compare_lores = `gm compare -metric mse ../result/expected-lores.png ../result/generated-lores.png`;
	warn "lores compare:\n", $compare_lores if scalar(() = $compare_lores =~ m/\:\s*0?\.0/g) != 5;
	is scalar(() = $compare_lores =~ m/\:\s*0?\.0/g), 5, "generated image-lores matches expected";
	my $compare_hires = `gm compare -metric mse ../result/expected-hires.png ../result/generated-hires.png`;
	warn "hires compare:\n", $compare_hires if scalar(() = $compare_hires =~ m/\:\s*0?\.0/g) != 5;
	is scalar(() = $compare_hires =~ m/\:\s*0?\.0/g), 5, "generated image-hires matches expected";
}
elsif(eval { require GD })
{
	my $image1 = GD::Image->new('../result/expected-lores.png');
	my $image2 = GD::Image->new('../result/generated-lores.png');
	is $image1->compare($image2) & GD::GD_CMP_IMAGE(), 0, "generated image-lores matches expected";
	my $image3 = GD::Image->new('../result/expected-hires.png');
	my $image4 = GD::Image->new('../result/generated-hires.png');
	is $image3->compare($image4) & GD::GD_CMP_IMAGE(), 0, "generated image-hires matches expected";
}
else
{
	warn "No graphics implementation found!";
}

# render the changed stylesheet
write_file('../result/sprites.css', $rv->render);

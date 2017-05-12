use strict;
use Test::More;
use File::HomeDir;
use Path::Tiny;
use OpenGbg;

use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

my $home = File::HomeDir->my_home;
my $has_conf_file = path($home)->child('.opengbg.ini')->exists;

if(!$has_conf_file) {
    plan skip_all => 'You need to get an api key from http://data.goteborg.se/ and put it in ~/.opengbg.ini. See documentation.';
}

my $open = OpenGbg->new;

is $open->air_quality->get_latest_measurement->temperature_unit, 'degrees C', 'Got temperature unit';

done_testing;

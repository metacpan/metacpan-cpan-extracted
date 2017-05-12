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

my $gbg = OpenGbg->new;

is ref $gbg, 'OpenGbg', 'Right object';

is $gbg->styr_och_stall->get_bike_station(1)->label, 'Lilla Bommen', 'Found Lilla Bommen';

is $gbg->styr_och_stall->get_bike_stations->get_by_id(1)->label, 'Lilla Bommen', 'Found Lilla Bommen, after fetching all';

done_testing;

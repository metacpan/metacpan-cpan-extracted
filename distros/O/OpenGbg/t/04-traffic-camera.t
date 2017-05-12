use strict;
use Test::More;
use File::HomeDir;
use Path::Tiny;
use OpenGbg;
use DateTime;

use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

my $home = File::HomeDir->my_home;
my $has_conf_file = path($home)->child('.opengbg.ini')->exists;

if(!$has_conf_file) {
    plan skip_all => 'You need to get an api key from http://data.goteborg.se/ and put it in ~/.opengbg.ini. See documentation.';
}

my $open = OpenGbg->new;

main();

sub main {

    my $response;

    $response = $open->traffic_camera->get_traffic_cameras;

    is $response->camera_devices->count > 10, 1, 'There are lots of cameras';

}

done_testing;

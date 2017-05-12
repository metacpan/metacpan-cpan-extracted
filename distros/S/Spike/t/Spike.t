use strict;
use warnings;

use Test::More (tests => 12);

BEGIN {
    use_ok('Spike');
    use_ok('Spike::Cache');
    use_ok('Spike::Config');
    use_ok('Spike::Error');
    use_ok('Spike::Log');
    use_ok('Spike::Object');
    use_ok('Spike::Site::Handler');
    use_ok('Spike::Site::Request');
    use_ok('Spike::Site::Response');
    use_ok('Spike::Site::Router');
    use_ok('Spike::Site::Router::Route');
    use_ok('Spike::Tree');
}

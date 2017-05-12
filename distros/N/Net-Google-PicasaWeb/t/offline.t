use Test::Able::Runner;

use_test_packages
    -base_package => 'Net::Google::PicasaWeb::Test',
    -test_path    => [ 't/offline' ];

run;

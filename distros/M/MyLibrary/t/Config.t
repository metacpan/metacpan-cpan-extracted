use Test::More tests => 4;

use_ok('MyLibrary::Config');

my $data_source = ($MyLibrary::Config::DATA_SOURCE);
ok($MyLibrary::Config::DATA_SOURCE, 'DATA_SOURCE defined');

my $username = ($MyLibrary::Config::USERNAME);
ok($MyLibrary::Config::USERNAME, 'USERNAME defined');

my $password = ($MyLibrary::Config::PASSWORD);
ok($MyLibrary::Config::PASSWORD, 'PASSWORD defined');



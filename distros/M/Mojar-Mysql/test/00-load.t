use Mojo::Base -strict;
use Test::More;

use_ok 'Mojar::Mysql';
diag "Testing Mojar::Mysql $Mojar::Mysql::VERSION, Perl $], $^X";
use_ok 'Mojar::Mysql::Connector';
use_ok 'Mojar::Mysql::Replication';
use_ok 'Mojar::Mysql::Util';

done_testing();

use Mojo::Base -strict;
use Test::More;

use_ok 'Mojar';
diag "Testing Mojar $Mojar::VERSION, Perl $], $^X";
use_ok 'Mojar::Util';
use_ok 'Mojar::Cache';
use_ok 'Mojar::Log';
use_ok 'Mojar::Config';
use_ok 'Mojar::ClassShare';

done_testing();

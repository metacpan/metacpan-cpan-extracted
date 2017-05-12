use Mojo::Base -strict;
use Test::More;

use_ok('Mojar::Cron');
diag "Testing Mojar::Cron $Mojar::Cron::VERSION, Perl $], $^X";

done_testing();

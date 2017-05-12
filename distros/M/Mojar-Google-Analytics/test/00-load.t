use Mojo::Base -strict;
use Test::More;

use_ok('Mojar');
use_ok('Mojar::Google::Analytics');
diag "Testing Mojar::Google::Analytics $Mojar::Google::Analytics::VERSION, Perl $], $^X";

done_testing();

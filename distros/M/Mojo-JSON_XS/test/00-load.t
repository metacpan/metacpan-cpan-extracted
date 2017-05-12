use Mojo::Base -strict;
use Test::More;

use_ok('Mojo::JSON_XS');
diag "Testing Mojo::JSON_XS $Mojo::JSON_XS::VERSION, Perl $], $^X";

done_testing();

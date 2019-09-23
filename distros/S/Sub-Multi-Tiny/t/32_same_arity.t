use 5.006;
use lib::relative '.';
use Kit;

fails_ok('32_same_arity.pl', qr/same.arity/);

done_testing;
# vi: set fdm=marker: #

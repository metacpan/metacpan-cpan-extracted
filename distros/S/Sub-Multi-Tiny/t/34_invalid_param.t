use 5.006;
use lib::relative '.';
use Kit;

fails_ok('34_invalid_param.pl', qr/Argument.+is not listed/);

done_testing;
# vi: set fdm=marker: #

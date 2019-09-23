use 5.006;
use lib::relative '.';
use Kit;

fails_ok('35_invalid_type.pl', qr/Type constraint.+first.+foo/);

done_testing;
# vi: set fdm=marker: #

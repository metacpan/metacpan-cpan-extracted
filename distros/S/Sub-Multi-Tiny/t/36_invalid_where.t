use 5.006;
use lib::relative '.';
use Kit;

fails_ok('36_invalid_where.pl', qr/where.+first.+foo/);

done_testing;
# vi: set fdm=marker: #

use t::Util;
use Test::More;

ok my $service = service();
isa_ok $service, 'Net::Google::Spreadsheets';

done_testing;

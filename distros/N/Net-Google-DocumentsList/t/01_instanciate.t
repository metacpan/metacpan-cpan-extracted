use t::Util;
use Test::More;

ok my $service = service();
isa_ok $service, 'Net::Google::DocumentsList';

done_testing;

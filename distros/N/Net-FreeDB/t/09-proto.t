use Test::Most;

require_ok('Net::FreeDB');

my $freedb = new Net::FreeDB();
ok($freedb, 'Unable to create instance');

if ($ENV{HAVE_INTERNET}) {
    ok($freedb->proto());
    ok($freedb->current_protocol_level() == 1);
    ok($freedb->max_protocol_level() == 6);
    
    ok($freedb->proto(6));
    ok($freedb->current_protocol_level() == 6);
}

done_testing;

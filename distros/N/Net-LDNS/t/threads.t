use Test::More;

use_ok('Net::LDNS');

my $can_use_threads = eval 'use threads; 1';
if ($can_use_threads) {

    my $resolver = Net::LDNS->new('8.8.8.8');
    isa_ok($resolver, 'Net::LDNS');
    my $rr = Net::LDNS::RR->new('www.iis.se.		60	IN	A	91.226.36.46');
    isa_ok($rr, 'Net::LDNS::RR::A');
    my $p = $resolver->query('www.google.com');
    isa_ok($p, 'Net::LDNS::Packet');
    my $rrlist = $p->all;
    isa_ok($rrlist, 'Net::LDNS::RRList');

    threads->create( sub {
        my $p = $resolver->query('www.lysator.liu.se');
        if (not ($p and ref($p) and ref($p) eq 'Net::LDNS::Packet')) {
            die "Something is wrong here";
        }
    } ) for 1..5;

    $_->join for threads->list;

}

done_testing;
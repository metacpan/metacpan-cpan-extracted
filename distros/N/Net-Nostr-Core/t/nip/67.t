use strictures 2;
use Test2::V0 -no_srand => 1;
use JSON ();
use Net::Nostr::Message;

subtest 'NIP-67 examples and legacy EOSE round trip' => sub {
    for my $wire ('["EOSE","sub2",["finish"]]',
                  '["EOSE","sub2b",["more"]]',
                  '["EOSE","sub4",["auth","finish"]]',
                  '["EOSE","sub",[]]', '["EOSE","sub"]',
                  '["EOSE","sub",["future-hint","more"]]') {
        my $message;
        ok lives { $message = Net::Nostr::Message->parse($wire) }, $wire;
        next unless $message;
        is(JSON->new->decode($message->serialize), JSON->new->decode($wire), 'wire shape preserved');
        ok($message->can('hints'), 'hints accessor exists');
        is($message->hints, JSON->new->decode($wire)->[2], 'hints exposed, absent stays absent') if $message->can('hints');
    }
};

subtest 'strict hint construction and parsing' => sub {
    for my $hints (undef, 'auth', {}, [undef], [{}], [JSON::true], [3]) {
        like dies { Net::Nostr::Message->new(type => 'EOSE', subscription_id => 's', hints => $hints) },
            qr/hints|hint/i, 'invalid constructor hint rejected';
        like dies { Net::Nostr::Message->parse(JSON->new->encode(['EOSE','s',$hints])) },
            qr/hints|hint/i, 'invalid wire hint rejected';
    }
    like dies { Net::Nostr::Message->parse('["EOSE","s",[],"extra"]') }, qr/EOSE/, 'fourth element rejected';
    like dies { Net::Nostr::Message->new(type => 'NOTICE', message => 'x', hints => []) }, qr/hints/, 'hints belong to EOSE';
    my $input = ['auth','future'];
    my $message = Net::Nostr::Message->new(type => 'EOSE', subscription_id => 's', hints => $input);
    $input->[0] = 'mutated';
    my $copy = $message->hints;
    push @$copy, 'mutated';
    is $message->hints, ['auth','future'], 'caller cannot mutate validated hints';
    like dies { $message->hints({}) }, qr/hints|hint/i, 'setter validates';
};

done_testing;

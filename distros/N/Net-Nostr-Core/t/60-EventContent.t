use strictures 2;
use Test2::V0 -no_srand => 1;
use JSON ();
use Net::Nostr::Event;
use Net::Nostr::Message;

use lib 't/lib';
use TestFixtures qw(%FIATJAF_EVENT make_event make_key_from_hex);

# NIP-01, "Events and signatures": content is a string both in the
# event object on the wire and in the canonical array used for its ID.
my $key = make_key_from_hex(('0' x 63) . '1');

subtest 'string content survives signing and JSON transport' => sub {
    for my $content ('', '0', 'hello', '{"message":"hello"}', "hello \x{1F600}\n") {
        my $event = $key->create_event(
            kind => 1, created_at => 1000, tags => [], content => $content,
        );
        ok lives { $event->validate }, 'original signed event validates';
        my $wire = JSON::encode_json(['EVENT', 'content-test', $event->to_hash]);
        my $received = Net::Nostr::Message->parse($wire)->event;
        is $received->content, $content, 'content survives JSON transport';
        is $received->id, $event->id, 'event ID survives JSON transport';
        ok lives { $received->validate }, 'received event still validates';
    }
};

for my $case (
    ['empty array', []],
    ['nonempty array', ['hello']],
    ['empty object', {}],
    ['nonempty object', {message => 'hello'}],
    ['JSON true', JSON::true],
    ['JSON false', JSON::false],
) {
    my ($name, $content) = @$case;

    subtest "$name content is rejected at public entry points" => sub {
        like dies { make_event(content => $content) }, qr/content must be a string/,
            'Event->new rejects reference content';
        like dies {
            $key->create_event(kind => 1, created_at => 1000, content => $content);
        }, qr/content must be a string/, 'Key->create_event rejects reference content before signing';

        my $hash = {%FIATJAF_EVENT, content => $content};
        like dies { Net::Nostr::Event->from_wire($hash) }, qr/content must be a string/,
            'Event->from_wire rejects reference content without a later validate call';
        for my $envelope (
            ['client EVENT', ['EVENT', $hash]],
            ['relay EVENT', ['EVENT', 'content-test', $hash]],
            ['client AUTH', ['AUTH', $hash]],
        ) {
            my ($label, $message) = @$envelope;
            like dies { Net::Nostr::Message->parse(JSON::encode_json($message)) },
                qr/content must be a string/, "$label parser rejects reference content";
        }
    };
}

done_testing;

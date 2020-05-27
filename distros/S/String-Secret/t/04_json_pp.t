use strict;
use Test::More 0.98;

use String::Secret;
use Scalar::Util qw/refaddr/;
use Test::Requires qw/JSON::PP/;

subtest 'allow_tags' => sub {
    plan skip_all => 'JSON::PP have a bug about allow_tags?';

    my $json = JSON::PP->new->allow_tags;

    my $secret = String::Secret->new('mysecret');

    my $encoded = eval { $json->encode($secret) };
    is $@, '', 'encode successful';
    eval { $json->decode($encoded) };
    like $@, qr/\Qcannot deserialize it/, 'block to $json->decode';

    subtest 'encoded content' => sub {
        my $deserialized_secret = force_json_decode($encoded);
        is $deserialized_secret->unwrap, '*' x 8, 'masked';
    };

    subtest 'serializable' => sub {
        my $serializable_secret = $secret->to_serializable();

        my $encoded = eval { $json->encode($serializable_secret) };
        is $@, '', 'encode successful';

        my $deserialized_secret = eval { $json->decode($encoded) };
        is $@, '', '$json->decode successful';
        is $deserialized_secret->unwrap, 'mysecret', 'do not masked';
    };

    subtest '$DISABLE_MASK = 1' => sub {
        local $String::Secret::DISABLE_MASK = 1;

        my $encoded = eval { $json->encode($secret) };
        is $@, '', 'encode successful';
        eval { $json->decode($encoded) };
        like $@, qr/\Qcannot deserialize it/, 'block to $json->decode';

        subtest 'encoded content' => sub {
            my $deserialized_secret = force_json_decode($encoded);
            is $deserialized_secret->unwrap, 'mysecret', 'do not masked';
        };
    };
};

subtest 'convert_blessed' => sub {
    my $json = JSON::PP->new->convert_blessed->allow_nonref;

    my $secret = String::Secret->new('mysecret');

    my $encoded = eval { $json->encode($secret) };
    is $@, '', 'encode successful';
    my $decoded = eval { $json->decode($encoded) };
    is $@, '', 'decode successful';
    is $decoded, '*' x 8, 'masked';

    subtest 'serializable' => sub {
        my $serializable_secret = $secret->to_serializable();

        my $encoded = eval { $json->encode($serializable_secret) };
        is $@, '', 'encode successful';

        my $decoded = eval { $json->decode($encoded) };
        is $@, '', '$json->decode successful';
        is $decoded, 'mysecret', 'do not masked';
    };

    subtest '$DISABLE_MASK = 1' => sub {
        local $String::Secret::DISABLE_MASK = 1;

        my $encoded = eval { $json->encode($secret) };
        is $@, '', 'encode successful';
        my $decoded = eval { $json->decode($encoded) };
        is $@, '', 'decode successful';
        is $decoded, 'mysecret', 'do not masked';
    };
};

sub force_json_decode {
    my $encoded = shift;

    no warnings qw/redefine/;
    local *String::Secret::THAW = do {
        use warnings qw/redefine/;
        my $super = \&String::Secret::THAW;
        sub {
            my ($class, $serialiser, $raw) = @_;
            return $class->new($raw);
        };
    };
    use warnings qw/redefine/;

    return JSON::PP->new->allow_tags->decode($encoded);
}

done_testing;



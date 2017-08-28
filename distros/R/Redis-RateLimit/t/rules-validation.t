use 5.14.1;
use warnings;
use JSON::MaybeXS qw/encode_json/;
use Redis::RateLimit;
use Test::Fatal;
use Test::Spec;

describe 'Redis::RateLimit' => sub {
    it 'croaks if interval undefined' => sub {
        like exception {
            Redis::RateLimit->new( rules => [
                { interval => 60, limit => 3600, precision => 5 },
                { interval => 3600, limit => 10_000 },
                { limit => 100, precision => 10 },
            ]);
        }, qr/interval undefined/;
    };

    it 'croaks if limit is undefined' => sub {
        like exception {
            Redis::RateLimit->new( rules => [
                { interval => 60 },
            ]);
        }, qr/limit undefined/;
    };

    it 'numifies values' => sub {
        my $rl = Redis::RateLimit->new(
            rules => [ { interval => '60', limit => '100' } ],
        );
        is encode_json($rl->rules), encode_json([ [ 60, 100 ] ]);
    };
};

runtests;

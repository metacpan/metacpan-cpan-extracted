use Test::More;
use Spica::Spec::Declare;

subtest 'edge case' => sub {
    my $klass = 'Spica::Test::Declare002Spec';
    my $spec = spec {
        client {
            name 'foo';
        };
    } $klass;

    ok $spec;
    isa_ok $spec => $klass;

    ok ! $spec->get_client('bar'), "non exists client should return undef";
    ok ! $spec->get_client(), "no name given should return undef";
};

done_testing;

use Mojo::Base -strict;
use Mojo::JSON qw(encode_json);

use Test::More;

use_ok('Mojo::Snoo::Subreddit');

no warnings 'redefine';
local *Mojo::Snoo::Base::_do_request = sub {
    my ($class, $method, $path) = @_;
    my $tx = Mojo::Transaction::HTTP->new();
    $tx->res->code(200);

    diag('TODO test mods and about subroutines as well.');
    my $mock_data = {
        data => {
            children => [
                {   date            => '1201247831',
                    mod_permissions => [qw( all )],
                    name            => 'mr_chromatic',
                    id              => 't2_15b0o',
                },
                {   date            => '1229953469',
                    mod_permissions => [qw( all )],
                    name            => 'petdance',
                    id              => 't2_1rm1',
                },
            ],
        },
    };

    cmp_ok(
        scalar(@{$mock_data->{data}{children}}),    #
        '==', 2, 'Mock response contains two children'
    );

    $tx->res->body(encode_json($mock_data));
    $tx->res;
};

my $cb = 0;

my $mods = Mojo::Snoo::Subreddit->new('perl')->mods(
    sub {
        isa_ok(shift, 'Mojo::Message::Response', 'Callback has response object');
        $cb = 1;
    }
);
ok($cb, 'Callback was run');
done_testing();

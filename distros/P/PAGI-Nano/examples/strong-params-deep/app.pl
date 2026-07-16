use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use PAGI::Nano;

# The strong-parameters grammar past the simple cases: a nested hash rule, a
# bare array, an array-of-hashes, and (for form bodies) namespace + flat-key
# reconstruction. $c->params picks the source by content-type — JSON keeps
# structure as-is; an urlencoded form rebuilds nested shapes from dotted/bracket
# keys. required's on-missing callback owns the 400.
#
#     pagi-server app.pl
#
#     # JSON order: nested address, bare-array coupons, array-of-hashes items
#     curl -H 'content-type: application/json' -d '{
#       "customer":"Ada","address":{"street":"1 Calc Ln","city":"London"},
#       "coupons":["EARLY","VIP"],
#       "items":[{"sku":"A1","qty":"2"},{"sku":"B2","qty":"1"}]
#     }' http://127.0.0.1:5000/orders
#
#     # Form profile: dotted keys rebuilt under a namespace
#     curl -d 'user.name=Ada&user.email=ada@calc.dev&spam=x' http://127.0.0.1:5000/profile

my $app = app {
    # JSON body: the rich rule grammar, with required guarding the must-haves.
    post '/orders' => async sub ($c) {
        my $order = await $c->params->required(
            'customer',                          # a required scalar
            address => ['street', 'city'],       # a nested hash (its keys whitelisted)
            +{ items   => ['sku', 'qty'] },      # an array of hashes
            +{ coupons => [] },                  # a bare array of scalars
            sub ($c, $missing) {
                $c->json({ error => 'missing', fields => $missing }, status => 400);
            },
        );
        $c->json({ accepted => $order }, status => 201);
    };

    # Form body: namespace scopes the rules to a key prefix, and the dotted flat
    # keys (user.name, user.email) are reconstructed into a nested hash. Keys
    # outside the whitelist (spam) are dropped.
    post '/profile' => async sub ($c) {
        my $profile = await $c->params->namespace(['user'])->permitted('name', 'email');
        $c->json({ user => $profile });
    };
};

$app;

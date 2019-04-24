use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojolicious::Static;

throws_ok { Mojolicious::Static->new->with_roles('+Compressed')->should_serve_asset([]) }
qr/reftype of should_serve_asset must be either undef \(scalar\) or 'CODE', but was 'ARRAY'/,
    'arrayref should_serve_asset throws';

throws_ok { Mojolicious::Static->new->with_roles('+Compressed')->should_serve_asset({}) }
qr/reftype of should_serve_asset must be either undef \(scalar\) or 'CODE', but was 'HASH'/,
    'arrayref should_serve_asset throws';

lives_ok { Mojolicious::Static->new->with_roles('+Compressed')->should_serve_asset(undef) }
'undef should_serve_asset lives';
lives_ok { Mojolicious::Static->new->with_roles('+Compressed')->should_serve_asset(0) }
'0 should_serve_asset lives';
lives_ok { Mojolicious::Static->new->with_roles('+Compressed')->should_serve_asset(1) }
'1 should_serve_asset lives';
lives_ok { Mojolicious::Static->new->with_roles('+Compressed')->should_serve_asset('string') }
'string should_serve_asset lives';
lives_ok {
    Mojolicious::Static->new->with_roles('+Compressed')->should_serve_asset(sub { })
}
'CODE should_serve_asset lives';

done_testing;

use strict;
use warnings;
use utf8;
use Test::More;

use_ok('Plack::Middleware::WOVN::Lang');

ok($Plack::Middleware::WOVN::Lang::LANG);

is( scalar( keys(%$Plack::Middleware::WOVN::Lang::LANG) ), 28 );

for my $key ( keys %$Plack::Middleware::WOVN::Lang::LANG ) {
    my $l = $Plack::Middleware::WOVN::Lang::LANG->{$key};
    ok( exists $l->{name} );
    ok( exists $l->{code} );
    ok( exists $l->{en} );
    is( $key, $l->{code} );
}

is( Plack::Middleware::WOVN::Lang->get_code('ms'),                 'ms' );
is( Plack::Middleware::WOVN::Lang->get_code('zh-cht'),             'zh-CHT' );
is( Plack::Middleware::WOVN::Lang->get_code('Portuguese'),         'pt' );
is( Plack::Middleware::WOVN::Lang->get_code('हिन्दी'), 'hi' );
is( Plack::Middleware::WOVN::Lang->get_code('WOVN4LYFE'),          undef );
is( Plack::Middleware::WOVN::Lang->get_code(''),                   undef );
is( Plack::Middleware::WOVN::Lang->get_code(undef),                undef );

print Plack::Middleware::WOVN::Lang->get_lang('ms');
print "\n";

done_testing;


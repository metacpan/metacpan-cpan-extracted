use utf8;
use strict;
use warnings;
use Test::More;
use Test::Name::FromLine;
use Plack::Middleware::Assets::RailsLike;

my $assets = new_ok 'Plack::Middleware::Assets::RailsLike';
can_ok $assets, $_ for qw(path root search_path cache expires minify);

$assets->prepare_app;

is $assets->path,      qr{^/assets};
is $assets->root,      '.';
is_deeply $assets->search_path, [qw(assets)];
can_ok $assets->cache, $_ for qw(get set);
is $assets->expires,   '3 days';
is $assets->minify,    1;

done_testing;

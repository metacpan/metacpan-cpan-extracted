use Mojo::Base -strict;
use Test::More;
use Mojolicious::Static;

my $static = Mojolicious::Static->new->with_roles('+Compressed');

# test default
is_deeply $static->compression_types,
    [{ext => 'br', encoding => 'br'}, {ext => 'gz', encoding => 'gzip'}], 'expected default';

# test that expansion works
$static->compression_types(['ab', 'cd']);

is_deeply $static->compression_types,
    [{ext => 'ab', encoding => 'ab'}, {ext => 'cd', encoding => 'cd'}],
    'ext and encoding expansion works';

# test no expansion works
$static->compression_types(
    [{ext => 'ef', encoding => 'ef-encoding'}, {ext => 'gh', encoding => 'gh-encoding'}]);

is_deeply $static->compression_types,
    [{ext => 'ef', encoding => 'ef-encoding'}, {ext => 'gh', encoding => 'gh-encoding'}],
    'ext and encoding without expansion works';

# test that mixture of expansion and no expansion works
$static->compression_types(['ij', {ext => 'kl', encoding => 'kl-encoding'}]);

is_deeply $static->compression_types,
    [{ext => 'ij', encoding => 'ij'}, {ext => 'kl', encoding => 'kl-encoding'}],
    'ext and encoding with expansion then no expansion works';

$static->compression_types([{ext => 'mn', encoding => 'mn-encoding'}, 'op']);

is_deeply $static->compression_types,
    [{ext => 'mn', encoding => 'mn-encoding'}, {ext => 'op', encoding => 'op'}],
    'ext and encoding with no expansion then expansion works';

is $static->compression_types(['br']), $static, 'returns $self when used as a setter';

done_testing;

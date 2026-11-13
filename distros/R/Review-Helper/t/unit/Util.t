# Test origin: AI
use v5.36;
use Test2::V0;

use File::Spec;
use Cwd ();

use Review::Helper::Util qw/json_encode json_decode gen_uuid now/;

is(json_encode({b => 1, a => [1, undef], c => "\x{2713}"}), qq/{"a":[1,null],"b":1,"c":"\xe2\x9c\x93"}/, 'canonical UTF-8 bytes');
is(json_decode(qq/{"c":"\xe2\x9c\x93"}/),                   {c => "\x{2713}"},                           'decodes UTF-8 bytes to characters');
ok(dies { json_decode('{') }, 'invalid JSON dies');

my $id = gen_uuid();
like($id, qr/^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/, 'UUID v7');
isnt(gen_uuid(), $id, 'unique');

like(now(), qr/^\d+$/, 'integer epoch');
ok(abs(now() - time) <= 1, 'current time');

is(\@Review::Helper::Util::EXPORT, [], 'nothing exported by default');

subtest share_dir => sub {
    my $dir = Review::Helper::Util::share_dir();
    ok(-f "$dir/ux/html/index.html",            'finds the checkout share directory');
    ok(File::Spec->file_name_is_absolute($dir), 'an absolute path');
    unlike($dir, qr{(?:^|/)\.\.?(?:/|$)}, 'with no . or .. in it');

    my $orig = Cwd::getcwd();
    chdir('/') or die "chdir: $!";
    is(Review::Helper::Util::share_dir(), $dir, 'same answer after a chdir');
    chdir($orig) or die "chdir: $!";
};

done_testing;

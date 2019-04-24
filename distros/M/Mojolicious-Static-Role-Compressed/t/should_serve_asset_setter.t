use Mojo::Base -strict;
use Test::More;
use Test::Warn;
use Mojolicious::Static;
use Mojo::Asset::File;

my $static = Mojolicious::Static->new->with_roles('+Compressed');

# test default
local $_ = Mojo::Asset::File->new(path => 'file.pdf');
ok !$static->should_serve_asset->(), 'pdf should not be served';

local $_ = Mojo::Asset::File->new(path => 'file.jpeg');
ok !$static->should_serve_asset->(), 'jepg should not be served';

local $_ = Mojo::Asset::File->new(path => 'file.jpg');
ok !$static->should_serve_asset->(), 'jpg should not be served';

local $_ = Mojo::Asset::File->new(path => 'file.gif');
ok !$static->should_serve_asset->(), 'gif should not be served';

local $_ = Mojo::Asset::File->new(path => 'file.png');
ok !$static->should_serve_asset->(), 'png should not be served';

local $_ = Mojo::Asset::File->new(path => 'file.webp');
ok !$static->should_serve_asset->(), 'webp should not be served';

# test that case doesn't matter
local $_ = Mojo::Asset::File->new(path => 'file.PDF');
ok !$static->should_serve_asset->(), 'PDF case should not matter';

local $_ = Mojo::Asset::File->new(path => 'file.pdF');
ok !$static->should_serve_asset->(), 'pdF case should not matter';

local $_ = Mojo::Asset::File->new(path => 'file.jPeG');
ok !$static->should_serve_asset->(), 'jPeG case should not matter';

# test that in the middle doesn't matter
local $_ = Mojo::Asset::File->new(path => '/home/file.pdf/hello.txt');
ok $static->should_serve_asset->(), 'pdf in the middle does not matter';

local $_ = Mojo::Asset::File->new(path => '/home/file.jpeg/hello.txt');
ok $static->should_serve_asset->(), 'jpeg in the middle does not matter';

local $_ = Mojo::Asset::File->new(path => '/file.gif/srchulo/hello.txt');
ok $static->should_serve_asset->(), 'gif in the beginning does not matter';

# period required
local $_ = Mojo::Asset::File->new(path => 'filepdf');
ok $static->should_serve_asset->(), 'period required before pdf';

local $_ = Mojo::Asset::File->new(path => 'filejpeg');
ok $static->should_serve_asset->(), 'period required before jpeg';

# test that must end with the compressed types exactly
local $_ = Mojo::Asset::File->new(path => 'file.pdfx');
ok $static->should_serve_asset->(), 'pdfx should be served';

local $_ = Mojo::Asset::File->new(path => 'file.jpegx');
ok $static->should_serve_asset->(), 'jpegx should be served';

local $_ = Mojo::Asset::File->new(path => 'file.jpgx');
ok $static->should_serve_asset->(), 'jpgx should be served';

local $_ = Mojo::Asset::File->new(path => 'file.gifx');
ok $static->should_serve_asset->(), 'gifx should be served';

local $_ = Mojo::Asset::File->new(path => 'file.pngx');
ok $static->should_serve_asset->(), 'pngx should be served';

local $_ = Mojo::Asset::File->new(path => 'file.webpx');
ok $static->should_serve_asset->(), 'webpx should be served';

# other standard files should return true
local $_ = Mojo::Asset::File->new(path => 'file.html');
ok $static->should_serve_asset->(), 'html should be served';

local $_ = Mojo::Asset::File->new(path => 'file.htm');
ok $static->should_serve_asset->(), 'htm should be served';

local $_ = Mojo::Asset::File->new(path => 'file.css');
ok $static->should_serve_asset->(), 'css should be served';

local $_ = Mojo::Asset::File->new(path => 'file.js');
ok $static->should_serve_asset->(), 'js should be served';

# standard files with paths
local $_ = Mojo::Asset::File->new(path => 'public/file.html');
ok $static->should_serve_asset->(), 'public/file.html should be served';

local $_ = Mojo::Asset::File->new(path => 'public/file.htm');
ok $static->should_serve_asset->(), 'public/file.htm should be served';

local $_ = Mojo::Asset::File->new(path => 'public/file.css');
ok $static->should_serve_asset->(), 'public/file.css should be served';

local $_ = Mojo::Asset::File->new(path => 'file.js');
ok $static->should_serve_asset->(), 'public/file.js should be served';

# test warn
warning_is { $static->should_serve_asset(undef) }
'should_serve_asset is a scalar that is always false, so compressed assets will never be served. If this is because you are in development mode, you should instead just not load this role.',
    'undef causes warning';
warning_is { $static->should_serve_asset(0) }
'should_serve_asset is a scalar that is always false, so compressed assets will never be served. If this is because you are in development mode, you should instead just not load this role.',
    '0 causes warning';
warning_is { $static->should_serve_asset('0') }
'should_serve_asset is a scalar that is always false, so compressed assets will never be served. If this is because you are in development mode, you should instead just not load this role.',
    q{'0' causes warning};
warning_is { $static->should_serve_asset('') }
'should_serve_asset is a scalar that is always false, so compressed assets will never be served. If this is because you are in development mode, you should instead just not load this role.',
    'empty string causes warning';

warning_is { $static->should_serve_asset(1) } undef, '1 does not cause warning';
warning_is { $static->should_serve_asset('string') } undef,
    'non-empty string does not cause warning';
warning_is {
    $static->should_serve_asset(sub { })
}
undef, 'CODE does not cause warning';

# test setter
my $sub = sub { };
$static->should_serve_asset($sub);
is $static->should_serve_asset, $sub, 'setting sub succeeds';

$static->should_serve_asset(1);
is $static->should_serve_asset, 1, 'setting 1 succeeds';

$static->should_serve_asset('string');
is $static->should_serve_asset, 'string', 'setting string succeeds';

is $static->should_serve_asset(1), $static, 'returns $self when used as a setter';

done_testing;

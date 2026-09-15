use strict;
use warnings;
use utf8;
use Test::More;
use Package::Prototype;
BEGIN { plan skip_all => 'Unicode method names require Perl 5.36 or later in this module' if $] < 5.036 }
my $obj = Package::Prototype->bless({ '名前' => '日本語', 'é' => 1 }, '例');
is $obj->名前, '日本語', 'Unicode getter on creation';
is $obj->é, 1, 'Latin-1 getter on creation';
is ref($obj), '例', 'Unicode class label';
$obj->prototype('挨拶' => sub { 'こんにちは' });
is $obj->挨拶, 'こんにちは', 'Unicode dynamic method';
$obj->prototype('名前' => '更新', 'é' => 2);
is $obj->名前, '更新', 'Unicode method replacement';
is $obj->é, 2, 'Latin-1 replacement';
ok $obj->can('名前'), 'Unicode can lookup';
my $explicit = Package::Prototype->create(properties => {
    '値' => { value => 3, writer => '設定' },
});
$explicit->設定(4);
is $explicit->値, 4, 'Unicode explicit accessors';
done_testing;

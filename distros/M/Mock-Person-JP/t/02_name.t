use strict;
use warnings;
use utf8;
use Mock::Person::JP;
use Test::More;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

my $mpj = Mock::Person::JP->new;

my $person = $mpj->create_person(sex => 'female');
my $name   = $person->name;
isa_ok($name, 'Mock::Person::JP::Person::Name');

subtest 'basic format check for female' => sub {
    like($name->last_name,        qr/^[\p{Han}\p{InHiragana}\p{InKatakana}〆]+$/, 'last_name');
    like($name->first_name,       qr/^[\p{Han}\p{InHiragana}\p{InKatakana}\x{30FC}〆]+$/, 'first_name');
    like($name->sei,              qr/^[\p{Han}\p{InHiragana}\p{InKatakana}〆]+$/, 'sei');
    like($name->mei,              qr/^[\p{Han}\p{InHiragana}\p{InKatakana}\x{30FC}〆]+$/, 'mei');
    like($name->last_name_yomi,   qr/^[\p{InHiragana}\x{30FC}]+$/, 'last_name yomi');
    like($name->first_name_yomi,  qr/^[\p{InHiragana}\x{30FC}]+$/, 'first_name yomi');
    like($name->sei_yomi,         qr/^[\p{InHiragana}\x{30FC}]+$/, 'sei yomi');
    like($name->mei_yomi,         qr/^[\p{InHiragana}\x{30FC}]+$/, 'mei yomi');
};

subtest 'same person has the same name' => sub {
    is($person->name->last_name,  $person->name->last_name);
    is($person->name->first_name, $person->name->first_name);
    is($person->name->sei,        $person->name->sei);
    is($person->name->mei,        $person->name->mei);
};

subtest 'different person has a different name' => sub {
    my $name2 = $mpj->create_person(sex => 'female')->name;
    isnt($name2->last_name,  $name->last_name);
    isnt($name2->first_name, $name->first_name);
    isnt($name2->sei,        $name->sei);
    isnt($name2->mei,        $name->mei);
};

subtest 'basic format check for male' => sub {
    my $name2 = $mpj->create_person(sex => 'male')->name;
    like($name2->last_name,        qr/^[\p{Han}\p{InHiragana}\p{InKatakana}〆]+$/, 'last_name');
    like($name2->first_name,       qr/^[\p{Han}\p{InHiragana}\p{InKatakana}\x{30FC}〆]+$/, 'first_name');
    like($name2->sei,              qr/^[\p{Han}\p{InHiragana}\p{InKatakana}〆]+$/, 'sei');
    like($name2->mei,              qr/^[\p{Han}\p{InHiragana}\p{InKatakana}\x{30FC}〆]+$/, 'mei');
    like($name2->last_name_yomi,   qr/^[\p{InHiragana}\x{30FC}]+$/, 'last_name yomi');
    like($name2->first_name_yomi,  qr/^[\p{InHiragana}\x{30FC}]+$/, 'first_name yomi');
    like($name2->sei_yomi,         qr/^[\p{InHiragana}\x{30FC}]+$/, 'sei yomi');
    like($name2->mei_yomi,         qr/^[\p{InHiragana}\x{30FC}]+$/, 'mei yomi');
};

done_testing;

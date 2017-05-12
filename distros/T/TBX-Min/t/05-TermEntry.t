# test the functionality of TBX::Min::TermEntry

use strict;
use warnings;
use Test::More;
plan tests => 13;
use Test::Deep;
use Test::NoWarnings;
use Test::Exception;
use TBX::Min;

my $args = {
    id => 'B001',
    subject_field => 'foo',
    lang_groups => [
        TBX::Min::LangSet->new({code => 'en'}),
        TBX::Min::LangSet->new({code => 'zh'}),
    ],
};

#test constructor without arguments
my $concept = TBX::Min::TermEntry->new;
isa_ok($concept, 'TBX::Min::TermEntry');

ok(!$concept->id, 'id not defined by default');
ok(!$concept->subject_field,
    'subject_field not defined by default');
is_deeply($concept->lang_groups, [],
    'lang_groups returns empty array by default');

#test constructor with arguments
$concept = TBX::Min::TermEntry->new($args);
is($concept->id, $args->{id}, 'correct id from constructor');
is($concept->subject_field, $args->{subject_field},
    'correct subject_field from constructor');
cmp_deeply($concept->lang_groups, $args->{lang_groups},
    'correct term groups from constructor');

#test setters
$concept = TBX::Min::TermEntry->new();

$concept->id($args->{id});
is($concept->id, $args->{id}, 'id correctly set');

$concept->subject_field($args->{subject_field});
is($concept->subject_field, $args->{subject_field},
    'subject_field correctly set');

$concept->add_lang_group($args->{lang_groups}->[0]);
cmp_deeply($concept->lang_groups->[0], $args->{lang_groups}->[0],
    'add_lang_group works correctly');

throws_ok {
    TBX::Min::TermEntry->new({foo=>'bar'});
} qr{Invalid attributes for class: foo},
'constructor fails with bad arguments';

throws_ok {
    TBX::Min::TermEntry->new({lang_groups => 'bar'});
} qr{Attribute 'lang_groups' should be an array reference},
'constructor fails with incorrect data type for lang_groups';

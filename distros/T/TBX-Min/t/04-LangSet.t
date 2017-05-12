# test the functionality of TBX::Min::LangSet

use strict;
use warnings;
use Test::More;
plan tests => 10;
use Test::Deep;
use Test::NoWarnings;
use Test::Exception;
use TBX::Min;

my $args = {
    code => 'en',
    term_groups => [
        TBX::Min::TIG->new({term => 'foo'}),
        TBX::Min::TIG->new({term => 'bar'}),
    ],
};

#test constructor without arguments
my $lang_grp = TBX::Min::LangSet->new;
isa_ok($lang_grp, 'TBX::Min::LangSet');

ok(!$lang_grp->code, 'language not defined by default');
cmp_deeply($lang_grp->term_groups, [],
    'term_groups returns empty array by default');

#test constructor with arguments
$lang_grp = TBX::Min::LangSet->new($args);
is($lang_grp->code, $args->{code}, 'correct language code from constructor');
cmp_deeply($lang_grp->term_groups, $args->{term_groups},
    'correct term groups from constructor');

#test setters
$lang_grp = TBX::Min::LangSet->new();

$lang_grp->code($args->{code});
is($lang_grp->code, $args->{code}, 'code correctly set');

$lang_grp->add_term_group($args->{term_groups}->[0]);
cmp_deeply($lang_grp->term_groups->[0], $args->{term_groups}->[0],
    'add_term_group works correctly');

throws_ok {
    TBX::Min::LangSet->new({foo => 'bar'});
} qr{Invalid attributes for class: foo},
'constructor fails with bad arguments';

throws_ok {
    TBX::Min::LangSet->new({term_groups => 'bar'});
} qr{Attribute 'term_groups' should be an array reference},
'constructor fails with incorrect data type for term_groups';

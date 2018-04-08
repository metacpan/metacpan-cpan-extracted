#!/usr/bin/perl

use Test::More;
use Test::Deep;

use qbit;

use lib::abs qw(../lib);

use QBit::QueryData;

my $data = [
    {id => 1, label => 'label 1', num => 1,},
    {id => 2, label => 'label 1', num => 1,},
    {id => 3, label => 'label 1', num => 2,},
    {id => 4, label => 'label 2', num => 3,},
    {id => 5, label => 'label 3', num => 4,},
    {id => 5, label => 'label 3', num => 4,},
];

my $q = QBit::QueryData->new(data => $data);

$q->fields([qw(id label num)]);

try {
    $q->group_by(qw(label num));
}
catch {
    is(shift->message, gettext("You've forgotten grouping function for query fields: %s", 'id'), 'correctly message');
}
finally {
    is(ref(shift), 'Exception::BadArguments', 'throw exception');
};

$q->fields([qw(label num)]);
$q->group_by(qw(label num));

my $group_by_label_num = [
    {
        'label' => 'label 1',
        'num'   => 1
    },
    {
        'label' => 'label 1',
        'num'   => 2
    },
    {
        'num'   => 3,
        'label' => 'label 2'
    },
    {
        'num'   => 4,
        'label' => 'label 3'
    }
];

cmp_deeply($q->get_all(), $group_by_label_num, 'group by label, num');

$q->distinct();

cmp_deeply($q->get_all(), $group_by_label_num, 'distinct not needed');

$q->fields([]);
$q->distinct(FALSE);
$q->group_by();

cmp_deeply($q->get_all(), $data, 'reset fields, distinct and group by');

$q->distinct();

cmp_deeply($q->get_all(), [@$data[0 .. 4]], 'distinct');
$q->distinct(FALSE);

$q->fields({caption => 'label', num => ''});
$q->group_by(qw(caption num));

cmp_deeply($q->get_all(), [map {$_->{'caption'} = delete($_->{'label'}); $_} @$group_by_label_num], 'group by alias');

done_testing();

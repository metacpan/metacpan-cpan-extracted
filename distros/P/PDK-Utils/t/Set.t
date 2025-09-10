#!/usr/bin/env perl

use v5.30;
use strict;
use warnings;
use Test::More;

use PDK::Utils::Set;

# 测试对象创建
subtest '对象创建测试' => sub {
    my $set;

    ok(
        eval {
            $set = PDK::Utils::Set->new;
            1;
        } && $set->isa('PDK::Utils::Set'),
        '创建默认 PDK::Utils::Set 对象成功'
    );

    ok(
        eval {
            $set = PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ]);
            1;
        } && $set->isa('PDK::Utils::Set'),
        '使用 mins 和 maxs 数组初始化对象成功'
    );

    ok(
        eval {
            $set = PDK::Utils::Set->new(4, 1);
            1;
        } && $set->isa('PDK::Utils::Set') &&
            $set->mins->[0] == 1 &&
            $set->maxs->[0] == 4,
        '使用两个数值参数初始化对象成功（顺序自动校正）'
    );

    ok(
        eval {
            my $other_set = PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ]);
            $set = PDK::Utils::Set->new($other_set);
            1;
        } && $set->isa('PDK::Utils::Set') &&
            $set->isEqual(PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ])),
        '使用另一个 Set 对象初始化对象成功'
    );

    done_testing();
};

# 测试基本属性方法
subtest '基本属性方法测试' => sub {
    my $set = PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ]);

    is($set->length, 2, 'length 方法返回正确值');
    is($set->min, 1, 'min 方法返回正确值');
    is($set->max, 10, 'max 方法返回正确值');

    done_testing();
};

# 测试合并操作
subtest '合并操作测试' => sub {
    my $set;

    $set = PDK::Utils::Set->new(7, 10);
    $set->mergeToSet(2, 4);
    ok(
        $set->isEqual(PDK::Utils::Set->new(mins => [ 2, 7 ], maxs => [ 4, 10 ])),
        'mergeToSet(min, max) 方法工作正常'
    );

    $set = PDK::Utils::Set->new(7, 10);
    $set->_mergeToSet(2, 4);
    ok(
        $set->isEqual(PDK::Utils::Set->new(mins => [ 2, 7 ], maxs => [ 4, 10 ])),
        '_mergeToSet(min, max) 方法工作正常'
    );

    $set = PDK::Utils::Set->new(7, 10);
    $set->addToSet(2, 4);
    ok(
        $set->isEqual(PDK::Utils::Set->new(mins => [ 2, 7 ], maxs => [ 4, 10 ])),
        'addToSet(min, max) 方法工作正常'
    );

    $set = PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ]);
    my $aSet = PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ]);
    $set->mergeToSet($aSet);
    ok(
        $set->isEqual($aSet),
        'mergeToSet(PDK::Utils::Set) 方法工作正常'
    );

    done_testing();
};

# 测试集合关系判断
subtest '集合关系判断测试' => sub {
    my $set = PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ]);

    ok(
        $set->isEqual(PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ])),
        'isEqual 方法正确判断相等集合'
    );

    ok(
        !$set->isEqual(PDK::Utils::Set->new(mins => [ 1, 8 ], maxs => [ 4, 9 ])),
        'isEqual 方法正确判断不相等集合'
    );

    ok(
        $set->isContain(PDK::Utils::Set->new(mins => [ 1, 8 ], maxs => [ 4, 9 ])),
        'isContain 方法正确判断包含关系'
    );

    ok(
        $set->isContain(PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ])),
        'isContain 方法正确判断相等集合的包含关系'
    );

    ok(
        !$set->isContain(PDK::Utils::Set->new(mins => [ 1, 8 ], maxs => [ 4, 11 ])),
        'isContain 方法正确判断不包含关系'
    );

    ok(
        $set->_isContain(PDK::Utils::Set->new(mins => [ 1, 8 ], maxs => [ 4, 9 ])),
        '_isContain 方法正确判断包含关系'
    );

    ok(
        $set->isContainButNotEqual(PDK::Utils::Set->new(mins => [ 1, 8 ], maxs => [ 4, 9 ])),
        'isContainButNotEqual 方法正确判断真包含关系'
    );

    ok(
        !$set->isContainButNotEqual(PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ])),
        'isContainButNotEqual 方法正确判断非真包含关系'
    );

    done_testing();
};

# 测试属于关系判断
subtest '属于关系判断测试' => sub {
    my $set = PDK::Utils::Set->new(mins => [ 1, 8 ], maxs => [ 4, 9 ]);

    ok(
        $set->isBelong(PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ])),
        'isBelong 方法正确判断属于关系'
    );

    ok(
        $set->isBelong(PDK::Utils::Set->new(mins => [ 1, 8 ], maxs => [ 4, 9 ])),
        'isBelong 方法正确判断相等集合的属于关系'
    );

    ok(
        !$set->isBelong(PDK::Utils::Set->new(mins => [ 1, 9 ], maxs => [ 4, 11 ])),
        'isBelong 方法正确判断不属于关系'
    );

    ok(
        $set->_isBelong(PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ])),
        '_isBelong 方法正确判断属于关系'
    );

    ok(
        $set->isBelongButNotEqual(PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ])),
        'isBelongButNotEqual 方法正确判断真属于关系'
    );

    ok(
        !$set->isBelongButNotEqual(PDK::Utils::Set->new(mins => [ 1, 8 ], maxs => [ 4, 9 ])),
        'isBelongButNotEqual 方法正确判断非真属于关系'
    );

    done_testing();
};

# 测试集合比较
subtest '集合比较测试' => sub {
    my $set = PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ]);

    is(
        $set->compare(PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 10 ])),
        'equal',
        'compare 方法正确判断相等关系'
    );

    is(
        $set->compare(PDK::Utils::Set->new(mins => [ 1, 8 ], maxs => [ 4, 9 ])),
        'containButNotEqual',
        'compare 方法正确判断包含但不相等关系'
    );

    is(
        $set->compare(PDK::Utils::Set->new(mins => [ 1, 7 ], maxs => [ 4, 11 ])),
        'belongButNotEqual',
        'compare 方法正确判断属于但不相等关系'
    );

    is(
        $set->compare(PDK::Utils::Set->new(mins => [ 1, 8 ], maxs => [ 5, 9 ])),
        'other',
        'compare 方法正确判断其他关系'
    );

    done_testing();
};

# 测试集合交集
subtest '集合交集测试' => sub {
    my $set = PDK::Utils::Set->new(mins => [ 1, 4, 12 ], maxs => [ 2, 10, 15 ]);
    my $result = $set->interSet(PDK::Utils::Set->new(mins => [ 3, 9 ], maxs => [ 7, 16 ]));

    ok(
        $result->isEqual(PDK::Utils::Set->new(mins => [ 4, 9, 12 ], maxs => [ 7, 10, 15 ])),
        'interSet 方法正确计算集合交集'
    );

    done_testing();
};

done_testing();


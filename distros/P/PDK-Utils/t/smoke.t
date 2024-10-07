use strict;
use warnings;
use 5.014;
use Test::Simple tests => 20;
use Data::Dumper;


use PDK::Utils::Set;


my $set;

ok(
  do {
    eval { $set = PDK::Utils::Set->new; };
    warn $@ if $@;
    $set->isa('PDK::Utils::Set');
  },
  ' 生成 PDK::Utils::Set 对象'
);


ok(
  do {
    my @params = (mins => [1, 7], maxs => [4, 10]);
    eval { $set = PDK::Utils::Set->new(@params); };
    warn $@ if $@;
    $set->isa('PDK::Utils::Set');
  },
  ' 以 mins => [1,7], maxs => [4,10] 为参数初始化对象成功'
);


ok(
  do {
    my @params = (4, 1);
    eval { $set = PDK::Utils::Set->new(@params); };
    warn $@ if $@;
    $set->isa('PDK::Utils::Set') and $set->mins->[0] == 1 and $set->maxs->[0] == 4;
  },
  ' 以 4,1 为参数初始化对象成功'
);


ok(
  do {
    my @params = PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]);
    eval { $set = PDK::Utils::Set->new(@params); };
    warn $@ if $@;
    $set->isa('PDK::Utils::Set') and $set->isEqual($params[0]);
  },
  ' 以 PDK::Utils::Set对象 为参数初始化对象成功'
);


ok(
  do {
    my @params = (mins => [1, 7], maxs => [4, 10]);
    eval { $set = PDK::Utils::Set->new(@params); };
    warn $@ if $@;
    $set->length == 2;
  },
  ' length'
);


ok(
  do {
    my @params = (mins => [1, 7], maxs => [4, 10]);
    eval { $set = PDK::Utils::Set->new(@params); };
    warn $@ if $@;
    $set->min == 1;
  },
  ' min'
);


ok(
  do {
    my @params = (mins => [1, 7], maxs => [4, 10]);
    eval { $set = PDK::Utils::Set->new(@params); };
    warn $@ if $@;
    $set->max == 10;
  },
  ' max'
);


ok(
  do {
    my $aSet;
    eval {
      $aSet = PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]);
      $set->mergeToSet($aSet);
    };
    warn $@ if $@;
    $set->isEqual($aSet);
  },
  ' mergeToSet(PDK::Utils::Set)'
);


ok(
  do {
    eval {
      $set = PDK::Utils::Set->new(7, 10);
      $set->mergeToSet(2, 4);
    };
    warn $@ if $@;
    $set->isEqual(PDK::Utils::Set->new(mins => [2, 7], maxs => [4, 10]));
  },
  ' mergeToSet(min, max)'
);


ok(
  do {
    eval {
      $set = PDK::Utils::Set->new(7, 10);
      $set->_mergeToSet(2, 4);
    };
    warn $@ if $@;
    $set->isEqual(PDK::Utils::Set->new(mins => [2, 7], maxs => [4, 10]));
  },
  ' _mergeToSet(min, max)'
);


ok(
  do {
    eval {
      $set = PDK::Utils::Set->new(7, 10);
      $set->addToSet(2, 4);
    };
    warn $@ if $@;
    $set->isEqual(PDK::Utils::Set->new(mins => [2, 7], maxs => [4, 10]));
  },
  ' addToSet(min, max)'
);


ok(
  do {
    eval { $set = PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]); };
    warn $@ if $@;
    $set->isEqual(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]))
      and not $set->isEqual(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9]));
  },
  ' isEqual'
);

ok(
  do {
    eval { $set = PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]); };
    warn $@ if $@;
    $set->isContain(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9]))
      and $set->isContain(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]))
      and not $set->isContain(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 11]));
  },
  ' isContain'
);

ok(
  do {
    eval { $set = PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]); };
    warn $@ if $@;
    $set->_isContain(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9]))
      and $set->_isContain(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]))
      and not $set->_isContain(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 11]));
  },
  ' _isContain'
);

ok(
  do {
    eval { $set = PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]); };
    warn $@ if $@;
    $set->isContainButNotEqual(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9]))
      and $set->isContain(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]))
      and not $set->isContainButNotEqual(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]));
  },
  ' isContainButNotEqual'
);

ok(
  do {
    eval { $set = PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9]); };
    warn $@ if $@;
    $set->isBelong(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]))
      and $set->isBelong(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9]))
      and not $set->isBelong(PDK::Utils::Set->new(mins => [1, 9], maxs => [4, 11]));
  },
  ' isBelong'
);

ok(
  do {
    eval { $set = PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9]); };
    warn $@ if $@;
    $set->_isBelong(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]))
      and $set->_isBelong(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9]))
      and not $set->_isBelong(PDK::Utils::Set->new(mins => [1, 9], maxs => [4, 11]));
  },
  ' _isBelong'
);

ok(
  do {
    eval { $set = PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9]); };
    warn $@ if $@;
    $set->isBelongButNotEqual(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]))
      and $set->isBelong(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9]))
      and not $set->isBelongButNotEqual(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9]));
  },
  ' isBelongButNotEqual'
);


ok(
  do {
    eval { $set = PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]); };
    warn $@ if $@;
          $set->compare(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10])) eq 'equal'
      and $set->compare(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9])) eq 'containButNotEqual'
      and $set->compare(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 11])) eq 'belongButNotEqual'
      and $set->compare(PDK::Utils::Set->new(mins => [1, 8], maxs => [5, 9])) eq 'other';
  },
  ' compare'
);


ok(
  do {
    eval { $set = PDK::Utils::Set->new(mins => [1, 4, 12], maxs => [2, 10, 15]); };
    warn $@ if $@;
    $set->interSet(PDK::Utils::Set->new(mins => [3, 9], maxs => [7, 16]))
      ->compare(PDK::Utils::Set->new(mins => [4, 9, 12], maxs => [7, 10, 15])) eq 'equal';
  },
  ' interSet'
);



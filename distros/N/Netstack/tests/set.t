#!/usr/bin/env perl
use 5.016;
use warnings;
use Test::Simple tests => 20;
use Mojo::Util qw(dumper);

use Netstack::Utils::Set;

my $set;

ok(
  do {
    eval { $set = Netstack::Utils::Set->new };
    warn $@ if $@;
    $set->isa('Netstack::Utils::Set');
  },
  ' 生成 Netstack::Utils::Set 对象'
);

=lala
    if ( @_ == 0 ) {
        return $class->$orig();
    } elsif ( @_ == 1 and ref($_[0]) eq __PACKAGE__ ) {
        my $setObj = $_[0];
        return $class->$orig( mins => [@{$setObj->mins}], maxs => [@{$setObj->maxs}] );
    } elsif ( @_ == 2 and $_[0] =~ /^\d+$/o and $_[1] =~ /^\d+$/o ) {
        my ($MIN, $MAX) = $_[0] < $_[1] ? ($_[0], $_[1]) : ($_[1], $_[0]);
        return $class->$orig( mins => [$MIN], maxs => [$MAX] );
    } else {
        return $class->$orig(@_);
    }
=cut

ok(
  do {
    my @params = (
      mins => [ 1, 7 ],
      maxs => [ 4, 10 ]
    );
    eval { $set = Netstack::Utils::Set->new(@params) };
    warn $@ if $@;
    $set->isa('Netstack::Utils::Set');
  },
  ' 以 mins => [1,7], maxs => [4,10] 为参数初始化对象成功'
);

ok(
  do {
    my @params = ( 4, 1 );
    eval { $set = Netstack::Utils::Set->new(@params) };
    warn $@ if $@;
    $set->isa('Netstack::Utils::Set')
      and $set->mins->[0] == 1
      and $set->maxs->[0] == 4;
  },
  ' 以 4,1 为参数初始化对象成功'
);

ok(
  do {
    my @params = Netstack::Utils::Set->new(
      mins => [ 1, 7 ],
      maxs => [ 4, 10 ]
    );
    eval { $set = Netstack::Utils::Set->new(@params) };
    warn $@ if $@;
    $set->isa('Netstack::Utils::Set') and $set->isEqual( $params[0] );
  },
  ' 以 Netstack::Utils::Set对象 为参数初始化对象成功'
);

ok(
  do {
    my @params = (
      mins => [ 1, 7 ],
      maxs => [ 4, 10 ]
    );
    eval { $set = Netstack::Utils::Set->new(@params) };
    warn $@ if $@;
    $set->length == 2;
  },
  ' length'
);

ok(
  do {
    my @params = (
      mins => [ 1, 7 ],
      maxs => [ 4, 10 ]
    );
    eval { $set = Netstack::Utils::Set->new(@params) };
    warn $@ if $@;
    $set->min == 1;
  },
  ' min'
);

ok(
  do {
    my @params = (
      mins => [ 1, 7 ],
      maxs => [ 4, 10 ]
    );
    eval { $set = Netstack::Utils::Set->new(@params) };
    warn $@ if $@;
    $set->max == 10;
  },
  ' max'
);

ok(
  do {
    my $aSet;
    eval {
      $aSet = Netstack::Utils::Set->new(
        mins => [ 1, 7 ],
        maxs => [ 4, 10 ]
      );
      $set->mergeToSet($aSet);
    };
    warn $@ if $@;
    $set->isEqual($aSet);
  },
  ' mergeToSet(Netstack::Utils::Set)'
);

ok(
  do {
    eval {
      $set = Netstack::Utils::Set->new( 7, 10 );
      $set->mergeToSet( 2, 4 );
    };
    warn $@ if $@;
    $set->isEqual(
      Netstack::Utils::Set->new(
        mins => [ 2, 7 ],
        maxs => [ 4, 10 ]
      )
    );
  },
  ' mergeToSet(min, max)'
);

ok(
  do {
    eval {
      $set = Netstack::Utils::Set->new( 7, 10 );
      $set->_mergeToSet( 2, 4 );
    };
    warn $@ if $@;
    $set->isEqual(
      Netstack::Utils::Set->new(
        mins => [ 2, 7 ],
        maxs => [ 4, 10 ]
      )
    );
  },
  ' _mergeToSet(min, max)'
);

ok(
  do {
    eval {
      $set = Netstack::Utils::Set->new( 7, 10 );
      $set->addToSet( 2, 4 );
    };
    warn $@ if $@;
    $set->isEqual(
      Netstack::Utils::Set->new(
        mins => [ 2, 7 ],
        maxs => [ 4, 10 ]
      )
    );
  },
  ' addToSet(min, max)'
);

ok(
  do {
    eval { $set = Netstack::Utils::Set->new( mins => [ 1, 7 ], maxs => [ 4, 10 ] ); };
    warn $@ if $@;
    $set->isEqual(
      Netstack::Utils::Set->new(
        mins => [ 1, 7 ],
        maxs => [ 4, 10 ]
      )
      )
      and not $set->isEqual(
      Netstack::Utils::Set->new(
        mins => [ 1, 8 ],
        maxs => [ 4, 9 ]
      )
      );
  },
  ' isEqual'
);

ok(
  do {
    eval { $set = Netstack::Utils::Set->new( mins => [ 1, 7 ], maxs => [ 4, 10 ] ); };
    warn $@ if $@;
    $set->isContain(
      Netstack::Utils::Set->new(
        mins => [ 1, 8 ],
        maxs => [ 4, 9 ]
      )
      )
      and $set->isContain(
      Netstack::Utils::Set->new(
        mins => [ 1, 7 ],
        maxs => [ 4, 10 ]
      )
      )
      and not $set->isContain(
      Netstack::Utils::Set->new(
        mins => [ 1, 8 ],
        maxs => [ 4, 11 ]
      )
      );
  },
  ' isContain'
);

ok(
  do {
    eval { $set = Netstack::Utils::Set->new( mins => [ 1, 7 ], maxs => [ 4, 10 ] ); };
    warn $@ if $@;
    $set->_isContain(
      Netstack::Utils::Set->new(
        mins => [ 1, 8 ],
        maxs => [ 4, 9 ]
      )
      )
      and $set->_isContain(
      Netstack::Utils::Set->new(
        mins => [ 1, 7 ],
        maxs => [ 4, 10 ]
      )
      )
      and not $set->_isContain(
      Netstack::Utils::Set->new(
        mins => [ 1, 8 ],
        maxs => [ 4, 11 ]
      )
      );
  },
  ' _isContain'
);

ok(
  do {
    eval { $set = Netstack::Utils::Set->new( mins => [ 1, 7 ], maxs => [ 4, 10 ] ); };
    warn $@ if $@;
    $set->isContainButNotEqual(
      Netstack::Utils::Set->new(
        mins => [ 1, 8 ],
        maxs => [ 4, 9 ]
      )
      )
      and $set->isContain(
      Netstack::Utils::Set->new(
        mins => [ 1, 7 ],
        maxs => [ 4, 10 ]
      )
      )
      and not $set->isContainButNotEqual(
      Netstack::Utils::Set->new(
        mins => [ 1, 7 ],
        maxs => [ 4, 10 ]
      )
      );
  },
  ' isContainButNotEqual'
);

ok(
  do {
    eval { $set = Netstack::Utils::Set->new( mins => [ 1, 8 ], maxs => [ 4, 9 ] ); };
    warn $@ if $@;
    $set->isBelong(
      Netstack::Utils::Set->new(
        mins => [ 1, 7 ],
        maxs => [ 4, 10 ]
      )
      )
      and $set->isBelong(
      Netstack::Utils::Set->new(
        mins => [ 1, 8 ],
        maxs => [ 4, 9 ]
      )
      )
      and not $set->isBelong(
      Netstack::Utils::Set->new(
        mins => [ 1, 9 ],
        maxs => [ 4, 11 ]
      )
      );
  },
  ' isBelong'
);

ok(
  do {
    eval { $set = Netstack::Utils::Set->new( mins => [ 1, 8 ], maxs => [ 4, 9 ] ); };
    warn $@ if $@;
    $set->_isBelong(
      Netstack::Utils::Set->new(
        mins => [ 1, 7 ],
        maxs => [ 4, 10 ]
      )
      )
      and $set->_isBelong(
      Netstack::Utils::Set->new(
        mins => [ 1, 8 ],
        maxs => [ 4, 9 ]
      )
      )
      and not $set->_isBelong(
      Netstack::Utils::Set->new(
        mins => [ 1, 9 ],
        maxs => [ 4, 11 ]
      )
      );
  },
  ' _isBelong'
);

ok(
  do {
    eval { $set = Netstack::Utils::Set->new( mins => [ 1, 8 ], maxs => [ 4, 9 ] ); };
    warn $@ if $@;
    $set->isBelongButNotEqual(
      Netstack::Utils::Set->new(
        mins => [ 1, 7 ],
        maxs => [ 4, 10 ]
      )
      )
      and $set->isBelong(
      Netstack::Utils::Set->new(
        mins => [ 1, 8 ],
        maxs => [ 4, 9 ]
      )
      )
      and not $set->isBelongButNotEqual(
      Netstack::Utils::Set->new(
        mins => [ 1, 8 ],
        maxs => [ 4, 9 ]
      )
      );
  },
  ' isBelongButNotEqual'
);

ok(
  do {
    eval { $set = Netstack::Utils::Set->new( mins => [ 1, 7 ], maxs => [ 4, 10 ] ); };
    warn $@ if $@;
    $set->compare(
      Netstack::Utils::Set->new(
        mins => [ 1, 7 ],
        maxs => [ 4, 10 ]
      )
      ) eq 'equal'
      and $set->compare(
      Netstack::Utils::Set->new(
        mins => [ 1, 8 ],
        maxs => [ 4, 9 ]
      )
      ) eq 'containButNotEqual'
      and $set->compare(
      Netstack::Utils::Set->new(
        mins => [ 1, 7 ],
        maxs => [ 4, 11 ]
      )
      ) eq 'belongButNotEqual'
      and $set->compare(
      Netstack::Utils::Set->new(
        mins => [ 1, 8 ],
        maxs => [ 5, 9 ]
      )
      ) eq 'other';
  },
  ' compare'
);

ok(
  do {
    eval { $set = Netstack::Utils::Set->new( mins => [ 1, 4, 12 ], maxs => [ 2, 10, 15 ] ); };
    warn $@ if $@;
    $set->interSet(
      Netstack::Utils::Set->new(
        mins => [ 3, 9 ],
        maxs => [ 7, 16 ]
      )
    )->compare(
      Netstack::Utils::Set->new(
        mins => [ 4, 9,  12 ],
        maxs => [ 7, 10, 15 ]
      )
    ) eq 'containButNotEqual';
  },
  ' interSet函数比对结果'
);


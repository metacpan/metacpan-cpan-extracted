#!/usr/bin/env perl
use strict;
use Test::Spec;

use rlib;

use SQL::Concat qw(Q WHERE OPT);

describe "eq: ", sub {
  it "Q() eq Q()", sub {
    ok(Q() eq Q());
  };
  it "Q() eq ''", sub {
    ok(Q() eq '');
  };
  it "'' eq Q()", sub {
    ok('' eq Q());
  };
  it "Q() ne undef", sub {
    ok(Q() ne undef);
  };
  it "Q(' ') eq ' '", sub {
    ok(Q(' ') eq ' ');
  };
  it "SQL(' ') ne ''", sub {
    ok(Q(' ') ne '');
  };

  it "Q('') eq Q('')", sub {
    ok(Q('') eq Q(''));
  };

  it "Q('select ?', 1) eq ['select ?', 1]", sub {
    ok(Q('select ?', 1) eq ['select ?', 1]);
  };

  it "Q('select ?', 1) ne ['select ?', 1, 2]", sub {
    ok(Q('select ?', 1) ne ['select ?', 1, 2]);
  };

  it "Q('select ? is null', undef) eq ['select ? is null', undef]", sub {
    local $SIG{__WARN__} = sub {die @_};
    ok(Q('select ? is null', undef) eq ['select ? is null', undef]);
  };

};

describe "concat: ", sub {

  describe "Q()", sub {
    it "should return empty string(identity)", sub {
      my $q = Q();
      is($q, "");
    };
  };
  describe "Q().Q().Q()", sub {
    it "should return empty string(identity)", sub {
      my $q = Q().Q().Q();
      is($q, "");
    };
  };

  describe "Q('select') . 1", sub {
    my $cat = Q("select") . 1;

    it "should return 'select 1'", sub {
      is_deeply([$cat->as_sql_bind]
                , ["select 1"]);
    };
  };

  describe "'select' . Q(1)", sub {
    my $cat = "select" . Q(1);
    it "should return 'select 1'", sub {
      is_deeply([$cat->as_sql_bind]
                , ["select 1"]);
    };
  };

  describe "'select * from user' . WHERE(...) . 'limit 10'", sub {
    my $test = sub {
      my ($minAge) = @_;
      'select * from user' . WHERE(
        OPT("age >= ?", $minAge || undef)
      ) . "limit 10";
    };

    it "should return 'select * from user limit 10' when minAge is undef", sub {
      is_deeply([$test->()->as_sql_bind]
                , ['select * from user limit 10']);
    };

    it "should return 'select * from user WHERE age >= ? limit 10' when minAge is 18", sub {
      is_deeply([$test->(18)->as_sql_bind]
                , ['select * from user WHERE age >= ? limit 10', 18]);
    };

  };
};

describe "bool: ", sub {

  describe "Q()", sub {

    my $cat = Q();

    it "should be falsy", sub {

      is(!!$cat, !!0);
    };
  };

  describe "Q('')", sub {

    my $cat = Q('');

    it "should be falsy", sub {

      is(!!$cat, !!0);
    };
  };

  describe "Q(1)", sub {

    my $cat = Q(1);

    it "should be truthy", sub {

      is(!!$cat, 1);
    };
  };

  describe "Q(0)", sub {

    my $cat = Q(0);

    it "should be truthy!(since it is a nonempty string)", sub {

      is(!!$cat, 1);
    };
  };

};

runtests unless caller;

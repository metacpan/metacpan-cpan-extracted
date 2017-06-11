#!/usr/bin/env perl
use strict;
use Test::Kantan;
use rlib;
use SQL::Concat;

sub catch (&) {my ($code) = @_; local $@; eval {$code->()}; $@}

describe "Constructors of SQL::Concat", sub {

  describe "SQL::Concat->new", sub {

    my %opts = (sep => '|', sql => 'select ?', bind => [3]);

    my $common = sub {
      my ($cat) = @_;
      expect($cat->sep)->to_be('|');
      expect($cat->sql)->to_be('select ?');
      expect($cat->bind)->to_be([3]);
    };

    it "should accept sep, sql, bind options without errors", sub {
      my $cat;
      ok {$cat = SQL::Concat->new(%opts)};
      $common->($cat);
    };

    it "should accept HASH too", sub {
      my $cat;
      ok {$cat = SQL::Concat->new(\%opts)};
      $common->($cat);
    };

    it "should set default value for sep", sub {
      expect(SQL::Concat->new->sep)->to_be(' ');
    };

    it "should raise error for unknown options", sub {
      expect(catch {SQL::Concat->new(foobar => 'baz')})->to_match(qr/foobar/);
    };

    it "should return a list of sql and bind via as_sql_bind", sub {
      my $cat;
      ok {$cat = SQL::Concat->new(\%opts)};
      expect([$cat->as_sql_bind])->to_be(['select ?', 3]);
      expect(scalar $cat->as_sql_bind)->to_be(['select ?', 3]);
    };

    it "should return a pair of sql and bind via sql_bind_pair", sub {
      my $cat;
      ok {$cat = SQL::Concat->new(\%opts)};
      expect([$cat->sql_bind_pair])->to_be(['select ?', [3]]);
      expect(scalar $cat->sql_bind_pair)->to_be(['select ?', [3]]);
    };
  };

  describe "SQL::Concat->concat", sub {
    it "should work as class method too.", sub {
      expect(SQL::Concat->concat(SELECT => '*')->sql)->to_be("SELECT *");
    };
  };

};

describe "concat(ITEMS...)", sub {

  my $SQL = sub {SQL::Concat->concat(@_)};

  describe "empty concat()", sub {
    it "should return empty string as sql", sub {
      expect($SQL->()->sql)->to_be("");
    };
    it "should return empty array as bind", sub {
      expect($SQL->()->bind)->to_be([]);
    };
  };

  describe "string items", sub {
    it "should accept any string as-is and join with ' '", sub {
      expect($SQL->(SELECT => '*,', q{rowid as '#'}
		    , FROM => "(select * from other)")->sql)
	->to_be("SELECT *, rowid as '#' FROM (select * from other)");
    };
  };

  describe "undef items", sub {
    it "should ignore undef without errors", sub {
      expect($SQL->(SELECT => 1, undef, FROM => 2)->sql)->to_be("SELECT 1 FROM 2");
    };
  };

  describe "bind with ARRAY(RAW_SQL, VALS...)", sub {

    it "should save sql and bind variables separately", sub {
      my $s;
      expect(($s = $SQL->(["c = ?", 3]))->sql)->to_be("c = ?");
      expect($s->bind)->to_be([3]);
      expect([$s->as_sql_bind])->to_be(["c = ?", 3]);

      expect(($s = $SQL->(["x = ? and y = ?", 3, 8]))->sql)->to_be("x = ? and y = ?");
      expect($s->bind)->to_be([3, 8]);
      expect([$s->as_sql_bind])->to_be(["x = ? and y = ?", 3, 8]);
    };

    it "should raise error for placeholder mismatch", sub {
      expect(catch {$SQL->(["select ?"])})->to_match(qr/Placeholder mismatch/);
      expect(catch {$SQL->(["select", 3])})->to_match(qr/Placeholder mismatch/);
    };

    it "should raise error for empty array", sub {
      expect(catch {$SQL->([])})->to_match(qr/Undefined/);
    };

    it "should accept 1 element array", sub {
      expect([$SQL->(["SELECT 1"])->as_sql_bind])->to_be(["SELECT 1"]);
    };

  };

  describe "SQL::Concat of SQL::Concat(s)", sub {

    it "should accept SQL::Concat as concat() arguments", sub {
      expect([$SQL->($SQL->())->as_sql_bind])->to_be(['']);
      expect([$SQL->($SQL->(), $SQL->())->as_sql_bind])->to_be([' ']);
      expect([$SQL->($SQL->(), $SQL->($SQL->(), $SQL->()))->as_sql_bind])->to_be(['  ']);

      expect([$SQL->(IN => SQL::Concat->concat_by(', '
						  , ['?', 3]
						  , ['?', 4]
						  , ['?', 5])->paren)
	      ->as_sql_bind])
	->to_be(["IN (?, ?, ?)", 3, 4, 5]);

      expect([$SQL->("SELECT * FROM member WHERE" =>
		     SQL::Concat->concat_by(" AND " =>
					    SQL::Concat->concat_by(" OR " =>
								   ["city = ?", 'tokyo']
								   , ['city = ?', 'osaka']
								 )
					    ->paren
					    , ["age > ?", 20]))
	      ->as_sql_bind])
	->to_be([q{SELECT * FROM member WHERE (city = ? OR city = ?) AND age > ?}, 'tokyo', 'osaka', 20]);


      expect([$SQL->("select * from"
                     => $SQL->("select rowid from t1 left join t2 using" => "(tid)")->paren
		   )
	      ->as_sql_bind])->to_be(["select * from (select rowid from t1 left join t2 using (tid))"]);
    };
  };
};

describe "Subclass of SQL::Concat", sub {
  {
    package
      SCat1;

    use SQL::Concat -as_base
      , [fields => qw/foo/];

    # Extend placeholder syntax.
    sub count_placeholders {
      (my MY $self) = @_;
      unless (defined $self->{sql}) {
        Carp::croak("Undefined SQL Fragment!");
      }

      my @match = $self->{sql} =~ /(\? | :\w+)/gx;
    }
  }

  describe "->concat()", sub {
    it "should allow extending placeholder syntax", sub {
      expect([SCat1->concat(["? = :y", 'x', 'y'])->as_sql_bind])->to_be(["? = :y", 'x', 'y']);
    };
  };
  
};

done_testing;


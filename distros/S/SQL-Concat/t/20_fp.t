#!/usr/bin/env perl
use strict;
use Test::Kantan;
use rlib;
use SQL::Concat qw/SQL PAR OPT CAT CSV PFX/;

sub catch (&) {my ($code) = @_; local $@; eval {$code->()}; $@}

describe "Functional interfaces of SQL::Concat", sub {

  describe "SQL", sub {

    expect(SQL(SELECT => '*', FROM => 'foo')->sql)
      ->to_be("SELECT * FROM foo");
  };

  describe "PAR", sub {
    expect(PAR(SELECT => '*', FROM => 'foo')->sql)
      ->to_be("(SELECT * FROM foo)");
  };

  describe "paren_nl_indent" => sub {
    it "should put paren, newline and indent", sub {
      expect(SQL("foo", SQL("bar")->paren_nl_indent)->sql)->to_be("foo (\n  bar\n)")
    };
  };

  describe "CAT", sub {
    expect(CAT(UNION =>
               SQL(SELECT => '*', FROM => 'x')
               , SQL(SELECT => '*', FROM => 'y')
               , SQL(SELECT => '*', FROM => 'z'))
           ->sql)
      ->to_be("SELECT * FROM x UNION SELECT * FROM y UNION SELECT * FROM z");
    
    expect(CAT("\nINTERSECT\n" =>
               SQL(SELECT => '*', FROM => 'x')
               , SQL(SELECT => '*', FROM => 'y')
               , SQL(SELECT => '*', FROM => 'z'))
           ->sql)
      ->to_be("SELECT * FROM x
INTERSECT
SELECT * FROM y
INTERSECT
SELECT * FROM z");

    describe "CAT empty CAT", sub {
      expect(CAT(AND => 1, CAT(AND => ()))->sql)
	->to_be("1");
    };
  };
  
  describe "CSV", sub {

    expect(SQL(SELECT => CSV(foo => bar =>
                             "datetime(ts) as dt"))
           ->sql)->to_be("SELECT foo, bar, datetime(ts) as dt");
  };

  describe "OPT(RAW_SQL, BINDVAL, \@REST)", sub {

    describe "If BINDVAL is undef,", sub {
      it "should result empty list.", sub {
        expect([OPT("limit ?" => undef)])->to_be([]);
      };
    };

    describe "If BINDVAL is defined,", sub {
      it "should result correct BIND_ARRAY.", sub {
        expect([OPT("limit ?" => 100)->as_sql_bind])->to_be(["limit ?", 100]);
      };
    };

    describe "OPT(_, X, OPT(_, Y, ...)) nesting", sub {

      describe "If both X and Y is defined,", sub {
        it "should result bind_array with X and Y.", sub {
          expect([OPT("limit ?" => 100
                      , OPT("offset ?", 3)
                    )->as_sql_bind])->to_be(["limit ? offset ?", 100, 3]);
        };
      };

      describe "If X is defined but Y is undef,", sub {
        it "should result bind_array only with X.", sub {
          expect([OPT("limit ?" => 100
                      , OPT("offset ?", undef)
                    )->as_sql_bind])->to_be(["limit ?", 100]);

        };
      };

      describe "If X is undef but Y is defined,", sub {
        it "should result empty result! This is intentional (imagine LIMIT x OFFSET y).", sub {
          expect([OPT("limit ?" => undef
                      , OPT("offset ?", 3)
                    )])->to_be([]);
        };

        it "should result empty for SQL()->as_sql_bind too.", sub {
          expect([SQL(OPT("limit ?" => undef
                          , OPT("offset ?", 3)
                        ))->as_sql_bind])->to_be(['']);
        };
      };
    };
  };

  describe "PFX", sub {

    describe "Empty params", sub {
      it "should result empty list.", sub {
        expect([PFX(WHERE => ())])->to_be([]);
      };
    };

    describe "Whitespace only sqls", sub {
      it "should result empty list.", sub {
        expect([PFX(WHERE => " \t\n \t\n"
                    , " ", "\n", "\t"
                  )])->to_be([]);
      };
    };

    describe "Many empty SQL()s", sub {
      it "should result empty list.", sub {
        expect([PFX(WHERE => SQL(), SQL(), SQL())])->to_be([]);
        expect([PFX(WHERE => SQL(" "), SQL("  \n"))])->to_be([]);
        expect([PFX(WHERE => SQL([" "]), SQL(["  \n"]))])->to_be([]);
        expect([PFX(WHERE => SQL(SQL([" "]), SQL(["  \n"])))])->to_be([]);
      };
    };
  };
};

done_testing;


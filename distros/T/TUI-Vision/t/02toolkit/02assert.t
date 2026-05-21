use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  # Force assertions ON
  $ENV{PERL_STRICT} = 1;
  $ENV{PERLX_ASSERT_PP_FILTER} = 1;
  use_ok 'PerlX::Assert::PP', qw( -check );
}

ok( $PerlX::Assert::PP::CHECK, '$CHECK is enabled via "-check"' );
ok( PerlX::Assert::PP::STRICT(), 'STRICT is enabled via %ENV' );
ok( PerlX::Assert::PP::ASSERT_BLOCK(), 'FILTER is enabled via %ENV' );

subtest 'Simple assertion without a name' => sub {
  my $x;
  dies_ok {
    assert { defined $x and !ref $x };
  } 'assert BLOCK dies when condition is false';

  like $@, qr/Assertion failed:/,
    'error message contains "Assertion failed"';
};

subtest 'Assertion with a name (string literal)' => sub {
  my $x;

  dies_ok {
    assert "not a valid string" { defined $x and !ref $x };
  } 'assert NAME BLOCK dies when false';

  like $@, qr/not a valid string/,
    'named assertion shows the given name';
};

subtest 'Assertion with q() as name' => sub {
  my $x;

  dies_ok {
    assert q(name via q) { defined $x and !ref $x };
  } 'assert q(...) BLOCK dies';

  like $@, qr/name via q/,
    'assertion name extracted correctly from q()';
};

subtest 'Successful assertion must not die' => sub {
  lives_ok {
    my $x = "ok";
    assert { defined $x and !ref $x };
  } 'assert BLOCK lives when condition is true';
};

subtest 'Check BLOCK output via message' => sub {
  # (Only in case no explicit name was given)
  my $x;

  dies_ok {
    assert { defined $x };
  } 'BLOCK dies on false condition';

  like $@, qr/defined \$x/,
    'BLOCK output included in message';
};

subtest 'Nested if-block inside assert { ... } - failing assertion' => sub {
  my $x;

  dies_ok {
    assert {
      if ( defined $x ) {
        !ref $x;
      }
      else {
        0;    # overall: false
      }
    };
  } 'nested if-block: assertion should die when inner logic is false';

  like $@, qr/Assertion failed:/,
    'nested if-block: error message prefix is correct';
};

subtest 'Nested if-block inside assert { ... } - passing assertion' => sub {
  lives_ok {
    my $x = "ok";

    assert {
      if ( defined $x ) {
        !ref $x;    # overall: true
      }
      else {
        0;
      }
    };
  } 'nested if-block: assertion should live when inner logic is true';
};

subtest 'Named assertion with nested block: assert "name" { ... }' => sub {
  # Here the filter must rewrite correctly, even with nested braces.
  my $x;

  dies_ok {
    assert "nested named assert" {
      if ( defined $x ) {
        !ref $x;
      }
      else {
        0;
      }
    };
  } 'named nested block: assertion should die';

  like $@, qr/nested named assert/,
    'named nested block: message contains assertion name';
};

subtest 'Nested hashrefs / blocks inside assertion - ensure braces' => sub {
  # inside data structures do not confuse the filter.
  my $href = {
    foo => {
      bar => 1,
    },
  };

  lives_ok {
    assert {
      # nested block + hashref with inner { }
      if ( $href->{foo}{bar} == 1 ) {
        1;
      }
      else {
        0;
      }
    };
  } 'nested hashrefs and blocks: assertion should live';
};

subtest 'Named assertion with nested hashrefs and blocks' => sub {
  my $href = {
    config => {
      enabled => 0,
    },
  };

  dies_ok {
    assert "deeply nested hash assertion" {
      if ( $href->{config} ) {
        $href->{config}{enabled};
      }
      else {
        0;
      }
    };
  } 'named nested hash assertion: should die when enabled == 0';

  like $@, qr/deeply nested hash assertion/,
    'named nested hash assertion: message contains assertion name';
};

subtest 'Multi-line named assertion with nested if - filter stress' => sub {
  my $x;

  dies_ok {
    assert "multiline nested" {
      if ( defined $x ) {
        !ref $x;
      }
      else {
        0;
      }
    };
  } 'multiline named nested assert: filter must still rewrite and die';

  like $@, qr/multiline nested/,
    'multiline named nested assert: message contains name';
};

subtest '"assert" inside a quoted string must NOT be rewritten' => sub {
  my $str = "this contains assert { die 'bad' } but is just a string";

  lives_ok {
    # This assertion should PASS (because $x is defined)
    my $x = 1;
    assert { defined $x };

    # And importantly: nothing inside the string should be executed.
    my $dummy = $str;    # do nothing, just ensure it parses
  } 'assert inside a string must not trigger the filter or die';
};

subtest '"assert" inside a comment must NOT be rewritten or executed' => sub {
  lives_ok {
    my $x = 1;

    # assert { die "BAD" }    <-- must NOT be rewritten or executed
    # The filter must completely ignore this comment.

    assert { defined $x };
  } 'assert inside a comment must be ignored completely';
};

done_testing();

use Test2::V0 -no_srand => 1;
use Test::CChecker;

sub c ($)
{
  my $fh;
  open $fh, '<', "corpus/$_[0].c";
  my $source = do { local $/; <$fh> };
  close $fh;
  $source;
}

subtest 'cc' => sub {

  my $cc;
  
  is(
    intercept { $cc = cc },
    array {
      event Diag => sub { call message => '' };
      event Diag => sub { call message => '' };
      event Diag => sub { call message => '' };
      event Diag => sub { call message => ' ********************************************* ' };
      event Diag => sub { call message => ' * WARNING:                                  * ' };
      event Diag => sub { call message => ' * Test::CChecker has been deprecated!       * ' };
      event Diag => sub { call message => ' * Please use Test::Alien instead.           * ' };
      event Diag => sub { call message => ' ********************************************* ' };
      event Diag => sub { call message => '' };
      event Diag => sub { call message => '' };
      end;
    },
    'annoying diagnostic warning about deprecation',
  );
  
  isa_ok $cc, 'ExtUtils::CChecker';

};

subtest 'compile_run_ok' => sub {

  is(
    intercept { compile_run_ok c 'foo1' },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'compile ok';
      };
      end;
    },
    'run and compile okay',
  );

  is(
    intercept { compile_run_ok c 'foo1', 'my message' },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'my message';
      };
      end;
    },
    'run and compile okay',
  );
  
  is(
    intercept { compile_run_ok c 'badrun' },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'compile ok';
      };
      event Diag => sub {};
      event Diag => sub {};
      event Diag => sub {};
      end;
    },
    'compile ok, run bad',
  );

  is(
    intercept { compile_run_ok c 'badcompile' },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'compile ok';
      };
      event Diag => sub {};
      event Diag => sub {};
      event Diag => sub {};
      end;
    },
    'compile ok, run bad',
  );
  
};

subtest 'compile_ok' => sub {

  is(
    intercept { compile_ok c 'foo1' },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'compile ok';
      };
      end;
    },
    'run and compile okay',
  );

  is(
    intercept { compile_ok c 'foo1', 'my message' },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'my message';
      };
      end;
    },
    'run and compile okay',
  );
  
  is(
    intercept { compile_ok c 'badrun' },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'compile ok';
      };
      end;
    },
    'compile ok, run bad',
  );

  is(
    intercept { compile_ok c 'badcompile' },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'compile ok';
      };
      event Diag => sub {};
      event Diag => sub {};
      event Diag => sub {};
      event Diag => sub {};
      end;
    },
    'compile ok, run bad',
  );
  
};

done_testing;

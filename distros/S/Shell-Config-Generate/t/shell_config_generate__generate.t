use Test2::V0 -no_srand => 1;
use Test2::Mock;
use Shell::Guess;
use Shell::Config::Generate;

subtest 'pass in shell as string' => sub {

  my $shell;

  my $mock = Test2::Mock->new(
    class => 'Shell::Config::Generate',
    override => [
      _generate => sub {
        (undef, $shell) = @_;
      },
    ],
  );

  my $scg = Shell::Config::Generate->new;

  $scg->generate('c');
  is(
    $shell,
    object {
      call ['isa', 'Shell::Guess'] => T();
      call name => 'c';
    },
    'for c shell',
  );

  $scg->generate('power');
  is(
    $shell,
    object {
      call ['isa', 'Shell::Guess'] => T();
      call name => 'power';
    },
    'for power shel',
  );

};

subtest 'pass in shell as object' => sub {

  my $shell;

  my $mock = Test2::Mock->new(
    class => 'Shell::Config::Generate',
    override => [
      _generate => sub {
        (undef, $shell) = @_;
      },
    ],
  );

  my $scg = Shell::Config::Generate->new;

  $scg->generate(Shell::Guess->c_shell);
  is(
    $shell,
    object {
      call ['isa', 'Shell::Guess'] => T();
      call name => 'c';
    },
    'for c shell',
  );

  $scg->generate(Shell::Guess->power_shell);
  is(
    $shell,
    object {
      call ['isa', 'Shell::Guess'] => T();
      call name => 'power';
    },
    'for power shel',
  );

};

done_testing;

use Test2::V0;
use Types::Standard qw( Int );
use Sub::WrapInType qw( wrap_method );

sub add {
    my $class = shift;
    my ($a, $b) = @_;
    $a + $b;
};

sub add_multi {
    my $class = shift;
    my ($a, $b) = @_;
    $a + $b, $a * $b
}

subtest 'single return type' => sub {
    my $typed_code = wrap_method [Int, Int] => Int, \&add;
    is $typed_code->(__PACKAGE__, 2, 3), 5;
    ok $typed_code->is_method;
};

subtest 'multi return types' => sub {
    my $typed_code = wrap_method(
      params => [Int, Int],
      isa    => [Int, Int],
      code   => \&add_multi,
    );
    my @returns = $typed_code->(__PACKAGE__, 2, 3);
    is \@returns, [5, 6];
    ok $typed_code->is_method;
};

subtest 'Use NDEBUG environment variable' => sub {
  my $wrong = wrap_method Int ,=> Int, sub { undef };
  like dies { $wrong->(__PACKAGE__, 1) }, qr/Undef did not pass type constraint "Int"/;

  {
    local $ENV{PERL_NDEBUG} = 1;
    my $wrong = wrap_method Int ,=> Int, sub { undef };
    ok lives { $wrong->() };
  }

  {
    local $ENV{NDEBUG} = 1;
    my $wrong = wrap_method Int ,=> Int, sub { undef };
    ok lives { $wrong->() };
  }
};

done_testing;

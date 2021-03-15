use Test2::V0;
use Types::Standard qw( Int Undef );
use Sub::WrapInType ();

sub twice { $_[0] * 2 }

$SIG{__WARN__} = \&Carp::cluck;

sub twice_method {
  my ($class, $num) = @_;
  $num * 2;
}

subtest 'Pass argments' => sub {
  
  subtest 'Default / named' => sub {
    my $wrong_typed_code = Sub::WrapInType->new(
      params  => Int,
      isa     => Undef,
      code    => \&twice,
    );
    ok !$wrong_typed_code->is_method;
    like(
      dies { $wrong_typed_code->(2) },
      qr/Value "4" did not pass type constraint "Undef"/,
      'Check option is enable on default.',
    );
  };
  
  subtest 'Default / sequenced' => sub {
    my $wrong_typed_code = Sub::WrapInType->new(Int ,=> Undef, \&twice);
    ok !$wrong_typed_code->is_method;
    like(
      dies { $wrong_typed_code->(2) },
      qr/Value "4" did not pass type constraint "Undef"/,
      'Check option is enable on default.',
    );
  };

};

subtest 'Use check option' => sub {
  
  subtest 'Enable' => sub {

    my $wrong_return_type = Sub::WrapInType->new(
      params  => Int,
      isa     => Undef,
      code    => \&twice,
      options => +{ check => 1 },
    );
    like dies { $wrong_return_type->(2) }, qr/Value "4" did not pass type constraint "Undef"/;

    my $wrong_params_type = Sub::WrapInType->new(
      params  => [Int, Int],
      isa     => Undef,
      code    => \&twice,
      options => +{ check => 1 },
    );
    like dies { $wrong_params_type->(2) }, qr/Wrong number of parameters; got 1; expected 2/;

    my $right = Sub::WrapInType->new(
      params  => Int,
      isa     => Int,
      code    => \&twice,
      options => +{ check => 1 },
    );
    ok lives { $right->(2) };

  };

  subtest 'Disable' => sub {

    my $wrong_return_type = Sub::WrapInType->new(
      params  => Int,
      isa     => Undef,
      code    => \&twice,
      options => +{ check => 0 },
    );
    ok lives { $wrong_return_type->(2) };

    my $wrong_params_type = Sub::WrapInType->new(
      params  => [Int, Int],
      isa     => Undef,
      code    => \&twice,
      options => +{ check => 0 },
    );
    ok lives { $wrong_params_type->(2) };

    my $right = Sub::WrapInType->new(
      params  => Int,
      isa     => Int,
      code    => \&twice,
      options => +{ check => 0 },
    );
    ok lives { $right->(2) };

  };

};

subtest 'Use skip_invocant option' => sub {

  subtest 'Enable' => sub {
    my $typed_code = Sub::WrapInType->new(
      params  => Int,
      isa     => Int,
      code    => \&twice_method,
      options => +{ skip_invocant => 1 },
    );
    ok $typed_code->is_method;
    ok lives { $typed_code->('SomeClass', 2) };
    like dies { $typed_code->(2) }, qr/Wrong number of parameters; got 0; expected 1/;
  };

  subtest 'Disable' => sub {
    my $typed_code = Sub::WrapInType->new(
      params  => Int,
      isa     => Int,
      code    => \&twice_method,
      options => +{ skip_invocant => 0 },
    );
    ok !$typed_code->is_method;
    like dies { $typed_code->('SomeClass', 2) }, qr/Wrong number of parameters; got 2; expected 1/;
    like warning { $typed_code->(2) }, qr/Use of uninitialized value/;
  };

};

done_testing;

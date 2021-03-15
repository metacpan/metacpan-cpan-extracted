use 5.010001;
use strict;
use warnings;
use Test2::V0;
use Types::Standard qw( Int Undef );
use Sub::WrapInType qw( wrap_sub );

subtest 'Create typed anonymous subroutine' => sub {

  ok lives {
    wrap_sub Int ,=> Int, sub {
      my $x = shift;
      $x ** 2;
    };
  };
  
  ok lives {
    wrap_sub [ Int, Int ] => Int, sub {
      my ($x, $y) = @_;
      $x + $y;
    };
  };

  ok lives {
    wrap_sub +{ x => Int, y => Int } => Int, sub {
      my ($x, $y) = @{ shift() }{qw( x y )};
      $x + $y;
    };
  };

  ok lives {
    wrap_sub [ Int, Int ] => [ Int, Int ], sub {
      my ($x, $y) = @_;
      $x, $y;
    };
  };
  
  ok lives {
    wrap_sub(
      params => [ Int, Int ],
      isa    => Int,
      code   => sub {
        my ($x, $y) = @_;
        $x + $y;
      },
    );
  };

  ok lives {
    wrap_sub(
      params => +{
        x => Int,
        y => Int,
      },
      isa    => Int,
      code   => sub {
        my ($x, $y) = @{ shift() }{qw( x y )};
        $x + $y;
      },
    );
  };

  ok lives {
    wrap_sub({
      params => Int,
      isa    => Int,
      code   => sub { }
    });
  }, 'hashref arguments';

  ok dies { wrap_sub }, 'Too few arguments.';

  ok dies { wrap_sub \(my $wrap_sub) => Int, sub {} };

  ok dies { wrap_sub [ 'Int', 'Int' ] => 'Int', sub {} }, 'Arguments is not typeconstraint object.';
  
  ok dies {
    wrap_sub(
      params => [ Int, Int ],
      return => Int,
      code   => sub {
        my ($x, $y) = @_;
        $x + $y;
      },
    );
  }, 'Wrong key.';

  ok dies {
    wrap_sub([
      Int,
      Int,
      sub { }
    ]);
  }, 'arrayref arguments';
  
};

subtest 'Run typed anonymous subroutine' => sub {

  my $pow = wrap_sub Int ,=> Int, sub {
    my $x = shift;
    $x ** 2;
  };
  is $pow->(2), 4;

  my $sum = wrap_sub [ Int, Int ] => Int, sub {
    my ($x, $y) = @_;
    $x + $y;
  };
  is $sum->(2, 5), 7;

  my $sub = wrap_sub +{ x => Int, y => Int } => Int, sub {
    my ($x, $y) = @{ shift() }{qw( x y )};
    $x - $y;
  };
  is $sub->(x => 10, y => 5), 5;

  my $multi_return_values = wrap_sub [ Int, Int ] => [ Int, Int ], sub {
    my ($x, $y) = @_;
    $x, $y;
  };
  is [ $multi_return_values->(2, 4) ], [2, 4], 'Multiple return values.';

  my $wrong = wrap_sub Int ,=> Int, sub { undef };
  like dies { $wrong->(1) }, qr/Undef did not pass type constraint "Int"/;

  {
    local $ENV{PERL_NDEBUG} = 1;
    my $wrong = wrap_sub Int ,=> Int, sub { undef };
    ok lives { $wrong->() };
  }

  {
    local $ENV{NDEBUG} = 1;
    my $wrong = wrap_sub Int ,=> Int, sub { undef };
    ok lives { $wrong->() };
  }

};

subtest 'Confirm get_info' => sub {
  
  my $orig_info = +{
    params => [ Int, Int ],
    isa    => Int,
    code   => sub {
      my ($x, $y) = @_;
      $x + $y;
    },
  };
  my $typed_code = wrap_sub @$orig_info{qw( params isa code )};

  ok object {
    prop blessed => 'Sub::WrapInType';
    call params    => $orig_info->{params};
    call returns   => $orig_info->{returns};
    call code      => $orig_info->{code};
    call is_method => F;
  };

};

done_testing;

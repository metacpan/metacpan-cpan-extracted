use strict;
use warnings;

use Test::Tester 0.08;
use Test::More;

use Test::Deep qw( cmp_deeply superhashof re all );
use Test::Deep::Filter qw( filter );

our $TODO;

can_ok( 'main', qw( filter cmp_deeply ) );

subtest "Split-filter" => sub {
  my ( $premature, @results ) = run_tests(
    sub {
      cmp_deeply(
        "Hello World",
        filter( sub { [ split /\s+/, $_ ] }, [qw( Hello World )] ),
        "Comparing a word by its split tokens"
      );
    },
  );
  cmp_deeply(
    \@results,
    [
      superhashof(
        {
          diag      => '',
          ok        => 1,
          actual_ok => 1,
        }
      )
    ],
    "Split tokens is OK"
  ) or note explain $premature, \@results;
};
done_testing;

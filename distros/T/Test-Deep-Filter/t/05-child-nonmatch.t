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
      cmp_deeply( "Hello World", filter( sub { [ split /\s+/, $_ ] }, [qw( Foo Bar )] ), "Comparing a word by its split tokens" );
    },
  );
  cmp_deeply(
    \@results,
    [
      superhashof(
        {
          diag      => re(qr/expect\s*:\s*'Foo'/),
          ok        => 0,
          actual_ok => 0,
        }
      )
    ],
    "Split tokens is OK"
  ) or note explain $premature, \@results;
};
done_testing;

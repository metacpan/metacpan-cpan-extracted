use strict;
use warnings;

use Test::Tester 0.08;
use Test::More;

use Test::Deep qw( cmp_deeply superhashof re all );
use Test::Deep::Filter qw( filter );

our $TODO;

can_ok( 'main', qw( filter cmp_deeply ) );

my $passthrough = [
  { name => 'String',   value => "Hello" },
  { name => 'ArrayRef', value => [ 1, 2, 3 ] },
  { name => 'HashRef', value => { key => 'value' } },
];

for my $pass ( @{$passthrough} ) {
  my (%properties) = %{$pass};

  subtest "Passthrough $properties{name} filter" => sub {
    my ( $premature, @results ) = run_tests(
      sub {
        cmp_deeply( $properties{value}, filter( sub { $_ }, $properties{value} ), "Passthrough comparsion test" );
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
      "Passthrough $properties{name} is OK"
    ) or note explain $premature, \@results;
  };
}
done_testing;

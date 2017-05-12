use Test::More tests => 4;
BEGIN { use_ok('POE::Filter::CSV_XS') };

my $test = '"This is just a test",line,"so there"';

my $filter = POE::Filter::CSV_XS->new();

ok( defined $filter, 'Create Filter');

my $results = $filter->get( [ $test ] );

foreach my $result ( @$results ) {
  ok( ( $result->[0] eq 'This is just a test' and $result->[1] eq 'line' and $result->[2] eq 'so there' ) , 'Test Get' );
}

my $answer = $filter->put( $results );

foreach my $line ( @$answer ) {
  ok( $line eq $test, 'Test put' ) or diag("$line");
}


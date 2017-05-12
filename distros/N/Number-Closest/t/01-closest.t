#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Number::Closest' );
}

diag( "Testing Number::Closest $Number::Closest::VERSION, Perl $], $^X" );

my @num  = qw/1 7 4.5 88 2 55/ ;

my $num = 14;

my $closest = Number::Closest->new(number => $num, numbers => \@num, amount => 2) ;

use Data::Dumper;


my $analysis = [
          [
            7,
            7
          ],
          [
            '4.5',
            '9.5'
          ],
          [
            2,
            12
          ],
          [
            1,
            13
          ],
          [
            55,
            41
          ],
          [
            88,
            74
          ]
        ];


is_deeply($closest->analyze, $analysis, 'closest analysis') ;

is_deeply($closest->find(2), [7, 4.5], 'closest find') ;


is($closest->find(1), 7, 'closest single');

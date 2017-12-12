use strict;
use warnings;

use Test::More;
use Perl::Critic::TestUtils qw(pcritique);

my @switch_keywords = qw( given when default CORE::given CORE::when CORE::default );

my $test_set = {
    'in single quotes' => [ map qq{ '$_' }, @switch_keywords ],
    'in double quotes' => [ map qq{ "$_" }, @switch_keywords ],
    'unquoted'         => [ map qq{ $_ },   @switch_keywords ],
};

my $code;

foreach my $test_case ( keys %{$test_set} ) {
    my $code = 'my %foo = ( ';
    $code .= " $_ => 1, " foreach @{ $test_set->{$test_case} };
    $code .= ');';

    is( pcritique( 'ControlStructures::ProhibitSwitchStatements', \$code, ), 0 );

}

done_testing;

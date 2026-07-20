#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/07.pattern_selection.t
##----------------------------------------------------------------------------
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use PersonName::Format::Pattern;
    use PersonName::Format::SimpleName;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

my $name = PersonName::Format::SimpleName->new(
    given   => 'Jacques',
    surname => 'Deguest',
);

my $selector = PersonName::Format::Pattern->new( '{given}' );
my $best = $selector->select_best(
    [
        '{title} {given} {given2} {surname}, {credentials}',
        '{given} {surname}',
        '{given}',
    ],
    $name,
);

isa_ok( $best, 'PersonName::Format::Pattern' );
is( $best->pattern, '{given} {surname}', 'Best pattern maximises populated fields then minimises empty fields' );

$best = $selector->select_best(
    [ '{surname} {given}', '{given} {surname}' ],
    $name,
);
is( $best->pattern, '{given} {surname}', 'Alphabetically least pattern wins the final tie' );

done_testing();

__END__

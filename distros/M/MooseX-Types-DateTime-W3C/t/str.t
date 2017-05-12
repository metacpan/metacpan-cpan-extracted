
use strict;
use warnings;

use Test::More tests => 30;
use Test::Exception;

{

    package Test::MooseX::Types::DateTime::W3C;
    use Moose;
    use MooseX::Types::DateTime::W3C qw( DateTimeW3C );

    has 'dt' => (
        is => 'rw',
        isa => DateTimeW3C,
    );
}

my $o;

lives_ok {
    $o = Test::MooseX::Types::DateTime::W3C->new();
} 'test object created';


my @tests = (
    'YYYY' => '1997',
    'YYYY-MM' => '1997-07',
    'YYYY-MM-DD' => '1997-07-16',
    'YYYY-MM-DDThh:mmTZD' => [qw(
        1997-07-16T19:20Z
        1997-07-16T19:20+01:30
        1997-07-16T19:20-01:45
    )],
    'YYYY-MM-DDThh:mm:ssTZD' => [qw(
        1997-07-16T19:20:30Z
        1997-07-16T19:20:30+01:30
        1997-07-16T19:20:30-01:45
    )],
    'YYYY-MM-DDThh:mm:ss.sTZD' => [qw(
        1997-07-16T19:20:30.45Z
        1997-07-16T19:20:30.45+01:30
        1997-07-16T19:20:30.45-01:45
    )],
);
for (my $i = 0; $i < @tests; $i += 2 ) {
    my ($format, $values) = @tests[ $i, $i+1 ];

    my @vals = ref $values ? @$values : $values;
    for my $val ( @vals ) {
        lives_ok {
            $o->dt( $val );
        } "format accepted: $format";
        is $o->dt, $val, "...with value: $val";
    }
}


my @invalid = (
    'YYYYMMDD' => '19970716',
    'YYYY-Www' => '1997-W29',
    'YYYY-Www-D' => '1997-W29-3',
    'YYYY-DDD' => '1997-197',
    'YYYY-MM-DDThh:mm:ss+/-hhmm' => '1997-07-16T19:20:30+0130',
);
for (my $i = 0; $i < @invalid; $i += 2 ) {
    my ($format, $val) = @invalid[ $i, $i+1 ];

    dies_ok {
        $o->dt( $val );
    } "format not accepted: $format, with value $val";
}



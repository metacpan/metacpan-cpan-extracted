package Testify;
use v5.20;

use Test::More;

use Time::HiRes qw( usleep );
use Object::Exercise qw( benchmark );

SKIP:
{
    skip 'RUN_LARGE_TEST not set', 1
    unless $ENV{ RUN_LARGE_TEST };

    my @testz
    = map
    {
        my $i   = int rand 200;
        [
            [ snooze => $i ],
            [ $i ],
        ]
    }
    ( 1 .. 16_385 );

    $exercise->( __PACKAGE__->new, @testz );
}

done_testing
unless $ENV{ RUN_LARGE_TEST };

sub new
{
    my $proto = shift;

    bless {}, ref $proto || $proto
}

sub snooze
{
    my ( undef, $sleep ) = @_;

    usleep $sleep;

    $sleep
}

__END__

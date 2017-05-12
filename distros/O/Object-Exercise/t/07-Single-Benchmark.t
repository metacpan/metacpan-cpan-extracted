package Testify;
use v5.20;

use Test::More;

use Time::HiRes qw( usleep );

use Object::Exercise    qw( nobenchmark );

my @testz
= map
{
    my $i   = int rand 200;
    [
        [ snooze => $i ],
        [ $i ],
    ]
}
( 1 .. 8 );

# benchmark half of the tests.

splice @testz, 3, 0, 'benchmark';

eval '__PACKAGE__->new->$exercise( @testz )';

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

0
__END__

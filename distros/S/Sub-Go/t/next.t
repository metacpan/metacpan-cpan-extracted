use strict;
use warnings;

use Test::More;
use Sub::Go;

{
    package TestGoNext;
    sub new { 
        my @arr = qw/100 200 300/;
        return bless { ix=>0, arr=>\@arr }, 'TestGoNext'; 
    }
    sub next {
        my $self = shift;
        return $self->{arr}->[ $self->{ix}++ ]; 
    }
}
{
    my @out;
    my @out2;

    my $obj = TestGoNext->new;
    $obj ~~ go {
        push @out2, shift; 
        $_;
    } \@out;
    is( join(',',@out), '100,200,300', 'next iter' );
    is( join(',',@out2), '100,200,300', 'next iter shift' );
}

done_testing;

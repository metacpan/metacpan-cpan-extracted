package TaskPipe::Task_SeparateArray;

use Moose;
extends 'TaskPipe::Task';
use Data::Dumper;


has test_pinterp => (is => 'ro', isa => 'ArrayRef[HashRef]', default => sub{[{
    
    unimportant => 'data',
    array => [{
        one => 'result 1-1',
        two => 'result 1-2',
        three => 'result 1-3'
    }, {
        one => 'result 2-1',
        two => 'result 2-2',
        three => 'result 2-3'
    }]

}]});
    

sub action{
    my ($self) = @_;

    confess "Need an 'array' parameter" unless $self->pinterp->{array};
    my $array_ref;

    if ( ref $self->pinterp->{array} eq ref [] ){

        $array_ref = $self->pinterp->{array};

    } elsif( ref $self->pinterp->{array} eq ref '' ) {

        my @vals;
        eval '@vals = ('.$self->pinterp->{array}.');';
        $array_ref = [];
        foreach my $val (@vals){
            push @$array_ref, +{ li => $val };
        }

    } else {

        confess "unrecognised type for 'array' parameter. Expected string or arrayref but got ".ref($self->pinterp->{array});

    }

    if ( @$array_ref ){
        confess "value specified in 'array' should be an array of hashrefs" unless ref($array_ref->[0]) eq ref {};
    }

    return $array_ref;

}

1;

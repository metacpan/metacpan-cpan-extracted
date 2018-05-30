package TaskPipe::Iterator_Array;

use Moose;
extends 'TaskPipe::Iterator';
with 'MooseX::ConfigCascade';

has array => (is => 'rw', isa => 'ArrayRef', required => 1);
has array_pointer => (is => 'rw', isa => 'Int', default => 0);

has 'next' => (is => 'rw', isa => 'CodeRef', lazy => 1, default => sub{
    my ($self) = @_;
    return sub{
        my $result;
        if ( $self->array_pointer > $#{$self->array} ){
            $result = undef;
        } else {
            $result = $self->array->[ $self->array_pointer ];
            $self->array_pointer( $self->array_pointer + 1 );
        }
        return $result;
    }
});


has 'reset' => (is => 'rw', isa => 'CodeRef', lazy => 1, default => sub{
    my ($self) = @_;
    return sub{
        my ($index) = @_;
        $self->array_pointer( $index );
    };
});


has 'count' => (is => 'rw', isa => 'CodeRef', lazy => 1, default => sub{
    my ($self) = @_;
    return sub{
        return +scalar @{$self->array};
    };
});



1;

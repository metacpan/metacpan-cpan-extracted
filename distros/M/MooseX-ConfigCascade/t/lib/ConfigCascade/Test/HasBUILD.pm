package ConfigCascade::Test::HasBUILD;

use Moose;
with 'MooseX::ConfigCascade';

has string_att => (is => 'rw', isa => 'Str');
has hash_att => (is => 'rw', isa => 'HashRef');
has array_att => (is => 'ro', isa => 'ArrayRef', default => sub{[ 'array_att package value' ]});
has num_att => (is => 'rw', isa => 'Num');


sub BUILD{
    my $self = shift;

    $self->string_att( 'string_att package value from BUILD' );
    $self->hash_att( { 'hash_att package key from BUILD' => 'hash_att package value from BUILD' } );

}

after BUILD => sub{
    my $self = shift;
    $self->num_att( 74.9 );
};

1;

package Monorail::Change::RunPerl;
$Monorail::Change::RunPerl::VERSION = '0.4';
use Moose;

with 'Monorail::Role::Change';

has function => (
    isa      => 'CodeRef',
    is       => 'ro',
    required => 1,
);

sub as_hashref_keys {
    return qw/function/
}

sub transform_schema {
    return;
}

sub transform_database {
    my ($self, $dbix) = @_;

    return $self->function->($dbix);
}

__PACKAGE__->meta->make_immutable;

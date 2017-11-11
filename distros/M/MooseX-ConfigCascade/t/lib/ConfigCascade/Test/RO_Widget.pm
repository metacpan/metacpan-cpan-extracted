package ConfigCascade::Test::RO_Widget;

use Moose;
with 'MooseX::ConfigCascade';

#strings
has str_no_default => (is => 'ro', isa => 'Str');
has str_has_default => (is => 'ro', isa => 'Str', default => 'str_has_default from package value');
has str_has_builder => (is => 'ro', isa => 'Str', builder => '_build_str');
has str_lazy => (is => 'ro', isa => 'Str', default => 'str_lazy from package value', lazy => 1);

# HashRefs
has hash_no_default => (is => 'ro', isa => 'HashRef');
has hash_has_default => (is => 'ro', isa => 'HashRef', default => sub{{ 
    'hash_has_default from package key' => 'hash_has_default from package value'
}});
has hash_has_builder => (is => 'ro', isa => 'HashRef', builder => '_build_hash');
has hash_lazy => (is => 'ro', isa => 'HashRef', default => sub{{
    'hash_lazy from package key' => 'hash_lazy from package value'
}}, lazy => 1);

# ArrayRefs
has array_no_default => (is => 'ro', isa => 'ArrayRef');
has array_has_default => (is => 'ro', isa => 'ArrayRef', default => sub{[
    'array_has_default from package value'
]});
has array_has_builder => (is => 'ro', isa => 'ArrayRef', builder => '_build_array');
has array_lazy => (is => 'ro', isa => 'ArrayRef', default => sub{[
    "array_lazy from package value",
]}, lazy => 1);

# Bools
has bool_no_default => (is => 'ro', isa => 'Bool');
has bool_has_default => (is => 'ro', isa => 'Bool', default => 0);
has bool_has_builder => (is => 'ro', isa => 'Bool', builder => '_build_bool');
has bool_lazy => (is => 'ro', isa => 'Bool', default => 0, lazy => 1);


# Numbers
has num_no_default => (is => 'ro', isa => 'Num');
has num_has_default => (is => 'ro', isa => 'Num', default => 2.2);
has num_has_builder => (is => 'ro', isa => 'Num', builder => '_build_num');
has num_lazy => (is => 'ro', isa => 'Num', default => 4.4, lazy => 1);


# Ints
has int_no_default => (is => 'ro', isa => 'Int');
has int_has_default => (is => 'ro', isa => 'Num', default => 22, lazy => 1);
has int_has_builder => (is => 'ro', isa => 'Int', builder => '_build_int');
has int_lazy => (is => 'ro', isa => 'Int', default => 44, lazy => 1);


#Builders
sub _build_str{
    return 'str_has_builder from package value';
}


sub _build_hash{
    return {
        'hash_has_builder from package key' => 'hash_has_builder from package value'
    };
}


sub _build_array{
    return [
        'array_has_builder from package value'
    ];
}


sub _build_bool{
    return 0;
}


sub _build_num{
    return 3.3;
}


sub _build_int{
    return 33;
}



1;


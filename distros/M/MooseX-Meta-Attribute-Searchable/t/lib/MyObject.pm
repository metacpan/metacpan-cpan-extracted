package # Hide from CPAN
    MyObject;
use Moose;

with qw(MooseX::Storage::Deferred MooseX::Role::Searchable);

has 'name' => (
    is => 'rw',
    isa => 'Str',
    traits => [ qw(MooseX::Meta::Attribute::Searchable) ],
    search_field_names => [ qw(name name_ngram) ],
);

has 'fieldless_name' => (
    is => 'rw',
    isa => 'Str',
    traits => [ qw(MooseX::Meta::Attribute::Searchable) ],
);

1;
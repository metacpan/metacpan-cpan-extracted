package Example::Schema::Result;
use parent 'DBIx::Class::Core';
use UUID::Tiny ':std';

__PACKAGE__->load_components(qw/
    DynamicDefault
    TimeStamp
    InflateColumn::DateTime
/);

sub insert {
    my $self = shift;
    for my $column ($self->primary_columns) {
        $self->store_column($column, create_uuid_as_string())
          unless defined $self->get_column($column);
    }
    $self->next::method(@_);
}

1;


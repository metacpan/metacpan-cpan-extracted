package Monorail::Change::CreateTable;
$Monorail::Change::CreateTable::VERSION = '0.4';
use Moose;
use Monorail::Change::AddField;
use SQL::Translator::Schema;
use SQL::Translator::Schema::Table;
use SQL::Translator::Schema::Constraint;

with 'Monorail::Role::Change::StandardSQL';

has name   => (is => 'ro', isa => 'Str',                required => 1);
has fields => (is => 'ro', isa => 'ArrayRef[HashRef]',  required => 1);

__PACKAGE__->meta->make_immutable;

sub as_hashref_keys {
    return qw/name fields/;
}

sub as_sql {
    my ($self) = @_;

    my $table = $self->as_sql_translator_table;

    my ($create, $fks) = $self->producer->create_table($table);

    $fks ||= [];

    return ($create, @$fks);
}

sub as_sql_translator_table {
    my ($self) = @_;

    my $table = SQL::Translator::Schema::Table->new(name => $self->name);
    foreach my $field (@{$self->fields}) {
        local $field->{table} = $self->name;
        my $change = Monorail::Change::AddField->new($field);
        $table->add_field($change->as_sql_translator_field);

        if ($change->is_primary_key) {
            $table->add_constraint(
                fields => [$change->name],
                type   => 'primary_key',
            );
        }
        elsif ($change->is_unique) {
            $table->add_constraint(
                fields => [$change->name],
                type   => 'unique',
            );
        }

    }

    return $table;
}

sub transform_schema {
    my ($self, $schema) = @_;

    $schema->add_table($self->as_sql_translator_table);
}

1;

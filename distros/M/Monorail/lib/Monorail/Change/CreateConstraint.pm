package Monorail::Change::CreateConstraint;
$Monorail::Change::CreateConstraint::VERSION = '0.4';
use Moose;
use SQL::Translator::Schema::Constraint;

with 'Monorail::Role::Change::StandardSQL';

=head1 SYNOPSIS

    my $add_const = Monorail::Change::CreateConstrant->new(
        table       => 'train',
        name        => 'uniq_train_name_idx',
        type        => 'unique',
        field_names => [qw/name/],
    );

    print $add_const->as_perl;

    $add_const->as_sql;

    $add_const->transform_dbix($dbix)

=cut


has table            => (is => 'ro', isa => 'Str',           required => 1);
has name             => (is => 'ro', isa => 'Str',           required => 1);
has type             => (is => 'ro', isa => 'Str',           required => 1);
has field_names      => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
has on_delete        => (is => 'ro', isa => 'Str',           required => 0);
has on_update        => (is => 'ro', isa => 'Str',           required => 0);
has match_type       => (is => 'ro', isa => 'Str',           required => 0);
has deferrable       => (is => 'ro', isa => 'Bool',          required => 0);
has reference_table  => (is => 'ro', isa => 'Str',           required => 0);
has reference_fields => (is => 'ro', isa => 'ArrayRef[Str]', required => 0);

__PACKAGE__->meta->make_immutable;


sub as_sql {
    my ($self) = @_;

    my $field = $self->as_sql_translator_constraint;

    return $self->producer->alter_create_constraint($field);
}

sub as_sql_translator_constraint {
    my ($self) = @_;

    my $table = $self->schema_table_object;

    return SQL::Translator::Schema::Constraint->new(
        table            => $table,
        name             => $self->name,
        type             => $self->type,
        field_names      => $self->field_names,
        on_delete        => $self->on_delete,
        on_update        => $self->on_update,
        match_type       => $self->match_type,
        deferrable       => $self->deferrable,
        reference_table  => $self->reference_table,
        reference_fields => $self->reference_fields,
    );
}

sub transform_schema {
    my ($self, $schema) = @_;

    $schema->get_table($self->table)->add_constraint($self->as_sql_translator_constraint);
}

sub as_hashref_keys {
    return qw/
        name table type field_names on_delete on_update match_type deferrable
        reference_table reference_fields
    /;
}

1;
__END__

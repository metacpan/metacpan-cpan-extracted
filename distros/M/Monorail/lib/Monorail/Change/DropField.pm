package Monorail::Change::DropField;
$Monorail::Change::DropField::VERSION = '0.4';
use Moose;
use SQL::Translator::Schema::Field;

with 'Monorail::Role::Change::StandardSQL';

=head1 SYNOPSIS

    my $add_field = Monorail::Change::DropField->new(
        table => $fld->table->name,
        name  => $fld->name,
    );

    print $add_field->as_perl;

    $add_field->as_sql;

    $add_field->transform_dbix($dbix)

=cut


has table          => (is => 'ro', isa => 'Str',  required => 1);
has name           => (is => 'ro', isa => 'Str',  required => 1);

__PACKAGE__->meta->make_immutable;


sub as_sql {
    my ($self) = @_;

    my $field = $self->as_sql_translator_field;

    return $self->producer->drop_field($field);
}

sub as_sql_translator_field {
    my ($self) = @_;

    my $table = $self->schema_table_object;

    return SQL::Translator::Schema::Field->new(
        table          => $table,
        name           => $self->name,
    );
}

sub transform_schema {
    my ($self, $schema) = @_;

    $schema->get_table($self->table)->drop_field($self->name);
}


sub as_hashref_keys {
    return qw/name table/;
}


1;
__END__

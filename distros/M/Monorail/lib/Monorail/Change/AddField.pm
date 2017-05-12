package Monorail::Change::AddField;
$Monorail::Change::AddField::VERSION = '0.4';
use Moose;
use SQL::Translator::Schema::Field;
use List::Util qw(max);

with 'Monorail::Role::Change::StandardSQL';

=head1 SYNOPSIS

    my $add_field = Monorail::Change::AddField->new(
        table => $fld->table->name,
        name  => $fld->name,
        type  => $fld->data_type,
        is_nullable => $fld->is_nullable,
        is_primary_key => $fld->is_primary_key,
        is_unique      => $fld->is_uniq,
        default_value  => $fld->default_value,
    );

    print $add_field->as_perl;

    $add_field->as_sql;

    $add_field->transform_dbix($dbix)

=cut


has table          => (is => 'ro', isa => 'Str',      required => 1);
has name           => (is => 'ro', isa => 'Str',      required => 1);
has type           => (is => 'ro', isa => 'Str',      required => 1);
has is_nullable    => (is => 'ro', isa => 'Bool',     required => 1, default => 1);
has is_primary_key => (is => 'ro', isa => 'Bool',     required => 1, default => 0);
has is_unique      => (is => 'ro', isa => 'Bool',     required => 1, default => 0);
has default_value  => (is => 'ro', isa => 'Any',      required => 0);
has size           => (is => 'ro', isa => 'ArrayRef', required => 0);

__PACKAGE__->meta->make_immutable;


sub as_sql {
    my ($self) = @_;

    my $field = $self->as_sql_translator_field;

    return $self->producer->add_field($field);
}

sub as_sql_translator_field {
    my ($self) = @_;

    my $table = $self->schema_table_object;

    return SQL::Translator::Schema::Field->new(
        table          => $table,
        name           => $self->name,
        data_type      => $self->type,
        is_nullable    => $self->is_nullable,
        is_primary_key => $self->is_primary_key,
        is_unique      => $self->is_unique,
        default_value  => $self->default_value,
        size           => $self->size,
    );
}

sub transform_schema {
    my ($self, $schema) = @_;

    my $table = $schema->get_table($self->table);

    # set the order ourselves to avoid fragility in SQL::Translator's auto-order
    # stuff.  Turns out we don't really care about order.

    my $max = max map { $_->order } $table->get_fields;
    $max ||= 0;
    
    my $field = $self->as_sql_translator_field;
    $field->order($max + 1);
    $table->add_field($field);
}

sub as_hashref_keys {
    return qw/name table is_nullable type is_primary_key is_nullable is_unique default_value size/;
}

1;
__END__

package Monorail::Change::AlterField;
$Monorail::Change::AlterField::VERSION = '0.4';
use Moose;
use SQL::Translator::Schema::Field;
use List::Compare;

with 'Monorail::Role::Change::StandardSQL';

=head1 SYNOPSIS

    my $change = Monorail::Change::AlterField->new(
        table => $from->table->name,
        from  => {
            name           => $from->name,
            type           => $from->data_type,
            is_nullable    => $from->is_nullable,
            is_primary_key => $from->is_primary_key,
            is_unique      => $from->is_unique,
            default_value  => $from->default_value,
            size           => $from->size,
        },
        to => {
            name           => $to->name,
            type           => $to->data_type,
            is_nullable    => $to->is_nullable,
            is_primary_key => $to->is_primary_key,
            is_unique      => $to->is_unique,
            default_value  => $to->default_value,
            size           => $to->size,
        }
    );

    if ($change->has_changes) {
        return $change->as_perl
    }
    else {
        return;
    }

=cut


has table => (is => 'ro', isa => 'Str',     required => 1);
has from  => (is => 'ro', isa => 'HashRef', required => 1);
has to    => (is => 'ro', isa => 'HashRef', required => 1);


__PACKAGE__->meta->make_immutable;


sub has_changes {
    my ($self) = @_;

    if ($self->from->{name} ne $self->to->{name}) {
        return 1;
    }

    if ($self->from->{is_nullable} != $self->to->{is_nullable}) {
        return 1;
    }

    if ($self->from->{type} ne $self->to->{type}) {
        return 1;
    }

    if ($self->from->{is_primary_key} != $self->to->{is_primary_key}) {
        return 1;
    }

    if ($self->from->{is_unique} != $self->to->{is_unique}) {
        return 1;
    }

    if (List::Compare->new($self->from->{size}, $self->to->{size})->get_symmetric_difference) {
        return 1;
    }

    my $old_default = defined $self->from->{default_value} ? $self->from->{default_value} : '_MAGIC_MONORAIL_NULL_STRING';
    my $new_default = defined $self->to->{default_value}   ? $self->to->{default_value}   : '_MAGIC_MONORAIL_NULL_STRING';

    if ($old_default ne $new_default) {
        return 1;
    }

    return;
}

sub as_sql {
    my ($self) = @_;

    return unless $self->has_changes;

    return $self->producer->alter_field(
        $self->from_as_sql_translator_field,
        $self->to_as_sql_translator_field,
    );
}


sub transform_schema {
    my ($self, $schema) = @_;

    return unless $self->has_changes;

    my $table = $schema->get_table($self->table);

    $table->drop_field($self->from->{name});
    $table->add_field($self->to_as_sql_translator_field);
}

sub as_hashref_keys {
    return qw/table from to/;
}


sub from_as_sql_translator_field {
    my ($self) = @_;

    my $table = $self->schema_table_object;

    return SQL::Translator::Schema::Field->new(
        table          => $table,
        name           => $self->from->{name},
        data_type      => $self->from->{type},
        is_nullable    => $self->from->{is_nullable},
        is_primary_key => $self->from->{is_primary_key},
        is_unique      => $self->from->{is_unique},
        default_value  => $self->from->{default_value},
        size           => $self->to->{size},
    );
}

sub to_as_sql_translator_field {
    my ($self) = @_;

    my $table = $self->schema_table_object;

    return SQL::Translator::Schema::Field->new(
        table          => $table,
        name           => $self->to->{name},
        data_type      => $self->to->{type},
        is_nullable    => $self->to->{is_nullable},
        is_primary_key => $self->to->{is_primary_key},
        is_unique      => $self->to->{is_unique},
        default_value  => $self->to->{default_value},
        size           => $self->to->{size},
    );
}


1;
__END__

package Monorail::Change::CreateIndex;
$Monorail::Change::CreateIndex::VERSION = '0.4';
use Moose;
use SQL::Translator::Schema::Index;

with 'Monorail::Role::Change::StandardSQL';

=head1 SYNOPSIS

    my $crt_index = Monorail::Change::CreateIndex->new(
        table   => $idx->table->name,
        name    => $idx->name,
        fields  => scalar $idx->fields,
        type    => lc $idx->type,
        options => scalar $idx->options,
    );

    print $crt_index->as_perl;

    $crt_index->as_sql;

    $crt_index->transform_dbix($dbix)

=cut


has table            => (is => 'ro', isa => 'Str',           required => 1);
has name             => (is => 'ro', isa => 'Str',           required => 1);
has type             => (is => 'ro', isa => 'Str',           required => 1);
has fields           => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
has options          => (is => 'ro', isa => 'ArrayRef',      required => 0);

__PACKAGE__->meta->make_immutable;


sub as_sql {
    my ($self) = @_;

    return $self->producer->alter_create_index($self->as_sql_translator_index);
}

sub as_sql_translator_index {
    my ($self) = @_;

    my $table = $self->schema_table_object;

    return SQL::Translator::Schema::Index->new(
        table   => $table,
        name    => $self->name,
        type    => $self->type,
        fields  => $self->fields,
        options => $self->options,
    );
}

sub transform_schema {
    my ($self, $schema) = @_;

    $schema->get_table($self->table)->add_index($self->as_sql_translator_index);
}

sub as_hashref_keys {
    return qw/
        name table type fields options
    /;
}

1;
__END__

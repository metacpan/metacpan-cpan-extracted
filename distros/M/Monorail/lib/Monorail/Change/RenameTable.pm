package Monorail::Change::RenameTable;
$Monorail::Change::RenameTable::VERSION = '0.4';
use Moose;
use SQL::Translator::Schema::Table;

with 'Monorail::Role::Change::StandardSQL';

=head1 SYNOPSIS

    my $add_field = Monorail::Change::RenameTable->new(
        from => 'epcot_center',
        to   => 'epcot',
    );

    print $add_field->as_perl;

    $add_field->transform_database($dbix);

    $add_field->transform_dbix($dbix)

=cut


has from => (is => 'ro', isa => 'Str',  required => 1);
has to   => (is => 'ro', isa => 'Str',  required => 1);

__PACKAGE__->meta->make_immutable;


sub as_sql {
    my ($self) = @_;

    my $old = SQL::Translator::Schema::Table->new(name => $self->from);
    my $new = SQL::Translator::Schema::Table->new(name => $self->to);

    return $self->producer->rename_table($old, $new);
}

sub transform_schema {
    my ($self, $schema) = @_;

    my $table = $schema->drop_table($self->from);

    $table->name($self->to);

    $schema->add_table($table);
}


sub as_hashref_keys {
    return qw/from to/;
}


1;
__END__

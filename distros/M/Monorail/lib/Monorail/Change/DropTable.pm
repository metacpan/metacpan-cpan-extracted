package Monorail::Change::DropTable;
$Monorail::Change::DropTable::VERSION = '0.4';
use Moose;
use SQL::Translator::Schema::Table;

with 'Monorail::Role::Change::StandardSQL';

=head1 SYNOPSIS

    my $add_field = Monorail::Change::DropTable->new(
        name  => $fld->name,
    );

    print $add_field->as_perl;

    $add_field->as_sql;

    $add_field->transform_dbix($dbix)

    $add_field->transform_database($dbix);

=cut


has name => (is => 'ro', isa => 'Str',  required => 1);

__PACKAGE__->meta->make_immutable;


sub as_sql {
    my ($self) = @_;

    my $table = SQL::Translator::Schema::Table->new(name => $self->name);

    return $self->producer->drop_table($table);
}

sub transform_schema {
    my ($self, $schema) = @_;

    $schema->drop_table($self->name);
}


sub as_hashref_keys {
    return qw/name/;
}


1;
__END__

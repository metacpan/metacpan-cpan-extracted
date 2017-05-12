package Test::DB::Table;

use qbit;

use base qw(QBit::Application::Model::DB::Table);

sub _get_field_object {
    my ($self, %opts) = @_;

    return QBit::Application::Model::DB::Field->new(%opts);
}

sub _convert_fk_auto_type {
    my ($self, $field, $fk_field) = @_;

    $field->{'type'} = $fk_field->{'type'};
}

TRUE;

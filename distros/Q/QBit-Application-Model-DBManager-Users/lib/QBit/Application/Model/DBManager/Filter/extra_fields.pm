package QBit::Application::Model::DBManager::Filter::extra_fields;
$QBit::Application::Model::DBManager::Filter::extra_fields::VERSION = '0.007';
use qbit;

use base qw(QBit::Application::Model::DBManager::Filter::text);

sub as_filter {
    my ($self, $data, $field, %opts) = @_;

    my $pkg_stash   = package_stash(ref($self->{'db_manager'}));
    my $db_accessor = $pkg_stash->{'__DB_FILTER_DBACCESSOR__'};

    my $field_name = $field->{'field'};
    my $fk_field   = $field->{'fk_field'};
    my $table      = $field->{'table'};

    return [
        defined($field->{'db_expr'}) ? $field->{'db_expr'}
        : $field_name => '= ANY' => $self->{'db_manager'}->$db_accessor->query->select(
            table  => $self->{'db_manager'}->$db_accessor->$table,
            fields => [$fk_field],
            filter => [
                'AND',
                [
                    ['key' => '=' => \$data->[0]],
                    [
                        'value' => $data->[1] => \(
                            $data->[1] =~ /LIKE/
                            ? QBit::Application::Model::DBManager::Filter::text::__like_str($data->[2])
                            : $data->[2]
                        )
                    ]
                ]
            ]
        )
    ];
}

TRUE;

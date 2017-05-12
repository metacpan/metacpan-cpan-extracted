package TestApplication::Model::TestModel;

use qbit;

use base qw(QBit::Application::Model::DBManager);

use TestQuery;

__PACKAGE__->model_fields(
    id        => {db => TRUE, pk   => TRUE, default => TRUE},
    parent_id => {db => TRUE, pk   => TRUE, default => TRUE},
    caption   => {db => TRUE, i18n => TRUE, default => TRUE},
    view_id   => {
        depends_on => [qw(id parent_id)],
        get        => sub {
            return "id: $_[1]->{id}, parent_id: $_[1]->{parent_id}";
          }
    },
    parent => {
        depends_on => [qw(parent_id)],
        get        => sub {
            return $_[0]->{'__PARENTS__'}{$_[1]->{'parent_id'}};
          }
    },
    secret => {
        db           => TRUE,
        check_rights => 'view_secret',
    },
    reverse => {
        forced_depends_on => 'secret',
        get              => sub {
            return reverse($_[1]->{'secret'});
          }
    },
    view_secret => {
        depends_on => 'secret',
        get        => sub {
            return $_[1]->{'secret'};
          }
    },
    fix_db => {
        db  => TRUE,
        get => sub {
            return $_[1]->{'fix_db'} * 10;
          }
    }
);

sub query {
    return TestQuery->new();
}

sub pre_process_fields {
    my ($self, $fields, $result) = @_;

    if ($fields->need('parent')) {
        $fields->{'__PARENTS__'} = {
            1 => 'PARENT 1',
            2 => 'PARENT 2',
        };
    }
}

TRUE;

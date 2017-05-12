package QBit::WebInterface::Controller::RBAC;
$QBit::WebInterface::Controller::RBAC::VERSION = '0.004';
use qbit;

use base qw(QBit::WebInterface::Controller);

__PACKAGE__->model_accessors(rbac => 'QBit::Application::Model::RBAC');

eval {require Exception::DB::DuplicateEntry};

sub pre_cmd {
    my ($self) = @_;

    $self->app->set_option(
        left_menu => [
            grep {$self->check_rights($_->{'right'})} (
                {caption => gettext('Roles'),    cmd => 'roles',    right => 'rbac_roles_view'},
                {caption => gettext('Add role'), cmd => 'role_add', right => 'rbac_role_add'},
                {
                    caption => gettext('Assign rigths to roles'),
                    cmd     => 'role_rights',
                    right   => 'rbac_assign_rigth_to_role'
                },
            )
        ]
    );
}

sub roles : CMD : DEFAULT {
    my ($self) = @_;

    return $self->denied() unless $self->check_rights('rbac_roles_view');

    return $self->from_template('rbac/roles.tt2', vars => {roles => $self->rbac->get_roles()});
}

sub role_add : FORMCMD {
    my ($self) = @_;

    return (
        fields => [
            {name => 'name', type => 'input', lenght => 63, required => 1, label => gettext('Role name')},
            {name => 'description', type  => 'input', lenght => 255, label => gettext('Role description')},
            {type => 'submit',      value => gettext('Add')},
        ],

        check_rights => ['rbac_role_add'],

        redirect => 'roles',

        save => sub {
            my ($form, $controller) = @_;
            try {
                $controller->rbac->role_add(map {$_ => $form->get_value($_)} qw(name description));
            }
            catch Exception::DB::DuplicateEntry with {
                throw gettext('Role with the same name is exists');
            };
        }
    );
}

sub role_rights : FORMCMD {
    my ($self) = @_;

    my $registered_rights       = $self->app->get_registered_rights();
    my $registered_right_groups = $self->app->get_registered_right_groups();
    my $roles                   = $self->rbac->get_roles();
    my $role_rights             = $self->rbac->get_roles_rights();

    my %role_rights;
    foreach my $rec (@$role_rights) {
        $role_rights{$rec->{'role_id'}, $rec->{'right'}} = 1;
    }

    my %right_groups;
    foreach my $right (keys(%$registered_rights)) {
        my $r = {%{$registered_rights->{$right}}, id => $right};
        $right_groups{$r->{'group'}} ||= {
            name   => $registered_right_groups->{$r->{'group'}},
            rights => []
        };
        push(@{$right_groups{$r->{'group'}}{'rights'}}, $r);
    }

    my @role_rights_fields;
    foreach my $right (keys(%$registered_rights)) {
        foreach my $role (@$roles) {
            push(
                @role_rights_fields,
                {
                    name    => 'right__' . $right,
                    type    => 'checkbox',
                    value   => $role->{'id'},
                    checked => $role_rights{$role->{'id'}, $right}
                }
            );
        }
    }

    return (
        fields => [@role_rights_fields, {type => 'submit', name => 'submit', value => gettext('Apply')}],

        check_rights => ['rbac_assign_rigth_to_role'],

        template => 'rbac/role_rights.tt2',

        vars => {
            right_groups => \%right_groups,
            roles        => $roles,
        },

        save => sub {
            my ($form, $controller) = @_;

            my @right_fields =
              map {my $name = $_->{'name'}; $name =~ s/^right__//; {right => $name, role_id => $_->{'value'}}}
              grep {$_->{'name'} =~ /^right__/ && $_->{'checked'}} @{$form->get_fields};

            $controller->rbac->set_roles_rights(\@right_fields);
        }
    );
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::WebInterface::Controller::RBAC - RBAC manager for QBit application.

=head1 GitHub

https://github.com/QBitFramework/QBit-WebInterface-Controller-RBAC

=head1 Install

=over

=item *

cpanm QBit::WebInterface::Controller::RBAC

=item *

apt-get install libqbit-webinterface-controller-rbac-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut

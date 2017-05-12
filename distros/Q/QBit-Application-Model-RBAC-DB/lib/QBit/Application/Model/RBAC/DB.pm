package QBit::Application::Model::RBAC::DB;
$QBit::Application::Model::RBAC::DB::VERSION = '0.003';
use qbit;

use base qw(QBit::Application::Model::RBAC);

__PACKAGE__->model_accessors(db => 'QBit::Application::Model::DB::RBAC');

sub get_roles {
    my ($self, %opts) = @_;

    return $self->db->roles->get_all($opts{'ids'} ? (filter => {id => $opts{'ids'}}) : ());
}

sub role_add {
    my ($self, %role) = @_;

    throw Exception::Denied unless $self->check_rights('rbac_role_add');

    return $self->db->roles->add(\%role);
}

sub set_roles_rights {
    my ($self, $data) = @_;

    throw Exception::Denied unless $self->check_rights('rbac_assign_rigth_to_role');

    $self->db->transaction(
        sub {
            $self->db->role_rights->truncate();
            $self->db->role_rights->add_multi($data);
        }
    );
}

sub set_user_role {
    my ($self, $user_id, $role_id) = @_;

    throw Exception::Denied unless $self->check_rights('rbac_user_role_set');

    $self->db->user_role->replace({user_id => $user_id, role_id => $role_id});
}

sub get_roles_rights {
    my ($self, %opts) = @_;

    $opts{'fields'} = [qw(right role_id)] unless exists($opts{'fields'});

    my $filter = $self->db->filter();
    $filter->and({role_id => $opts{'role_id'}}) if exists($opts{'role_id'});

    return $self->db->role_rights->get_all(fields => $opts{'fields'}, filter => $filter);
}

sub get_cur_user_roles {
    my ($self) = @_;

    my $cur_user = $self->cur_user();

    return %$cur_user ? $self->get_roles_by_user_id($cur_user->{'id'}) : {};
}

sub get_roles_by_user_id {
    my ($self, $user_id) = @_;

    my $roles = $self->db->user_role->get_all(
        fields => [qw(role_id)],
        filter => {user_id => $user_id}
    );

    $roles = $self->get_roles(ids => [map {$_->{'role_id'}} @$roles]);

    my %hash_roles = map {$_->{id} => $_} @$roles;

    return \%hash_roles;
}

sub revoke_roles {
    my ($self, $user_id, $roles) = @_;

    throw Exception::Denied unless $self->check_rights('rbac_revoke_roles');

    throw Exception::BadArguments(gettext("Expected that 'user_id' is not to be undefined")) unless defined($user_id);
    throw Exception::BadArguments(gettext("Expected that 'role_id' is not to be undefined")) unless defined($roles);

    $self->db->user_role->delete({user_id => $user_id, role_id => $roles});
}

sub get_roles_by_rights {
    my ($self, $rights) = @_;

    throw Exception::BadArguments(gettext("Expected that 'rights' is not to be undefined")) unless defined($rights);

    if (ref($rights) eq '') {
        $rights = [$rights];
    } elsif (ref($rights) ne 'ARRAY') {
        throw Exception::BadArguments(gettext("Expected that 'rights' is a ref to an ARRAY or string"));
    }

    my $roles = $self->db->role_rights->get_all(fields => ['role_id'], filter => {right => $rights}, distinct => TRUE);

    return [map {$_->{'role_id'}} @$roles];
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::RBAC::DB - RBAC DB realization.

=head1 GitHub

https://github.com/QBitFramework/QBit-Application-Model-RBAC-DB

=head1 Install

=over

=item *

cpanm QBit::Application::Model::RBAC::DB

=item *

apt-get install libqbit-application-model-rbac-db-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut

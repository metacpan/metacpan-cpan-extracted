package QBit::Application::Model::KvStore;
$QBit::Application::Model::KvStore::VERSION = '0.004';
use qbit;

use base qw(QBit::Application::Model);

__PACKAGE__->model_accessors(db => 'QBit::Application::Model::DB::KvStore');

sub get {
    my ($self, $key, %opts) = @_;

    $self->_check($key);

    my $data = $self->db->kv_store->get($key, %opts);

    return $data->{value};
}

sub get_last_change {
    my ($self, $key, %opts) = @_;

    $self->_check($key);

    my $data = $self->db->kv_store->get($key, %opts);

    return $data->{last_change};
}

sub set {
    my ($self, $key, $value) = @_;

    $self->_check($key);
    $self->_check($value);

    $self->db->kv_store->replace({key => $key, value => $value});
}

sub delete {
    my ($self, $key) = @_;

    $self->_check($key);

    $self->db->kv_store->delete($key);
}

sub _check {
    my ($self, $smth) = @_;

    throw Exception::BadArguments gettext("'%s' should be scalar", $smth) if ref $smth ne '';
    throw Exception::BadArguments gettext("Element should be defined") if not defined $smth;
    throw Exception::BadArguments gettext("'%s' should be less than 256 symbols", $smth) if length($smth) > 255;
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::KvStore - Model for key value storage.

=head1 GitHub

https://github.com/QBitFramework/QBit-Application-Model-KvStore

=head1 Install

=over

=item *

cpanm QBit::Application::Model::KvStore

=item *

apt-get install libqbit-application-model-kvstore-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut

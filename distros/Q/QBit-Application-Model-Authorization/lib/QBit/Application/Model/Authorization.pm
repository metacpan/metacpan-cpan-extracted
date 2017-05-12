package Exception::Authorization;
$Exception::Authorization::VERSION = '0.007';
use base qw(Exception);

package Exception::Authorization::NotFound;
$Exception::Authorization::NotFound::VERSION = '0.007';
use base qw(Exception::Authorization);

package Exception::Authorization::BadPassword;
$Exception::Authorization::BadPassword::VERSION = '0.007';
use base qw(Exception::Authorization);

package Exception::Authorization::BadSession;
$Exception::Authorization::BadSession::VERSION = '0.007';
use base qw(Exception::Authorization);

package QBit::Application::Model::Authorization;
$QBit::Application::Model::Authorization::VERSION = '0.007';
use qbit;

use base qw(QBit::Application::Model);

use Digest::SHA qw(sha512_hex);
use Crypt::CBC;
use Crypt::Blowfish;

my $SALT;

__PACKAGE__->model_accessors(db => 'QBit::Application::Model::DB::Authorization');

sub init {
    my ($self) = @_;

    $SALT = $self->get_option('salt') // throw Exception::Authorization gettext('Add salt in config');
}

sub registration {
    my ($self, $keys, $password) = @_;

    $keys = [$keys] unless ref($keys) eq 'ARRAY';

    my $session;
    $self->db->transaction(
        sub {
            foreach my $key (@$keys) {
                my $password_hash = $self->_password_hash($key, $password);

                $self->db->authorization->add({key => $key, password_hash => $password_hash});

                $session = $self->_get_session($key, $password_hash);
            }
        }
    );

    return $session;
}

sub delete {
    my ($self, $key) = @_;

    $self->db->authorization->delete($key);
}

sub _get_session {
    my ($self, $key, $password_hash) = @_;

    my $session = {key => $key, session_hash => $self->_session_hash($key, $password_hash)};

    my $cipher = Crypt::CBC->new(
        -keysize => 16,
        -key     => $SALT,
        -cipher  => 'Blowfish'
    );

    return $cipher->encrypt(to_json($session));
}

sub _password_hash {
    my ($self, $key, $password) = @_;

    utf8::encode($key);
    utf8::encode($password);

    return sha512_hex($password . sha512_hex($key . $SALT));
}

sub _session_hash {
    my ($self, $key, $password_hash) = @_;

    utf8::encode($key);
    utf8::encode($password_hash);

    return sha512_hex($key . $password_hash . sha512_hex($SALT));
}

sub check_auth {
    my ($self, $key, $password) = @_;

    my $auth = $self->db->authorization->get($key, fields => ['password_hash']);
    throw Exception::Authorization::NotFound gettext('"%s" not found', $key) unless defined($auth);

    return $self->_password_hash($key, $password) eq $auth->{'password_hash'}
      ? $self->_get_session($key, $auth->{'password_hash'})
      : throw Exception::Authorization::BadPassword gettext('Invalid password');
}

sub check_session {
    my ($self, $session) = @_;

    my $cipher = Crypt::CBC->new(
        -keysize => 16,
        -key     => $SALT,
        -cipher  => 'Blowfish'
    );

    try {
        $session = from_json($cipher->decrypt($session));
    }
    catch {
        throw Exception::Authorization::BadSession gettext('Invalid session');
    };

    my $auth = $self->db->authorization->get($session->{'key'}, fields => [qw(password_hash)]);
    throw Exception::Authorization::NotFound gettext('"%s" not found', $session->{'key'}) unless defined($auth);

    return $session->{'session_hash'} eq $self->_session_hash($session->{'key'}, $auth->{'password_hash'})
      ? $session->{'key'}
      : throw Exception::Authorization::BadSession gettext('Invalid session');
}

sub process {
    my ($self, $cookie_name, $interval, $request, $response, $cb) = @_;

    my $session = $request->cookie($cookie_name);

    return FALSE unless defined($session);

    my $key = $self->check_session($session);

    $cb->($key);

    $response->add_cookie($cookie_name, $session, expires => $interval,);

    return TRUE;
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::Authorization - Simple model for authorization in QBit application.

=head1 GitHub

https://github.com/QBitFramework/QBit-Application-Model-Authorization

=head1 Install

=over

=item *

cpanm QBit::Application::Model::Authorization

=item *

apt-get install libqbit-application-model-authorization-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut

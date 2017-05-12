##############################################################################
#
# Package to model a remote client

package Mock::Apache::RemoteClient;

use Readonly;
use Scalar::Util qw(weaken);

use parent qw(Class::Accessor);

Readonly my @PARAMS    => qw(mock_apache REMOTE_ADDR REMOTE_HOST REMOTE_USER);
Readonly my @ACCESSORS => ( map { lc $_ } @PARAMS );

__PACKAGE__->mk_ro_accessors(@ACCESSORS, 'connection');

sub new {
    my ($class, %params) = @_;

    $params{REMOTE_ADDR} ||= '10.0.0.10';
    $params{REMOTE_HOST} ||= 'remote.example.com';

    my $attrs = { map { ( lc $_ => $params{$_} ) } @PARAMS };
    my $self  = $class->SUPER::new($attrs);

    weaken($self->{mock_apache});

    $self->{connection} ||= Apache::Connection->new($self);

    return $self;
}

sub new_request {
    my $self = shift;

    return  Apache->_new_request($self, @_);
}

1;

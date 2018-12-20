package Protocol::DBus::Authn::Mechanism::DBUS_COOKIE_SHA1;

# https://dbus.freedesktop.org/doc/dbus-specification.html#auth-mechanisms-sha

use strict;
use warnings;

use parent qw( Protocol::DBus::Authn::Mechanism );

use Protocol::DBus::Authn::Mechanism::DBUS_COOKIE_SHA1::Pieces ();

use File::Spec ();

my $sha_module;

use constant must_send_initial => 0;

use constant {
    DEBUG => 0,
};

sub new {
    my ($class) = @_;

    local $@;

    if ( eval { require Digest::SHA1; 1 } ) {
        $sha_module = 'Digest::SHA1';
    }
    elsif ( eval { require Digest::SHA; 1 } ) {
        $sha_module = 'Digest::SHA';
    }
    else {
        die "No SHA module available!";
    }

    return $class->SUPER::new( @_[ 1 .. $#_ ] );
}

sub INITIAL_RESPONSE {
    my ($self) = @_;

    return unpack( 'H*', ($self->_getpw())[0] );
}

sub AFTER_AUTH {
    my ($self) = @_;

    return (
        [ 1 => sub {
            _consume_data($self, @_);
        } ],
        [ 0 => \&_authn_respond_data ],
    );
}

sub _getpw {
    my ($self) = @_;

    $self->{'_pw'} ||= [ getpwuid $> ];

    return @{ $self->{'_pw'} };
}

sub _consume_data {
    my ($self, $authn, $line) = @_;

    if (0 != index($line, 'DATA ')) {
        die "Invalid line: [$line]";
    }

    substr( $line, 0, 5, q<> );

    my ($ck_ctx, $ck_id, $sr_challenge) = split m< >, pack( 'H*', $line );

    if (DEBUG()) {
        print STDERR (
            "AUTHN/SHA1 context: $ck_ctx$/",
            "AUTHN/SHA1 cookie ID: $ck_id$/",
            "AUTHN/SHA1 server challenge: $sr_challenge$/",
        );
    }

    my $cookie = $self->_get_cookie($ck_ctx, $ck_id);

    my $cl_challenge = _create_challenge();

    my $str = join(
        ':',
        $sr_challenge,
        $cl_challenge,
        $cookie,
    );

    my $str_digest = _sha1_hex($str);

    if (DEBUG()) {
        print STDERR (
            "AUTHN/SHA1 cookie: $cookie$/",
            "AUTHN/SHA1 client challenge: $ck_id$/",
            "AUTHN/SHA1 string: $str$/",
        );
    }

    $authn->{'_sha1_response'} = unpack 'H*', "$cl_challenge $str_digest";

    return;
}

sub _authn_respond_data {
    return (
        'DATA',
        $_[0]->{'_sha1_response'} || do {
           die "No SHA1 DATA response set!";
        },
    );
}

*_sha1_hex = \&Protocol::DBus::Authn::Mechanism::DBUS_COOKIE_SHA1::Pieces::sha1_hex;

*_create_challenge = \&Protocol::DBus::Authn::Mechanism::DBUS_COOKIE_SHA1::Pieces::create_challenge;

sub _get_cookie {
    my ($self, $ck_ctx, $ck_id) = @_;

    return Protocol::DBus::Authn::Mechanism::DBUS_COOKIE_SHA1::Pieces::get_cookie(
        ($self->_getpw())[7],
        $ck_ctx,
        $ck_id,
    );
}

1;

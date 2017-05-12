package Reaction::InterfaceModel::Object::User::Role::ConfirmationCodeSupport;

use Reaction::Role;
use Crypt::Eksblowfish::Bcrypt ();
use namespace::clean -except => [ qw(meta) ];

requires 'identity_string';

sub generate_confirmation_code {
    my $self = shift;
    my $salt = join(q{}, map { chr(int(rand(256))) } 1 .. 16);
    $salt = Crypt::Eksblowfish::Bcrypt::en_base64( $salt );
    my $settings_base = join(q{},'$2','a','$',sprintf("%02i", 8), '$');
    return Crypt::Eksblowfish::Bcrypt::bcrypt(
        $self->identity_string, $settings_base . $salt
    );
}

1;

package Palm::Zetetic::Strip::PDB::PasswordV05i;

use strict;
use Palm::PDB;
use Palm::Raw;
use Palm::Zetetic::Strip::CryptV05i;

use vars qw(@ISA $VERSION);

require Exporter;

@ISA = qw(Exporter);
$VERSION = "1.02";

sub new
{
    my $class = shift;
    my $self = {};

    bless $self, $class;
    $self->{pdb} = undef;
    return $self;
}

sub load
{
    my ($self, $file) = @_;
    my $pdb;

    $pdb = new Palm::PDB;
    $pdb->Load($file);
    $self->{pdb} = $pdb;
}

sub get_encrypted_password
{
    my ($self) = @_;
    my $records;

    $records = $self->{pdb}->{records};
    return $records->[0]->{data};
}

sub verify_password
{
    my ($self, $plaintext_password) = @_;
    my $encrypted_password;
    my $decrypted_password;
    my $hashed_password;
    my $crypt;

    # The encrypted password is the MD5 hash of the plaintext
    # password, encrypted.  The MD5 hash is only 16 bytes long, so
    # only look at the first 16 bytes after decrypting.  To verify a
    # password, decrypt the current password using the supplied
    # password as the key.

    $crypt = new Palm::Zetetic::Strip::CryptV05i($plaintext_password);

    $hashed_password = $crypt->get_hashed_key();
    $encrypted_password = $self->get_encrypted_password();
    $decrypted_password = $crypt->decrypt($encrypted_password);
    $decrypted_password = substr($decrypted_password,0,16);

    if ($decrypted_password eq $hashed_password)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

1;

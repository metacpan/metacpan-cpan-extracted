package Palm::Zetetic::Strip::PDB::PasswordV10;

use strict;
use Palm::PDB;
use Palm::Raw;
use Palm::Zetetic::Strip::CryptV10;

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

    $crypt = new Palm::Zetetic::Strip::CryptV10($plaintext_password);

    $hashed_password = $crypt->get_hashed_key();
    $encrypted_password = $self->get_encrypted_password();
    $decrypted_password = $crypt->decrypt($encrypted_password);

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

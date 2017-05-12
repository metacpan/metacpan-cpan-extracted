package Palm::Zetetic::Strip::PDB::AccountsV05i;

use strict;
use Palm::PDB;
use Palm::Raw;
use Palm::Zetetic::Strip::CryptV05i;
use Palm::Zetetic::Strip::Account;

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

sub get_accounts
{
    my ($self, $password) = @_;
    my $records;
    my $record;
    my $crypt;
    my @accounts;

    $crypt = new Palm::Zetetic::Strip::CryptV05i($password);

    $records = $self->{pdb}->{records};
    @accounts = ();
    foreach $record (@$records)
    {
        my $data;
        my $id;
        my $system_id;
        my $account_id;
        my $username;
        my $password;
        my $system;
        my $comment;
        my $strings;
        my $encrypted_data;
        my $decrypted_data;
        my $account;

        $data = $record->{"data"};
        ($id, $encrypted_data) = unpack("na*", $data);
        $decrypted_data = $crypt->decrypt($encrypted_data);
        ($system_id, $account_id, $strings)
            = unpack("nna*", $decrypted_data);
        ($username, $password, $system, $comment) = split(/\000/, $strings);
        $account =
            new Palm::Zetetic::Strip::Account("system" => $system,
                                              "username" => $username,
                                              "password" => $password,
                                              "system_id" => $system_id,
                                              "comment" => $comment);
        push(@accounts, $account);
    }

    return \@accounts;
}

1;

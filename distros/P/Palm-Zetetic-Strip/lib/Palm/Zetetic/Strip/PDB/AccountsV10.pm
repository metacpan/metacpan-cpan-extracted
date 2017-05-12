package Palm::Zetetic::Strip::PDB::AccountsV10;

use strict;
use Palm::PDB;
use Palm::Raw;
use Palm::Zetetic::Strip::CryptV10;
use Palm::Zetetic::Strip::Account;
use Palm::Zetetic::Strip::Util qw(hexdump null_split);

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

    $crypt = new Palm::Zetetic::Strip::CryptV10($password);

    $records = $self->{pdb}->{records};
    @accounts = ();
    foreach $record (@$records)
    {
        my $encrypted_data;
        my $decrypted_data;
        my $account;

        my $system_id;
        my $account_id;
        my $hash;
        my $series;
        my $hash_type;
        my $system_type;
        my $service_type;
        my $username_type;
        my $password_type;
        my $account_mod_date;
        my $password_mod_date;
        my $binary_data_length;
        my $strings;
        my $system;
        my $username;
        my $comment;
        my $key;
        my $service;
        my @binary_data;

        ($system_id, $account_id, $hash, $encrypted_data)
            = unpack("nna32a*", $record->{data});
        $decrypted_data = $crypt->decrypt($encrypted_data);
        ($series, $hash_type, $system_type, $service_type, $username_type,
         $password_type, $account_mod_date, $password_mod_date,
         $binary_data_length, $strings)
            = unpack("nnnnnnNNna*", $decrypted_data);

        ($system, $service, $username, $password, $comment, $key, @binary_data)
            = split("\0", $strings);

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

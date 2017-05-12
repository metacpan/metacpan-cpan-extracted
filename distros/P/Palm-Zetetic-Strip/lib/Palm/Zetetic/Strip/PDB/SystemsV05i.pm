package Palm::Zetetic::Strip::PDB::SystemsV05i;

use strict;
use Palm::PDB;
use Palm::Raw;
use Palm::Zetetic::Strip::CryptV05i;
use Palm::Zetetic::Strip::System;

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

sub get_systems
{
    my ($self, $password) = @_;
    my $records;
    my $record;
    my $crypt;
    my @systems;

    $crypt = new Palm::Zetetic::Strip::CryptV05i($password);

    $records = $self->{pdb}->{records};
    @systems = ();
    foreach $record (@$records)
    {
        my $encrypted_data;
        my $decrypted_data;
        my $id;
        my $name;
        my $system;

        $encrypted_data = $record->{"data"};
        $decrypted_data = $crypt->decrypt($encrypted_data);
        ($id, $name) = unpack("nZ*", $decrypted_data);
        $system = new Palm::Zetetic::Strip::System("id" => $id,
                                                   "name" => $name);
        push (@systems, $system);
    }

    return \@systems;
}

1;

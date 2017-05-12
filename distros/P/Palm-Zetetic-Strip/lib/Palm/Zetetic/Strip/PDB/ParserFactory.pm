package Palm::Zetetic::Strip::PDB::ParserFactory;

use strict;
use Carp;
use Palm::PDB;
use Palm::Raw;
use Palm::Zetetic::Strip::Util qw(true false);

use Palm::Zetetic::Strip::Version;

use vars qw(@ISA $VERSION);

require Exporter;

@ISA = qw(Exporter);
$VERSION = "1.02";

sub new
{
    my $class = shift;
    my $self = {};

    bless $self, $class;
    $self->set_available_versions();
    $self->load_available_modules();
    $self->set_initial_version();
    return $self;
}

sub set_initial_version
{
    my ($self) = @_;

    $self->{strip_version} = new Palm::Zetetic::Strip::Version();

    # Try setting the versions, walking down the list of available
    # versions.  If none are available, croak.

    if ($self->is_v0_5i_available())
    {
        $self->{strip_version}->set_version_string("0.5i");
    }
    elsif ($self->is_v1_0_available())
    {
        $self->{strip_version}->set_version_string("1.0");
    }
    else
    {
        croak "Cannot find any crypt/hash modules\n";
    }
}

sub get_strip_version
{
    my ($self) = @_;
    return $self->{strip_version};
}

sub set_strip_version
{
    my ($self, $strip_version) = @_;

    $self->{strip_version}->set_version_string($strip_version);
}

sub set_strip_version_autodetect
{
    my ($self, $directory) = @_;
    my $pdb;
    my $password_length;

    # Load the password PDB.  We can autodetect the version from the
    # password.
    $pdb = new Palm::PDB;
    $pdb->Load("${directory}/StripPassword-SJLO.pdb");
    $password_length = length($pdb->{records}->[0]->{data});

    if ($password_length eq 24)
    {
        if (! $self->is_v0_5i_available())
        {
            croak("Cannot decrypt version 0.5i databases, install Digest::MD5 and Crypt::IDEA");
        }

        $self->{strip_version}->set_version_string("0.5i");
    }
    elsif ($password_length eq 48)
    {
        if (! $self->is_v1_0_available())
        {
            croak("Cannot decrypt version 1.0 databases, install Digest::SHA256 and Crypt::Rijndael");
        }

        $self->{strip_version}->set_version_string("1.0");
    }
}

sub load_module
{
    my ($module) = @_;

    eval "use $module";
    if (!$@)
    {
        return true;
    }
    else
    {
        return false;
    }
}

sub set_available_versions
{
    my ($self) = @_;
    my $found_md5;
    my $found_idea;
    my $found_sha256;
    my $found_rijndael;

    # Attempt to load all hash/crypt modules and record their success
    $found_md5      = load_module("Digest::MD5");
    $found_idea     = load_module("Crypt::IDEA");
    $found_sha256   = load_module("Digest::SHA256");
    $found_rijndael = load_module("Crypt::Rijndael");

    # Version 0.5i uses MD5 and IDEA
    if ($found_md5 and $found_idea)
    {
        $self->{v0_5i_available} = true;
    }
    else
    {
        $self->{v0_5i_available} = false;
    }

    # Version 1.0 uses SHA256 and Rijndael
    if ($found_sha256 and $found_rijndael)
    {
        $self->{v1_0_available} = true;
    }
    else
    {
        $self->{v1_0_available} = false;
    }
}

sub is_v0_5i_available
{
    my ($self) = @_;
    return $self->{v0_5i_available};
}

sub is_v1_0_available
{
    my ($self) = @_;
    return $self->{v1_0_available};
}

sub load_available_modules
{
    my ($self) = @_;
    my $rc;

    if ($self->is_v0_5i_available())
    {
        $rc = load_module("Palm::Zetetic::Strip::PDB::PasswordV05i");
        $rc |= load_module("Palm::Zetetic::Strip::PDB::SystemsV05i");
        $rc |= load_module("Palm::Zetetic::Strip::PDB::AccountsV05i");
        croak("Unable to load v0.5i modules") if ! $rc;
    }

    if ($self->is_v1_0_available())
    {
        $rc = load_module("Palm::Zetetic::Strip::PDB::PasswordV10");
        $rc |= load_module("Palm::Zetetic::Strip::PDB::SystemsV10");
        $rc |= load_module("Palm::Zetetic::Strip::PDB::AccountsV10");
        croak("Unable to load v1.0 modules") if ! $rc;
    }
}

sub get_password_parser
{
    my ($self) = @_;
    my $password_parser;

    if ($self->{strip_version}->is_0_5i())
    {
        $password_parser = Palm::Zetetic::Strip::PDB::PasswordV05i->new()
    }
    elsif ($self->{strip_version}->is_1_0())
    {
        $password_parser = Palm::Zetetic::Strip::PDB::PasswordV10->new();
    }

    return $password_parser;
}

sub get_systems_parser
{
    my ($self) = @_;
    my $systems_parser;

    if ($self->{strip_version}->is_0_5i())
    {
        $systems_parser = Palm::Zetetic::Strip::PDB::SystemsV05i->new();
    }
    elsif ($self->{strip_version}->is_1_0())
    {
        $systems_parser = Palm::Zetetic::Strip::PDB::SystemsV10->new();
    }

    return $systems_parser;
}

sub get_accounts_parser
{
    my ($self) = @_;
    my $accounts_parser;

    if ($self->{strip_version}->is_0_5i())
    {
        $accounts_parser = Palm::Zetetic::Strip::PDB::AccountsV05i->new();
    }
    elsif ($self->{strip_version}->is_1_0())
    {
        $accounts_parser = Palm::Zetetic::Strip::PDB::AccountsV10->new();
    }

    return $accounts_parser;
}

1;

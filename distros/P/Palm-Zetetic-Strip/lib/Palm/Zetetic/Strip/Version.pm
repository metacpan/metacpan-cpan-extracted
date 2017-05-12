package Palm::Zetetic::Strip::Version;

use strict;

use vars qw(@ISA $VERSION);

require Exporter;

@ISA = qw(Exporter);
$VERSION = "1.02";

sub new
{
    my $class = shift;
    my $hashed_key;
    my $self = {};

    bless $self, $class;
    $self->set_version_string("0.5i");
    return $self;
}

sub set_version_string
{
    my ($self, $version) = @_;

    if (($version ne "0.5i") and ($version ne "1.0"))
    {
        $version = "0.5i";
    }
    $self->{version} = $version;
}

sub get_version_string
{
    my ($self) = @_;
    return $self->{version};
}

sub is_0_5i
{
    my ($self) = @_;
    return ($self->{version} eq "0.5i");
}

sub is_1_0
{
    my ($self) = @_;
    return ($self->{version} eq "1.0");
}

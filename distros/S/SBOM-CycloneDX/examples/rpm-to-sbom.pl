#!perl

# rpm-to-bom.pl - Generate a BOM file from installed RPM packages

# (C) 2026, Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>
# License MIT

use strict;
use warnings;
use utf8;
use v5.16;

use SBOM::CycloneDX;
use SBOM::CycloneDX::Enum;
use SBOM::CycloneDX::Component;
use SBOM::CycloneDX::Metadata::Lifecycle;
use SBOM::CycloneDX::Tool;
use SBOM::CycloneDX::Util qw(cyclonedx_tool);

use Carp;
use URI::PackageURL;

my $packages = `rpm -qa --qf '%{NAME}\t%{VERSION}-%{RELEASE}\t%{ARCH}\t%{SUMMARY}\n'`;
my @packages = split /\n/, $packages;

my %os_release = parse_os_release();

my $bom = SBOM::CycloneDX->new(spec_version => 1.7);

my $os_component = SBOM::CycloneDX::Component->new(
    type    => 'operating-system',
    name    => $os_release{NAME},
    version => $os_release{VERSION},
    bom_ref => sprintf('%s-%s', $os_release{ID}, $os_release{VERSION_ID}),
    cpe     => $os_release{CPE_NAME},
);

my $root_component = SBOM::CycloneDX::Component->new(
    type      => 'operating-system',
    name      => $os_release{NAME},
    version   => $os_release{VERSION},
    lifecycle => {phase => 'operation'},
);

my $this_tool = SBOM::CycloneDX::Tool->new(name => $0, version => '1.0');
my $lifecycle = SBOM::CycloneDX::Metadata::Lifecycle->new(phase => 'operations');

my $metadata = $bom->metadata;

$metadata->lifecycles->add($lifecycle);
$metadata->component($root_component);

$metadata->tools->add(cyclonedx_tool);
$metadata->tools->add($this_tool);

$bom->components->add($os_component);

foreach my $package (@packages) {

    my ($name, $version, $arch, $summary) = split /\t/, $package;

    my $purl = URI::PackageURL->new(
        type      => 'rpm',
        namespace => $os_release{ID},
        name      => $name,
        version   => $version,
        qualifiers => {arch => $arch, distro => sprintf('%s-%s', $os_release{ID}, $os_release{VERSION_ID})}
    );

    my $pkg_component = SBOM::CycloneDX::Component->new(
        type        => 'application',
        name        => $name,
        description => $summary,
        version     => $version,
        bom_ref     => "$name-$version",
        purl        => $purl
    );

    $bom->components->add($pkg_component);
    $bom->add_dependency($os_component, [$pkg_component]);

}

my @errors = $bom->validate;

say STDERR "[VALIDATION] $_" for @errors;

say $bom;

sub parse_os_release {

    open my $fh, '<', '/etc/os-release' or Carp::croak "Failed to open os-release: $!";

    my %os_release = ();

    while (my $line = <$fh>) {
        chomp($line);
        my ($key, $value) = ($line =~ /(.*)=(.*)/);
        $value =~ s/"//g;
        $os_release{$key} = $value;
    }

    close $fh;

    return wantarray ? %os_release : \%os_release;

}

use strict;
use warnings;
use Module::Build;

$ENV{'PERL_MB_OPT'} = '--install-base=/usr'; # I could not make this work via the parameters below :/
$ENV{'DEB_BUILD_OPTIONS'}='nocheck';

my $debian = Module::Build->subclass(
    class => "Module::Build::Debian",
    code => <<'SUBCLASS' );

sub DEBVERSION {
    return 1;
}

sub ACTION_cpan_upload {
    my $self = shift;

    $self->depends_on("dist");
    my $version = $self->dist_version;
    $self->do_system(qq{   cpan-upload Net-Async-DigitalOcean-${version}.tar.gz } );
}

sub ACTION_README {
    my $self = shift;

    $self->do_system(qq{   pod2readme -f markdown lib/Net/Async/DigitalOcean.pm } );
}

sub ACTION_debian {
    my $self = shift;

    $self->depends_on("README");
    $self->depends_on("distdir");

    my $version = $self->dist_version;
    my $debversion = $self->DEBVERSION;
    $self->do_system(qq{   dh-make-perl --build --version=$version-$debversion Net-Async-DigitalOcean-$version } );
}

sub ACTION_inject {
    my $self = shift;

    $self->depends_on("debian");

    my $version = $self->dist_version;
    my $debversion = $self->DEBVERSION;
    $self->do_system(qq{ scp libnet-async-digitalocean-perl_${version}-${debversion}_all.deb packages.devc.at:packages/ } );
    foreach (qw(stretch) ) { # squeeze wheezy jessie 
        $self->do_system(qq{ ssh packages.devc.at -Y -t reprepro --ask-passphrase -b /var/www/packages/data/dists/ includedeb $_ packages/libnet-async-digitalocean-perl_${version}-${debversion}_all.deb });
    }
}
SUBCLASS

my $builder = $debian->new(
    module_name         => 'Net::Async::DigitalOcean',
    license             => 'artistic_2',
    dist_author         => q{Robert Barta <rho@devc.at>},
    dist_version_from   => 'lib/Net/Async/DigitalOcean.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More'          => 0,
        'Test::Exception'     => 0,
	'JSON'                => 0,
	'IO::Async'           => 0,
	'HTTP::Status'        => 0,
	'Future::Utils'       => 0,
	'Test::CheckManifest' => 0.9,
	'Test::Pod::Coverage' => 0,
	'Net::DNS'            => 0,
    },
    requires => {
	'IO::Async'           => 0,
	'JSON'                => 0,
	'HTTP::Status'        => 0,
	'Net::Async::HTTP'    => 0,
	'HTTP::Request'       => 0,
	'HTTP::Response'      => 0,
	'HTTP::Cookies'       => 0,
	'Moose'               => 0,
	'Log::Log4perl'       => 0,
    },
    add_to_cleanup     => [ 'Net-Async-DigitalOcean-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

use strict;
use warnings;
use Module::Build;


$ENV{'PERL_MB_OPT'} = '--install-base=/usr'; # I could not make this work via the parameters below :/
$ENV{'DEB_BUILD_OPTIONS'}='nocheck';

my $debian = Module::Build->subclass(
    class => "Module::Build::Debian",
    code => <<'SUBCLASS' );

sub DEBVERSION {
    return 2;
}

sub ACTION_cpan_upload {
    my $self = shift;

    $self->depends_on("dist");
    my $version = $self->dist_version;
    $self->do_system(qq{   cpan-upload Net-Async-WebService-lxd-${version}.tar.gz } );
}

sub ACTION_README {
    my $self = shift;

    $self->depends_on("POD");
    $self->do_system(qq{   pod2readme -f markdown lib/Net/Async/WebService/lxd.pod } );
}

sub ACTION_POD {
    my $self = shift;

    $self->do_system(qq{    perl -Ilib -MNet::Async::WebService::lxd -e 'Net::Async::WebService::lxd->generate_pod' > lib/Net/Async/WebService/lxd.pod  } );
}

sub ACTION_debian {
    my $self = shift;

    $self->depends_on("README");
    $self->depends_on("distdir");

    my $version = $self->dist_version;
    my $debversion = $self->DEBVERSION;
    $self->do_system(qq{ DEB_BUILD_OPTIONS=nocheck  dh-make-perl --build --version=$version-$debversion Net-Async-WebService-lxd-$version } );
}

sub ACTION_inject {
    my $self = shift;

    $self->depends_on("debian");

    my $version = $self->dist_version;
    my $debversion = $self->DEBVERSION;
    $self->do_system(qq{ scp libnet-async-webservice-lxd-perl_${version}-${debversion}_all.deb packages.devc.at:packages/ } );
    foreach (qw(stretch buster bullseye) ) { # squeeze wheezy jessie 
        $self->do_system(qq{ ssh packages.devc.at -Y -t reprepro --ask-passphrase -b /var/www/packages/data/dists/ includedeb $_ packages/libnet-async-webservice-lxd-perl_${version}-${debversion}_all.deb });
    }
}
SUBCLASS

my $builder = $debian->new(
    module_name         => 'Net::Async::WebService::lxd',
    license             => 'artistic_2',
    dist_author         => q{Robert Barta <rho@devc.at>},
    dist_version_from   => 'lib/Net/Async/WebService/lxd.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More'          => 0,
	'Test::Deep'          => 0,
	'Test::Exception'     => 0,
	'JSON'                => 0,
	'File::Slurp'         => 0,
	'Test::CheckManifest' => 0,
    },
    requires => {
	'IO::Async'               => 0,
	    'JSON'                => 0,
	    'URI'                 => 0,
	    'Encode'              => 0,
	    'Moose'               => 0,
	    'YAML'                => 0,
	    'HTTP::Status'        => 0,
	    'Net::Async::HTTP'    => 0,
	    'HTTP::Request'       => 0,
	    'HTTP::Response'      => 0,
	    'HTTP::Cookies'       => 0,
	    'Log::Log4perl'       => 0,
	    'Net::Async::HTTP'    => 0,

    },
    add_to_cleanup     => [ 'Net-Async-WebService-lxd-*' ],
);

$builder->create_build_script();

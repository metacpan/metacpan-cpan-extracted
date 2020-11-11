use Modern::Perl;
package Orbital::Transfer::System::MSYS2;
# ABSTRACT: System for MSYS2 + MinGW64 subsystem
$Orbital::Transfer::System::MSYS2::VERSION = '0.001';
use Mu;
use Orbital::Transfer::Common::Setup;
use Object::Util magic => 0;
use Module::Util ();

use Orbital::Transfer::EnvironmentVariables;
use aliased 'Orbital::Transfer::Runnable';

has msystem => (
	is => 'ro',
	default => sub { 'MINGW64' },
);

lazy msystem_base_path => method() {
	my $msystem_lc = lc $self->msystem;
	File::Spec->catfile( $self->msys2_dir, $msystem_lc );
};

lazy msystem_bin_path => method() {
	File::Spec->catfile( $self->msystem_base_path, qw(bin) );
};

has msys2_dir => (
	is => 'ro',
	default => sub {
		qq|C:\\msys64|;
	},
);

lazy perl_path => method() {
	File::Spec->catfile( $self->msystem_bin_path, qw(perl.exe) );
};

lazy paths => method() {
	my $msystem_lc = lc $self->msystem;
	[
		map { $self->msys2_dir . '\\' . $_ } (
			qq|${msystem_lc}\\bin|,
			qq|${msystem_lc}\\bin\\core_perl|,
			qq|usr\\bin|,
		)
	];
};

lazy environment => method() {
	my $env = Orbital::Transfer::EnvironmentVariables->new;

	$env->set_string('MSYSTEM', $self->msystem );

	$env->prepend_path_list('PATH', $self->paths );

	# Skip font cache generation (for fontconfig):
	# <https://github.com/Alexpux/MINGW-packages/commit/fdea2f9>
	# <https://github.com/Homebrew/homebrew-core/issues/10920>
	$env->set_string('MSYS2_FC_CACHE_SKIP', 1 );

	# OpenSSL
	delete $ENV{OPENSSL_CONF};
	$env->set_string('OPENSSL_PREFIX', $self->msystem_base_path);

	my $eumm_module = 'Orbital::Payload::Environment::Perl::System::MSWin32::EUMMnosearch';
	# search @INC for module and use its path
	my $path = path(Module::Util::find_installed($eumm_module))
		->child( qw(..) x Module::Util::module_path_parts($eumm_module) )->realpath;
	$env->set_string('PERL5OPT', "-I$path -M$eumm_module");

	# MSYS/MinGW pkg-config command line is more reliable since it does the
	# needed path conversions. Note that there are three pkg-config
	# packages, one for each subsystem.
	$env->set_string('ALIEN_BUILD_PKG_CONFIG', 'PkgConfig::CommandLine' );

	$env;
};

method _pre_run() {
}

method perl_bin_paths() {
	my $msystem_lc = lc $self->msystem;
	local $ENV{PATH} = join ";", @{ $self->paths }, $ENV{PATH};

	chomp( my $site_bin   = `perl -MConfig -E "say \$Config{sitebin}"` );
	chomp( my $vendor_bin = `perl -MConfig -E "say \$Config{vendorbin}"` );
	my @perl_bins = ( $site_bin, $vendor_bin, '/mingw64/bin/core_perl' );
	my @perl_bins_w;
	for my $path_orig ( @perl_bins ) {
		chomp(my $path = `cygpath -w '$path_orig'`);
		push @perl_bins_w, $path;
	}
	join ";", @perl_bins_w;
}

method cygpath($path_orig) {
	local $ENV{PATH} = join ";", @{ $self->paths }, $ENV{PATH};
	chomp(my $path = `cygpath -u $path_orig`);

	$path;
}

method _install() {
	# Appveyor under MSYS2/MinGW64

	# Update keys for new packagers:
	# See <https://www.msys2.org/news/#2020-06-29-new-packagers>,
	# <https://github.com/msys2/MSYS2-packages/issues/2058>
	my $repo_main_server = 'http://repo.msys2.org/';
	my @repo_mirrors = (
		$repo_main_server,
		'https://mirror.yandex.ru/mirrors/msys2/',
	);

	my $run_mirror_update_cmd = 1;
	my $mirror_update_cmd =
		Runnable->new(
			command => [ qw(bash -c), <<'EOF' ],
perl -i -lpE 's/^(Server.*(\Qrepo.msys2.org\E|\Qsourceforge.net\E).*)$/# $1/' /etc/pacman.d/mirrorlist.m*
EOF
			environment => $self->environment,
		);

	$self->runner->system( $mirror_update_cmd ) if $run_mirror_update_cmd;

	$self->runner->system(
		Runnable->new(
			command => [ qw(bash -c), <<"EOF" ],
curl -s -O @{[ $repo_mirrors[1] ]}msys/x86_64/msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz;
curl -s -O @{[ $repo_mirrors[1] ]}msys/x86_64/msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz.sig;
pacman-key --verify msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz{.sig,};
pacman --noconfirm -U msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz;
EOF
			environment => $self->environment,
		)
	);


	$self->pacman('pacman-mirrors');
	$self->pacman('git');

	# For the `--ask 20` option, see
	# <https://github.com/Alexpux/MSYS2-packages/issues/1141>.
	#
	# Otherwise the message
	#
	#     :: msys2-runtime and catgets are in conflict. Remove catgets? [y/N]
	#
	# is displayed when trying to update followed by an exit rather
	# than selecting yes.
	my $update_runnable = Runnable->new(
		command => [ qw(pacman -Syu --ask 20 --noconfirm) ],
		environment => $self->environment,
	);

	# Kill background processes using DLL:
	# <https://www.msys2.org/news/#2020-05-22-msys2-may-fail-to-start-after-a-msys2-runtime-upgrade>
	my $kill_msys2 = Runnable->new(
		command => [ qw(taskkill /f /fi), "MODULES eq msys-2.0.dll" ],
	);

	# Update
	$self->runner->$_try( system => $update_runnable );
	$self->runner->$_try( system => $kill_msys2 );

	# Workaround GCC9 update issues:
	# Ada and ObjC support were dropped by MSYS2 with GCC9. See commit
	# <https://github.com/msys2/MINGW-packages/commit/0c60660b0cbb485fa29ea09a229cb368e2d01bae>.
	# and broken dependencies issue in <https://github.com/msys2/MINGW-packages/issues/5434>.
	try {
		my @gcc9_remove = qw(
			mingw-w64-i686-gcc-ada   mingw-w64-i686-gcc-objc
			mingw-w64-x86_64-gcc-ada mingw-w64-x86_64-gcc-objc
		);
		$self->runner->system(
			Runnable->new(
				command => [ qw(pacman -R --noconfirm), @gcc9_remove ],
				environment => $self->environment,
			)
		);
	} catch { };

	# Fix mirrors again
	$self->runner->system( $mirror_update_cmd ) if $run_mirror_update_cmd;

	# Update again
	$self->runner->$_try( system => $update_runnable );
	$self->runner->$_try( system => $kill_msys2 );

	# build tools
	$self->pacman(qw(mingw-w64-x86_64-make mingw-w64-x86_64-toolchain autoconf automake libtool make patch mingw-w64-x86_64-libtool));

	# OpenSSL
	$self->pacman(qw(mingw-w64-x86_64-openssl));

	# There is not a corresponding cc for the mingw64 gcc. So we copy it in place.
	$self->run(qw(cp -pv /mingw64/bin/gcc /mingw64/bin/cc));
	$self->run(qw(cp -pv /mingw64/bin/mingw32-make /mingw64/bin/gmake));

	# Workaround for Data::UUID installation problem.
	# See <https://github.com/rjbs/Data-UUID/issues/24>.
	mkdir 'C:\tmp';

	$self->_install_perl;
}

method _install_perl() {
	$self->pacman(qw(mingw-w64-x86_64-perl));
	$self->pacman(qw(mingw-w64-x86_64-wget)); # needed for cpanm
	$self->build_perl->script( 'pl2bat', $self->build_perl->which_script('pl2bat') );
	{
		local $ENV{PERL_MM_USE_DEFAULT} = 1;
		$self->build_perl->script( qw(cpan App::cpanminus) );
	}
	$self->build_perl->script( qw(cpanm --notest), $_ ) for (
		# App::cpm
		'https://github.com/orbital-transfer/cpm.git@multi-worker-win32',
		# Parallel::Pipes
		'https://github.com/orbital-transfer/Parallel-Pipes.git@multi-worker-win32',
	);
	$self->build_perl->script( qw(cpanm --notest ExtUtils::MakeMaker Module::Build App::pmuninstall) );
	$self->build_perl->script( qw(cpanm --notest Win32::Process IO::Socket::SSL) );
}

method run( @command ) {
	$self->runner->system( Runnable->new(
		command => [ @command ],
		environment => $self->environment
	));
}

method pacman(@packages) {
	return unless @packages;
	$self->runner->system(
		Runnable->new(
			command => [ qw(pacman -S --needed --noconfirm), @packages ],
			environment => $self->environment,
		)
	);
}

method choco(@packages) {
	return unless @packages;
	$self->runner->system(
		Runnable->new(
			command => [ qw(choco install -y), @packages ],
			environment => $self->environment,
		)
	);
}

method install_packages($repo) {
	my @mingw_packages = @{ $repo->msys2_mingw64_get_packages };
	my @choco_packages = @{ $repo->chocolatey_get_packages };
	say STDERR "Installing repo native deps";
	$self->pacman(@mingw_packages);
	$self->choco(@choco_packages);
}

with qw(
	Orbital::Transfer::System::Role::Config
	Orbital::Transfer::System::Role::DefaultRunner
	Orbital::Payload::Environment::Perl::System::Role::Perl
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::Transfer::System::MSYS2 - System for MSYS2 + MinGW64 subsystem

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

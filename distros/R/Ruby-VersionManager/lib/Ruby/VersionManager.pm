package Ruby::VersionManager;

use 5.010;
use strict;
use feature 'say';
use warnings;
use autodie;

use Moo;
use YAML;
use LWP::UserAgent;
use HTTP::Request;
use LWP::Simple;
use File::Path;
use File::Spec;
use Cwd qw'abs_path cwd';

use Ruby::VersionManager::Gem;

has rootdir          => ( is => 'rw' );
has ruby_version     => ( is => 'rw' );
has major_version    => ( is => 'rw' );
has rubygems_version => ( is => 'rw' );
has available_rubies => ( is => 'rw' );
has agent_string     => ( is => 'rw' );
has archive_type     => ( is => 'rw' );
has gemset           => ( is => 'rw' );
has installed_rubies => ( is => 'rw' );
has version          => ( is => 'rw' );

our $VERSION = 0.004004;

sub BUILD {
	my ($self) = @_;

	$self->version($VERSION);

	$self->agent_string( 'Ruby::VersionManager/' . $self->version );
	$self->archive_type('.tar.bz2') unless $self->archive_type;
	$self->rootdir( abs_path( $self->rootdir ) ) if $self->rootdir;
	$self->_make_base or die;
	$self->_check_db  or die;
	$self->_check_installed;
	$self->gemset('default') unless $self->gemset;
}

sub _make_base {
	my ($self) = @_;

	$self->rootdir( File::Spec->catdir($ENV{'HOME'}, '.ruby_vmanager' )) unless $self->rootdir;

	if ( not -d $self->rootdir ) {
		say "root directory for installation not found.\nbootstraping to " . $self->rootdir;
		mkdir $self->rootdir;
		mkdir File::Spec->catdir($self->rootdir, 'bin');
		mkdir File::Spec->catdir($self->rootdir, 'source');
		mkdir File::Spec->catdir($self->rootdir, 'var');
		mkdir File::Spec->catdir($self->rootdir, 'gemsets');
		mkdir File::Spec->catdir($self->rootdir, 'rubies');
	}

	return 1;

}

sub _check_db {
	my ($self) = @_;

	$self->updatedb unless -f File::Spec->catfile($self->rootdir, 'var', 'db.yml');
	$self->available_rubies( YAML::LoadFile( File::Spec->catfile($self->rootdir, 'var', 'db.yml')));

}

sub _check_installed {
	my ($self) = @_;

	my $rubies         = {};
	my $checked_rubies = {};

	if ( -f File::Spec->catfile($self->rootdir, 'var', 'installed.yml' )) {
		$rubies = YAML::LoadFile( File::Spec->catfile($self->rootdir, 'var', 'installed.yml' ));
	}

	for my $major ( keys %$rubies ) {
		for my $ruby ( @{ $rubies->{$major} } ) {
			if ( -x File::Spec->catfile($self->rootdir, 'rubies', $major, $ruby, 'bin', 'ruby' )) {
				push @{ $checked_rubies->{$major} }, $ruby;
			}
		}
	}

	$self->installed_rubies($checked_rubies);

}

sub updatedb {
    no if $] >= 5.018, warnings => "experimental::smartmatch";
	my ($self) = @_;

	my @versions = qw( 1.8 1.9 2.0 2.1 );

	my $rubies = {};

	for my $version (@versions) {
		my $ruby_ftp = 'ftp://ftp.ruby-lang.org/pub/ruby/' . $version;
		my $req = HTTP::Request->new( GET => $ruby_ftp );

		my $ua = LWP::UserAgent->new;
		$ua->agent( $self->agent_string );

		my $res = $ua->request($req);

		if ( $res->is_success ) {
			$rubies->{$version} = [];
			for ( grep { $_ ~~ /ruby.*\.tar\.bz2/ } split '\n', $res->content ) {
				my $at = $self->archive_type;
				( my $ruby = $_ ) =~ s/(.*)$at/$1/;
				push @{ $rubies->{$version} }, ( split ' ', $ruby )[-1];
			}
		}
	}

	die "Did not get any data from ftp.ruby-lang.org" unless %$rubies;

	YAML::DumpFile( File::Spec->catfile($self->rootdir, 'var', 'db.yml'), $rubies );

	$self->_check_db;

}

sub uninstall {
	my ($self) = @_;

	return 0 unless $self->ruby_version;

	for my $major ( keys %{ $self->installed_rubies } ) {
		for my $ruby ( @{ $self->installed_rubies->{$major} } ) {
			if ( $ruby eq $self->ruby_version ) {
				$self->major_version($major);
				$self->_remove_ruby;
				$self->_remove_source;
				$self->_check_installed;
				$self->_update_installed;
			}
		}
	}

	return 1;
}

sub _remove_ruby {
	my ($self) = @_;

	my $dir_to_remove = File::Spec->catdir($self->rootdir, 'rubies', $self->major_version, $self->ruby_version);

	File::Path::rmtree($dir_to_remove) if -d $dir_to_remove;
}

sub _remove_source {
	my ($self) = @_;

	return 1;
}

sub list {
	my ($self) = @_;

	$self->_check_db or die;
	my %rubies    = %{ $self->available_rubies };
	my %installed = %{ $self->installed_rubies };

	say "Available ruby versions";
	for ( keys %rubies ) {
		say "\tVersion $_:";
		my @rubies = $self->_sort_rubies( $rubies{$_} );
		for (@rubies) {
			my $at = $self->archive_type;
			( my $ruby = $_ ) =~ s/(.*)$at/$1/;
			say "\t\t$ruby";
		}
	}

	say "Installed ruby versions";
	for ( keys %installed ) {
		say "\tVersion: $_";
		for ( @{ $installed{$_} } ) {
			say "\t\t$_";
		}
	}
}

sub gem {
	my ( $self, $action, @args ) = @_;

	my $gem = Ruby::VersionManager::Gem->new;
	$gem->run_action( $action, @args );

	return 1;
}

sub switch_gemset {
    no if $] >= 5.018, warnings => "experimental::smartmatch";
	my ($self, $gemset) = @_;

	if ($ENV{RUBY_VERSION} && $gemset){
		$self->ruby_version($ENV{RUBY_VERSION});
		( my $major_version = $self->ruby_version ) =~ s/ruby-(\d\.\d).*/$1/;
		$self->major_version($major_version);
		$self->_check_installed;

		my $installed = $self->installed_rubies->{$major_version};

		if ($self->ruby_version ~~ @$installed){
			$self->gemset($gemset);
			$self->_setup_environment;

			$self->_sub_shell;
		}
	}

	return 0;
}

sub gemsets {
    no if $] >= 5.018, warnings => "experimental::smartmatch";
	my $self = shift;

	my @gemsets = ();

	if ($ENV{RUBY_VERSION}) {
		$self->ruby_version($ENV{RUBY_VERSION});
		( my $major_version = $self->ruby_version ) =~ s/ruby-(\d\.\d).*/$1/;
		$self->major_version($major_version);
		$self->_check_installed;

		my $installed = $self->installed_rubies->{$major_version};

		if ($self->ruby_version ~~ @$installed){
			my $dir = File::Spec->catdir($self->rootdir, 'gemsets', $self->major_version, $self->ruby_version);
			opendir my $dh, $dir || die "Could not open $dir.";
			# filter . and .. and mark current gemset with a *
			@gemsets = map { $ENV{GEM_PATH} =~ /$_/ ? "$_ *" : $_ } grep { !/^\.\.?$/ } readdir $dh;
		}
	}

	return wantarray ? @gemsets : [@gemsets];
}

sub _sort_rubies {
	my ( $self, $rubies ) = @_;

	my @sorted = ();
	my $major_versions;

	for (@$rubies) {
		my ( undef, $major, $patchlevel ) = split '-', $_;
		$major_versions->{$major} = [] unless $major_versions->{$major};
        $patchlevel = 'x' if !defined($patchlevel);
		push @{ $major_versions->{$major} }, $patchlevel;
	}

	for my $version ( sort { $a cmp $b } keys %{$major_versions} ) {
		my @patchlevels = grep { defined $_ && $_ =~ /p\d{1,3}/ } @{ $major_versions->{$version} };
		my @pre         = grep { defined $_ && $_ =~ /preview\d{0,1}|rc\d{0,1}/ } @{ $major_versions->{$version} };
		my @old         = grep { defined $_ && $_ =~ /^\d/ } @{ $major_versions->{$version} };
		my @no_plevel   = grep { defined $_ && $_ =~ 'x' } @{ $major_versions->{$version} };

		my @numeric_levels;
		for my $level (@patchlevels) {
			( my $num = $level ) =~ s/p(\d+)/$1/;
			push @numeric_levels, $num;
		}

		@patchlevels = ();
		for ( sort { $a <=> $b } @numeric_levels ) {
			push @patchlevels, 'p' . $_;
		}

		for ( ( sort { $a cmp $b } @old ), @patchlevels, ( sort { $a cmp $b } @pre ) ) {
			push @sorted, "ruby-$version-$_";
		}

		for ( ( sort { $a cmp $b } @no_plevel ) ) {
			push @sorted, "ruby-$version";
		}
    }

	return @sorted;
}

sub _guess_version {
	my ($self) = @_;

	my @rubies      = ();
	my $req_version = $self->ruby_version;

	# 1.8 or 1.9?
	for my $major_version ( keys %{ $self->available_rubies } ) {
		if ( $req_version =~ /$major_version/ ) {
			for my $ruby ( @{ $self->available_rubies->{$major_version} } ) {
				if ( $ruby =~ /$req_version/ ) {

					my $at = $self->archive_type;
					( $ruby = $ruby ) =~ s/(.*)$at/$1/;

					if ( $ruby eq $req_version ) {
						push @rubies, $ruby;
						last;
					}
					elsif ( $ruby =~ /preview|rc\d?+/ ) {
						next;
					}

					push @rubies, $ruby;
				}
			}
		}
	}

	my $guess = ( $self->_sort_rubies( [@rubies] ) )[-1];

	if ( not $guess ) {
		say "No matching version found. Valid versions:";
		$self->list;

		exit 1;
	}

	return $guess;
}

sub install {
    no if $] >= 5.018, warnings => "experimental::smartmatch";
	my ($self) = @_;

	$self->ruby_version( $self->_guess_version );
	( my $major_version = $self->ruby_version ) =~ s/ruby-(\d\.\d).*/$1/;
	$self->major_version($major_version);

	my $ruby      = $self->ruby_version;
	my $installed = 0;
	$installed = 1 if join ' ', @{ $self->installed_rubies->{$major_version} } ~~ /$ruby/;

	if ( not $installed ) {
		$self->_fetch_ruby;
		$self->_unpack_ruby;
		$self->_make_install;
	}

	$self->_setup_environment;

	if ( not $installed ) {
		$self->_install_rubygems;
		push @{ $self->installed_rubies->{$major_version} }, $ruby unless $installed;
		$self->_update_installed;
	}

	$self->_sub_shell;
}

sub _update_installed {
	my ($self) = @_;

	YAML::DumpFile( File::Spec->catfile($self->rootdir, 'var', 'installed.yml'), $self->installed_rubies );

}

sub _unpack_ruby {
	my ($self) = @_;

	system 'tar xf ' . File::Spec->catfile($self->rootdir, 'source', $self->ruby_version . $self->archive_type) . ' -C  ' . File::Spec->catdir($self->rootdir, 'source');

	return 1;
}

sub _make_install {
	my ($self) = @_;

	my $prefix = File::Spec->catdir($self->rootdir, 'rubies', $self->major_version, $self->ruby_version);

	my $cwd = cwd();

	chdir File::Spec->catdir($self->rootdir, 'source', $self->ruby_version);

	# TODO make more portable
	# TODO make options depend on ruby version
	# TODO make silent
    my $cores = 1;
    my $nproc = `which nproc`;
    chomp $nproc;
    if (-x $nproc){
        $cores = `$nproc`;
        chomp $cores;
    }
	system "./configure --with-ssl --with-yaml --enable-ipv6 --enable-pthread --enable-shared --prefix=$prefix && make -j$cores && make install";

	chdir $cwd;

	return 1;
}

sub _setup_environment {
	my ($self) = @_;

	$ENV{PATH} = $self->_clean_path;

	$ENV{RUBY_VERSION} = $self->ruby_version;
	$ENV{GEM_PATH}     = File::Spec->catdir( abs_path( $self->rootdir ), 'gemsets', $self->major_version, $self->ruby_version, $self->gemset );
	$ENV{GEM_HOME}     = File::Spec->catdir( abs_path( $self->rootdir ), 'gemsets', $self->major_version, $self->ruby_version, $self->gemset );
	$ENV{MY_RUBY_HOME} = File::Spec->catdir( abs_path( $self->rootdir ), 'rubies', $self->major_version, $self->ruby_version );
	$ENV{PATH}         = File::Spec->catdir( abs_path( $self->rootdir ), 'rubies', $self->major_version, $self->ruby_version, 'bin' )
		. ':'
		. File::Spec->catdir( abs_path( $self->rootdir ), 'gemsets', $self->major_version, $self->ruby_version, $self->gemset, 'bin' )
		. ':'
		. $ENV{PATH};

	open my $rcfile, '>', File::Spec->catfile($self->rootdir, 'var', 'ruby_vmanager.rc');
	say $rcfile 'export RUBY_VERSION=' . $self->ruby_version;
	say $rcfile 'export GEM_PATH=' . $ENV{GEM_PATH};
	say $rcfile 'export GEM_HOME=' . $ENV{GEM_HOME};
	say $rcfile 'export MY_RUBY_HOME=' . $ENV{MY_RUBY_HOME};
	say $rcfile 'export PATH=' . File::Spec->catdir( abs_path( $self->rootdir ), 'rubies', $self->major_version, $self->ruby_version, 'bin' )
		. ':'
		. File::Spec->catdir( abs_path( $self->rootdir ), 'gemsets', $self->major_version, $self->ruby_version, $self->gemset, 'bin' )
		. ':'
		. $ENV{PATH};

	close $rcfile;

	return 1;
}

sub _clean_path {
	my $self = shift;
	my $rootdir = $self->rootdir;
	my $seen = {};
	my @path = grep {
		$seen->{$_}++;
		$seen->{$_} <= 1 && $_ !~ /$rootdir/
	} split ':', $ENV{PATH};

	return join ':', @path;
}

sub _sub_shell {
    # disable. find better way
    return
	my $self = shift;
	my $shell = $ENV{SHELL};

	if ($shell) {
		say "launching subshell with new settings.";
		exec($shell);
	}
}

sub _fetch_ruby {
	my ($self) = @_;

	my $url = 'ftp://ftp.ruby-lang.org/pub/ruby/' . $self->major_version . '/' . $self->ruby_version . $self->archive_type;

	my $file = File::Spec->catfile($self->rootdir, 'source', $self->ruby_version . $self->archive_type);

	if ( -f $file ) {
		return 1;
	}

	my $result = LWP::Simple::getstore( $url, $file );

	die if $result != 200;

	return 1;

}

sub _install_rubygems {
	my ($self) = @_;

	if ( -d File::Spec->catdir($self->rootdir, 'source', $self->ruby_version, 'bin') ) {
		my $source_bin_dir = File::Spec->catdir($self->rootdir, 'source', $self->ruby_version, 'bin');
		my $ruby_bin_dir   = File::Spec->catdir($ENV{MY_RUBY_HOME}, 'bin');
		system "cp $source_bin_dir/* $ruby_bin_dir";
	}

	unless ( -f $ENV{MY_RUBY_HOME} . '/bin/gem' ) {
		my $url  = 'http://rubyforge.org/frs/download.php/70696/rubygems-1.3.7.tgz';
		my $file = File::Spec->catfile($self->rootdir, 'source', 'rubygems-1.3.7.tgz');

		unless ( -f $file ) {
			my $result = LWP::Simple::getstore( $url, $file );
			die if $result != 200;
		}

		system 'tar xf ' . $file . ' -C ' . File::Spec->catdir($self->rootdir, 'source');

		my $cwd = cwd();

		chdir File::Spec->catdir($self->rootdir, 'source', 'rubygems-1.3.7');
		system 'ruby setup.rb';
	}

	return 1;
}

1;

__END__

=head1 NAME

Ruby::VersionManager

=head1 WARNING!

This is an unstable development release not ready for production!

=head1 VERSION

Version 0.004004

=head1 SYNOPSIS

The Ruby::VersionManager Module will provide a subset of the bash rvm.

Ruby::VersionManager comes with a script rvm.pl. See the perldoc of rvm.pl for a list of actions and options.

=head1 ATTRIBUTES

=head2 rootdir

Root directory for Ruby::VersionManager file structure.

=head2 ruby_version

The ruby version to install, check or remove.
Any String matching one of the major ruby versions is valid. Ruby::VersionManager will guess a version based on available versions matching the string. If multiple versions match the latest stable release will be used.
Preview and RC versions will never be installed automatically. You have to provide the full matching version string as shown with the list method.

=head2 gemset

Name your gemset. More sophisticated support for gemsets needs to be implemented.

=head2 gemsets

Returns an array of the created gemsets.

=head2 gem

Uses Ruby::VersionManager::Gem to pass arguments to the 'gem' command.
Additionally you can resemble gemsets from other users or machines by using reinstall with a file containing the output of 'gem list'. When omiting the file name the currently installed gemset will be completely reinstalled without pulling in any additional dependencies.

	$rvm->gem('reinstall', ($filename)); # install all gems given in the file
	$rvm->gem('reinstall');              # reinstall all gems from the currently used gemset

	$rvm->gem('install', ('unicorn', '-v=4.0.1));   # install unicorn. Same as 'gem install unicorn -v=4.0.1' on the command line

=head2 agent_string

The user agent used when downloading ruby.
Defaults to Ruby::VersionManager/0.004004.

=head2 archive_type

Type of the ruby archive to download.
Defaults to .tar.bz2, valid are also .tar.gz and .zip.

=head2 major_version

Will be automatically set.

=head2 rubygems_version

Not yet in use.

=head1 CONSTRUCTION

All attributes are optional at creation. Note that rootdir should be set at construction if you want another directory than default because Ruby::VersionManager->new will bootstrap the needed directories.

	my $rvm = Ruby:VersionManager->new;

Or

	my $rvm = Ruby:VersionManager->new(
		rootdir => '/path/to/root',
		ruby_version => '1.8',
		gemset => 'name_of_the_set',
	);


=head1 METHODS

=head2 available_rubies

Returns a hashref of the available ruby versions.

=head2 installed_rubies

Returns a hashref of the installed ruby versions.

=head2 list

Print a list of available and installed ruby versions to STDOUT.

	$rvm->list;

=head2 updatedb

Update database of available ruby versions.

	$rvm->updatedb;

=head2 install

Install a ruby version. If no version is given the latest stable release will be installed.
The program tries to guess the correct version from the provided string. It should at least match the major release.
If you need to install a preview or rc version you will have to provide the full exact version.

Latest ruby

	$rvm->ruby_version('1.9');
	$rvm->install;

Latest ruby-1.8

	$rvm->ruby_version('1.8');
	$rvm->install;

Install preview

	$rvm->ruby_version('ruby-1.9.3-preview1');
	$rvm->install;

=head2 uninstall

Remove a ruby version and the source dir including the downloaded archive.
You have to provide the full exact version of the ruby you want to remove as shown with list.

	$rvm->ruby_version('ruby-1.9.3-preview1');
	$rvm->uninstall;

=head2 switch_gemset

Update the environment to use another gem set for the corrently active ruby.

	$rvm->switch_gemset('another_set')

=head2 version

Returns the numerical version of the distribution.

	my $version = $rvm->version

=head1 LIMITATIONS

Currently Ruby::VersionManager is only tested to be running on Linux.

=head1 AUTHOR

Matthias Krull, C<< <m.krull at uninets.eu> >>

=head1 BUGS

Report bugs at:

=over 2

=item * Ruby::VersionManager issue tracker

L<https://github.com/uninets/p5-Ruby-VersionManager/issues>

=item * support at uninets.eu

C<< <m.krull at uninets.eu> >>

=back

=head1 SUPPORT

=over 2

=item * Technical support

C<< <m.krull at uninets.eu> >>

=back

=cut


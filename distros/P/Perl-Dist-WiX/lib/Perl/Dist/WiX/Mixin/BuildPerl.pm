package Perl::Dist::WiX::Mixin::BuildPerl;

=pod

=head1 NAME

Perl::Dist::WiX::Mixin::BuildPerl - 4th generation Win32 Perl distribution builder

=head1 VERSION

This document describes Perl::Dist::WiX::Mixin::BuildPerl version 1.500002.

=head1 DESCRIPTION

This module provides (most of) the routines that Perl::Dist::WiX uses in 
order to build Perl itself.  

=head1 SYNOPSIS

	# This module is not to be used independently.
	# It provides methods to be called on a Perl::Dist::WiX object.

=head1 INTERFACE

=cut

use 5.010;
use Moose;
use English qw( -no_match_vars );
use List::MoreUtils qw( any );
use Params::Util qw( _HASH _STRING _INSTANCE );
use Readonly qw( Readonly );
use Storable qw( retrieve );
use File::Spec::Functions qw(
  catdir catfile catpath tmpdir splitpath rel2abs curdir
);
use Module::CoreList 2.32 qw();
use Perl::Dist::WiX::Asset::Perl qw();
use Perl::Dist::WiX::Toolchain qw();
use File::List::Object qw();
use CPAN 1.9600 qw();

our $VERSION = '1.500002';
$VERSION =~ s/_//sm;

# Keys are what's in the filename, with - being converted to ::.
# Values are the actual module to use to check whether it's in core.
Readonly my %CORE_MODULE_FIX => (
	'IO::Compress'         => 'IO::Compress::Base',
	'Filter'               => 'Filter::Util::Call',
	'podlators'            => 'Pod::Man',
	'Text'                 => 'Text::Tabs',
	'PathTools'            => 'Cwd',
	'Scalar::List::Utils'  => 'List::Util',
	'Locale::Constants'    => 'Locale::Codes',
	'TermReadKey'          => 'Term::ReadKey',
	'Term::ReadLine::Perl' => 'Term::ReadLine',
	'libwww::perl'         => 'LWP',
	'LWP::UserAgent'       => 'LWP',
);

# Keys are the module name after processing against %CORE_MODULE_FIX.
# Values are the directory name the .packlist file is in, with
# / being converted to ::.
Readonly my %CORE_PACKLIST_FIX => (
	'IO::Compress::Base' => 'IO::Compress',
	'Pod::Man'           => 'Pod',
	'Filter::Util::Call' => 'Filter',
	'Locale::Maketext'   => 'Locale-Maketext',
);

# List of modules to delay building until last when upgrading all CPAN
# modules (they depend on upgraded versions of modules that originally
# were upgraded after them.)
Readonly my @MODULE_DELAY => qw(
  CPANPLUS::Dist::Build
  File::Fetch
  Thread::Queue
);



sub _delay_upgrade {
	my ( $self, $module ) = @_;

	return ( any { $module->id eq $_ } @MODULE_DELAY ) ? 1 : 0;
}



sub _module_fix {
	my ( $self, $module ) = @_;

	return ( exists $CORE_MODULE_FIX{$module} )
	  ? $CORE_MODULE_FIX{$module}
	  : $module;
}



sub _packlist_fix {
	my ( $self, $module ) = @_;

	return ( exists $CORE_PACKLIST_FIX{$module} )
	  ? $CORE_PACKLIST_FIX{$module}
	  : $module;
}

#####################################################################
# CPAN installation and upgrade support

# NOTE: "The object that called it" is supposed to be a Perl::Dist::WiX
# object.

=head2 install_cpan_upgrades

The C<install_cpan_upgrades> method is provided to upgrade all the
modules that were installed with Perl that were not upgraded by the
L<install_perl_toolchain|/install_perl_toolchain> subroutine.

Returns true or throws an exception.

This is recommended to be used as a task in the tasklist, and is in 
the default tasklist after the "perl toolchain" is installed.

=cut

sub _force_flag { ## no critic(UnusedPrivateSubroutines)
	shift;                             # We don't use $self.
	my $force = shift;
	return $force ? ( force => 1 ) : (),;
}

sub install_cpan_upgrades {
	my $self = shift;

	# Check for Perl - we can't do things out of order.
	if ( not $self->bin_perl() ) {
		PDWiX->throw(
			'Cannot install CPAN modules yet, perl is not installed');
	}

	my $sources_dir = $self->image_dir()->subdir(qw(cpan sources authors));
	if ( not -d $sources_dir ) {
		$self->make_path($sources_dir);
	}

	# Get list of modules to be upgraded.
	# (The list is saved as a Storable arrayref of CPAN::Module objects.)
	my $cpan_info_file = $self->_get_cpan_upgrades_list();
	my $module_info    = retrieve($cpan_info_file);
	my $default_force  = $self->force();

	# Now go through the loop for each module.
	my $force;
	my @delayed_modules;
  MODULE:

	for my $module ( @{$module_info} ) {

		# Skip modules that we want to skip.
		next MODULE if $self->_skip_upgrade($module);

		# If we're on the "delay this module" list, do so.
		if ( $self->_delay_upgrade($module) ) {
			unshift @delayed_modules, $module;
			next MODULE;
		}

		given ( $module->cpan_file() ) {

			when (m{/Net-Ping-\d}msx) {

				# Net::Ping seems to require that a web server be
				# available on localhost in order to pass tests.
				$self->_install_cpan_module( $module, 1 );
			}

			when (m{/Safe-\d}msx) {

				# Safe seems to have problems inside a build VM, but
				# not outside.  Forcing to be safe.
				$self->_install_cpan_module( $module, 1 );
			}

			when (m{/File-Fetch-\d}msx) {

				# File::Fetch is network-dependent.
				$self->_install_cpan_module( $module, $self->offline() );
			}

			when (m{/Locale-Maketext-Simple-0 [.] 20}msx) {

				# Locale::Maketext::Simple 0.20 has a test bug. Forcing.
				$self->_install_cpan_module( $module, 1 );
			}

			when (m{/Time-HiRes-}msx) {

				# Time-HiRes is timing-dependent, of course.
				$self->_install_cpan_module( $module, 1 );
			}

=for cmt
			# There's a problem with extracting these two files, so
			# upgrading to these versions, instead...
			## no critic(ProhibitUnusedCapture)
			when (
				m{Unicode-Collate-0 [.] (\d\d)
                   -withoutworldwriteables}msx
			  )
			{
				$self->install_distribution(
					name     => "SADAHIRO/Unicode-Collate-0.$1.tar.gz",
					mod_name => 'Unicode::Collate',
					$self->_install_location(1),
					$self->_force_flag($default_force),
				);
			} ## end when ( m{Unicode-Collate-0 [.] (\d\d) })

			when (
				/Unicode-Normalize-1 [.] (\d\d)-withoutworldwriteables/msx)
			{
				$self->install_distribution(
					name     => "SADAHIRO/Unicode-Normalize-1.$1.tar.gz",
					mod_name => 'Unicode::Normalize',
					$self->_install_location(1),
					$self->_force_flag($default_force),
				);
			}
=cut

			when (m{/ExtUtils-MakeMaker-\d}msx) {

   # Get rid of the old ExtUtils::MakeMaker files that were deleted in 6.50.
				$self->remove_file(
					qw{perl lib ExtUtils MakeMaker bytes.pm});
				$self->remove_file(
					qw{perl lib ExtUtils MakeMaker vmsish.pm});
				$self->_install_cpan_module( $module, $default_force );
			}

			when (m{/CGI [.] pm-\d}msx) {

				# New CGI.pm (3.46 and later) versions require FCGI.
				$self->install_modules(qw( FCGI ));
				$self->_install_cpan_module( $module, $default_force );
			}

			when (m{/\QDevel-DProf-20110228}msx) {

				#errors in tests, and this version does not contains
				#any useful changes
				#already patched in repository
				next
			}

			default {
				$self->_install_cpan_module( $module, $default_force );
			}
		} ## end given
	} ## end for my $module ( @{$module_info...})

	# NOW install delayed modules!
	for my $module (@delayed_modules) {
		$self->_install_cpan_module( $module, $default_force );
	}

	# Getting modules for autodie support installed.
	# Yes, I know that technically it's a core module with
	# non-core dependencies, and that's ugly. I've just got
	# to live with it.
	my $autodie_location = $self->file(qw(perl lib autodie.pm));

	if ( -e $autodie_location ) {
		$self->install_modules(qw( Win32::Process IPC::System::Simple ));
	}

	# Getting CPANPLUS config file installed.
	# (Since we're building 5.10.0+ only, it IS installed now.)
	$self->trace_line( 1,
		"Getting CPANPLUS config file ready for patching\n" );
	$self->patch_file(
		'perl/lib/CPANPLUS/Config.pm' => $self->image_dir(),
		{ dist => $self, } );

	# Install newest dev version of CPAN if we haven't already.
	if ( not $self->fragment_exists('CPAN') ) {
		$self->install_distribution(
			name             => 'ANDK/CPAN-1.9600.tar.gz',
			mod_name         => 'CPAN',
			makefilepl_param => ['INSTALLDIRS=perl'],
			buildpl_param    => [ '--installdirs', 'core' ],
		);
	}

	# Install version of Module::Build if we haven't already.
	if ( not $self->fragment_exists('Module_Build') ) {
		$self->install_distribution(
			name             => 'DAGOLDEN/Module-Build-0.3800.tar.gz',
			mod_name         => 'Module::Build',
			makefilepl_param => ['INSTALLDIRS=perl'],
			buildpl_param    => [ '--installdirs', 'core' ],
			force            => ( $self->image_dir() =~ /\AD:/ms ) ? 1 : 0,
		);
	}

	return $self;
} ## end sub install_cpan_upgrades

sub _get_cpan_upgrades_list {
	my $self = shift;

	# Get the CPAN url.
	my $url = $self->cpan()->as_string();

	# Generate the CPAN installation script
	my $cpan_string = <<"END_PERL";
print "Loading CPAN...\\n";
use CPAN 1.9600;
CPAN::HandleConfig->load unless \$CPAN::Config_loaded++;
\$CPAN::Config->{'urllist'} = [ '$url' ];
END_PERL
	$cpan_string .= <<'END_PERL';
print "Loading Storable...\n";
use Storable qw(nstore);

my ($module, %seen, %need, @toget);
	
my @modulelist = CPAN::Shell->expand('Module', '/./');

# Schwartzian transform from CPAN.pm.
my @expand;
@expand = map {
	$_->[1]
} sort {
	$b->[0] <=> $a->[0]
	||
	$a->[1]{ID} cmp $b->[1]{ID},
} map {
	[$_->_is_representative_module,
	 $_
	]
} @modulelist;

require Config;
my $vendorlib=$Config::Config{'installvendorlib'};
MODULE: for $module (@expand) {
	my $file = $module->cpan_file;
	
	# If there's no file to download, skip it.
	next MODULE unless defined $file;

	$file =~ s{^./../}{};
	my $latest  = $module->cpan_version;
	my $inst_file = $module->inst_file;
	my $have;
	my $next_MODULE;
	eval { # version.pm involved!
		if ($inst_file and $vendorlib ne substr($inst_file,0,length($vendorlib))) {
			$have = $module->inst_version;
			local $^W = 0;
			++$next_MODULE unless CPAN::Version->vgt($latest, $have);
			# to be pedantic we should probably say:
			#    && !($have eq "undef" && $latest ne "undef" && $latest gt "");
			# to catch the case where CPAN has a version 0 and we have a version undef
		} else {
		   ++$next_MODULE;
		}
	};

	next MODULE if $next_MODULE;
	
	if ($@) {
		next MODULE;
	}
	
	$seen{$file} ||= 0;
	next MODULE if $seen{$file}++;
	
	push @toget, $module;
	
	$need{$module->id}++;
}

unless (%need) {
	print "All modules are up to date\n";
}
	
END_PERL
	my $cpan_info_file = catfile( $self->output_dir(), 'cpan.info' );
	$cpan_string .= <<"END_PERL";
nstore \\\@toget, '$cpan_info_file';
print "Completed collecting information on all modules\\n";

exit 0;
END_PERL

	# Dump the CPAN script to a temp file and execute.
	$self->trace_line( 1, "Running upgrade of all modules\n" );
	my $cpan_file = catfile( $self->build_dir(), 'cpan_string.pl' );
  SCOPE: {
		my $CPAN_FILE;
		open $CPAN_FILE, '>', $cpan_file
		  or PDWiX->throw("CPAN script open failed: $OS_ERROR");
		print {$CPAN_FILE} $cpan_string
		  or PDWiX->throw("CPAN script print failed: $OS_ERROR");
		close $CPAN_FILE
		  or PDWiX->throw("CPAN script close failed: $OS_ERROR");
	}
	$self->execute_perl($cpan_file)
	  or PDWiX->throw('CPAN script execution failed');
	if ($CHILD_ERROR) {
		PDWiX->throw('Failure detected during cpan upgrade, stopping');
	}

	return $cpan_info_file;
} ## end sub _get_cpan_upgrades_list

sub _install_location {
	my ( $self, $core ) = @_;

	# Return the correct location information.
	my $vendor =
	    !$self->portable()                    ? 1
	  : ( $self->perl_major_version() >= 12 ) ? 1
	  :                                         0;

	if ($core) {
		return (
			makefilepl_param => ['INSTALLDIRS=perl'],
			buildpl_param    => [ '--installdirs', 'core' ],
		);
	} elsif ($vendor) {
		return (
			makefilepl_param => ['INSTALLDIRS=vendor'],
			buildpl_param    => [ '--installdirs', 'vendor' ],
		);
	} else {
		return (
			makefilepl_param => ['INSTALLDIRS=site'],
			buildpl_param    => [ '--installdirs', 'site' ],
		);
	}
} ## end sub _install_location



sub _install_cpan_module {
	my ( $self, $module, $force ) = @_;

	# Collect information.
	$force = $force or $self->force();
	my $perl_version = $self->perl_version_literal();
	my $module_id    = $self->_module_fix( $module->id() );
	my $module_file  = substr $module->cpan_file(), 5;
#<<<
	my $core =
	  exists $Module::CoreList::version{ $perl_version }{ $module_id }
	  ? 1
	  : 0;

	# Override core determination for this module.
	# (It's not in core, but other modules that this distribution
	# installs are)
	if ('Locale::Codes' eq $module_id) {
		$core = 1;
	}

	# Actually do the installation.
	$self->install_distribution(
		name     => $module_file,
		mod_name => $self->_packlist_fix($module_id),
		$self->_install_location($core),
		$force
		  ? ( force => 1 )
		  : (),
	);
#>>>
	return 1;
} ## end sub _install_cpan_module



sub _skip_upgrade {
	my ( $self, $module ) = @_;

	# DON'T try to install Perl at this point!
	return 1 if $module->cpan_file() =~ m{/perl-5 [.]}msx;

	# DON'T try to install Term::ReadKey, we
	# already upgraded it.
	return 1 if $module->id() eq 'Term::ReadKey';

	# DON'T try to install Win32API::Registry, we
	# already upgraded it as far as we can.
	return 1 if $module->id() eq 'Win32API::Registry';

	# If the ID is CGI::Carp, there's a bug in the index.
	return 1 if $module->id() eq 'CGI::Carp';

	# If the ID is ExtUtils::MakeMaker, we've already installed it.
	# There were some files gotten rid of after 6.50, so
	# install_cpan_upgrades thinks that it needs to upgrade
	# those files using it when using perl versions that
	# still had those files.

	# This code is in here for safety as of yet.
	return 1 if $module->cpan_file() =~ m{/ExtUtils-MakeMaker-6 [.] 50}msx;

	return 0;
} ## end sub _skip_upgrade



#####################################################################
# Perl installation support

=head2 install_perl

The C<install_perl> method is a minimal routine provided to call the 
C<_install_perl_plugin> routine (which the "perl version" plugins 
provide.)

Returns true or throws an exception.

This is recommended to be used as a task in the tasklist, and is in 
the default tasklist after the "c toolchain" is installed.

=cut

# Just hand off to the larger set of Perl install methods.
sub install_perl {
	my $self = shift;

	$self->_install_perl_plugin();

	# Should have a perl to use now.
	$self->_set_bin_perl( $self->file(qw/perl bin perl.exe/) );

	# Create the site/bin path so we can add it to the PATH.
	$self->make_path( $self->dir(qw(perl site bin)) );

	# Add to the environment variables
	$self->add_path(qw(perl site bin));
	$self->add_path(qw(perl bin));

	# Add the perllocal.pod to the perl fragment.
	$self->add_to_fragment( 'perl',
		[ $self->file(qw(perl lib perllocal.pod)) ] );

	return 1;
} ## end sub install_perl



sub _install_perl_plugin {
	return PDWiX::Unimplemented->throw();
}



sub _find_perl_file { ## no critic(ProhibitUnusedPrivateSubroutines)
	return undef; ## no critic(ProhibitExplicitReturnUndef)
}



# This routine is called by the _install_perl_plugin routines.
sub _create_perl_toolchain { ## no critic(ProhibitUnusedPrivateSubroutines)
	my $self = shift;
	my $cpan = $self->cpan();

	# Quick check for a nonexistent minicpan directory.
	if ( _INSTANCE( $cpan, 'URI::file' ) ) {
		if ( not -d $cpan->dir() ) {
			PDWiX::Directory->throw(
				message =>
				  'Directory referred to by CPAN url does not exist',
				dir => $cpan->dir() );
		}
	}

	# Prefetch and predelegate the toolchain so that it
	# fails early if there's a problem
	$self->trace_line( 1, "Pregenerating toolchain...\n" );
	my $force = {};
	if ( $self->perl_version =~ m/\A512/ms ) {
		$force = { 'Pod::Text' => 'RRA/podlators-2.4.0.tar.gz' };
	}
	if ( $self->perl_version eq '5140' ) {
		$force = { 'ExtUtils::MakeMaker' =>
			  'MSCHWERN/ExtUtils-MakeMaker-6.57_10.tar.gz' };
	}
	$force->{'LWP'} = 'GAAS/libwww-perl-5.837.tar.gz';

	#new version creates problems for https on 64 bit systems

	my $toolchain = Perl::Dist::WiX::Toolchain->new(
		perl_version => $self->perl_version_literal(),
		cpan         => $cpan->as_string(),
		bits         => $self->bits(),
		force        => $force,
	) or PDWiX->throw('Failed to resolve toolchain modules');
	if ( not eval { $toolchain->delegate(); 1; } ) {
		PDWiX::Caught->throw(
			message => 'Delegation error occured',
			info    => defined($EVAL_ERROR) ? $EVAL_ERROR : 'Unknown error',
		);
	}
	if ( defined $toolchain->get_error() ) {
		PDWiX::Caught->throw(
			message => 'Failed to generate toolchain distributions',
			info    => $toolchain->get_error() );
	}

	$self->_set_toolchain($toolchain);

	# Make the perl directory if it hasn't been made already.
	$self->make_path( $self->dir('perl') );

	return $toolchain;
} ## end sub _create_perl_toolchain



#####################################################################
# Perl Toolchain Support

=head2 install_perl_toolchain

The C<install_perl_toolchain> method is a routine provided to install the
"perl toolchain": the modules required for CPAN and CPANPLUS to be able to 
install modules.

Returns true (technically, the object that called it), or throws an exception.

This is recommended to be used as a task in the tasklist, and is in 
the default tasklist after the perl interpreter is installed.

=cut

sub install_perl_toolchain {
	my $self = shift;

	# Retrieves and verifies the toolchain.
	my $toolchain = $self->_get_toolchain();
	if ( 0 == $toolchain->dist_count() ) {
		PDWiX->throw('Toolchain did not get collected');
	}

	# Install the toolchain dists
	my ( $core, $module_id );
	my $perl_version  = $self->perl_version_literal();
	my $default_force = $self->force();
	foreach my $dist ( $toolchain->get_dists() ) {
		my $automated_testing = 0;
		my $release_testing   = 0;
		my $overwritable      = 0;
		my $force             = $default_force;
		given ($dist) {

			when (/Scalar-List-Util/msx) {

				# Does something weird with tainting
				$force = 1;
			}
			when (/ExtUtils-ParseXS/msx) {

		# TODO: remove this.
		# Testing using jkeenan-extutils-parsexs-use-strict-57-gdb2e0c7.zip,
		# then 'Build dist' from it, as downloaded from github.
#				$self->install_distribution_from_file(
#					file => File::ShareDir::dist_file('Perl-Dist-WiX', 'ExtUtils-ParseXS-3.tar.gz'),
#					mod_name => 'ExtUtils::ParseXS',
#					$self->_install_location(1),
#				);
#				next;
			} ## end when (/ExtUtils-ParseXS/msx)
			when (/URI-/msx) {

				# Can't rely on t/heuristic.t not finding a www.perl.bv
				# because some ISP's use DNS redirectors for unfindable
				# sites.
				$force = 1;
			}
			when (/Time-HiRes/msx) {

				# Tests are so timing-sensitive they fail on their own
				# sometimes.
				$force = 1;
			}
			when (/Term-ReadLine-Perl/msx) {

				# Does evil things when testing, and
				# so testing cannot be automated.
				$automated_testing = 1;
			}
			when (/TermReadKey-2 [.] 30/msx) {

				# Upgrading to this version, instead...
				$dist = 'STSI/TermReadKey-2.30.02.tar.gz';
			}
			when (/ExtUtils-MakeMaker-/msx) {

				# There are modules that overwrite portions of this one.
				$overwritable = 1;
			}
			when (/Win32API-Registry-/msx) {

				# This module needs forced on Vista
				# (and probably 2008/Win7 as well).
				$force = 1;
			}
			when (/IO-Compress-2 [.] 034/msx) {

				# This module needs forced - has a test bug.
				$force = 1;
			}
			when (/Win32-TieRegistry-/msx) {

				# This module needs forced on Vista
				# (and probably 2008/Win7 as well).
				$force = 1;
			}
			when (/Module-Build-/msx) {

				# Can't test on D-drive builds.
				$force ||= ( $self->image_dir() =~ /\AD:/ms ) ? 1 : 0;

			}
		} ## end given

		# Actually DO the installation, now
		# that we've got the information we need.
		$module_id = $self->_module_fix( $self->_name_to_module($dist) );
		$core =
		  exists $Module::CoreList::version{$perl_version}{$module_id}
		  ? 1
		  : 0;
#<<<
		$self->install_distribution(
			name              => $dist,
			mod_name          => $self->_packlist_fix($module_id),
			force             => $force,
			automated_testing => $automated_testing,
			release_testing   => $release_testing,
			overwritable      => $overwritable,
			$self->_install_location($core),
		);
#>>>
	} ## end foreach my $dist ( $toolchain...)

	return $self;
} ## end sub install_perl_toolchain



sub _name_to_module {
	my $self = shift;
	my $dist = shift;

	# Convert a distribution name with dashes to
	# a module name with double colons.
	$self->trace_line( 3, "Trying to get module name out of $dist\n" );
#<<<
	my ( $module ) = $dist =~ m{\A  # Start the string...
					[[:alpha:]/]*   # With a string of letters and slashes
					/               # followed by a forward slash. 
					(.*?)           # Then capture all characters, non-greedily 
					-\d*[.]         # up to a dash, a sequence of digits, and then a period.
					}smx;           # (i.e. starting a version number.)
#>>>
	$module =~ s{-}{::}msg;

	return $module;
} ## end sub _name_to_module

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2011 Curtis Jewell.

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut

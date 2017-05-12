package Perl::Dist::Padre;

#<<<
use 5.008001;
use strict;
use warnings;
use Perl::Dist::WiX          1.200002;
use Perl::Dist::Strawberry   2.10     qw();
use URI::file                         qw();
use English                           qw( -no_match_vars );
use File::Spec::Functions             qw( catfile catdir );
use parent                            qw( Perl::Dist::Strawberry );
#>>>

# http://www.dagolden.com/index.php/369/version-numbers-should-be-boring/
our $VERSION = '0.630';
$VERSION =~ s/_//ms;



######################################################################
# Configuration

sub new {
	my $dist_dir = File::ShareDir::dist_dir('Perl-Dist-Padre');

	return shift->SUPER::new(

		# Define the distribution information and where it goes.
		app_id            => 'padre',
		app_name          => 'Strawberry Perl plus Padre',
		app_ver_name      => 'Strawberry Perl 5.10.1.2 plus Padre 0.62',
		app_publisher     => 'Padre',
		app_publisher_url => 'http://padre.perlide.org/',
		image_dir         => 'C:\strawberry',

		# Set e-mail to something Padre-specific.
		perl_config_cf_email => 'padre-dev@perlide.org',

		# The MSI stuff.
		msi_product_icon => catfile( $dist_dir, 'padre.ico' ),
		msi_help_url     => undef,
		msi_banner_top   => catfile( $dist_dir, 'PadreBanner.bmp' ),
		msi_banner_side  => catfile( $dist_dir, 'PadreDialog.bmp' ),

		# Perl version
		perl_version => '5101',

		# Program version.
		build_number => 1,

		# Trace level.
		trace => 1,

		# Build both exe and zip versions.
		msi => 1,
		zip => 1,

		# These are the locations to pull down the msm.
		msm_to_use =>
'http://strawberryperl.com/download/strawberry-msm/strawberry-perl-5.10.1.2.msm',
		msm_zip =>
		  'http://strawberryperl.com/download/strawberry-perl-5.10.1.2.zip',
		msm_code => 'BC4B680E-4871-31E7-9883-3E2C74EA4F3C',

		# Tasks to complete to create Strawberry + Padre.
		tasklist => [
			'final_initialization',
			'initialize_using_msm',
			'install_padre_prereq_modules_1',
			'install_padre_prereq_modules_2',
			'install_padre_modules',
			'install_win32_extras',
			'install_strawberry_extras',
			'install_padre_extras',
			'remove_waste',
			'regenerate_fragments',
			'write',
		],

		# Other parameters passed in override the ones
		# here and in Strawberrry.
		@_,
	);

} ## end sub new



sub output_base_filename {
	return 'strawberry-plus-padre-0.63';
}



#####################################################################
# Customisations for Perl assets

sub install_perl_589 {
	my $self = shift;
	PDWiX->throw('Perl 5.8.9 is not available in Padre Standalone');
	return;
}



sub install_perl_5100 {
	my $self = shift;
	PDWiX->throw('Perl 5.10.0 is not available in Padre Standalone');
	return;
}



sub install_perl_5120 {
	my $self = shift;
	PDWiX->throw('Perl 5.12.0 is not available in Padre Standalone');
	return;
}



sub install_perl_5121 {
	my $self = shift;
	PDWiX->throw('Perl 5.12.1 is not available in Padre Standalone');
	return;
}



sub install_padre_prereq_modules_1 {
	my $self = shift;

	# Manually install our non-Wx dependencies first to isolate
	# them from the Wx problems
	$self->install_modules( qw{
		  File::Glob::Windows
		  File::Next
		  App::Ack
		  Class::Adapter
		  Class::Inspector
		  Class::Unload
		  AutoXS::Header
		  Class::XSAccessor
		  Devel::Dumpvar
		  File::Copy::Recursive
		  File::ShareDir
		  File::ShareDir::PAR
		  Test::Object
		  Config::Tiny
		  Test::ClassAPI
		  Clone
		  Hook::LexWrap
	} );

	return 1;
} ## end sub install_padre_prereq_modules_1



sub install_padre_prereq_modules_2 {
	my $self = shift;

# Manually install our non-Wx dependencies first to isolate
# them from the Wx problems
# NOTE: ORLite::Migrate goes after ORLite once they don't clone it privately.
# NOTE: Test::Exception goes before Test::Most when it's not in Strawberry.
	$self->install_modules( qw{
		  Test::SubCalls
		  List::MoreUtils
		  PPI
		  Module::Locate
		  Perl::Tags
		  Module::Refresh
		  Devel::Symdump
		  Pod::Coverage
		  Test::Pod::Coverage
		  Test::Pod
		  Module::Starter
		  ORLite
		  Test::Differences
		  Pod::POM
		  Parse::ErrorString::Perl
		  Text::FindIndent
		  Pod::Abstract
		  Devel::StackTrace
		  Class::Data::Inheritable
		  Exception::Class
		  Test::Most
		  Parse::ExuberantCTags
		  CPAN::Mini
		  Portable
		  Capture::Tiny
		  prefork
		  PPIx::EditorTools
		  Spiffy
		  Test::Base
		  ExtUtils::XSpp
		  Locale::Msgfmt
		  Module::ScanDeps
		  Module::Install
		  Format::Human::Bytes
		  Template::Tiny
		  Win32::Shortcut
		  Debug::Client
		  Devel::Refactor
		  App::cpanminus
		  POD2::Base
		  Readonly
		  Readonly::XS
		  PPIx::Regexp
		  UNIVERSAL::isa
		  UNIVERSAL::can
		  Test::MockObject
	} );

	return 1;
} ## end sub install_padre_prereq_modules_2



sub install_padre_modules {
	my $self = shift;

	## no critic(RestrictLongStrings)
	# Install the Alien::wxWidgets module from a precompiled .par
	my $par_url =
'http://strawberryperl.com/download/padre/Alien-wxWidgets-0.50-MSWin32-x86-multi-thread-5.10.1.par';
	my $filelist = $self->install_par(
		name => 'Alien_wxWidgets',
		url  => $par_url,
	);

	# Install the Wx module over the top of alien module
	$self->install_module( name => 'Wx' );

	# Install modules that add more Wx functionality
	$self->install_module(
		name  => 'Wx::Perl::ProcessStream',
		force => 1                     # since it fails on vista
	);

	# And finally, install Padre itself
	$self->install_module( name => 'Padre', );

	return 1;
} ## end sub install_padre_modules

sub install_padre_extras {
	my $self = shift;

	# Check that the padre.exe exists
	my $to = catfile( $self->image_dir(), 'perl', 'bin', 'padre.exe' );
	if ( not -f $to ) {
		PDWiX->throw(q{The "padre.exe" file does not exist});
	}

	# Get the Id for directory object that stores the filename passed in.
	my $dir_id = $self->get_directory_tree()->search_dir(
		path_to_find => catdir( $self->image_dir(), 'perl', 'bin' ),
		exact        => 1,
		descend      => 1,
	)->get_id();

	my $icon_id =
	  $self->_icons()
	  ->add_icon( catfile( $self->dist_dir(), 'padre.ico' ), 'padre.exe' );

	# Add the start menu icon.
	$self->get_fragment_object('StartMenuIcons')->add_shortcut(
		name => 'Padre',
		description =>
'Perl Application Development and Refactoring Environment - a Perl IDE',
		target      => "[D_$dir_id]padre.exe",
		id          => 'Padre',
		working_dir => $dir_id,
		icon_id     => $icon_id,
	);

	return 1;
} ## end sub install_padre_extras



sub dist_dir {
	my $self = shift;

	my $dir;

	if ( not eval { $dir = File::ShareDir::dist_dir('Perl-Dist-Padre'); 1; }
	  )
	{
		PDWiX::Caught->throw(
			message =>
			  'Could not find distribution directory for Perl::Dist::Padre',
			info => ( defined $EVAL_ERROR ) ? $EVAL_ERROR : 'Unknown error',
		);
	}

	return $dir;
} ## end sub dist_dir

1;                                     # Magic true value required at end of module

__END__

=pod

=begin readme text

Perl::Dist::Padre version 0.630

=end readme

=for readme stop

=head1 NAME

Perl::Dist::Padre - Strawberry + Padre for Win32 builder

=head1 VERSION

This document describes Perl::Dist::Padre version 0.630.

=for readme continue

=head1 DESCRIPTION

This is the distribution builder used to create Strawberry + Padre Standalone for Win32.

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

=end readme

=for readme stop

=head1 SYNOPSIS

	# This module is only used to build Strawberry + Padre. 
	# See below if you want to try it yourself.

=head2 Building Padre Standalone

Unlike Strawberry, Strawberry + Padre does not have a standalone build script.

To build Strawberry + Padre, run the following.

	perldist_w Padre

You may wish to view the BUILDING.txt file in the distribution for more 
information.

=head1 DIAGNOSTICS

The diagnostics that are specifically returned by this module are 
C<< PDWiX >> classes or subclasses ( subclasses of 
L<Exception::Class::Base|Exception::Class::Base>. )

=over

=item C<< Could not find distribution directory for Perl::Dist::Padre >>

L<File::ShareDir|File::ShareDir> could not find the share directory for this module.

(returned as a C<PDWiX::Caught> object.)

=item C<< Perl %s is not available in Padre Standalone >>

You can only build Padre Standalone on Perl 5.10.1.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Perl::Dist::Padre requires no configuration files or environment variables.

=for readme continue

=head1 DEPENDENCIES

Dependencies of this module that are non-core in perl 5.8.1 (which is the 
minimum version of Perl required) include 
L<Perl::Dist::Strawberry|Perl::Dist::Strawberry> version 2.02, 
L<URI::file|URI::file>, and L<parent|parent>.

=for readme stop

=head1 INCOMPATIBILITIES

This module cannot be used from a perl installed in C:\strawberry.

=head1 SUPPORT

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Padre>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-Padre@rt.cpan.orgE<gt> if you do not.

Please note that B<only> bugs in the distribution itself or the CPAN
configuration should be reported to RT. Bugs in individual modules
should be reported to their respective distributions.

For other issues not mentioned above, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt> and Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://csjewell.comyr.com/perl/>

=for readme continue

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Adam Kennedy and Curtis Jewell.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic> and L<perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=for readme stop

package Perl::Dist::WiX::Asset::Perl;

=pod

=head1 NAME

Perl::Dist::WiX::Asset::Perl - "Perl core" asset for a Win32 Perl

=head1 VERSION

This document describes Perl::Dist::WiX::Asset::Perl version 1.500002.

=head1 SYNOPSIS

  my $distribution = Perl::Dist::WiX::Asset::Perl->new(
    parent => $dist, # A Perl::Dist::WiX object.
    url    => 'http://strawberryperl.com/package/perl-5.10.1.tar.gz',
    patch  => [ qw{
        lib/CPAN/Config.pm
        win32/config.gc
        win32/config_sh.PL
        win32/config_H.gc
        }
    ],
    license => {
        'perl-5.10.1/Readme'   => 'perl/Readme',
        'perl-5.10.1/Artistic' => 'perl/Artistic',
        'perl-5.10.1/Copying'  => 'perl/Copying',
	},
  );

  $distribution->install();
  
=head1 DESCRIPTION

This asset downloads the Perl source code for a given version of Perl
and patches and installs it into a specified directory

=cut

#<<<
use 5.010;
use Moose;
use MooseX::Types::Moose   qw( Str HashRef ArrayRef Bool Maybe );
use File::Spec::Functions  qw( catdir splitpath rel2abs catfile );
use File::Basename         qw();
#>>>

our $VERSION = '1.500002';

with 'Perl::Dist::WiX::Role::Asset';

=head1 METHODS

This class is a L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>
and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new C<Perl::Dist::WiX::Asset::Perl> object.

It inherits all the parameters described in the 
L<< Perl::Dist::WiX::Role::Asset->new()|Perl::Dist::WiX::Role::Asset/new >> 
method documentation, and adds the additional parameters described below.

=head3 name

The C<name> parameter is the name of the package for the purposes of 
identification in messages.

This defauls to 'perl'.

=cut



has name => (
	is      => 'bare',
	isa     => Str,
	reader  => '_get_name',
	default => 'perl',
);




=head3 license

The required C<license> parameter allows you to specify which files get 
copied to the license directory of the distribution.

The keys are the files to copy, as relative filenames from the subdirectory
named in C<unpack_to>. (Git checkouts are copied to a directory named 
C<'perl-git'>, and that directory needs to be specified in the keys.)

The values are the locations to copy them to, relative to the license 
directory of the distribution.

=cut



has license => (
	is       => 'bare',
	isa      => HashRef,
	reader   => '_get_license',
	required => 1,
);



=head3 patch

The required C<patch> parameter allows you to specify which files get 
patched before the distribution is built.

These files will be passed to the routine C<_find_perl_file>, which will 
check the share directory of each plugin module(s) that was/were loaded
for the named file, and return the correct location. 

VERSION is 'git' for git checkouts.

The patch files can either have the names of original files (in which case 
the files are copied) or can have an additional extension of C<.tt> (in 
which case the files are processed through Template Toolkit, with the 
parameters described in 
L<< Perl::Dist::WiX->patch_file()|Perl::Dist::WiX::Mixin::Patching/patch_file >>.)

The makefile.mk is automatically patched and is not mentioned here.

=cut



has patch => (
	is       => 'bare',
	isa      => ArrayRef,
	reader   => '_get_patch',
	required => 1,
);



=head3 unpack_to

The optional C<unpack_to> parameter allows you to specify in which 
subdirectory of the build directory the tarball gets unpacked to or the
checkout gets copied to.

This defaults to 'perl'.

=cut



has unpack_to => (
	is      => 'bare',
	isa     => Str,
	reader  => '_get_unpack_to',
	default => 'perl',
);



=head3 install_to

The optional C<install_to> parameter allows you to specify in which 
subdirectory of the image directory the Perl distribution gets
installed to.

This defaults to 'perl'.

=cut



has install_to => (
	is      => 'ro',
	isa     => Str,
	reader  => '_get_install_to',
	default => 'perl',
);



=head3 force

The optional boolean C<force> param allows you to specify that the tests
should be skipped and Perl installed without validating it.

This defaults to true if either the force() or forceperl() attributes of 
the C<Perl::Dist::WiX> parent object are true.  Otherwise, it defaults to
false.

=cut



has force => (
	is      => 'bare',
	isa     => Bool,
	reader  => '_get_force',
	lazy    => 1,
	default => sub {
		$_[0]->_force() ? 1 : $_[0]->_forceperl() ? 1 : 0;
	},
);



=head3 git

The optional C<git> param specifies, if defined, that:

1) Perl is being built from a checkout directory, as opposed to a tarball, 
and

2) The "git describe" output is as specified in this parameter.

This defaults to undef, and needs to be specified for building a git 
checkout.

=cut



has git => (
	is      => 'bare',
	isa     => Maybe [Str],
	reader  => '_get_git',
	default => undef,
);



=head2 install

The install method installs the Perl distribution described by the
B<Perl::Dist::WiX::Asset::Perl> object and returns true or throws
an exception.

The C<install> method takes care of the detailed process
of building the Perl binary and installing it into the
distribution.

A short summary of the process would be that it downloads or otherwise
fetches the package that was named when the object is created, unpacks it, 
copies out any license files from the source code, then tweaks the Win32 
makefile to point to the specific build directory, and then runs 
make/make test/make install. 

Returns true (after 20 minutes or so) or throws an exception on
error.



=cut



sub install {
	my $self = shift;

	# Get the initial directory contents to compare against later.
	$self->_trace_line( 0, 'Preparing ' . $self->_get_name() . "\n" );
	my $fl2 = File::List::Object->new->readdir(
		catdir( $self->_get_image_dir, 'perl' ) );

	# Are we building from a git snapshot?
	my $git = $self->_get_git();

	# Download the perl tarball if needed.
	my $tgz;
	if ( not defined $git ) {

		# Download the file
		$tgz =
		  $self->_mirror( $self->_get_url(), $self->_get_download_dir(), );
	}

	# Prepare for building.
	my $unpack_to =
	  catdir( $self->_get_build_dir(), $self->_get_unpack_to() );
	if ( -d $unpack_to ) {
		$self->_trace_line( 2, "Removing previous $unpack_to\n" );
		File::Remove::remove( \1, $unpack_to );
	}

	my $perlsrc;
	if ( defined $git ) {

		# Copy to the build directory.
		$self->_copy(
			URI->new( $self->_get_url() )->file(),
			catdir( $unpack_to, 'perl-git' ) );
		$perlsrc = 'perl-git';
	} else {

		# Unpack to the build directory
		my @files = $self->_extract( $tgz, $unpack_to );

		# Get the versioned name of the directory
		( $perlsrc = $tgz ) =~
s{[.] tar[.] gz\z | [.] tgz\z | [.] tar[.] bz2\z | [.] tbz\z}{}msx;
		$perlsrc = File::Basename::basename($perlsrc);
	}

	# Pre-copy updated files over the top of the source
	my $patch   = $self->_get_patch();
	my $version = $self->_get_pv_human();
	if ($patch) {

		# Overwrite the appropriate files
		foreach my $file ( @{$patch} ) {
			$self->_patch_perl_file( $file => "$unpack_to\\$perlsrc" );
		}
	}

	# Copy in licenses
	if ( ref $self->_get_license() eq 'HASH' ) {
		my $licenses = $self->_get_license();
		my $license_dir = catdir( $self->_get_image_dir(), 'licenses' );
		if ( defined $git ) {
			foreach my $key ( keys %{$licenses} ) {
				$self->_copy( catfile( $unpack_to, $key ),
					catfile( $license_dir, $licenses->{$key} ) );
			}
		} else {
			$self->_extract_filemap( $tgz, $self->_get_license(),
				$license_dir, 1 );
		}
	} ## end if ( ref $self->_get_license...)

	# Build win32 perl
  SCOPE: {

		# Prepare to patch
		my $image_dir = $self->_get_image_dir();
		my $INST_TOP = catdir( $image_dir, $self->_get_install_to() );
		my ($INST_DRV) = splitpath( $INST_TOP, 1 );

		my $wd = $self->_pushd( $unpack_to, $perlsrc, 'win32' );

		# Patch the makefile.
		$self->_trace_line( 2, "Patching makefile.mk\n" );
		$self->_patch_perl_file(
			'win32/makefile.mk' => "$unpack_to\\$perlsrc",
			{   dist     => $self->_get_parent(),
				INST_DRV => $INST_DRV,
				INST_TOP => $INST_TOP,
			} );

		# Compile perl.
		$self->_trace_line( 1, "Building perl $version...\n" );
		$self->_make();

		# Get information required for testing and installing perl.
		my $force = $self->_get_force();
		my $long_build =
		  Win32::GetLongPathName( rel2abs( $self->_get_build_dir() ) );

		# Warn about problem with testing perl 5.10.0
		if (   ( not $force )
			&& ( $long_build =~ /\s/ms )
			&& ( $self->_get_pv_human() eq '5.10.0' ) )
		{
			$force = 1;
			$self->_trace_line( 0, <<"EOF");
***********************************************************
* Perl 5.10.0 cannot be tested at this point.
* Because the build directory
* $long_build
* contains spaces when it becomes a long name,
* testing the CPANPLUS module fails in 
* lib/CPANPLUS/t/15_CPANPLUS-Shell.t
* 
* You may wish to build perl within a directory
* that does not contain spaces by setting the build_dir
* (or temp_dir, which sets the build_dir indirectly if
* build_dir is not specified) parameter to new to a 
* directory that does not contain spaces.
*
* -- csjewell\@cpan.org
***********************************************************
EOF
		} ## end if ( ( not $force ) &&...)

		# Testing perl if requested.
		if ( not $force ) {
			local $ENV{PERL_SKIP_TTY_TEST} = 1;
			$self->_trace_line( 1, "Testing perl...\n" );
			$self->_make('test');
		}

		# Installing perl.
		$self->_trace_line( 1, "Installing perl...\n" );
		$self->_make(qw/install UNINST=1/);
	} ## end SCOPE:

	# If using gcc4, copy the helper dll into perl's bin directory.
	if ( 4 == $self->_gcc_version() ) {
		$self->_copy(
			catfile(
				$self->_get_image_dir(), 'c',
				'bin',                   'libgcc_s_sjlj-1.dll'
			),
			catfile(
				$self->_get_image_dir(), 'perl',
				'bin',                   'libgcc_s_sjlj-1.dll'
			),
		);
	} ## end if ( 4 == $self->_gcc_version...)

	# Delete a2p.exe if relocatable (Can't relocate a binary).
	if ( $self->_relocatable() ) {
		unlink catfile( $self->_get_image_dir(), 'perl', 'bin', 'a2p.exe' )
		  or PDWiX->throw("Could not delete a2p.exe\n");
	}

	# Create the perl_licenses fragment.
	my $fl_lic = File::List::Object->new()
	  ->readdir( catdir( $self->_get_image_dir(), 'licenses', 'perl' ) );
	$self->_insert_fragment( 'perl_licenses', $fl_lic );

	# Now create the perl fragment.
	my $fl = File::List::Object->new()
	  ->readdir( catdir( $self->_get_image_dir(), 'perl' ) );
	$fl->subtract($fl2)->filter( $self->_filters );
	$self->_insert_fragment( 'perl', $fl, 1 );

	return 1;
} ## end sub install

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>

=head1 COPYRIGHT

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

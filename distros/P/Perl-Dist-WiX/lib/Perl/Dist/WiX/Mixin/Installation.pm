package Perl::Dist::WiX::Mixin::Installation;

=pod

=head1 NAME

Perl::Dist::WiX::Mixin::Installation - Basic installation routines

=head1 VERSION

This document describes Perl::Dist::WiX::Mixin::Installation version 1.500.

=head1 DESCRIPTION

This module provides the routines that Perl::Dist::WiX uses in order to
install files.  

=head1 SYNOPSIS

	# This module is not to be used independently.
	# It provides methods to be called on a Perl::Dist::WiX object.

=head1 INTERFACE

=cut

use 5.010;
use Moose;
use Perl::Dist::WiX::Exceptions;
use Perl::Dist::WiX::Asset::Binary qw();
use Perl::Dist::WiX::Asset::Distribution qw();
use Perl::Dist::WiX::Asset::DistFile qw();
use Perl::Dist::WiX::Asset::File qw();
use Perl::Dist::WiX::Asset::Launcher qw();
use Perl::Dist::WiX::Asset::Library qw();
use Perl::Dist::WiX::Asset::Module qw();
use Perl::Dist::WiX::Asset::PAR qw();
use Perl::Dist::WiX::Asset::Website qw();

our $VERSION = '1.500';
$VERSION =~ s/_//ms;

=pod

=head2 install_binary

	$self->install_binary(
		name => 'gmp',
	);

The C<install_binary> method is used by library-specific methods to
install pre-compiled and un-modified tar.gz or zip archives into
the distribution.

Returns true or throws an exception on error.

=cut



sub install_binary {
	my $self   = shift;
	my $binary = Perl::Dist::WiX::Asset::Binary->new(
		parent     => $self,
		install_to => 'c',             # Default to the C dir
		@_,
	);

	my $filelist = $binary->install();

	return $filelist;
} ## end sub install_binary



=head2 install_library

  $self->install_library(
	  name => 'gmp',
  );

The C<install_library> method is used by library-specific methods to
install pre-compiled and un-modified tar.gz or zip archives into
the distribution.

Returns true or throws an exception on error.

=cut



sub install_library {
	my $self    = shift;
	my $library = Perl::Dist::WiX::Asset::Library->new(
		parent => $self,
		@_,
	);

	my $filelist = $library->install();

	return $filelist;
}



=pod

=head2 install_distribution

	$self->install_distribution(
	  name              => 'ADAMK/File-HomeDir-0.69.tar.gz,
	  force             => 1,
	  automated_testing => 1,
	  makefilepl_param  => [
		  'LIBDIR=' . File::Spec->catdir(
			  $self->image_dir, 'c', 'lib',
		  ),
	  ],
	);

The C<install_distribution> method is used to install a single
CPAN or non-CPAN distribution directly, without installing any of the
dependencies for that distribution.

It is used primarily during CPAN bootstrapping, to allow the
installation of the toolchain modules, with the distribution install
order precomputed or hard-coded.

It takes a compulsory 'name' param, which should be the AUTHOR/file
path within the CPAN mirror.

The optional 'force' param allows the installation of distributions
with spuriously failing test suites.

The optional 'automated_testing' param allows for installation
with the C<AUTOMATED_TESTING> environment flag enabled, which is
used to either run more-intensive testing, or to convince certain
Makefile.PLs that insist on prompting that there is no human around
and they REALLY need to just go with the default options.

The optional 'makefilepl_param' param should be a reference to an
array of additional params that should be passwd to the
C<perl Makefile.PL>. This can help with distributions that insist
on taking additional options via Makefile.PL.

Distributions that do not have a Makefile.PL cannot be installed via
this routine.

Returns true or throws an exception on error.

=cut



sub install_distribution {
	my $self = shift;
	my $dist = Perl::Dist::WiX::Asset::Distribution->new(
		parent => $self,
		@_,
	);

	$dist->install();

	return $self;
}



=pod

=head2 install_distribution_from_file

	$self->install_distribution_from_file(
	  file              => 'c:\distdir\File-HomeDir-0.69.tar.gz',
	  force             => 1,
	  automated_testing => 1,
	  makefilepl_param  => [
		  'LIBDIR=' . File::Spec->catdir(
			  $self->image_dir, 'c', 'lib',
		  ),
	  ],
	);

The C<install_distribution_from_file> method is used to install a single
CPAN or non-CPAN distribution directly, without installing any of the
dependencies for that distribution, from disk.

It takes a compulsory 'file' parameter, which should be the location of the
distribution on disk.

The optional 'force' parameter allows the installation of distributions
with spuriously failing test suites.

The optional 'automated_testing' parameter allows for installation
with the C<AUTOMATED_TESTING> environment flag enabled, which is
used to either run more-intensive testing, or to convince certain
Makefile.PL that insists on prompting that there is no human around
and they REALLY need to just go with the default options.

The optional 'makefilepl_param' param should be a reference to an
array of additional params that should be passed to the
C<perl Makefile.PL>. This can help with distributions that insist
on taking additional options via Makefile.PL.

The optional 'buildpl_param' parameter does the same thing as makefile_pl,
but for Build.PL instead of Makefile.PL.

Returns true or throws an exception on error.

=cut



sub install_distribution_from_file {
	my $self = shift;

	my $dist = Perl::Dist::WiX::Asset::DistFile->new(
		parent => $self,
		@_,
	);

	my $filelist = $dist->install();
	my $mod_id   = $dist->get_name();

	$mod_id =~ s{::}{_}msg;
	$mod_id =~ s{-}{_}msg;

	# Insert fragment.
	$self->insert_fragment( $mod_id, $filelist );

	return $self;
} ## end sub install_distribution_from_file



=pod

=head2 install_module

  $self->install_module(
	  name => 'DBI',
  );

The C<install_module> method is a high level installation method that can
be used during the C<install_perl_modules_*> phases, once the CPAN toolchain
has been been initialized.

It makes the installation call using the CPAN client directly, allowing
the CPAN client to both do the installation and fulfill all of the
dependencies for the module, identically to if it was installed from
the CPAN shell via an "install Module::Name" command.

The compulsory 'name' param should be the class name of the module to
be installed.

The optional 'force' param can be used to force the install of module.
This does not, however, force the installation of the dependencies of
the module.

The optional 'packlist' param should be 0 if a .packlist file is not 
installed with the module.

This does NOT install the dependencies of the module named - they have
to be installed before the named module, in one way or another.

Returns true or throws an exception on error.

=cut



sub install_module {
	my $self   = shift;
	my $module = Perl::Dist::WiX::Asset::Module->new(
		parent => $self,
		@_,
	);

	my $filelist = $module->install();
	my $name     = $module->get_name();
	my $feature  = $module->get_feature();

	# Make legal fragment id.
	$name =~ s{::}{_}gmsx;

	# Insert fragment.
	if ( 0 != scalar @{ $filelist->files } ) {
		$self->insert_fragment( $name, $filelist, 0, $feature );
	}

	return $self;
} ## end sub install_module



=pod

=head2 install_modules

  $self->install_modules( qw{
	  Foo::Bar
	  This::That
	  One::Two
  } );

  $self->install_modules( qw{
	  One::Two::Three
	  Test::One::Two::Three
  }, { force => 1 } );

The C<install_modules> method is a convenience shorthand that makes it
trivial to install a series of modules via C<install_module>.

As a convenience, any other parameters that are necessary for 
C<install_module> are applied to all modules, and must be specified via 
an optional hashref (not just hash pairing), as shown above.

=cut



sub install_modules {
	my $self = shift;
	my %args;

	if ( 'HASH' eq ref $_[-1] ) {
		%args = %{ pop @_ };
	}

	foreach my $name (@_) {
		$self->install_module(
			name => $name,
			%args
		);
	}

	return $self;
} ## end sub install_modules



=pod

=head2 install_par

The C<install_par> method extends the available installation options to
allow for the install of pre-compiled modules via "PAR" packages.

The compulsory 'name' param should be a simple identifying name, and does
not have any functional use other than determining the fragment name.

The compulsory 'uri' param should be a URL string to the PAR package.

Returns true on success or throws an exception on error.

=cut



sub install_par {
	my $self = shift;

	# Create Asset::Par object.
	my $par = Perl::Dist::WiX::Asset::PAR->new(
		parent => $self,

		# not supported at the moment:
		#install_to => 'c', # Default to the C dir
		@_,
	);

	my $filelist = $par->install();

	my $name = $par->get_name();
	$name =~ s{::}{_}msg;
	$name =~ s{-}{_}msg;

	$self->insert_fragment( $name, $filelist );

	return $self;
} ## end sub install_par



=pod

=head2 install_file

  # Overwrite the CPAN::Config
  $self->install_file(
	  share      => 'Perl-Dist CPAN_Config.pm',
	  install_to => 'perl/lib/CPAN/Config.pm',
  );
  
  # Install a custom icon file
  $self->install_file(
	  name       => 'Strawberry Perl Website Icon',
	  url        => 'http://strawberryperl.com/favicon.ico',
	  install_to => 'Strawberry Perl Website.ico',
  );

The C<install_file> method is used to install a single specific file from
various sources into the distribution.

It is generally used to overwrite modules with distribution-specific
customisations, or to install licenses, README files, or other
miscellaneous data files which don't need to be compiled or modified.

It takes a variety of different params.

The optional 'name' param provides an optional plain name for the file.
It does not have any functional purpose or meaning for this method.

One of several alternative source methods must be provided.

The 'url' method is used to provide a fully-resolved path to the
source file and should be a fully-resolved URL.

The 'file' method is used to provide a local path to the source file
on the local system, and should be a fully-resolved filesystem path.

The 'share' method is used to provide a path to a file installed as
part of a CPAN distribution, and accessed via 
L<File::ShareDir|File::ShareDir>.

It should be a string containing two space-separated values, the first
of which is the distribution name, and the second is the path within
the share dir of that distribution.

The final compulsory method is the 'install_to' method, which provides
either a destination file path, or alternatively a path to an existing
directory that the file be installed below, using its source file name.

Returns the file installed as a L<File::List::Object|File::List::Object> 
or throws an exception on error.

=cut



sub install_file {
	my $self = shift;
	my $file = Perl::Dist::WiX::Asset::File->new(
		parent => $self,
		@_,
	);

	my $filelist = $file->install();

	return $filelist;
}



=pod

=head2 install_launcher

  $self->install_launcher(
	  name => 'CPAN Client',
	  bin  => 'cpan',
  );

The C<install_launcher> method is used to describe a binary program
launcher that will be added to the Windows "Start" menu when the
distribution is installed.

It takes two compulsory parameters.

The compulsory 'name' param is the name of the launcher, and the text
that label will be displayed in the start menu (Currently this only
supports ASCII, and is not language-aware in any way).

The compulsory 'bin' param should be the name of a .bat script launcher
in the Perl bin directory. The program itself MUST be installed before
trying to add the launcher.

Returns true or throws an exception on error.

=cut



sub install_launcher {
	my $self     = shift;
	my $launcher = Perl::Dist::WiX::Asset::Launcher->new(
		parent => $self,
		@_,
	);

	$launcher->install();

	return $self;
}



=pod

=head2 install_website

  $self->install_website(
	  name       => 'Strawberry Perl Website',
	  url        => 'http://strawberryperl.com/',
	  icon_file  => 'Strawberry Perl Website.ico',
	  icon_index => 1,
  );

The C<install_website> param is used to install a "Start" menu entry
that will load a website using the default system browser.

The compulsory 'name' param should be the name of the website, and will
be the labelled displayed in the "Start" menu.

The compulsory 'url' param is the fully resolved URL for the website.

The optional 'icon_file' param should be the path to a file that contains the
icon for the website.

The optional 'icon_index' param should be the icon index within the icon file.
This param is optional even if the 'icon_file' param has been provided, by
default the first icon in the file will be used.

Returns true on success, or throws an exception on error.

=cut



sub install_website {
	my $self    = shift;
	my $website = Perl::Dist::WiX::Asset::Website->new(
		parent => $self,
		@_,
	);

	$website->install();

	return $self;
}

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

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut

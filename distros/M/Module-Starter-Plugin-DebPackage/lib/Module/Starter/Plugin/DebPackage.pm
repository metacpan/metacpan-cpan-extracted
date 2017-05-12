package Module::Starter::Plugin::DebPackage;

use base 'Module::Starter::Simple';

use warnings;
use strict;

use version; our $VERSION = qv('0.0.5');

use File::Path qw();
use File::Spec qw();
use POSIX qw(strftime);

# Overloaded to create a step after create_modules
sub create_modules {
  my ($self, @modules) = @_;

  $self->progress( "Calling SUPER::create_modules" );
  my @files = $self->SUPER::create_modules(@modules);

  $self->progress( "Calling extra step: create_debian_conf" );
  push @files, $self->create_debian_conf();

  return @files;
}

sub create_debian_conf {
  my ($self) = @_;
 
  my @files = ();

  # Define attributes used for deb conf files
  $self->{deb_pkg_name} = 'lib'
                        . lc( $self->{main_module} )
                        . '-perl';
  $self->{deb_pkg_name} =~ s/::/-/g;

  my @datestamp = localtime();
  $self->{deb_datestamp} = strftime( '%a, %d %b %Y %H:%M:%S %z', @datestamp );
  $self->{deb_year} = strftime( '%Y', @datestamp );

  # Create the debian directory
  my $deb_dir = File::Spec->catdir( $self->{basedir}, 'debian' );
  File::Path::mkpath( $deb_dir );

  # Create the compat file
  my $compat_file = File::Spec->catfile( $deb_dir, 'compat' );
  $self->create_file( $compat_file, $self->deb_compat_guts() );
  $self->progress("Created ${compat_file}");
  push @files, $compat_file;

  # Create the control file
  my $control_file = File::Spec->catfile( $deb_dir, 'control' );
  $self->create_file( $control_file, $self->deb_control_guts() );
  $self->progress("Created ${control_file}");
  push @files, $control_file;

  # Create the changelog file
  my $changelog_file = File::Spec->catfile( $deb_dir, 'changelog' );
  $self->create_file( $changelog_file, $self->deb_changelog_guts() );
  $self->progress("Created ${changelog_file}");
  push @files, $changelog_file;

  # Create the copyright file
  my $copyright_file = File::Spec->catfile( $deb_dir, 'copyright' );
  $self->create_file( $copyright_file, $self->deb_copyright_guts() );
  $self->progress("Created ${copyright_file}");
  push @files, $copyright_file;

  # Create the conffiles file
  my $conffiles_file = File::Spec->catfile( $deb_dir, 'conffiles' );
  $self->create_file( $conffiles_file, $self->deb_conffiles_guts() );
  $self->progress("Created ${conffiles_file}");
  push @files, $conffiles_file;

  # Create the rules file
  my $rules_file = File::Spec->catfile( $deb_dir, 'rules' );
  $self->create_file( $rules_file, $self->deb_rules_guts() );
  chmod 0755, $rules_file;
  $self->progress("Created ${rules_file}");
  push @files, $rules_file;

  return @files;
}

sub deb_compat_guts {
  my ($self) = @_;

  return <<"END_COMPAT_GUTS";
6
END_COMPAT_GUTS
}

sub deb_control_guts {
  my ($self) = @_;

  return <<"END_CONTROL_GUTS";
Source: $self->{deb_pkg_name}
Section: perl
Priority: optional
Build-Depends: debhelper (>= 6.0.0)
Build-Depends-Indep: perl
Maintainer: $self->{author} <$self->{email}>
Standards-Version: 3.7.2
Homepage: http://search.cpan.org/dist/$self->{distro}

Package: $self->{deb_pkg_name}
Architecture: all
Depends: \${perl:Depends}, \${misc:Depends}
Description: One-liner description of module
 One-liner description of module
 .
 Describe the module in detail here
 .
END_CONTROL_GUTS
}

sub deb_changelog_guts {
  my ($self) = @_;

  return <<"END_CHANGELOG_GUTS";
$self->{deb_pkg_name} (0.01) unstable; urgency=low

  * Initial Release.

 -- $self->{author} <$self->{email}>  $self->{deb_datestamp}
END_CHANGELOG_GUTS
}

sub deb_copyright_guts {
  my ($self) = @_;

  return <<"END_COPYRIGHT_GUTS";
This is the debian package for the $self->{main_module} module.
It was created by $self->{author} <$self->{email}> using module-starter
with the Module::Starter::Plugin::DebPackage plugin.

It was downloaded from http://search.cpan.org/dist/$self->{distro}

Copyright (C) $self->{deb_year} $self->{author} <$self->{email}>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

The author is: $self->{author} <$self->{email}>

The Debian packaging is (C) $self->{deb_year}, $self->{author} <$self->{email}> and
is licensed under the same terms as the software itself (see above).
END_COPYRIGHT_GUTS
}

sub deb_conffiles_guts {
  my ($self) = @_;

  # An empty file
  return '';
}

sub deb_rules_guts {
  my ($self) = @_;

  return <<'END_RULES_GUTS';
#!/usr/bin/make -f
# This debian/rules file is provided as a template for normal perl
# packages. It was created by Marc Brockschmidt <marc@dch-faq.de> for
# the Debian Perl Group (http://pkg-perl.alioth.debian.org/) but may
# be used freely wherever it is useful.

# Uncomment this to turn on verbose mode.
#export DH_VERBOSE=1

# If set to a true value then MakeMaker's prompt function will
# always return the default without waiting for user input.
export PERL_MM_USE_DEFAULT=1

PACKAGE=$(shell dh_listpackages)

ifndef PERL
PERL = /usr/bin/perl
endif

TMP     =$(CURDIR)/debian/$(PACKAGE)

build: build-stamp
build-stamp:
	dh_testdir

	# As this is a architecture independent package, we are not
	# supposed to install stuff to /usr/lib. MakeMaker creates
	# the dirs, we prevent this by setting the INSTALLVENDORARCH
	# and VENDORARCHEXP environment variables.

	# Add commands to compile the package here
	$(PERL) Makefile.PL INSTALLDIRS=vendor \
		INSTALLVENDORARCH=/usr/share/perl5/ \
		VENDORARCHEXP=/usr/share/perl5/
	$(MAKE)
	$(MAKE) test

	touch $@

clean:
	dh_testdir
	dh_testroot

	dh_clean build-stamp install-stamp

	# Add commands to clean up after the build process here
	[ ! -f Makefile ] || $(MAKE) realclean

install: install-stamp
install-stamp: build-stamp
	dh_testdir
	dh_testroot
	dh_clean -k

	# Add commands to install the package into debian/$PACKAGE_NAME here
	$(MAKE) install DESTDIR=$(TMP) PREFIX=/usr

	touch $@

binary-arch:
# We have nothing to do here for an architecture-independent package

binary-indep: build install
	dh_testdir
	dh_testroot
	dh_installexamples
	dh_installdocs README
	dh_installchangelogs Changes
	dh_perl
	dh_compress
	dh_fixperms
	dh_installdeb
	dh_gencontrol
	dh_md5sums
	dh_builddeb

source diff:
	@echo >&2 'source and diff are obsolete - use dpkg-source -b'; false

binary: binary-indep binary-arch
.PHONY: build clean binary-indep binary-arch binary
END_RULES_GUTS
}

=head1 NAME

Module::Starter::Plugin::DebPackage - Module::Starter plugin which creates debian package config files

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use Module::Starter qw(
    Module::Starter::Simple
    Module::Starter::Plugin::DebPackage
    );

  use Module::Starter::App;
  Module::Starter::App->run;

=head1 ABSTRACT

This is a plugin for L<Module::Starter> that includes a set of skeleton
debian package configuration files for the new module. Once the Makefile
is generated the package can be built using C<make deb>.

=head1 METHODS

=head2 create_modules

This method first executes C<SUPER::create_modules> and then creates
the debian config files by running C<create_debian_conf>.

=head2 create_debian_conf

Creates the debian config files.

This method is creates, populates (using the C<deb_*_guts> methods) and
reports progress for all files created by this plugin.

=head2 deb_compat_guts

Generate the contents for the compat file.

The compat version is important because the default version used by debhelper
is 1 which will generate a incomplete deb.

=head2 deb_control_guts

Generate the contents for the control file.

=head2 deb_changelog_guts

Generate the contents for the changelog file.

=head2 deb_copyright_guts

Generate the contents for the copyright file.

This is the normal perl license used by L<Module::Starter::Simple>.

=head2 deb_conffiles_guts

Generate the contents for the conffiles file.

This is an empty file - add any configuration files that should not be
overwritten during package updates.

=head2 deb_rules_guts

Generate the contents for the rules file.

=head1 AUTHOR

Bradley Dean, C<< <bjdean at bjdean.id.au> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-starter-plugin-debpackage at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Starter-Plugin-DebPackage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Starter::Plugin::DebPackage

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Starter-Plugin-DebPackage>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Starter-Plugin-DebPackage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Starter-Plugin-DebPackage>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Starter-Plugin-DebPackage/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Andy Lester, Ricardo Signes and C.J. Adams-Collier for
writing L<Module::Starter>.

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Bradley Dean.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Module::Starter::Plugin::DebPackage

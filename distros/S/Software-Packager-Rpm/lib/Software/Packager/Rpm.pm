################################################################################
# Name:		Software::Packager::RPM.pm
# Description:	This module is used to package software into Redhat's RPM
#		Package Format.
# Author:	Bernard Davison
# Contact:	rbdavison@cpan.org
#

package		Software::Packager::Rpm;

####################
# Standard Modules
use strict;
use File::Path;
use File::Copy;
use File::Basename;
use Cwd;
# Custom modules
use Software::Packager;
use Software::Packager::Object::Rpm;

####################
# Variables
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw( Software::Packager );
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = 0.06;

####################
# Functions

################################################################################
# Function:	new()
# Description:	This function creates and returns a new Packager object.
# Arguments:	none.
# Return:	new Packager object.
#
sub new
{
	my $class = shift;
	my $self = bless {}, $class;

	return $self;
}

################################################################################
# Function:	add_item()

=head2 B<add_item()>

 my %object_data = (
    'SOURCE' => '/source/file1',
    'TYPE' => 'file',
    'KIND' => 'doc',
    'DESTINATION' => '/usr/local/file1',
    'USER' => 'joe',
    'GROUP' => 'staff',
    'MODE' => 0750,
    );
 $packager->add_item(%object_data);

This method overrides the add_item method in Software::Packager. It adds the 
ability to add extra features used by RPM for each object in the package.

For more details see the documentation in:
Software::Packager
Software::Packager::Object::Rpm

=cut
sub add_item
{
	my $self = shift;
	my %data = @_;
	my $object = new Software::Packager::Object::Rpm(%data);

	return undef unless $object;

	# check that the object has a unique destination
	return undef if $self->{'OBJECTS'}->{$object->destination()};

	$self->{'OBJECTS'}->{$object->destination()} = $object;
}

################################################################################
# Function:	program_name()

=head2 B<program_name()>

 $packager->program_name('SoftwarePackager');
 my $program_name = $packager->program_name();

This method is used to set the name of the program that the package is
installing. This may in should be the same as the package name but that is 
not required.
It must not contain spaces or a dash "-" and must be all on one line.

=cut
sub program_name
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		if ($value =~ /\s|-|\n/)
		{
			warn "Warning: The program name passed contains invalid charaters. Removing them\n";
			$value =~ s/\s|-|\n//g;
		}
		$self->{'PROGRAM_NAME'} = $value;
	}
	else
	{
		return $self->{'PROGRAM_NAME'};
	}
}

################################################################################
# Function:	version()

=head2 B<version()>

 $packager->version(1.2.3.4.5.6);
 my $version = $packager->version();

This method sets the version for the package to the passed value.
The version passed cannot contain a dash "-" or spaces and must be on one line.

=cut
sub version
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		if ($value =~ /\s|-|\n/)
		{
			warn "Warning: The version passed contains invalid charaters. Removing them\n";
			$value =~ s/\s|-|\n//g;
		}
		$self->{'PACKAGE_VERSION'} = $value;
	}
	else
	{
		return $self->{'PACKAGE_VERSION'};
	}
}

################################################################################
# Function:	release()

=head2 B<release()>

This method sets the release version for the package.
The release is the number of times the package has been recreated.
If the release is not set then a default of 1 is used.
It cannot contain spaces, a dash or new lines.

=cut
sub release
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		if ($value =~ /\s|-|\n/)
		{
			warn "Warning: The release passed contains invalid charaters. Removing them\n";
			$value =~ s/\s|-|\n//g;
		}
		$self->{'RELEASE'} = $value;
	}
	else
	{
		unless ($self->{'RELEASE'})
		{
			$self->{'RELEASE'} = 1;
		}
		return $self->{'RELEASE'};
	}
}

################################################################################
# Function:	copyright()

=head2 B<copyright()>

This method sets the copyright type for the package.
This should be the name of the copyright 

=cut
sub copyright
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		if ($value =~ /\n/)
		{
			warn "Warning: The copyright contains new lines. Removing them\n";
			$value =~ s/\n//g;
		}
		$self->{'COPYRIGHT'} = $value;
	}
	else
	{
		return $self->{'COPYRIGHT'};
	}
}

################################################################################
# Function:	source()

=head2 B<source()>

This method sets the source location for the package. This should be the URL for
the source package used to create this package.

=cut
sub source
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'SOURCE'} = $value;
	}
	else
	{
		return $self->{'SOURCE'};
	}
}

################################################################################
# Function:	architecture()

=head2 B<architecture()>

 $packager->architecture("sparc");
 my $arch = $packager->architecture();

This method sets the architecture for the package to the passed value. If no
argument is passed then the current architecture is returned.
This is the output "from uname -p"

=cut
sub architecture
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
            $self->{'ARCHITECTURE'} = $value;
	}
	else
	{
		unless ($self->{'ARCHITECTURE'})
		{
			$self->{'ARCHITECTURE'} = `uname -m`;
			$self->{'ARCHITECTURE'} =~ s/\n//g;
		}
		return $self->{'ARCHITECTURE'};
	}
}

################################################################################
# Function:	package_name()

=head2 B<package_name()>

 my $name = $packager->package_name();
 
This method returns the name of the package that will be created.

=cut
sub package_name
{
	my $self = shift;
#	my $value = shift;

#	if ($value)
#	{
#		$self->{'PACKAGE_NAME'} = $value;
#	}
#	else
#	{
#		return $self->{'PACKAGE_NAME'};
#	}
	my $package_name = $self->program_name();
	$package_name .= "-";
	$package_name .= $self->version();
	$package_name .= "-";
	$package_name .= $self->release();
	$package_name .= ".";
	$package_name .= $self->architecture();
	$package_name .= ".rpm";

	return $package_name;
}

################################################################################
# Function:	short_description()

=head2 B<short_description()>

 $packager->short_description("This is a short description.");
 my $description = $packager->short_description();
 
The short description is just that a short description of the program.
It must be all on one line.

=cut
sub short_description
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		if ($value =~ /\n/)
		{
			warn "Warning: The short description contains new lines. Removing them\n";
			$value =~ s/\n//g;
		}
		$self->{'SHORT_DESCRIPTION'} = $value;
	}
	else
	{
		return $self->{'SHORT_DESCRIPTION'};
	}
}

################################################################################
# Extra documentation is added between here and the package method

=head2 B<description()>

 $packager->description("This is the description.");
 my $description = $packager->description();
 
The description method sets the package description to the passed value. If no
arguments are passed the package description is returned.

The discription can be of any length. It will be formatted by RPM in the 
following way:

=item *

If a line starts with a space it will be printed verbatim.

=item *

A blank line signifies a new paragraph.

=item *

All other lines will be assumed to be part of a paragraph and will be formatted 
by RPM. 

=cut

################################################################################
# Function:	package()

=head2 B<package()>

This method creates the package and returns true if it is successful else it
returns undef

=cut
sub package
{
	my $self = shift;

	return undef unless $self->_setup_in_tmp();
	return undef unless $self->_build_package();
	return undef unless $self->_cleanup();
	return 1;
}

################################################################################
# Function:	_setup_in_tmp
# DEscription:	This method sets up the package to before it is created
# Arguments:	None.
# Returns:	True on success else undef
#
sub _setup_in_tmp
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	
	unless (-d $tmp_dir)
	{
		mkpath("$tmp_dir", 0, 0755);
	}
	my $cwd = getcwd();
	chdir $tmp_dir;
	$tmp_dir = getcwd();
	rmtree($tmp_dir, 0, 0);
	$self->tmp_dir($tmp_dir);
	chdir $cwd;
	unless (-d $tmp_dir)
	{
		mkpath("$tmp_dir/BUILD", 0, 0755);
		mkpath("$tmp_dir/RPMS", 0, 0755);
		mkpath("$tmp_dir/SOURCES", 0, 0755);
		mkpath("$tmp_dir/SPECS", 0, 0755);
		mkpath("$tmp_dir/SRPMS", 0, 0755);
	}

	# create the rpmrc
	open (RPMRC, ">$tmp_dir/rpmrc") or
		die "Error: Cannot open $tmp_dir/rpmrc: $!\n";
	my $macrofiles = `grep macrofiles /usr/lib/rpm/rpmrc`;
	$macrofiles =~ s/\n//g;
	print RPMRC "$macrofiles:$tmp_dir/rpmmacros\n";
	close RPMRC;

	# create the rpmmacros
	open (RPMMACROS, ">$tmp_dir/rpmmacros") or
		die "Error: Cannot open $tmp_dir/rpmmacros: $!\n";
	print RPMMACROS "\%_topdir $tmp_dir\n";
	close RPMMACROS;

	# create the spec file
	open (SPEC , ">$tmp_dir/SPECS/package.spec") or
		die "Error: Cannot open $tmp_dir/SPECS/package.spec for writing: $!\n";

	print SPEC "Summary:" . $self->short_description() . "\n";
	print SPEC "Name:" . $self->program_name() . "\n";
	print SPEC "Version:" . $self->version() . "\n";
	print SPEC "Release:" . $self->release() . "\n";
	print SPEC "Copyright:" . $self->copyright() . "\n";
	print SPEC "Group:" . $self->category() . "\n";
	print SPEC "Source:" . $self->source() . "\n";
	print SPEC "URL:" . $self->homepage() . "\n";
	print SPEC "Vendor:" . $self->vendor() . "\n";
	print SPEC "Packager:" . $self->creator() . "\n";
	print SPEC "BuildRoot:$tmp_dir\n";
	print SPEC "Prefix:". $self->install_dir() . "\n" if $self->install_dir();
	print SPEC "\n";

	print SPEC "\%description\n" . $self->description() . "\n\n";

	# now copy everything to the tmp directory
	#print SPEC "\%prep\n\n";
	#print SPEC "\%build\n\n";
	#print SPEC "\%install\n\n";
	foreach my $object ($self->get_directory_objects())
	{
		my $directory = "$tmp_dir/" . $object->destination();
		mkpath($directory, 0, 0755);
	}
	foreach my $object ($self->get_file_objects())
	{
		my $source = $object->source();
		my $destination = "$tmp_dir/" . $object->destination();
		my $dir = dirname($destination);
		unless (-d $dir)
		{
			mkpath($dir, 0, 0755) or
				warn "Error: Problems were encountered creating directory \"$dir\": $!\n";
		}
		copy($source, $destination);
	}
	foreach my $object ($self->get_link_objects())
	{
		my $source = $object->source();
		my $destination = "$tmp_dir/" . $object->destination();
		my $type = $object->type();
		if ($type =~ /hard/i)
		{
			eval link "$source", "$destination";
			warn "Warning: Hard links not supported on this operatiing system: $@\n" if $@;
		}
		elsif ($type =~ /soft/i)
		{
			eval symlink "$source", "$destination";
			warn "Warning: Soft links not supported on this operatiing system: $@\n" if $@;
		}
		else
		{
			warn "Error: Not sure what type of link to create soft or hard.";
		}
	}

	# here is where we specify all the installable objects
	print SPEC "\%files\n";
	foreach my $object ($self->get_directory_objects(), $self->get_file_objects(), $self->get_link_objects())
	{
		my $destination = $object->destination();
		my $user = getpwuid($object->user());
		my $group = getgrgid($object->group());
		my $mode = $object->mode();
		print SPEC "\%attr($mode, $user, $group)";
		print SPEC " \%" . $object->kind() if $object->kind();
		print SPEC " /$destination\n"
	}

	close SPEC;

	return 1;
}

################################################################################
# Function:	_build_package
# Description:	This method builds the package and moves it to the output
#		 directory.
# Arguments:	None.
# Returns:	True on success else undef
#
sub _build_package
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	
	# build the package
	unless (system("rpm -bb --rcfile $tmp_dir/rpmrc $tmp_dir/SPECS/package.spec") == 0)
	{
		warn "Error: There were problems creating the package.\n";
	}

	# move the pacakge to the output directory
	my $package = "$tmp_dir/RPMS/" . $self->architecture();
	$package .= "/" . $self->package_name();
	my $output_dir = $self->output_dir();
	unless (move($package, $output_dir))
	{
		warn "Error: Couldn't move \"$package\" to \"$output_dir\"\n";
	}

	return 1;
}

################################################################################
# Function:	_cleanup
# Description:	This method cleans up the temp directory
# Arguments:	None.
# Returns:	True on success else undef
#
sub _cleanup
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	
	unless (system("chmod -R 0777 $tmp_dir") == 0)
	{
		warn "Warning: Couldn't change the permissions on $tmp_dir: $!\n";
	}
	return undef unless rmtree($tmp_dir, 0, 0);

	return 1;
}

1;
__END__

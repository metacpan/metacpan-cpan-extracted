=head1 NAME

Software::Packager::Solaris - The Software::Packager extension for Solaris 2.5.1 and above

=head1 SYNOPSIS

 use Software::Packager;
 my $packager = new Software::Packager('solaris');

=head1 DESCRIPTION

This module is used to create software packages in a format suitable for
installation with pkgadd.
The process of creating packages is baised upon the document 
Application Packaging Developer's Guide. Which can be found at
http://docs.sun.com/ab2/@LegacyPageView?toc=SUNWab_42_2:/safedir/space3/coll1/SUNWasup/toc/PACKINSTALL:Contents;bt=Application+Packaging+Developer%27s+Guide;ps=ps/SUNWab_42_2/PACKINSTALL/Contents

=head1 FUNCTIONS

=cut

package		Software::Packager::Solaris;

####################
# Standard Modules
use strict;
use File::Copy;
use File::Path;
use File::Basename;
use FileHandle 2.0;
#use Cwd;
# Custom modules
use Software::Packager;
use Software::Packager::Object::Solaris;

####################
# Variables
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw( Software::Packager );
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = 0.10;

####################
# Functions

################################################################################
# Function:	new()

=head2 B<new()>

This method creates and returns a new Software::Packager::Solaris object.

=cut

sub new
{
	my $class = shift;
	my $self = bless {}, $class;

	return $self;
}

################################################################################
# Function:	add_item()

=head2 B<add_item()>

 $packager->add_item(%object_data);
This method overrides the add_item function in the Software::Packager module.
This method adds a new object to the package.

=cut

sub add_item
{
	my $self = shift;
	my %data = @_;
	my $object = new Software::Packager::Object::Solaris(%data);

	return undef unless $object;

	# check that the object has a unique destination
	return undef if $self->{'OBJECTS'}->{$object->destination()};

	return 1 if $self->{'OBJECTS'}->{$object->destination()} = $object;
	return undef;
}

################################################################################
# Function:	package()

=head2 B<package()>

$packager->packager();
This method overrides the base API in Software::Packager, it controls the
process if package creation.

=cut

sub package
{
	my $self = shift;

	# setup the tmp structure
	return undef unless $self->_setup_in_tmp();

	# Create the package
	return undef unless $self->_create_package();

	# remove tmp structure
	return undef unless $self->_remove_tmp();

	return 1;
}

################################################################################
# Function:	package_name()

=head2 B<package_name()>

This method is used to specify the abbreviated package name.

Sun say: (Application Packaging Developer's Guide. Page 32)
A valid package abbreviation must the criteria defined below: 

=item *

It must start with a letter. Additional charaters may be alphanumeric and can
be the two special charaters + and -.

=item *

It must be nine or fewer charaters.

=item *

Reserved names are install, new, and all.

For more details see the pkginfo(4) man page.

=cut

sub package_name
{
	my $self = shift;
	my $name = shift;
	
	if ($name)
	{
		if ($name =~ /^(?![a-zA-Z])/)
		{
			warn "Warning: Package name \"$name\" does not start with a letter. Removing non letters from the start.\n";
			$name =~ s/^(.*?)(?=[a-zA-Z])(.*)/$2/;
		}
		if ($name !~ /[a-zA-Z0-9+-]!/)
		{
			warn "Warning: Package name \"$name\" contains charaters other that alphanumeric, + and -. Removing them.\n";
			$name =~ tr/a-zA-Z0-9+-//cd;
		}
		if (length $name > 9)
		{
			warn "Warning: Package name \"$name\" is longer than 9 charaters. Truncating to 9 charaters.\n";
			$name = sprintf("%.9s", $name);
		}
		if ($name =~ /^install$|^new$|^all$/)
		{
			warn "Warning: The package name $name is reserved.\n";
		}
		$self->{'PACKAGE_NAME'} = $name;
	}

	return $self->{'PACKAGE_NAME'};
}

################################################################################
# Function:	program_name()

=head2 B<program_name()>

This is used to specify the full package name.

The program name must be less that 256 charaters.

For more details see the pkginfo(4) man page.

=cut

sub program_name
{
	my $self = shift;
	my $name = shift;
	
	if ($name)
	{
		if (length $name > 256)
		{
			warn "Warning: Package name \"$name\" is longer than 256 charaters. Truncating to 256 charaters.\n";
			$name = sprintf("%.256s", $name);
		}
		$self->{'PROGRAM_NAME'} = $name;
	}

	return $self->{'PROGRAM_NAME'};
}

################################################################################
# Function:	architecture()

=head2 B<architecture()>

The architecture must be a comma seperated list of alphanumeric tokens that 
indicate the architecture associated with the package.
The maximum length of a token is 16 charaters.
A token should be in the format "instruction set"."platform group"
 where:
 instruction set is the output of `uname -p`
 platform group is the output of `uname -m`

If the architecture is not set then the current instruction set is used.

For more details see the pkginfo(4) man page.

=cut

sub architecture
{
	my $self = shift;
	my $name = shift;

	if ($name)
	{
		if ($name !~ /sparc|i386|ppc/)
		{
			warn "Warning: Archiecture does not include a Solaris-supported instruction set.\n";
		}
		if ($name !~ /sun4u|sun4d|sun4m|i86pc/)
		{
			warn "Warning: Architecture does not include a Solaris-supported platform group.\n";
		}
		foreach my $arch (split ',', $name)
		{
			if (length $arch > 16)
			{
				warn "Warning: The Architecture $arch is longer than 16 charaters. Truncating it.";
				$arch = sprintf("%.16s", $arch);
			}
		}

		$self->{'ARCHITECTURE'} = $name;
	}
	else
	{
		unless ($self->{'ARCHITECTURE'})
		{
			$self->{'ARCHITECTURE'} = `uname -p`;
			$self->{'ARCHITECTURE'} =~ s/\n//g;
		}
		return $self->{'ARCHITECTURE'};
	}
}

################################################################################
# Function:     version()

=head2 B<version()>

This method is used to check the format of the version and return it in the
format required for Solaris.

=item *

The version must be 256 charaters or less.

=item *

The first charater cannot be a left parenthesis.

The recommended format isi an arbitrary string of numbers in Dewey-decimal
format.
For more datails see the pkginfo(4) man page.

=cut

sub version
{
        my $self = shift;
        my $version = shift;
        if ($version)
        {
                if ($version =~ /^\(/)
                {
                        warn "Warning: The version starts with a left parenthesis. Removing it.\n";
			$version =~ s/^\(//;
                }
                if (length $version > 256)
                {
                        warn "Warning: The version is longer than 256 charaters. Truncating it.\n";
			$version = sprintf("%.256s", $version);
                }
                $self->{'PACKAGE_VERSION'} = $version;
        }

        return $self->{'PACKAGE_VERSION'};
}

################################################################################
# Function:	install_dir()

=head2 B<install_dir()>

 $packager->install_dir('/usr/local');
 my $base_dir = $packager->install_dir();
 
This method sets the base directory for the software to be installed.
The installation directory must start with a "/".
 
=cut

sub install_dir
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		if ($value !~ /^\//)
		{
			warn "Warning: The installation directory does not start with a \"/\". Prepending \"/\" to $value.";
			$value = "/" . $value;
		}
		$self->{'BASEDIR'} = $value;
	}
	else
	{
		return $self->{'BASEDIR'};
	}
}

################################################################################
# Function:	compatible_version()

=head2 B<compatible_version()>

 $packager->compatible_version('/some/path/file');
 or
 $packager->compatible_version($compver_stored_in_string);

 my $compatible_version = $packager->compatible_version();
 
This method sets the compatible versions file for the software to be installed.
 
=cut

sub compatible_version
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'COMPVER'} = $value;
	}
	else
	{
		return $self->{'COMPVER'};
	}
}

################################################################################
# Function:	space()

=head2 B<space()>

 $packager->space('/some/path/file');
 or
 $packager->space($space_data_stored_in_string);
 my $space = $packager->space();
 
This method sets the space file for the software to be installed.
 
=cut

sub space
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'SPACE'} = $value;
	}
	else
	{
		return $self->{'SPACE'};
	}
}

################################################################################
# Function:	request_script()

=head2 B<request_script()>

 $packager->request_script('/some/path/file');
 or
 $packager->request_script($request_script_stored_in_string);
 my $request_script = $packager->request_script();
 
This method sets the space file for the software to be installed.
 
=cut

sub request_script
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'REQUEST_SCRIPT'} = $value;
	}
	else
	{
		return $self->{'REQUEST_SCRIPT'};
	}
}

################################################################################
# Function:	_setup_in_tmp()
# Description:	This function sets up the temporary structure for the package.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub _setup_in_tmp
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	# process directories
	unless (-d $tmp_dir)
	{
		return undef unless mkpath($tmp_dir, 0, 0777);
	}

	# process files
	if ($self->license_file())
	{
		return undef unless copy($self->license_file(), "$tmp_dir/copyright");
	}

	return 1;
}

################################################################################
# Function:	create_package()
# Description:	This function creates the package
# Arguments:	none.
# Return:	true if ok else undef.
#
sub _create_package
{
	my $self = shift;

	# create the prototype file
	return undef unless $self->_create_prototype();

	# create the pkginfo file
	return undef unless $self->_create_pkginfo();

	# make the package
	return undef unless $self->_create_pkgmk();

	return 1;
}

################################################################################
# Function:	_remove_tmp()
# Description:	This function removes the temporary structure for the package.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub _remove_tmp
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	return undef unless system("chmod -R 0777 $tmp_dir") eq 0;
	rmtree($tmp_dir, 0, 1);
	return 1;
}

################################################################################
# Function:	_create_prototype()
# Description:	This function create the prototype file
# Arguments:	none.
# Return:	true if ok else undef.
#
sub _create_prototype
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	my $protofile = new FileHandle() or return undef;
	return undef unless $protofile->open(">$tmp_dir/prototype");

	$protofile->print("i pkginfo\n");
	$protofile->print("i copyright\n") if $self->license_file();

	# add the directories then files then links
	foreach my $object ($self->get_directory_objects(), $self->get_file_objects(), $self->get_link_objects())
	{
		$protofile->print($object->part(), " ");
		$protofile->print($object->prototype(), " ");
		$protofile->print($object->class(), " ");
		if ($object->prototype() =~ /[dx]/)
		{
			$protofile->print($object->destination(), " ");
		}
		else
		{
			$protofile->print($object->destination(), "=");
			$protofile->print($object->source(), " ");
		}
		$protofile->print($object->mode(), " ");
		$protofile->print($object->user(), " ");
		$protofile->print($object->group(), "\n");
	}

	return undef unless $protofile->close();
	return 1;
}

################################################################################
# Function:	_create_pkginfo()
# Description:	This function creates the pkginfo file
# Arguments:	none.
# Return:	true if ok else undef.
#
sub _create_pkginfo
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	my $protofile = new FileHandle() or return undef;
	return undef unless $protofile->open(">$tmp_dir/pkginfo");
	return undef unless $protofile->print("PKG=\"", $self->package_name(), "\"\n");
	return undef unless $protofile->print("NAME=\"", $self->program_name(), "\"\n");
	return undef unless $protofile->print("ARCH=\"", $self->architecture(), "\"\n");
	return undef unless $protofile->print("VERSION=\"", $self->version(), "\"\n");
	return undef unless $protofile->print("CATEGORY=\"", $self->category(), "\"\n");
	return undef unless $protofile->print("VENDOR=\"", $self->vendor(), "\"\n");
	return undef unless $protofile->print("EMAIL=\"", $self->email_contact(), "\"\n");
	return undef unless $protofile->print("PSTAMP=\"", $self->creator(), "\"\n");
	return undef unless $protofile->print("BASEDIR=\"", $self->install_dir(), "\"\n");
	return undef unless $protofile->print("CLASSES=\"none\"\n");
	return undef unless $protofile->close();

	return 1;
}

################################################################################
# Function:	_create_package()
# Description:	This function creates the package and puts it in the output
#		directory
# Arguments:	none.
# Return:	true if ok else undef.
#
sub _create_pkgmk
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $output_dir = $self->output_dir();
	my $name = $self->package_name();

	unless (-d $output_dir)
	{
		return undef unless mkpath($output_dir, 0, 0777);
	}

	return undef unless system("pkgmk -r / -d $output_dir -f $tmp_dir/prototype ") eq 0;
	#return undef unless system("pkgtrans -s /var/spool/pkg $output_dir/$name $name") eq 0;

	return 1;
}

1;
__END__

=head1 SEE ALSO

Software::Packager
Software::Packager::Object::Solaris

=head1 AUTHOR

R Bernard Davison <rbdavison@cpan.org>

Also, special mention should go to the following people who provided bug fixes

Krist van Besien

=head1 HOMEPAGE

http://bernard.gondwana.com.au

=head1 COPYRIGHT

Copyright (c) 2001 Gondwanatech. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut


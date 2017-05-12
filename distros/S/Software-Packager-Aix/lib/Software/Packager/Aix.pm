=head1 NAME

Software::Packager::Aix - The Software::Packager extension for AIX 4.1 and above

=head1 SYNOPSIS

 use Software::Packager;
 my $packager = new Software::Packager('aix');

=head1 DESCRIPTION

This module is used to create software packages in a Backup-format file (bff)
suitable for installation with installp.

This module creates packages for AIX 4.1 and higher only.
Due to the compatability requirements of Software::Packager multiple
components in the same package are not supported. This may be changed at some
point in the future.

This module is in part a baised on the workings of the lppbuild scripts. Where
possible I've worked from the standards, where I had no idea what they were
talking about I refered to the lppbuild scripts for an understanding. As such
I'd like to thank the writers of lppbuild version 2.1.
I believe these scripts to be written by Jim Abbey. Who ever it was thanks 
for your work. It has proven envaluable.
lppbuild is available from http://aixpdslib.seas.ucla.edu/

Please note that this module will eventually comply with the IBM documented
standard which can be found at

http://publibn.boulder.ibm.com/doc_link/en_US/a_doc_lib/aixprggd/genprogc/pkging_sw4_install.htm

=head1 FUNCTIONS

=cut

package		Software::Packager::Aix;

####################
# Standard Modules
use strict;
use File::Path;
use File::Copy;
use File::Basename;
use Cwd;
# Custom modules
use Software::Packager;
use Software::Packager::Object::Aix;

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

The method overrides the add_item method of Software::Packager to use
Software::Packager::Object::Aix.
For more details see the documentation in:

 Software::Packager
 Software::Packager::Object
 Software::Packager::Object::Aix

=cut
sub add_item
{
	my $self = shift;
	my %data = @_;
	
	# Hardlinks are associated with the file they refernce on AIX
	if ($data{'TYPE'} =~ /hardlink/i)
	{
		unless (exists $self->{'OBJECTS'}->{$data{'SOURCE'}})
		{
			warn "Error: Cannot add a hard link for $data{'DESTINATION'}\n";
			warn "       until the source object has been added to the package.\n";
			return undef;
		}
		$self->{'OBJECTS'}->{$data{'SOURCE'}}->links($data{'DESTINATION'});
		return 1;
	}

	my $object = new Software::Packager::Object::Aix(%data);

	return undef unless $object;

	# check that the object has a unique destination
	return undef if $self->{'OBJECTS'}->{$object->destination()};

	$self->{'OBJECTS'}->{$object->destination()} = $object;
}

################################################################################
# Function:	lpp_package_type()

=head2 B<lpp_package_type()>

This method sets or returns the lpp package type.
The lpp package types are
"I" for an install package
"ML" for a maintenance level package
"S" for a single update package

If the lpp package type is not set, the default of "I" for an install package is 
set (version minor and fix numbers are 0) and "S" for an update package 
(version minor and/or fix numbers are non 0)

=cut
sub lpp_package_type
{
	my $self = shift;
	my $value = shift;
	if ($value)
	{
	    $self->{'LPP_PACKAGE_TYPE'} = $value;
	}
	else
	{
	    if ($self->{'LPP_PACKAGE_TYPE'})
            {
                return $self->{'LPP_PACKAGE_TYPE'};
            }
            else
            {
                if ($self->_lppmode() eq 'I')
                {
                    return 'I';
                }
                else
                {
                    return 'S';
                }
            }
	}
}

################################################################################
# Function:	component_name()

=head2 B<component_name()>

 $packager->component_name($value);
 $component_name = $packager->component_name();

This method sets or returns the component name for this package.
The compoment name is a required value for AIX packages.

=cut
sub component_name
{
	my $self = shift;
	my $value = shift;
	if ($value)
	{
	    $self->{'PACKAGE_COMPONENT'} = $value;
	}
	else
	{
            return $self->{'PACKAGE_COMPONENT'};
        }
}

################################################################################
# Function:	package()

=head2 B<package()>

 $packager->package();

This method overrides the base API in Software::Packager.
it does all the nasty work of creating the package.

=cut
sub package
{
	my $self = shift;

        # Do some checks before we build.
        unless (scalar $self->program_name())
        {
                warn "Error: This package doesn't have the program name set. This is required.";
                return undef;
        }
        unless (scalar $self->component_name())
        {
                warn "Error: This package doesn't have the component name set. This is required.";
                return undef;
        }

	unless ($self->_setup())
	{
		warn "Error: Problems were encountered in the setup phase\n";
		return undef;
	}

	# Now create the final backup file format package.
	unless ($self->_create_bff())
	{
		warn "Error: Problems were encountered creating the backup format file: $!\n";
                return undef;
	}
        
	unless ($self->_cleanup())
	{
		warn "Error: Problems were encountered in the cleanup phase\n";
		return undef;
	}
	return 1;
}

################################################################################
# Function:	_setup()
# Description:	This method sets up the temporary build structure.
# Arguments:	None
# Returns:	True is all goes okay else undef
#
sub _setup
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	unless (-d $tmp_dir)
        {
		unless (mkpath($tmp_dir, 0, 0750))
		{
			warn "Error: Problems were encountered creating directory \"$tmp_dir\": $!\n";
			return undef;
		}
        }

	# determine if we have a root part. If so set up some new objects and
	# modify the objects that are not installed in /usr
	if ($self->_find_lpp_type() eq "B")
	{
		$self->_setup_for_root();
	}
	elsif ($self->_find_lpp_type() eq "U")
	{
		# This object is required for user parts
		my %data;
		$data{'TYPE'} = 'directory';
		$data{'MODE'} = '0755';
		$data{'DESTINATION'} = "/usr/lpp/" . $self->program_name();
		unless ($self->add_item(%data))
		{
			warn "Error: Couldn't add $data{'DESTINATION'} to the package.\n";
		}
	}
	elsif ($self->_find_lpp_type() eq "H")
	{
		# This object is required for share parts
		my %data;
		$data{'TYPE'} = 'directory';
		$data{'MODE'} = '0755';
		$data{'DESTINATION'} = "/usr/share/lpp/" . $self->program_name();
		unless ($self->add_item(%data))
		{
			warn "Error: Couldn't add $data{'DESTINATION'} to the package.\n";
		}
	}

	# Create the controls files and add them to the package.
	unless ($self->_create_control_files())
        {
		warn "Error: Problems were encountered creating the control files for the package: $!\n";
                return undef;
        }

        # create the package structure under the tmp_dir
	unless ($self->_create_package_structure())
        {
		warn "Error: Problems were encountered creating the package structure: $!\n";
                return undef;
        }

        # create the lpp_name file
	unless ($self->_create_lpp_name())
        {
		warn "Error: Problems were encountered creating the file lpp_name: $!\n";
                return undef;
        }

	return 1;
}

################################################################################
# Function:	_cleanup()
# Description:	This method cleans up after us.
# Arguments:	None
# Returns:	True is all goes okay else undef
#
sub _cleanup
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	# there has to be a better way to to this!
	system("chmod -R 0777 $tmp_dir 2>/dev/null");
	#rmtree($tmp_dir, 0, 1);

	return 1;
}

################################################################################
# Function:	version()

=head2 B<version()>

This method is used to set the version and return it in the correct format
required for AIX. 

Any invalid entries in the version will be automatically corrected and a
warning printed.

This is a excerpt from the standard.

The fileset level is referred to as the level or alternatively as the v.r.m.f or VRMF and has the form: 

Version.Release.ModificationLevel.FixLevel[.FixID] 

 Version		A numeric field of 1 to 2 digits that identifies the version number.  
 Release		A numeric field of 1 to 2 digits that identifies the release number.  
 ModificationLevel	A numeric field of 1 to 4 digits that identifies the modification level.  
 FixLevel		A numeric field of 1 to 4 digits that identifies the fix level.  
 FixID			A character field of 1 to 9 characters identifying the fix identifier.
 			The FixID is used by Version 3.2-formatted fileset updates only.  

A base fileset installation level is the full initial installation level of a fileset.
This level contains all files in the fileset, as opposed to a fileset update,
which may contain a subset of files from the full fileset. 

All filesets in a software package should have the same fileset level,
though it is not required for AIX Version 4.1-formatted packages. 

For all new levels of a fileset, the fileset level must increase.
The installp command uses the fileset level to check for a later level of the
product on subsequent installations. 

Fileset level precedence reads from left to right (for example, 3.2.0.0 is a
newer level than 2.3.0.0). 


Fileset Level Rules and Conventions for AIX Version 4.1-Formatted Filesets
The following conventions and rules have been put in place in order to simplify
the software maintenance for product developers and customers: 

A base fileset installation level should have a fix level of 0 (zero). 

A base fileset installation level package must contain the functionality
provided in other installation packages for that fileset with lower fileset
levels. For example, the Plan.Day level 2.1 fileset must contain the
functionality provided in the Plan.Day level 1.1 fileset. 

A fileset update must have either a non-zero modification level or a non-zero
fix level. 

A fileset update must have the same version and release numbers as the base
fileset installation level to which it is to be applied. 

Unless otherwise specified in the software package, a fileset update with a
non-zero fix level must be an update to the fileset with the same version
number, release number, and modification level and a zero fix level. Providing
information in the requisite section of the lpp_name file causes an exception to
this rule. 

Unless otherwise specified in the software package, a fileset update with a
non-zero modification level and a zero fix level must be an update to the
fileset with the same version number and release number and a zero modification
level. Providing information in the requisite section of the lpp_name file
causes an exception to this rule. 

A fileset update must contain the functionality of the fileset's previous
updates that apply to the same fileset level. 

=cut
sub version
{
	my $self = shift;
	my $version = shift;
        if (scalar $version)
        {
                if ($version !~ /^\d+(\.\d+){3,4}$/)
                {
                        warn "Warning: The version \"$version\" is not a 4 or 5 field Dewey-Decimal number. It will be modified.\n";
			$version =~ tr/0-9\.//cd;
                }
        	my ($major, $release, $mod, $fix, $fixid) = split /\./, $version;
        	# check that we have 4 parts if not then create them
        	$major = 0 unless $major;
        	$release = 0 unless $release;
        	$mod = 0 unless $mod;
        	$fix = 0 unless $fix;

        	# check that the major and release values are non zero.
        	$major = 1 if $major <= 0;
        	$release = 1 if $release <= 0;

		# Check that the version fields are the correct length.
		if (length $major > 2)
		{
			warn "Warning: The \"Version\" field of the version contains more than two charaters.\n";
			warn "         It will be truncated.\n";
			$major = sprintf("%.2s", $major);
		}
		if (length $release > 2)
		{
			warn "Warning: The \"Release\" field of the version contains more than two charaters.\n";
			warn "         It will be truncated.\n";
			$release = sprintf("%.2s", $release);
		}
		if (length $mod > 4)
		{
			warn "Warning: The \"ModificationLevel\" field of the version contains more than four charaters.\n";
			warn "         It will be truncated.\n";
			$mod = sprintf("%.4s", $mod);
		}
		if (length $fix > 4)
		{
			warn "Warning: The \"FixLevel\" field of the version contains more than four charaters.\n";
			warn "         It will be truncated.\n";
			$fix = sprintf("%.4s", $fix);
		}
		if ((defined $fixid) and (length $fixid > 9))
		{
			warn "Warning: The \"FixID\" field of the version contains more than nine charaters.\n";
			warn "         It will be truncated.\n";
			$fixid = sprintf("%.9s", $fixid);
		}

        	# set the lppmode
        	if (($mod eq 0) and ($fix eq 0))
        	{
			$self->_lppmode('I');
        	}
        	else
        	{
			$self->_lppmode('U');
        	}

        	$self->{'PACKAGE_VERSION'} = "$major.$release.$mod.$fix";
        	$self->{'PACKAGE_VERSION'} .= ".$fixid" if defined $fixid;
        }

	return $self->{'PACKAGE_VERSION'};
}

################################################################################
# Function:	_find_lpp_type()
# Description:	This method finds the type of LPP we are building.
#	If all components are under /usr/share then the part is a SHARE package.
#	If all components are under /usr then the part is a USER package.
#	If components are under any other directory then the part is a ROOT+USER
#	package.  
#	ROOT only parts are not permitted.
#	SHARE + ROOT and or USER parts are not permitted.
# Returns:	The LPP code for the part type on success and undef if there are
#		errors.
#		A USER part will return U.
#		A ROOT+USER part will return B
#		A SHARE part will return H
# Arguments:	None
#
sub _find_lpp_type
{
	my $self = shift;
	my $share = 0;
	my $user = 0;
	my $root = 0;

	# As this function may be slow to run only run it once.
	return $self->{'LPP_TYPE'} if scalar $self->{'LPP_TYPE'};

	foreach my $object ($self->get_object_list())
	{
		if ($object->lpp_type_is_share()){ $share++; next;};
		if ($object->lpp_type_is_user()){ $user++; next;};
		if ($object->lpp_type_is_root()){ $root++; next;};
	}

	if ($share and $user)
	{
		warn "Error: Packages with SHARE and USER parts are not permitted.\n";
		return undef;
	}
	elsif ($share and $root)
	{
		warn "Error: Packages with SHARE and ROOT parts are not permitted.\n";
		return undef;
	}
	elsif ($root)
	{
		$self->{'LPP_TYPE'} = 'B';
	}
	elsif ($user)
	{
		$self->{'LPP_TYPE'} = 'U';
	}
	elsif ($share)
	{
		$self->{'LPP_TYPE'} = 'H';
	}
	else
	{
		warn "Error: Package type could not be determined.\n";
		return undef;
	}
}

################################################################################
# Function:	_lppmode()
# Description:	This method sets or returns the lppmode.
#		The lppmode can be either install (I) or update (U).
#		This is set when the version is set.
# Argument:	The mode of the package.
# Returns:	The mode of the package if nothing is passed.
#
sub _lppmode
{
	my $self = shift;
	my $value = shift;
	if ($value)
	{
	    $self->{'LPPMODE'} = $value;
	}
	else
	{
	    return $self->{'LPPMODE'};
	}
}

################################################################################
# Function:	_create_lpp_name()
# Description:	This method creates the file lpp_name for the package.
# Argument:	None.
# Returns:	None.
#
sub _create_lpp_name
{
        my $self = shift;
        my $lpp_name_file = $self->tmp_dir() . "/lpp_name";
        open (LPPNAME, ">$lpp_name_file");

        print LPPNAME "4 R";
        print LPPNAME " " . $self->lpp_package_type();
        print LPPNAME " " . $self->program_name();
        print LPPNAME " {\n";

        print LPPNAME " " . $self->program_name() .".". $self->component_name();
        print LPPNAME " " . $self->version();

        # not sure what this is for. I'll have to check the specs.
        print LPPNAME " 1";

        if ($self->reboot_required())
        {
            print LPPNAME " b";
        }
        else
        {
            print LPPNAME " N";
        }
        print LPPNAME " " . $self->_find_lpp_type();

        print LPPNAME " en_US";
        print LPPNAME " ". $self->description() . "\n";
        print LPPNAME "[\n";

        if ($self->prerequisites())
        {
            # TODO:  This needs to be implemented.
        }
        print LPPNAME "\%\n";
        print LPPNAME $self->_find_disk_usage();

        # TODO:  need to implement page space.
        # TODO:  need to implement install space. (space required to extract crontrol files from liblpp.a
        # TODO:  need to implement save space.

        print LPPNAME "\%\n";
        
        # TODO:  need to implement supersede ability

        print LPPNAME "\%\n";

        # TODO:  need to implement fix information

        print LPPNAME "]\n";
        print LPPNAME "}\n";
        close LPPNAME;
}

################################################################################
# Function:	_find_disk_usage()
# Description:	This method finds the disk usage for the package directories.
# Arguments:	None.
# Returns:	The disk usage.
#
sub _find_disk_usage
{
    my $self = shift;
    my $dir = $self->tmp_dir();
    my $cwd = getcwd();
    chdir $dir;
    
    # find the directories
   my @directories = `find . ! -type d -exec dirname {} \\; | sort -u`;

    # find the disk usage
    my $usage;
    foreach my $dir (@directories)
    {
        chomp $dir;
        $dir = "./" if $dir eq ".";
        $usage .= `du -s $dir |awk '{print substr(\$2,2) " " \$1}'`;
    }

    chdir $cwd;
    return $usage;
}

################################################################################
# Function:	_create_package_structure()
# Description:	This method creates the package structure for the package under
#		the tmp directory.
# Arguments:	None.
# Returns:	None.
#
sub _create_package_structure
{
        my $self = shift;
        my $tmp_dir = $self->tmp_dir();

	my $lpp_type = $self->_find_lpp_type();
        foreach my $object ($self->get_object_list())
        {
		my $destination = "$tmp_dir". $object->destination();
                my $source = $object->source();
                my $type = $object->type();
                my $mode = $object->mode();
                my $user = $object->user();
                my $group = $object->group();

		if ($type =~ /directory/i)
		{
			unless (-d $destination)
                        {
                            mkpath($destination, 0, oct($mode));
                        }
                        unless (system("chown $user $destination") eq 0)
                        {
                            warn "Error: Couldn't set the user to \"$user\" for \"$destination\": $!\n";
                            return undef;
                        }
                        unless (system("chgrp $group $destination") eq 0)
                        {
                            warn "Error: Couldn't set the group to \"$group\" for \"$destination\": $!\n";
                            return undef;
                        }
		}
                elsif ($type =~ /file/i)
                {
                        my $directory = dirname($destination);
                        unless (-d $directory)
                        {
				mkpath($directory, 0, 0755);
                        }
                        unless (copy($source, $destination))
			{
				warn "Error: Couldn't copy $source to $destination: $!\n";
			}
                        unless (system("chown $user $destination") eq 0)
                        {
                            warn "Error: Couldn't set the user to \"$user\" for \"$destination\": $!\n";
                            return undef;
                        }
                        unless (system("chgrp $group $destination") eq 0)
                        {
                            warn "Error: Couldn't set the group to \"$group\" for \"$destination\": $!\n";
                            return undef;
                        }
                        unless (system("chmod $mode $destination") eq 0)
                        {
                            warn "Error: Couldn't set the mode to \"$mode\" for \"$destination\": $!\n";
                            return undef;
                        }
                }
                elsif ($type =~ /hard/i)
		{
                        unless (link $source, $destination)
                        {
                            warn "Error: Could not create hard link from $source to $destination:\n$!\n";
                            return undef;
                        }
                }
                elsif ($type =~ /soft/i)
		{
                        unless (symlink $source, $destination)
                        {
                                warn "Error: Could not create soft link from $source to $destination:\n$!\n";
                                return undef;
                        }
                }
                else
                {
                        warn "Warning: Don't know what type of object \"$destination\" is.\n";
                }
        }

	# Now we need to remove the user_liblpp.a and root_liblpp.a so that they
	# are not added to the space requirements in the file lpp_name
	unlink "$tmp_dir/user_liblpp.a";
	unlink "$tmp_dir/root_liblpp.a" if -f "$tmp_dir/root_liblpp.a";

        return 1;
}

################################################################################
# Function:	_create_control_files()
# Description:	This method creates the lpp control files (liblpp.a). as well as
#		creating the apply list and inventory which are essentially
#		required files.
#		check what sort of install we have.
#		A share install will only have one liblpp.a in
#		/usr/share/lpp/PROGRAM/liblpp.a
#		A user install will only have one liblpp.a in 
#		/usr/lpp/PROGRAM/liblpp.a
#		A root install will have two liblpp.a files in 
#		/usr/lpp/PROGRAM/liblpp.a and
#		/usr/lpp/PROGRAM../inst_root/liblpp.a
# Arguments:	None.
# Returns:	true on success else undef.
#
sub _create_control_files
{
	my $self = shift;
        my $tmp_dir = $self->tmp_dir();

	my $program_name = $self->program_name();
	my $component_name = $self->component_name();
	my $version = $self->version();

	my $liblpp_dir = "/usr";
	$liblpp_dir .= "/share/lpp" if $self->_find_lpp_type() eq 'H';
	$liblpp_dir .= "/lpp" if $self->_find_lpp_type() =~ /U|B/;
	$liblpp_dir .= "/$program_name";
	if ($self->_lppmode() eq "U")
	{
		$liblpp_dir .= "/$program_name";
		$liblpp_dir .= ".$component_name";
		$liblpp_dir .= "/$version";
	}
	my $liblpp_file = "$liblpp_dir/liblpp.a";
	my $root_liblpp_dir = "$liblpp_dir/inst_root" if $self->_find_lpp_type() =~ /B/;
	my $root_liblpp_file .= "$root_liblpp_dir/liblpp.a";
	
	# first create the ROOT liblpp.a file so it can be added to the USER
	# part if there is a ROOT part.
	my $applylist = "$program_name.$component_name.al";
	my $inventory = "$program_name.$component_name.inventory";

	my $control_dir = "$tmp_dir/control_files";
        unless (-d $control_dir)
        {
            mkpath($control_dir, 0, 0755);
        }

	if ($self->_find_lpp_type() eq "B")
	{
		open (AL, ">>$control_dir/$applylist");
		open (INV, ">>$control_dir/$inventory");
		foreach my $object ($self->get_directory_objects(), $self->get_file_objects(), $self->get_link_objects())
		{
			my $destination = $object->destination();
			my $source = $object->source();
	                my $owner = $object->user();
	                my $group = $object->group();
	                my $type = $object->type();
	                my $mode = $object->mode();
			my $inv_type = $object->inventory_type();
	
			next unless $destination =~ m#/inst_root/#;
	
			$destination =~ s#^$root_liblpp_dir##;
	
			# This is all that needs to be done for the apply list
			print AL ".$destination\n" unless $inv_type eq 'SYMLINK';
	
			print INV "$destination:\n";
			print INV "\tclass = apply,inventory,$program_name.$component_name\n";
			print INV "\towner = $owner\n";
			print INV "\tgroup = $group\n";
			print INV "\tmode = $mode\n";
			print INV "\ttype = $inv_type\n";
			if ($inv_type =~ /FILE/)
			{
				if ($type =~ /config|volatile/i)
				{
					print INV "\tsize = VOLATILE\n";
					print INV "\tchecksum = VOLATILE\n";
				}
				else
				{
					my @stats = stat($source);
					print INV "\tsize = $stats[7]\n";
	
					my $checksum = `sum $source`;
					chomp $checksum;
					$checksum =~ s/(\d+\s+\d+\s).*/$1/;
					print INV "\tchecksum = \"$checksum\"\n";
				}
			}
	               	my $links = $object->links();
			if (scalar $links)
			{
				print INV "\tlinks = $links\n";
			}
			if ($inv_type eq 'SYMLINK')
			{
				print INV "\ttarget = $source\n";
			}
			print INV "\n";
		}
		close AL;
		close INV;
	}

	# now archive all the control files
	# We need to do the root part first.
	opendir (DIR, "$control_dir") or die "Error: Cannot open temporary directory \"$control_dir\" for reading: $!\n";
	my @control_file_list = readdir DIR;
	closedir DIR;
	foreach my $file (@control_file_list)
	{
		next if $file =~ /^.$|^..$/;
		unless (system("ar -c -q $tmp_dir/root_liblpp.a $control_dir/$file") == 0)
		{
			warn "Warning: There were problems adding the control file $file to $tmp_dir/root_liblpp.a:\n$!";
			return undef;
		}
	}
	rmtree($control_dir, 0, 1);

	if (-f "$tmp_dir/root_liblpp.a")
	{
		# Add the root liblpp.a to the package if it exists
		my %data;
		$data{'TYPE'} = 'file';
		$data{'MODE'} = '0755';
		$data{'SOURCE'} = "$tmp_dir/root_liblpp.a";
		$data{'DESTINATION'} .= "$root_liblpp_file";
		unless ($self->add_item(%data))
		{
			warn "Error: Couldn't add $tmp_dir/root_liblpp.a to the package\n";
			return undef;
		}
	}

	# Now we need to add any directories for the root part that don't exist.
	# as they are required to be deployed in the USER part. seems weird to
	# me but that's how it is. (There is logic to madness sometimes though
	# hard to see.)
	$self->_add_objects_for_user_part();

	# Now create the USER or SHARE control files.
        unless (-d $control_dir)
        {
            mkpath($control_dir, 0, 0755);
        }

	open (AL, ">>$control_dir/$applylist");
	open (INV, ">>$control_dir/$inventory");
	foreach my $object ($self->get_directory_objects(), $self->get_file_objects(), $self->get_link_objects())
	{
		my $destination = $object->destination();
		my $source = $object->source();
                my $owner = $object->user();
                my $group = $object->group();
                my $type = $object->type();
                my $mode = $object->mode();
		my $inv_type = $object->inventory_type();

		# This is all that needs to be done for the apply list
		print AL ".$destination\n";
		# I'm not sure if we should be doing this here to. some more
		# testing is required to check this as the standard is not to
		# clear.
		#print AL ".$destination\n" unless $inv_type eq 'SYMLINK';

		# if there is a root part we don't need to set the inventory
		# data for it in the user part
		next if $destination =~ m#/usr/lpp#;

		print INV "$destination:\n";
		print INV "\tclass = apply,inventory,$program_name.$component_name\n";
		print INV "\towner = $owner\n";
		print INV "\tgroup = $group\n";
		print INV "\tmode = $mode\n";
		print INV "\ttype = $inv_type\n";
		if ($inv_type =~ /FILE/)
		{
			if ($type =~ /config|volatile/i)
			{
				print INV "\tsize = VOLATILE\n";
				print INV "\tchecksum = VOLATILE\n";
			}
			else
			{
				my @stats = stat($source);
				print INV "\tsize = $stats[7]\n";

				my $checksum = `sum $source`;
				chomp $checksum;
				$checksum =~ s/(\d+\s+\d+\s).*/$1/;
				print INV "\tchecksum = \"$checksum\"\n";
			}
		}
               	my $links = $object->links();
		if (scalar $links)
		{
			print INV "\tlinks = $links\n";
		}
		if ($inv_type eq 'SYMLINK')
		{
			print INV "\ttarget = $source\n";
		}
		print INV "\n";
	}
	close AL;
	close INV;

        # This is a list of possible config files that can be added to the liblpp.a archive.
        # TODO: need to make a method to set all of these files.
        #my @config_files = qw( cfginfo cfgfiles err fixdata namelist odmadd rm_inv trc config config_u odmdel pre_d pre_i pre_u pre_rm posti post_u unconfig unconfig_u unodmadd unport_i unpost_u unpre_i unpre_u copyright );

	# The copyright file is mandatory so create it if it not set
	if ($self->license_file())
	{
		return undef unless copy($self->license_file(), "$control_dir/$program_name.$component_name.copyright");
	}
	else
	{
		open(FILE, ">$control_dir/lpp.copyright");
		print FILE "No specific copyright in effect.\n";
		close FILE;
	}

	# this will print a message for the user that a reboot is required.
	if ($self->reboot_required())
	{
		open(FILE, ">$control_dir/$program_name.$component_name.cfginfo");
		print FILE "BOOT\n";
		close FILE;
	}

	# now archive all the control files
	# We need to do the root part first.
	opendir (DIR, "$control_dir") or die "Error: Cannot open temporary directory \"$control_dir\" for reading: $!\n";
	@control_file_list = readdir DIR;
	closedir DIR;
	foreach my $file (@control_file_list)
	{
		next if $file =~ /^.$|^..$/;
		unless (system("ar -c -q $tmp_dir/user_liblpp.a $control_dir/$file") == 0)
		{
			warn "Warning: There were problems adding the control file $file to $tmp_dir/user_liblpp.a:\n$!";
			return undef;
		}
	}
	rmtree($control_dir, 0, 1);

	if (-f "$tmp_dir/user_liblpp.a")
	{
		# Add the root liblpp.a to the package if it exists
		my %data;
		$data{'TYPE'} = 'file';
		$data{'MODE'} = '0755';
		$data{'SOURCE'} = "$tmp_dir/user_liblpp.a";
		$data{'DESTINATION'} .= "$liblpp_file";
		unless ($self->add_item(%data))
		{
			warn "Error: Couldn't add $tmp_dir/user_liblpp.a to the package\n";
			return undef;
		}
	}

	return 1;
}

################################################################################
# Function:	_create_bff()
# Description:	This finction creates the backup format file that is the actual
#		package.
# Arguments:	None.
# Returns:	True on success else undef.
#
sub _create_bff
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	my $cwd = getcwd();
	chdir $tmp_dir;

	my @files_to_backup = ('./lpp_name');
	foreach my $object ($self->get_directory_objects(), $self->get_file_objects(), $self->get_link_objects())
	{
		push @files_to_backup, ".".$object->destination();
	}

	open (FILE, ">./backup.list") or 
		warn "Error: Cannot open $tmp_dir/backup.list for writing: $!\n" and
		chdir $cwd and
		return undef;

	foreach my $file (@files_to_backup)
	{
		print FILE "$file\n";
	}
	close FILE;

	my $package_file = $self->output_dir();
	$package_file .= "/" . $self->package_name();
	$package_file .= ".bff";
	unless (system("backup -vi -q -f $package_file < ./backup.list") eq 0)
	{
		warn "Error: Failed to create the Backup-format file. $!\n";
		chdir $cwd;
		return undef;
	}
	
	chdir $cwd;

	return 1;
}

################################################################################
# Function:	_setup_for_root()
# Description:	This function creates a bunch of objects that need to be added
#		for the root portion of the package and modifies objects that
#		are not installed in /usr.
# Arguments:	None.
# Returns:	None but modifies the objects.
#
sub _setup_for_root
{
	my $self = shift;

	# create objects for the root portion of the package
	my %data;
	$data{'TYPE'} = 'directory';
	$data{'MODE'} = '0755';
	$data{'DESTINATION'} = "/usr/lpp/" . $self->program_name();
	unless ($self->add_item(%data))
	{
		warn "Error: Couldn't add $data{'DESTINATION'} to the package.\n";
	}

	if ($self->_lppmode() eq "U")
	{
		$data{'DESTINATION'} .= "/" . $self->program_name();
		$data{'DESTINATION'} .= "." . $self->component_name();
		unless ($self->add_item(%data))
		{
			warn "Error: Couldn't add $data{'DESTINATION'} to the package.\n";
		}
		$data{'DESTINATION'} .= "/" . $self->version();
		unless ($self->add_item(%data))
		{
			warn "Error: Couldn't add $data{'DESTINATION'} to the package.\n";
		}
	}

	$data{'DESTINATION'} .= "/inst_root";
	unless ($self->add_item(%data))
	{
		warn "Error: Couldn't add $data{'DESTINATION'} to the package.\n";
	}

	# modify all objects not installed under /usr
	foreach my $object ($self->get_object_list())
	{
		my $destination = $object->destination();
		next if $destination =~ m#^/usr#;
		my $new_destination = "/usr/lpp";
		$new_destination .= "/" . $self->program_name();
		if ($self->_lppmode() eq "U")
		{
			$new_destination .= "/" . $self->program_name();
			$new_destination .= "." . $self->component_name();
			$new_destination .= "/" . $self->version();
		}
		$new_destination .= "/inst_root$destination";
		unless ($object->destination($new_destination))
		{
			warn "Error: Couldn't change the installation destination from $destination to $new_destination\n";
		}
	}
}

################################################################################
# Function:	_add_objects_for_user_part()
# Description:	This function adds DIRECTORY objects for objects installed into
#		the ROOT part of the package. This is required so that the ROOT
#		objects are deployed correctly. Not that these objects should
#		not be part of the ROOT part. i.e. if you install a config file
#		in /etc you shouldn't be deploying the directory /etc as this is
#		part of the base operating system (bos).
#		We cannot just do a find here as we haven't created the
#		directory structure yet.
# Arguments:	None.
# Returns:	true on success else undef.
#
sub _add_objects_for_user_part
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	my $root_dir = "/usr/lpp";
	$root_dir .= "/". $self->program_name();
	if ($self->_lppmode() eq "U")
	{
		$root_dir .= "/". $self->program_name();
		$root_dir .= ".". $self->component_name();
		$root_dir .= "/". $self->version();
	}
	$root_dir .= "/inst_root";

	# find a list of objects that are installed in the root part.
	my %destinations;
	foreach my $object ($self->get_object_list())
	{
		my $destination = $object->destination();
		next unless $destination =~ m#$root_dir/#;
		next if $destination =~ m#$root_dir/liblpp.a#;
		$destinations{$destination}++;
	}

	foreach my $destination (sort keys %destinations)
	{
		my $directory = dirname($destination);
		while ($directory !~ m#^$root_dir$#)
		{
			unless (exists $destinations{$directory})
			{
				my %data;
				$data{'TYPE'} = 'directory';
				$data{'MODE'} = '0755';
				$data{'DESTINATION'} = "$directory";
				unless ($self->add_item(%data))
				{
					warn "Error: Couldn't add $data{'DESTINATION'} to the package.\n";
				}
				$destinations{$directory}++;
			}

			$directory = dirname($directory);
		}
	}

	return 1;
}

1;
__END__

=head1 SEE ALSO

 Software::Packager

=head1 AUTHOR

R Bernard Davison E<lt>rbdavison@cpan.orgE<gt>

=head1 HOMEPAGE

http://bernard.gondwana.com.au

=head1 COPYRIGHT

Copyright (c) 2001 Gondwanatech. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut


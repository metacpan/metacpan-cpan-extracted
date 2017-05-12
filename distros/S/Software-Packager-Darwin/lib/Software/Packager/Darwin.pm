=head1 NAME

Software::Packager::Darwin - The Software::Packager extension for MacOS X

=head1 DESCRIPTION

 This module is a sub class of Software::Packager. It is used to create MacOS X
 software packages for installation using the Installer application.

 Note: I haven't managed to find to much information on the full format of 
 MacOS X packages so this module trys to mimic what the PackageMaker.app 
 program does and what is contains in packages from Apple. presumably they are
 using many of the features that PackageMaker doesn't provide.

=cut

package		Software::Packager::Darwin;

####################
# Standard Modules
use strict;
use File::Copy;
use File::Path;
use File::Basename;
use FileHandle 2.0;
# Custom modules
use Software::Packager;

####################
# Variables
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw( Software::Packager );
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = 0.08;

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
# Function:	package()

=head2 B<package()>

 This method overrides the base API from Software::Packager. This method does
 all the dirty work of creating the software package for MacOS X.

=cut
sub package
{
	my $self = shift;

	# setup the tmp structure
	unless ($self->setup())
	{
		warn "Error: Problems were encountered in the setup phase.\n";
		return undef;
	}

	# create the pax file
	unless ($self->create_package())
	{
		warn "Error: Problems were encountered in the package creation phase.\n";
		return undef;
	}

	# remove tmp structure
	unless ($self->cleanup())
	{
		warn "Error: Problems were encountered in the cleanup phase.\n";
		return undef;
	}

	return 1;
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
# Function:	setup()

=head2 B<setup()>

 This method creates the temporary package structure in preparation for the
 package creation phase

=cut
sub setup
{
	my $self = shift;

	# process directories
	unless ($self->process_directories())
	{
		warn "Error: Processing of the directory objects failed.\n";
		return undef;
	}

	# process files
	unless ($self->process_files())
	{
		warn "Error: Processing of the file objects failed.\n";
		return undef;
	}

	# process links
	unless ($self->process_links())
	{
		warn "Error: Processing of the link objects failed.\n";
		return undef;
	}

	# set permissions
	unless ($self->set_permissions())
	{
		warn "Error: Processing of permissions failed.\n";
		return undef;
	}

	return 1;
}

################################################################################
# Function:	cleanup()

=head2 B<cleanup()>

This method cleans up anything we have created but nolonger need.

=cut
sub cleanup
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $output_dir = $self->output_dir();
	my $package_name = $self->package_name();

	unless (system("chmod -R 0700 $tmp_dir") eq 0)
	{
		warn "Error: Problems were experienced changing the permissions.\n";
		return undef;
	}
	
	rmtree($tmp_dir, 1, 1);
	unlink "$output_dir/$package_name.info";
	return 1;
}

################################################################################
# Function:	create_package()

=head2 B<create_package()>

This function creates the .pkg package directory and all the associated files.

=cut
sub create_package
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $output_dir = $self->output_dir();
	my $name = $self->package_name();
	my $icon = " ";
	$icon .= $self->icon() if $self->icon();

	# Create the package.info file
	unless ($self->create_package_info())
	{
		warn "Error: Problems were encountered creating the .info file.\n";
		return undef;
	}

	# Create the package
	unless (system("package $tmp_dir $output_dir/$name.info $icon -d $output_dir") eq 0)
	{
		warn "Error: Problems were encountered running package.\n";
		return undef;
	}

	# copy the pre and post scripts into the package
	copy($self->pre_install_script(), "$output_dir/$name.pkg/$name.pre_install") if $self->pre_install_script();
	copy($self->post_install_script(), "$output_dir/$name.pkg/$name.post_install") if $self->post_install_script();
	copy($self->pre_uninstall_script(), "$output_dir/$name.pkg/$name.pre_uninstall") if $self->pre_uninstall_script();
	copy($self->post_uninstall_script(), "$output_dir/$name.pkg/$name.post_uninstall") if $self->post_uninstall_script();
	copy($self->pre_upgrade_script(), "$output_dir/$name.pkg/$name.pre_upgrade") if $self->pre_upgrade_script();
	copy($self->post_upgrade_script(), "$output_dir/$name.pkg/$name.post_upgrade") if $self->post_upgrade_script();

	# fix the permissions on the scripts
	chmod 0544, "$output_dir/$name.pkg/$name.pre_install";
	chmod 0544, "$output_dir/$name.pkg/$name.post_install";
	chmod 0544, "$output_dir/$name.pkg/$name.pre_uninstall";
	chmod 0544, "$output_dir/$name.pkg/$name.post_uninstall";
	chmod 0544, "$output_dir/$name.pkg/$name.pre_upgrade";
	chmod 0544, "$output_dir/$name.pkg/$name.post_upgrade";

	# Copy the license file into the package.
	copy($self->license_file(), "$output_dir/$name.pkg/License.rtf") if $self->license_file();
	chmod 0444, "$output_dir/$name.pkg/License.rtf";
		
	return 1;
}

################################################################################
# Function:	create_package_info()

=head2 B<create_package_info()>

 This method creates the package.info file for the package

=cut
sub create_package_info
{
	my $self = shift;
	my $output_dir = $self->output_dir();
	my $name = $self->package_name();

	# open a file handle on the file
	my $fh = new FileHandle();
	$fh->open(">$output_dir/$name.info");
	$fh->autoflush();

	$fh->print("#\n#These fields are displayed in the Info View\n#\n");
	$fh->print("Title ".$self->program_name()."\n");
	$fh->print("Version ".$self->version()."\n");
	$fh->print("Description ".$self->description()."\n");

	$fh->print("#\n#These fields are used for the installer media locations\n#\n");
	$fh->print("DefaultLocation ".$self->install_dir()."\n");
	$fh->print("Relocatable YES\n");
	$fh->print("Diskname $name\n");

	$fh->print("#\n#Other files that have varing importance\n#\n");
	$fh->print("NeedsAuthorization YES\n");
	$fh->print("DeleteWarning NO\n");
	$fh->print("DisableStop NO\n");
	$fh->print("UseUserMask NO\n");
	$fh->print("Application NO\n");
	$fh->print("Required NO\n");
	$fh->print("InstallOnly NO\n");
	$fh->print("RequiresReboot NO\n");
	$fh->print("InstallFat NO\n");

	$fh->close();
}

################################################################################
# Function:	process_directories()
# Description:	This function processes all of the directories.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub process_directories
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $output_dir = $self->output_dir();
	my $name = $self->package_name();

	# create the tmp processing directory
	mkpath($tmp_dir, 1, 0777);

	foreach my $object ($self->get_directory_objects())
	{
		my $destination = $object->destination();
		mkpath("$tmp_dir/$destination", 1, 0777);
	}

	# Create the output directory for the package
	unless (-d $output_dir)
	{
		mkpath("$output_dir", 1, 0777);
	}

	return 1;
}

################################################################################
# Function:	process_files()
# Description:	This function processes all of the files.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub process_files
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	foreach my $object ($self->get_file_objects())
	{
	    my $destination = $object->destination();
	    my $source = $object->source();

	    # check that the directory for this file exists if not create it
	    my $directory = dirname("$tmp_dir/$destination");
	    unless (-d $directory)
	    {
		return undef unless mkpath($directory, 1, 0777);
	    }

	    return undef unless copy($source, "$tmp_dir/$destination");
	}

	return 1;
}

################################################################################
# Function:	process_links()
# Description:	This function process all of the links.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub process_links
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	foreach my $object ($self->get_link_objects())
	{
	    my $source = $object->source();
	    my $destination = $object->destination();
	    my $type = $object->type();

	    if ($type eq 'softlink')
	    {
		unless (symlink $source, "$tmp_dir/$destination")
		{
		    warn "Error: Could not create soft link from $source to $tmp_dir/$destination:\n$!\n";
		    return undef;
		}
	    }
	    elsif ($type eq 'hardlink')
	    {
		unless (link $source, "$tmp_dir/$destination")
		{
		    warn "Error: Could not create hard link from $source to $tmp_dir/$destination:\n$!\n";
		    return undef;
		}
	    }
	    else
	    {
	    }
	}

	return 1;
}

################################################################################
# Function:	set_permissions()
# Description:	This function sets the permissions for all objects.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub set_permissions
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	foreach my $object ($self->get_directory_objects(), $self->get_file_objects())
	{
	    my $destination = $object->destination();
	    my $mode = oct($object->mode());
	    my $user = $object->user();
	    my $group = $object->group();
	    my $user_num = $user =~ /\d+/ ? $user : getpwnam($user);
	    my $group_num = $group =~ /\d+/ ? $group : getgrnam($group);

	    unless (chown($user_num, $group_num, "$tmp_dir/$destination"))
	    {
		warn "Error: Could not change owner or group:\n$!\n";
		return undef;
	    }

	    unless (chmod $mode, "$tmp_dir/$destination")
	    {
		warn "Error: Could not change owner or group:\n$!\n";
		return undef;
	    }
	}

	return 1;
}

1;
__END__

=head1 SEE ALSO

 Software::Packager

=head1 AUTHOR

 R Bernard Davison <rbdavison@cpan.org>

=head1 COPYRIGHT

 Copyright (c) 2001 Gondwanatech. All rights reserved.
 This program is free software; you can redistribute it and/or modify it under
 the same terms as Perl itself.

=cut


=head1 NAME

 Software::Packager::Tar

=head1 SYNOPSIS

 use Software::Packager;
 my $packager = new Software::Packager('tar');

=head1 DESCRIPTION

 This module is used to create tar files with the required structure 
 as specified by the list of object added to the packager.

=head1 FUNCTIONS

=cut

package		Software::Packager::Tar;

####################
# Standard Modules
use strict;
use Archive::Tar;
use File::Path;
use File::Copy;
use File::Find;
use File::Basename;
use Cwd;
# Custom modules
use Software::Packager;

####################
# Variables
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw( Software::Packager );
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = 0.04;

####################
# Functions

################################################################################
# Function:	new()

=head2 B<new()>

 This method creates and returns a new class object.

=cut
sub new
{
	my $class = shift;
	my $self = bless {}, $class;

	return $self;
}

################################################################################
# Function:	package_name()

=head2 B<package_name()>

This method is used to format the package name and return it in the format
required for tar packages.
This method overrides the package_name method of Software::Packager.

=cut
sub package_name
{
	my $self = shift;
	my $name = shift;

	if ($name)
	{
		$self->{'PACKAGE_NAME'} = $name;
		return $self->{'PACKAGE_NAME'};
	}
	else
	{
		my $package_name = $self->{'PACKAGE_NAME'};
		$package_name .= "-" . $self->version();

		return $package_name;
	}
}

################################################################################
# Function:	package()

=head2 B<package()>

 This method overrides the base API and implements the required functionality 
 to create Tar software packages.
 It calls teh following method in order setup, create_package and cleanup.

=cut
sub package
{
	my $self = shift;

	return undef unless $self->setup();
	return undef unless $self->create_package();
	return undef unless $self->cleanup();

	return 1;
}

################################################################################
# Function:	setup()

=head2 B<setup()>

 This function sets up the temporary structure for the package.

=cut
sub setup
{
	my $self = shift;
	my $cwd = getcwd();
	my $tmp_dir = $self->tmp_dir();
	my $package_build_dir = "$tmp_dir/" . $self->package_name();

	# process directories
	unless (-d $package_build_dir)
	{
		mkpath($package_build_dir, 0, 0755) or
			warn "Error: Problems were encountered creating directory \"$package_build_dir\": $!\n";
	}
	chdir $package_build_dir;

	# process directories
	my @directories = $self->get_directory_objects();
	foreach my $object (@directories)
	{
		my $destination = $object->destination();
		my $user = $object->user();
		my $group = $object->group();
		my $mode = $object->mode();
		unless (-d $destination)
		{
			mkpath($destination, 0, $mode) or
				warn "Error: Problems were encountered creating directory \"$destination\": $!\n";
		}
	}

	# process files
	my @files = $self->get_file_objects();
	foreach my $object (@files)
	{
		my $source = $object->source();
		my $destination = $object->destination();
		my $dir = dirname($destination);
		unless (-d $dir)
		{
			mkpath($dir, 0, 0755) or
				warn "Error: Problems were encountered creating directory \"$dir\": $!\n";
		}
		copy($source, $destination) or
			warn "Error: Problems were encountered coping \"$source\" to \"$destination\": $!\n";

		my $user_id = $object->user();
		my $group_id = $object->group();
		$user_id = getpwnam($object->user()) unless $user_id =~ /\d/;
		$group_id = getgrnam($object->group()) unless $group_id =~ /\d/;
		chown($user_id, $group_id, $destination) or 
			warn "Error: Problems were encountered changing ownership: $!\n";

		my $mode = oct($object->mode());
		chmod($mode, $destination) or
			warn "Error: Problems were encountered changing permissions: $!\n";
	}

	# process links
	my @links = $self->get_link_objects();
	foreach my $object (@links)
	{
		my $source = $object->source();
		my $destination = $object->destination();
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

	chdir $cwd;
	return 1;
}

################################################################################
# Function:	create_package()
# Description:	This function creates the package
# Arguments:	none.
# Return:	true if ok else undef.
#
sub create_package
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $tar_file = $self->output_dir();
	$tar_file .= "/" . $self->package_name();
	$tar_file .= ".tar";

	# create the object
	my $cwd = getcwd();
	chdir $tmp_dir;
	my $tar = new Archive::Tar();

	# Add everything to the archive.
	my @files;
	find  sub {push @files, $File::Find::name;}, $self->package_name();
	$tar->add_files(@files) or 
		warn "Error: Problems were encountered creating the archive: $!\n", $tar->error(), "\n";

	# write the sucker.
	$tar->write($tar_file);
	chdir $cwd;

	return 1;
}

################################################################################
# Function:	cleanup()
# Description:	This function removes the temporary structure for the package.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub cleanup
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	# there has to be a better way to to this!
	system("chmod -R 0777 $tmp_dir");
	rmtree($tmp_dir, 0, 0);
	return 1;
}

1;
__END__

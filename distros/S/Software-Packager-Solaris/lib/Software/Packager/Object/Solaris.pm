################################################################################
# Name:		Software::Packager::Object::Solaris.pm
# Description:	This module is used by Packager for holding data for a each item
# Author:	Bernard Davison
# Contact:	rbdavison@cpan.org
#

package		Software::Packager::Object::Solaris;

####################
# Standard Modules
use strict;
#use File::Basename;
# Custom modules
use Software::Packager::Object;

####################
# Variables
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw( Software::Packager::Object );
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = 0.02;

####################
# Functions

################################################################################
# Function:	_check_data()
# Description:	This function checks the passed data
#	TYPE 		- If the type is a file then the value of SOURCE must
#			  be a real file.
#			  If the type is a soft/hard link then the source and
#			  destination must both be present.
#	SOURCE		- nothing special to check
#	DESTINATION	- nothing special to check
#	CLASS		- if it is not set then set to "none"
#	PART		- if it is not set then set to "1"
#	MODE		- Defaults to 0777 for directories and for files the
#			  permissions currently set.
#	USER		- Defaults to the current user
#	GROUP		- Defaults to the current users primary group
# Arguments:	$self
# Return:	true if all OK else undef.
#
sub _check_data
{
	my $self = shift;
	my %data = @_;

	$data{'TYPE'} = lc $data{'TYPE'};
	if ($data{'TYPE'} eq 'file')
	{
	    return undef unless -f $data{'SOURCE'};
	}
	elsif ($data{'TYPE'} =~ /link/)
	{
	    return undef unless $data{'SOURCE'} and $data{'DESTINATION'};
	}

	unless ($data{'MODE'})
	{
	    if ($data{'TYPE'} eq 'directory')
	    {
		$data{'MODE'} = 0755;
	    }
	    else
	    {
		$data{'MODE'} =  sprintf("%04o", (stat($data{'SOURCE'}))[2] & 07777);
	    }
	}

	# make sure PART is set to a number
	if (scalar $data{'PART'})
	{
		#return undef unless $data{'PART'} =~ /\d+/;
		$data{'PART'} =~ /\d+/;
	}
	else
	{
		$data{'PART'} = 1;
	}

	$data{'CLASS'} = "none" unless scalar $data{'CLASS'};
	$data{'USER'} = getpwuid($<) unless $data{'USER'};

	unless ($data{'GROUP'})
	{
	    my $groups = $(;
	    my ($group, $crap) = split / /, $groups;
	    $data{'GROUP'} = getgrgid($group);
	}

	foreach my $key (keys %data)
	{
		my $function = lc $key;
		unless ($self->$function($data{$key}))
		{
			#warn "Error: There is an error with the value of $key.\n";
			return undef;
		}
	}

	return 1;
}

################################################################################
# Function:	class()
# Description:	This function returns or sets the class for this object.
# Arguments:	Value for CLASS or nothing.
# Return:	object class
#
sub class
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'CLASS'} = $value;
	}
	else
	{
		return $self->{'CLASS'};
	}
}

################################################################################
# Function:	part()
# Description:	This function returns or sets the part for this object.
# Arguments:	value for PART or nothing.
# Return:	object part
#
sub part
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'PART'} = $value;
	}
	else
	{
		return $self->{'PART'};
	}
}

################################################################################
# Function:	prototype()
# Description:	This function returns the object type for the object as
#		described in prototype(4) man page.
# Arguments:	$self
# Return:	object type
#
sub prototype
{
	my $self = shift;
	my %proto_types = (
		'block'		=> 'b',
		'charater'	=> 'c',
		'directory'	=> 'd',
		'edit'		=> 'e',
		'file'		=> 'f',
		'installation'	=> 'i',
		'hardlink'	=> 'l',
		'pipe'		=> 'p',
		'softlink'	=> 's',
		'volatile'	=> 'v',
		'exclusive'	=> 'x',
	);

	return $proto_types{$self->{'TYPE'}};
}

1;
__END__

=head1 NAME

Software::Packager::Object - Generic object data storage

=head1 SYNOPSIS

use Software::Packager::Object;

=head1 DESCRIPTION

This module is used by Software::Packager for holding data for a each item
added to the a software package. It provides an easy way of accessing the data
for each object to be installed.
This module is designed to be easly sub classed and / or extended.

=head1 SUB-CLASSING

To extend or sub-class this module create a new module along the lines of

 package Foo;

 use Software::Packager::Object;
 use vars qw(@ISA);
 @ISA = qw( Software::Packager::Object );

 ########################
 # _check_data we don't care about anything other that DESTINATION and FOO_DATA;
 sub _check_data
 {
 	my $self = shift;
	my %data = @_;

	return undef unless $self->{'DESTINATION'};
	return undef unless $self->{'FOO_DATA'};

	# now set the data for the object
	foreach my $key (keys %data)
	{
		my $function = lc $key;
		return undef unless $self->$function($data{$key});
	}
 }

 ########################
 # foo_data returns the foo value fo this object.
 sub foo_data
 {
 	my $self = shift;
	return $self->{'FOO_DATA'};
 }
 1;
 __END__


Of course I would have created the module with a package of
Software::Packager::Object::Foo but that's you choice.

=head1 FUNCTIONS

=cut

package		Software::Packager::Object;

####################
# Standard Modules
use strict;
# Custom modules

####################
# Variables
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw();
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = 0.08;

####################
# Functions

################################################################################
# Function:	new()

=head2 B<new()>

 my $object = new Software::Packager::Object(%object_data);

This function creates and returns a new Software::Packager::Object object which
is used to access the data in the passed hash. This passed data is passed on and
checked for problems by the _check_data() method.

The hash of data passed should contain at least the following
 
 %hash = (
	'TYPE' => 'file type',
	'SOURCE' => 'source file location. Not required for directories.',
	'DESTINATION' => 'destination location',
	'USER' => 'user to install as',
	'GROUP' => 'group to install as',
	'MODE' => 'permissions to install the file with',
 	);

=cut
sub new
{
	my $class = shift;
	my %data = @_;

	my $self = bless {}, $class;
	return undef unless $self->_check_data(%data);

	return $self;
}

################################################################################
# Function:	_check_data()

=head2 B<_check_data()>

 $self->_check_data(%data);

This function checks that the data for this object is okay and returns true if
there are problems with the data then undef is returned.

 TYPE		If the type is a file then the value of SOURCE must be a real
 		file. If the type is a soft/hard link then the source and
		destination must both be present.
 SOURCE		nothing special to check, see TYPE
 DESTINATION	nothing special to check, see TYPE
 MODE		Defaults to 0755 for directories and 0644 for files.
 USER		Defaults to the current user
 GROUP		Defaults to the current users primary group

=cut
sub _check_data
{
	my $self = shift;
	my %data = @_;

	# The object type must be set.
	unless (exists $data{'TYPE'})
	{
		warn "Error: The object type is not set. This value is required.\n";
		return undef;
	}
	
	# Now do some checks depending on the object type
	if ($data{'TYPE'} =~ /^file$/i)
	{
		unless (-f $data{'SOURCE'})
		{
			warn "Error: The value for SOURCE is not set! This is a required value for file objects.\n";
			return undef;
		}
	}
	elsif ($data{'TYPE'} =~ /link/i)
	{
		unless ($data{'SOURCE'} and $data{'DESTINATION'})
		{
			warn "Error: Either SOURCE of DESTINATION are not set! both are required for link objects.\n";
			warn "Error: SOURCE=\"$data{'SOURCE'}\" DESTINATION=\"$data{'DESTINATION'}\"\n";
			return undef;
		}
	}

	# now set the data for the object
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
# Function:	type()

=head2 B<type()>

 $object->type($value);
 $type = $object->type();

This method sets or returns the type of this object.
When the object type is being set then the value passed will be checked.

Valid object types are:

 File:       A standard file.
 Directory:  A directory.
 Hardlink:   A file link.
 Softlink:   A symbolic link.
 Install:    An installation file used by the installer.
 Config:     A configuration file.
 Volatile:   A volatile file.
 Pipe:       A named pipe.
 Charater:   A charater special device.
 Block:      A block special device.
 Multiplex:  A multiplexed special device.

=cut 
sub type
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		# first check that the type is a valid file type.
		unless ($value =~ /^file$|^directory$|^hardlink$|^softlink$|^install$|^config$|^volatile$|^pipe$|^charater$|^block$|^multiplex$|^installdir$/i)
		{
			warn "Error: Unknown object type \"$value\".\n";
			warn "       The object type should be one of:\n";
			warn "File:       A standard file.\n";
			warn "Directory:  A directory.\n";
			warn "Hardlink:   A file link.\n";
			warn "Softlink:   A symbolic link.\n";
			warn "Install:    An installation file used by the installer.\n";
			warn "Config:     A configuration file.\n";
			warn "Volatile:   A volatile file.\n";
			warn "Pipe:       A named pipe.\n";
			warn "Charater:   A charater special device.\n";
			warn "Block:      A block special device.\n";
			warn "Multiplex:  A multiplexed special device.\n";
			return undef;
		}

		$self->{'TYPE'} = $value;
	}
	else
	{
		return $self->{'TYPE'};
	}
}

################################################################################
# Function:	source()

=head2 B<source()>

 $object->source($value);
 $source = $object->source();

This method sets or returns the source location for this object.

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
# Function:	destination()

=head2 B<destination()>

 $object->destination($value);
 $destination = $object->destination();

This method sets or returns the destination location for this object.

=cut 
sub destination
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'DESTINATION'} = $value;
	}
	else
	{
		return $self->{'DESTINATION'};
	}
}

################################################################################
# Function:	mode()

=head2 B<mode()>

 $object->mode($value);
 $mode = $object->mode();

This method sets or returns the installation mode for this object.

NOTE: The mode is stored in octal but that doesn't mean that you are using it
in octal if you are trying to use the return value in a chmod command then do
something like.

 $mode = oct($object->mode());
 chmod($mode, $object->destination());

Do lots of tests!

If the mode is not set then default values are set. Directories are set to 0755
everything else defaults to the mode the object source has.

=cut 
sub mode
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'MODE'} = $value;
	}
	else
	{
		# set some defaults if nothing is set
		unless ($self->{'MODE'})
		{
	    		if ($self->{'TYPE'} eq 'directory')
	    		{
				$self->{'MODE'} = '0755';
	    		}
	    		else
	    		{
				if (-e $self->source())
				{
					my @stats = stat $self->source();
					$self->{'MODE'} = sprintf "%04o", $stats[2] & 07777;
				}
				else
				{
					$self->{'MODE'} = '0644';
				}
	    		}
		}

		# symbolic links are always 0777
		if ($self->{'TYPE'} =~ /softlink/i)
		{
			$self->{'MODE'} = '0777';
		}

		return $self->{'MODE'};
	}
}

################################################################################
# Function:	user()

=head2 B<user()>

 $object->user($value);
 $user = $object->user();

This method sets or returns the user id that this object should be installed as.
If the user is not set for the object then the user defaults to the current
user.

If this becomes a problem it can be changed to be the owner of the object.

=cut 
sub user
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		$self->{'USER'} = $value;
	}
	else
	{
		unless ($self->{'USER'})
		{
			$self->{'USER'} = $<;
		}
		return $self->{'USER'};
	}
}

################################################################################
# Function:	group()

=head2 B<group()>

This method sets or returns the group id that this object should be installed
as.
If the group is not set for the object then the group defaults to the current
primary group.

If this becomes a problem it can be changed to be the group of the object.

=cut 
sub group
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
	    	$self->{'GROUP'} = $value;
	}
	else
	{
		unless ($self->{'GROUP'})
		{
	    	my $groups = $(;
	    	my ($group, @rest) = split / /, $groups;
	    	$self->{'GROUP'} = $group;
		}
		return $self->{'GROUP'};
	}
}

1;
__END__

=head1 SEE ALSO

 Software::Packager

=head1 AUTHOR

 R Bernard Davison <rbdavison@cpan.org>
 If you extend this module I'd really like to see what you do with it. 

=head1 COPYRIGHT

 Copyright (c) 2001 Gondwanatech. All rights reserved.
 This program is free software; you can redistribute it and/or modify it under
 the same terms as Perl itself.

=cut

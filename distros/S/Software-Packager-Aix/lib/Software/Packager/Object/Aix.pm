=head1 NAME

 Software::Packager::Object::Aix

=head1 SYNOPSIS

 use Software::Packager::Object::Aix

=head1 DESCRIPTION

This module is extends Software::Packager::Object and adds extra methods for
use by the AIX software packager.

=head1 FUNCTIONS

=cut

package		Software::Packager::Object::Aix;

####################
# Standard Modules
use strict;
# Custom modules
use Software::Packager::Object;

####################
# Variables
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw( Software::Packager::Object );
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = 0.04;

my $m_inventory_type_map;
$m_inventory_type_map->{'directory'} = "DIRECTORY";
$m_inventory_type_map->{'file'} = "FILE";
$m_inventory_type_map->{'hardlink'} = undef;
$m_inventory_type_map->{'softlink'} = "SYMLINK";
$m_inventory_type_map->{'install'} = undef;
$m_inventory_type_map->{'config'} = "FILE";
$m_inventory_type_map->{'volatile'} = "FILE";
$m_inventory_type_map->{'pipe'} = "FIFO";
$m_inventory_type_map->{'charater'} = "CHAR_DEV";
$m_inventory_type_map->{'block'} = "BLK_DEV";
$m_inventory_type_map->{'multiplex'} = "MPX_DEV";

####################
# Functions

=head2 B<LPP TYPE>

The LPP type for objects determines the type of LPP package created.
If the objects destination is under /usr/share then the object is of type SHARE
If the objects destination is under /usr then the object has a type of USER
If the objects destination is under any other directory then the object has a
type of ROOT+USER.

 Note: when using the methods
 lpp_type_is_share()
 lpp_type_is_user()
 lpp_type_is_root()
 If the lpp_type_is_share() returns true then both lpp_type_is_user() and
 lpp_type_is_root() will also return true.
 Also if lpp_type_is_user() returns true then lpp_type_is_root() will also
 return true.
 So when calling these method do something like...

 foreach my $object ($self->get_object_list())
 {
 	$share++ and next if $object->lpp_type_is_share();
 	$user++ and next if $object->lpp_type_is_user();
 	$root++ and next if $object->lpp_type_is_root();
 }

=cut

################################################################################
# Function:	lpp_type_is_share()

=head2 B<lpp_type_is_share()>

 $share++ if $object->lpp_type_is_share();

Returns the true if the LPP is SHARE otherwise it returns undef.

=cut 
sub lpp_type_is_share
{
	my $self = shift;
	my $destination = $self->destination();
	return '1' if $destination =~ m#^/usr/share#;
	return undef;
}

################################################################################
# Function:	lpp_type_is_user()

=head2 B<lpp_type_is_user()>

 $share++ if $object->lpp_type_is_user();

Returns the true if the LPP is USER otherwise it returns undef.

=cut 
sub lpp_type_is_user
{
	my $self = shift;
	my $destination = $self->destination();
	return '1' if $destination =~ m#^/usr#;
	return undef;
}

################################################################################
# Function:	lpp_type_is_root()

=head2 B<lpp_type_is_root()>

 $share++ if $object->lpp_type_is_root();

Returns the true if the LPP is ROOT+USER otherwise it returns undef.

=cut 
sub lpp_type_is_root
{
	my $self = shift;
	my $destination = $self->destination();
	return '1' if $destination =~ m#^/#;
	return undef;
}

################################################################################
# Function:	inventory_type()

=head2 B<inventory_type()>

 $type = $object->inventory_type();

Returns the type of object to be added to the inventory file.

=cut 
sub inventory_type
{
	my $self = shift;
	return $m_inventory_type_map->{lc $self->type()};
}

################################################################################
# Function:	destination()

=head2 B<destination()>

 $object->destination($value);
 $destination = $object->destination();

This method sets or returns the destination location for this object.
The name of objects being installed cannot contain commas or colons. This is
because commas and colons are used as delimiters in the control files used
during the software installation process.
Object names can contain non-ASCII charaters.

=cut 
sub destination
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		if ($value =~ /\,|\:/)
		{
			warn "Error: Cannot add object to the package: Objects cannot have names containing commas or colons.\n";
			return undef;
		}
		$self->{'DESTINATION'} = $value;
	}
	else
	{
		return $self->{'DESTINATION'};
	}
}

################################################################################
# Function:	user()

=head2 B<user()>

This method sets or returns the user name that this object should be installed
as.

=cut 
sub user
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		# if we only have digits then get the name.
		if ($value =~ /^\d+$/) 
		{
			$value = getpwuid($value);
		}
		$self->{'USER'} = $value;
	}
	else
	{
		unless (scalar $self->{'USER'})
		{
			$self->{'USER'} = getpwuid($<);
		}
		return $self->{'USER'};
	}
}

################################################################################
# Function:	group()

=head2 B<group()>

 $object->group($value);
 $group = $object->group();

This method sets or returns the group name that this object should be installed
as.

=cut 
sub group
{
	my $self = shift;
	my $value = shift;

	if ($value)
	{
		# if we only have digits then get the name.
		if ($value =~ /^\d+$/) 
		{
			$value = getgrgid($value);
		}
		$self->{'GROUP'} = $value;
	}
	else
	{
		unless (scalar $self->{'GROUP'})
		{
			my $groups = $(;
			my ($group, @rest) = split / /, $groups;
			$self->{'GROUP'} = getgrgid($group);
		}
		return $self->{'GROUP'};
	}
}

################################################################################
# Function:	links()

=head2 B<links()>

This method adds to the list of hard links to add for the file.
If no arguments are passed then a string containing the list is returned.

=cut 
sub links
{
	my $self = shift;
	my $value = shift;

	if (defined $value)
	{
		push @{$self->{'LINKS'}}, $value;
	}
	else
	{
		if (exists $self->{'LINKS'})
		{
			my $links = join ',', @{$self->{'LINKS'}};
			return $links;
		}
		return undef;
	}
}

1;
__END__

=head1 SEE ALSO

Software::Packager::Object

=head1 AUTHOR

R Bernard Davison E<lt>rbdavison@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2001 Gondwanatech. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

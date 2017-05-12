package	Software::Packager::Object::Svr4;

use strict;
use base qw(Software::Packager::Object);
use vars qw($VERSION);
$VERSION = 0.02;

sub _check_data {
  my ($self, %data) = @_;

  $self->{TYPE} = lc $self->{TYPE};
  if ($self->{TYPE} eq 'file') {
    return undef unless -f $self->{SOURCE};
  } elsif ($self->{TYPE} eq 'hardlink' ||
	   $self->{TYPE} eq 'softlink') {
    return undef unless $self->{SOURCE}
      and $self->{DESTINATION};
  }

  $self->{MODE} ||= [stat($self->{SOURCE})]->[2] % 010000;

  # make sure PART is set to a number
  if (scalar $self->{PART}) {
    $self->{PART} =~ /\d+/;
  } else {
    $self->{PART} = 1;
  }

  $self->{CLASS} ||= "none";

  return 1;
}

sub user {
  my $self = shift;
  my $value = shift;

  $self->{USER} = $value
    if $value;
  $self->{USER} ||= [getpwuid([lstat($self->source)]->[4])]->[0];
  return $self->{USER};
}

sub group
{
	my $self = shift;
	my $value = shift;

	$self->{GROUP} = $value
	  if $value;
	$self->{GROUP} ||= [getgrgid([lstat($self->source)]->[5])]->[0];
	return $self->{GROUP};
}


################################################################################
# Function:	status()
# Description:	This function returns the status for this object.
# Arguments:	none.
# Return:	package directory.
#
sub status {
	my $self = shift;
	return $self->{STATUS};
}

################################################################################
# Function:	class()
# Description:	This function returns the class for this object.
# Arguments:	none.
# Return:	object class
#
sub class {
  my $self = shift;
  return $self->{CLASS};
}

################################################################################
# Function:	part()
# Description:	This function returns the part for this object.
# Arguments:	none.
# Return:	object part
#
sub part {
  my $self = shift;
  return $self->{PART};
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

1; __END__

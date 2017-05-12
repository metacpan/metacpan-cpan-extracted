#---------------------------------------------------------------------------

package Solaris::Procfs::Filesystem;

# Copyright (c) 1999,2000 John Nolan. All rights reserved.
# This program is free software.  You may modify and/or
# distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# You can run this file through either pod2text, pod2man or
# pod2html to produce pretty documentation in text, manpage or
# html file format (these utilities are part of the
# Perl 5 distribution).

use Solaris::Procfs::Process;

use vars qw($VERSION @ISA $AUTOLOAD);
use vars qw($DEBUG);
use Carp;
use strict;

require Exporter;

*VERSION        = *Solaris::Procfs::VERSION;
*DEBUG          = *Solaris::Procfs::DEBUG;
@ISA            = qw();


#-------------------------------------------------------------
#
sub new {

	my ($proto, @args) = @_;
	my $class = ref($proto) || $proto;

	my $self;

	print STDERR (caller 0)[3], ": Creating $class object\n"
		if $DEBUG >= 2;
	$self = { @args };
	tie  %$self, $class;
	bless $self, $class;

	return $self;     
}


#-------------------------------------------------------------
#
sub FETCH {

	my $self = "";
	my $index = "";
	($self, $index) = @_;

	return unless defined $index;

	print STDERR (caller 0)[3], ": Read \$index $index\n"
		if $DEBUG >= 2;

	if ($index =~ /^\d+$/) {

		if (-d "/proc/$index") {

			if (
				not exists  $self->{$index}       or 
				not defined $self->{$index}       or
				            $self->{$index} eq ''
			) {

				print STDERR (caller 0)[3], 
					": creating object for pid $index\n"
					if $DEBUG >= 2;

				my $temp        = new Solaris::Procfs::Process $index ; 
				$self->{$index} = $temp;
			}

			return $self->{$index}

		}

		print STDERR (caller 0)[3], 
			": No proc directory for pid $index\n"
				if $DEBUG >= 2;

		return;

	} else {

		print STDERR (caller 0)[3], 
			": no such process as $index\n"
				if $DEBUG >= 2;

		return;
	}
}

#-------------------------------------------------------------
#
sub DELETE {

	my ($self, $index) = @_;

	print STDERR (caller 0)[3], ": \$index is $index\n"
		if $DEBUG >= 2;

	# Can't remove the pid element
	#
	return if $index eq 'pid';

	return delete $self->{$index};
}

#-------------------------------------------------------------
#
sub EXISTS {

	my ($self, $index) = @_;
	print STDERR (caller 0)[3], ": \$index is $index\n"
		if $DEBUG >= 2;

	if (exists $self->{$index}) {

		return 1;

	} elsif ($self->FETCH($index)) {

		return 1;
	}

	return;
}

#-------------------------------------------------------------
#
sub STORE {

	my ($self, $index, $val) = @_;

	# Can't modify the pid element, if it's there.
	# It can only be defined at the time the hash is created. 
	#
	return if $index eq 'pid';

	print STDERR (caller 0)[3], ": \$index is $index, \$val is $val\n"
		if $DEBUG >= 2;
	return $self->{$index};
}

#-------------------------------------------------------------
#
sub TIEHASH {

	my ($pkg)  = @_;

	my %temp   = ();
	my @pids   = getpids();
	@temp{ @pids } = ("") x scalar @pids;

	my $self = \%temp;

	print STDERR (caller 0)[3], ": \$self is $self, \$pkg is $pkg\n"
		if $DEBUG >= 2;
	return (bless $self, $pkg);
}

#-------------------------------------------------------------
#
sub NEXTKEY {

	my ($self) = @_;
	print STDERR (caller 0)[3], ": \n"
		if $DEBUG >= 2;
	return each %{ $self };
}

#-------------------------------------------------------------
#
sub FIRSTKEY {

	my ($self) = @_;
	print STDERR (caller 0)[3], ": \n"
		if $DEBUG >= 2;
	keys %{ $self };
	return each %{ $self };
}

#-------------------------------------------------------------
#
sub DESTROY {

	my ($self) = @_;
	print STDERR (caller 0)[3], ": \$self is $self\n"
		if $DEBUG >= 2;
}

#-------------------------------------------------------------
#
sub CLEAR {

	my ($self) = @_;
	print STDERR (caller 0)[3], ": \$self is $self\n"
		if $DEBUG >= 2;
}

#-------------------------------------------------------------
#
sub getpids  {

	unless (opendir (DIR, "/proc") ) {

		carp "Couldn't open directory /proc : $!";
		return;
	}

	my @pids = grep /^\d+$/, readdir DIR;

	close(DIR);

	return  @pids;
}


1;

#---------------------------------------------------------------------------

package Solaris::Procfs::Process;   

# Copyright (c) 1999,2000 John Nolan. All rights reserved.
# This program is free software.  You may modify and/or
# distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# You can run this file through either pod2text, pod2man or
# pod2html to produce pretty documentation in text, manpage or
# html file format (these utilities are part of the
# Perl 5 distribution).

use vars qw($VERSION @ISA $AUTOLOAD);
use vars qw($DISPATCHER $NON_OWNER_FUNCTION_LIST $FUNCTION_LIST $DEBUG);
use vars qw(%DEFAULTPARAMS);

use Carp;
use strict;

require Exporter;

*VERSION        = *Solaris::Procfs::VERSION;
*DEBUG          = *Solaris::Procfs::DEBUG;
@ISA            = qw();

%DEFAULTPARAMS = (

	autoupdate => 0,
);

#-------------------------------------------------------------
# Dispatch hash, used by the AUTOLOAD function of 
# Solaris::Procfs::Process, to send method calls 
# directly to the corresponding method in Solaris::Procfs. 
#
$DISPATCHER = {

	# Dispatch to perl functions
	#
	'root'      => \&Solaris::Procfs::root,
	'cwd'       => \&Solaris::Procfs::cwd,
	'fd'        => \&Solaris::Procfs::fd,
	'writectl'  => \&Solaris::Procfs::writectl,

	# Dispatch to XS functions directly
	#
	'auxv'      => \&Solaris::Procfs::_auxv,
	'lpsinfo'   => \&Solaris::Procfs::_lpsinfo,
	'lstatus'   => \&Solaris::Procfs::_lstatus,
	'lusage'    => \&Solaris::Procfs::_lusage,
	'lwp'       => \&Solaris::Procfs::_lwp,
	'map'       => \&Solaris::Procfs::_map,
	'xmap'      => \&Solaris::Procfs::_xmap,
	'prcred'    => \&Solaris::Procfs::_prcred,
	'psinfo'    => \&Solaris::Procfs::_psinfo,
	'rmap'      => \&Solaris::Procfs::_rmap,
	'sigact'    => \&Solaris::Procfs::_sigact,
	'status'    => \&Solaris::Procfs::_status,
	'usage'     => \&Solaris::Procfs::_usage,
};


$FUNCTION_LIST = { 
	'root'     => '',
	'cwd'      => '',
	'fd'       => '',
	'auxv'     => '',
	'lpsinfo'  => '',
	'lstatus'  => '',
	'lusage'   => '',
	'lwp'      => '',
	'map'      => '',
	'xmap'     => '',
	'prcred'   => '',
	'psinfo'   => '',
	'rmap'     => '',
	'sigact'   => '',
	'status'   => '',
	'usage'    => '',
};

$NON_OWNER_FUNCTION_LIST = {

	'lpsinfo'  => '',
	'lusage'   => '',
	'lwp'      => '',
	'psinfo'   => '',
	'usage'    => '',
};

foreach (keys %$DISPATCHER) {

	$DISPATCHER->{"Solaris::Procfs::Process::$_"} = $DISPATCHER->{$_};
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
sub new {

	my $proto = shift;
	my $pid   = shift;
	my $class = ref($proto) || $proto;

	print STDERR (caller 0)[3], ": Creating object for pid $pid\n"
		if $DEBUG >= 2;

	return unless 
		defined $pid  and 
		not ref($pid) and
		$pid =~ /^\d+$/ and
		-d "/proc/$pid"
	;

	my $self = { };

	tie  %$self, $class, $pid, @_;
	bless $self, $class;


	print STDERR (caller 0)[3], ": ", join(" ", keys %$self),"\n\n"
		if $DEBUG >= 2;

	return $self;     
}

#-------------------------------------------------------------
#
sub TIEHASH {

	my $pkg = shift;
	my $pid = shift;

	my %temp     = (%DEFAULTPARAMS, @_);
	$temp{ pid } = $pid ;

	my $psinfo = Solaris::Procfs::psinfo($pid);

	# If we own the process or if we are root, then pre-define all
	# the available files.  Otherwise, just the owner's files.
	#
	my $available_procfiles = $psinfo->{pr_euid} == $< || $< == 0 
		? $FUNCTION_LIST 
		: $NON_OWNER_FUNCTION_LIST
	;

	print STDERR (caller 0)[3], ": Adding elements to object...\n"
		if $DEBUG >= 2;
	print STDERR (caller 0)[3], ": ", join(" ", keys %$available_procfiles),"\n\n"
		if $DEBUG >= 2;

	%temp = ( %temp, %$available_procfiles );

	my $self = \%temp;

	$self->{available_procfiles}  = $available_procfiles;
	$self->{psinfo} = $psinfo;

	print STDERR (caller 0)[3], ": \$self is $self, \$pkg is $pkg, \$pid is $pid\n"
		if $DEBUG >= 2;

	return (bless $self, $pkg);
}


#-------------------------------------------------------------
#
sub FETCH {

	my ($self, $index) = @_;
	return unless defined $index;

	print STDERR (caller 0)[3], ": Read \$index $index, \$self->{pid} is $self->{pid}\n"
		if $DEBUG >= 2;

	if ($index eq "pid") {

		print STDERR (caller 0)[3], ": Returning \$self->{$index} : $self->{$index}\n"
			if $DEBUG >= 2;
		return $self->{$index};

	} elsif ( exists $DISPATCHER->{$index} ) {

		if ( exists $self->{$index} and $self->{$index} ne '' and not $self->{autoupdate}) {

			print STDERR (caller 0)[3], ": Returning cached results\n"
				if $DEBUG >= 2;
			return $self->{$index};

		} elsif ( -d "/proc/$self->{pid}" ) {

			print STDERR (caller 0)[3], ": Delegating to function $index\n"
				if $DEBUG >= 2;

			if (exists $self->{available_procfiles}->{$index}) {

				$self->{$index} = &{ $DISPATCHER->{$index} }( $self->{pid} ) ;
				return $self->{$index};

			}  else {

				delete $self->{$index};
				return &{ $DISPATCHER->{$index} }( $self->{pid} ) ;
			}

		} else {   # if not -d "/proc/$self->{pid}" 
		
			print STDERR (caller 0)[3], ": No such process as $self->{pid}\n"
				if $DEBUG >= 2;
			return;  ## If the process no longer exists under /proc
		}


	} elsif ( exists $self->{$index} ) {    # and $DISPATCHER->{$index} does not exist

		return $self->{$index};

	} else {

		print STDERR (caller 0)[3], ": No such function or element as $index\n"
			if $DEBUG >= 2;

		return;  ## If the user requested a function not in Procfs
	}

}

#-------------------------------------------------------------
#
sub AUTOLOAD {

	my $self = shift;

	print STDERR (caller 0)[3], ": Want function $AUTOLOAD\n"
		if $DEBUG >= 2;

	if (exists $DISPATCHER->{$AUTOLOAD} ) {

		unless (defined $self and ref($self) eq "Solaris::Procfs::Process") {

			# You can't call Solaris::Procfs::Process::psinfo
			# or any other function directly.  (Even though you can call
			# Solaris::Procfs::psinfo and friends.)
			#
			carp "$AUTOLOAD: Must be called as a method, not as a class function";
			return;
		}

		print STDERR (caller 0)[3], ": Delegating to function $AUTOLOAD\n"
			if $DEBUG >= 2;
#		my $temp = &{ $DISPATCHER->{$AUTOLOAD} }( $self->{pid}, @_ );
#		return $temp;
		return &{ $DISPATCHER->{$AUTOLOAD} }( $self->{pid}, @_ );

	} else {
		carp ( 
			(caller 0)[3]  .  
			": Attempt to invoke nonexistant function $AUTOLOAD\n"
		);
		return;
	}
}

1;


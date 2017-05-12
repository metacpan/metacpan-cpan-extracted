# Copyright 1995,2002 Spider Boardman.
# All rights reserved.
#
# Automatic licensing for this software is available.  This software
# can be copied and used under the terms of the GNU Public License,
# version 1 or (at your option) any later version, or under the
# terms of the Artistic license.  Both of these can be found with
# the Perl distribution, which this software is intended to augment.
#
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

# rcsid: "@(#) $Id: Gen.dat,v 1.44 2002/04/10 11:27:18 spider Exp $"


package Net::Gen;
use 5.004_04;		# new minimum Perl version for this package

use strict;
#use Carp; # no!  just require Carp when we want to croak.
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS
	    %_missing $AUTOLOAD $adebug);

BEGIN {
    $VERSION = '1.011';
    eval "sub Version () { __PACKAGE__ . ' v$VERSION' }";
}

#use Socket qw(!/pack_sockaddr/ !/^MSG_OOB$/ !SOMAXCONN);
use Socket ();
use AutoLoader;
use Exporter ();
use DynaLoader ();
use Symbol qw(gensym);
use SelectSaver ();
use IO::Handle ();

# Special wart for new_from_f{d,h}, since only the _fh flavour's already
# known to AutoLoader.
sub new_from_fd;  *new_from_fd = \&new_from_fh;

BEGIN {
    @ISA = qw(IO::Handle Exporter DynaLoader);

    @EXPORT = ();

    @EXPORT_OK = qw(pack_sockaddr
		    unpack_sockaddr
		    VAL_O_NONBLOCK
		    VAL_EAGAIN
		    RD_NODATA
		    EOF_NONBLOCK
		    EINPROGRESS EALREADY ENOTSOCK EDESTADDRREQ
		    EMSGSIZE EPROTOTYPE ENOPROTOOPT EPROTONOSUPPORT
		    ESOCKTNOSUPPORT EOPNOTSUPP EPFNOSUPPORT EAFNOSUPPORT
		    EADDRINUSE EADDRNOTAVAIL ENETDOWN ENETUNREACH ENETRESET
		    ECONNABORTED ECONNRESET ENOBUFS EISCONN ENOTCONN
		    ESHUTDOWN ETOOMANYREFS ETIMEDOUT
		    ECONNREFUSED EHOSTDOWN EHOSTUNREACH
		    ENOSR ETIME EBADMSG EPROTO ENODATA ENOSTR
		    EAGAIN EWOULDBLOCK
		    ENOENT EINVAL EBADF
		    SHUT_RD SHUT_WR SHUT_RDWR
		    SOL_SOCKET
		    SOMAXCONN
		    SO_ACCEPTCONN SO_BROADCAST SO_DEBUG SO_DONTROUTE
		    SO_ERROR SO_EXPANDED_RIGHTS SO_FAMILY SO_KEEPALIVE
		    SO_LINGER SO_OOBINLINE SO_PAIRABLE SO_RCVBUF
		    SO_RCVLOWAT SO_RCVTIMEO SO_REUSEADDR SO_REUSEPORT
		    SO_SNDBUF SO_SNDLOWAT SO_SNDTIMEO SO_STATE SO_TYPE
		    SO_USELOOPBACK SO_XSE
		    SOCK_STREAM SOCK_DGRAM SOCK_RAW SOCK_RDM SOCK_SEQPACKET
		    AF_UNSPEC AF_UNIX AF_INET AF_IMPLINK AF_PUP AF_CHAOS
		    AF_NS AF_ISO AF_OSI AF_ECMA AF_DATAKIT AF_CCITT AF_SNA
		    AF_DECnet AF_DLI AF_LAT AF_HYLINK AF_APPLETALK AF_ROUTE
		    AF_LINK AF_NETMAN AF_X25 AF_CTF AF_WAN AF_USER AF_LAST
		    PF_UNSPEC PF_UNIX PF_INET PF_IMPLINK PF_PUP PF_CHAOS
		    PF_NS PF_ISO PF_OSI PF_ECMA PF_DATAKIT PF_CCITT PF_SNA
		    PF_DECnet PF_DLI PF_LAT PF_HYLINK PF_APPLETALK PF_ROUTE
		    PF_LINK PF_NETMAN PF_X25 PF_CTF PF_WAN PF_USER PF_LAST
		    AF_LOCAL PF_LOCAL
		   );

    %EXPORT_TAGS = (
	NonBlockVals => [qw(EOF_NONBLOCK RD_NODATA VAL_EAGAIN VAL_O_NONBLOCK)],
	routines	=> [qw(pack_sockaddr unpack_sockaddr)],
	errnos	=> [qw(EINPROGRESS EALREADY ENOTSOCK EDESTADDRREQ
		       EMSGSIZE EPROTOTYPE ENOPROTOOPT EPROTONOSUPPORT
		       ESOCKTNOSUPPORT EOPNOTSUPP EPFNOSUPPORT EAFNOSUPPORT
		       EADDRINUSE EADDRNOTAVAIL ENETDOWN ENETUNREACH ENETRESET
		       ECONNABORTED ECONNRESET ENOBUFS EISCONN ENOTCONN
		       ESHUTDOWN ETOOMANYREFS ETIMEDOUT
		       ECONNREFUSED EHOSTDOWN EHOSTUNREACH
		       ENOSR ETIME EBADMSG EPROTO ENODATA ENOSTR
		       EAGAIN EWOULDBLOCK
		       ENOENT EINVAL EBADF
		      )],
	shutflags => [qw(SHUT_RD SHUT_WR SHUT_RDWR)],
	sockopts => [qw(SO_ACCEPTCONN SO_BROADCAST SO_DEBUG SO_DONTROUTE
			SO_ERROR SO_EXPANDED_RIGHTS SO_FAMILY SO_KEEPALIVE
			SO_LINGER SO_OOBINLINE SO_PAIRABLE SO_RCVBUF
			SO_RCVLOWAT SO_RCVTIMEO SO_REUSEADDR SO_REUSEPORT
			SO_SNDBUF SO_SNDLOWAT SO_SNDTIMEO SO_STATE SO_TYPE
			SO_USELOOPBACK SO_XSE
		       )],
	sockvals => [qw(SOL_SOCKET
			SOCK_STREAM SOCK_DGRAM SOCK_RAW SOCK_RDM SOCK_SEQPACKET
		       )],
	af	=> [qw(AF_UNSPEC AF_UNIX AF_INET AF_IMPLINK AF_PUP AF_CHAOS
		       AF_NS AF_ISO AF_OSI AF_ECMA AF_DATAKIT AF_CCITT AF_SNA
		       AF_DECnet AF_DLI AF_LAT AF_HYLINK AF_APPLETALK AF_ROUTE
		       AF_LINK AF_NETMAN AF_X25 AF_CTF AF_WAN AF_USER AF_LAST
		       AF_LOCAL
		      )],
	pf	=> [qw(PF_UNSPEC PF_UNIX PF_INET PF_IMPLINK PF_PUP PF_CHAOS
		       PF_NS PF_ISO PF_OSI PF_ECMA PF_DATAKIT PF_CCITT PF_SNA
		       PF_DECnet PF_DLI PF_LAT PF_HYLINK PF_APPLETALK PF_ROUTE
		       PF_LINK PF_NETMAN PF_X25 PF_CTF PF_WAN PF_USER PF_LAST
		       PF_LOCAL
		      )],
	ALL	=> [@EXPORT, @EXPORT_OK],
    );
    $EXPORT_TAGS{'non_block_vals'} = $EXPORT_TAGS{'NonBlockVals'};
    $EXPORT_TAGS{'families'} = [@{$EXPORT_TAGS{'af'}}, @{$EXPORT_TAGS{'pf'}}];
}

my %loaded;


# dummies for the Carp:: routines, which we'll re-invoke if we get called.

sub croak
{
    require Carp;
    goto &Carp::croak;
}

sub carp
{
    require Carp;
    goto &Carp::carp;
}


my $nullsub = sub {};		# handy null warning handler
# If the warning handler is this exact code ref, don't bother calling
# croak in the AUTOLOAD constant section, since we're being called from
# inside the eval in initsockopts().

sub AUTOLOAD : locked
{
    # This AUTOLOAD is used to validate possible missing constants from
    # the XS code, or to auto-create get/setattr subs.
    # The defined constants are already available as XSUBs, and the same
    # XS code which handles that also sets up the %_missing hash to note
    # which names were known but are undefined.
    # If the name is in %_missing, we'll croak as a normal AUTOLOAD with
    # a constant() XS function (except for when $nullsub is the die handler).
    # If the name isn't known to %_missing, but it is known
    # as a key for setparams/getparams, it will be simulated via _accessor().
    # Otherwise, control will be passed to the AUTOLOAD in AutoLoader.

#   use attrs 'locked';		# modifies the symbol table and abuses a global

    my ($constname,$callpkg);
    {				# block to preserve $1,$2,et al.
	($callpkg,$constname) = $AUTOLOAD =~ /^(.*)::(.*)$/;
    }
    if (exists $_missing{$AUTOLOAD}) {
	my $wh = $SIG{__WARN__};
	die "\n"
	    if ($wh and (ref($wh) eq 'CODE') and $wh == $nullsub);
	croak "Your vendor has not defined $callpkg macro $constname, used";
    }
    if (@_ && ref $_[0] && @_ < 3 && exists $ {*{$_[0]}}{Keys}{$constname}) {
	no strict 'refs';	# allow us to define the sub
	my $what = $constname;	# don't tie up $constname for closures
	warn "Auto-generating accessor $AUTOLOAD\n" if $adebug;
	*$AUTOLOAD = sub {
	    splice @_, 1, 0, $what;
	    goto &_accessor;
	};
	goto &$AUTOLOAD;
    }
    warn "Autoloading $AUTOLOAD\n" if $adebug;
    $AutoLoader::AUTOLOAD = $AUTOLOAD;
    goto &AutoLoader::AUTOLOAD;
}

BEGIN {
# do this now so the constant XSUBs really are
    __PACKAGE__->DynaLoader::bootstrap($VERSION);
}


# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.


# This package has the core 'generic' routines for fiddling with
# sockets.


# initsockopts - Set up the socket options of a class using this module.
# The structure of a sockopt hash is like this:
# %sockopts = ( OPTION => ['pack_string', $option_number, $option_level,
#				$number_of_elements], ... );
# The option level and number are for calling [gs]etsockopt, and
# the number of elements is for some (weak) consistency checking.
# The pack/unpack template is used by $obj->getsopt and setsopt.
# Only the pack template is set on input to this routine.  On exit,
# it will have deleted any entries which cannot be resolved, and will
# have filled in the ones which can.  It will also have duplicated
# the entries to be indexed by option value as well as by option name.

my %evalopts;			# avoid compiling an eval per sockopt

#& initsockopts($class, $level+0, \%sockopts) : void
sub initsockopts : locked
{
    my ($class,$level,$opts) = @_;
    croak "Invalid arguments to " . __PACKAGE__ . "::initsockopts, called"
	if @_ != 3 or ref $opts ne 'HASH';
    $level += 0;		# force numeric
    my($opt,$oval,@oval,$esub);
    my $nullwarn = $nullsub;	# a handy __WARN__ handler
    # The above has to be there, since the file-scope 'my' won't be seen
    # in the generated closure.
    $class = ref $class if ref $class;
    $evalopts{$class} ||= eval "package $class; no strict 'refs';" .
	'sub ($) {local($SIG{__WARN__})=$nullwarn;local($SIG{__DIE__});' .
	    '&{$_[0]}()}';
    $esub = $evalopts{$class};
    foreach $opt (keys %$opts) {
	delete $$opts{$opt}, next if exists $_missing{"${class}::$opt"};
	$oval = eval {&$esub($opt)};
	delete $$opts{$opt}, next if $@ or !defined($oval) or $oval eq '';
	$oval += 0;		# force numeric
	push(@{$$opts{$opt}}, $oval, $level);
	$$opts{$oval} = $$opts{$opt};
	$oval = $$opts{$opt}[0];
	@oval = unpack($oval, pack($oval, 0));
	$$opts{$opt}[3] = scalar @oval;
    }
}


my %sockopts;

# The known socket options (from Socket.pm)

%sockopts = (
	     # First, the simple flag options

	     'SO_ACCEPTCONN'	=> [ 'I' ],
	     'SO_BROADCAST'	=> [ 'I' ],
	     'SO_DEBUG'		=> [ 'I' ],
	     'SO_DONTROUTE'	=> [ 'I' ],
	     'SO_ERROR'		=> [ 'I' ],
	     'SO_EXPANDED_RIGHTS' => [ 'I' ],
	     'SO_KEEPALIVE'	=> [ 'I' ],
	     'SO_OOBINLINE'	=> [ 'I' ],
	     'SO_PAIRABLE'	=> [ 'I' ],
	     'SO_REUSEADDR'	=> [ 'I' ],
	     'SO_REUSEPORT'	=> [ 'I' ],
	     'SO_USELOOPBACK'	=> [ 'I' ],
	     'SO_XSE'		=> [ 'I' ],

	     # Simple integer options

	     'SO_RCVBUF'	=> [ 'I' ],
	     'SO_SNDBUF'	=> [ 'I' ],
	     'SO_RCVTIMEO'	=> [ 'I' ],
	     'SO_SNDTIMEO'	=> [ 'I' ],
	     'SO_RCVLOWAT'	=> [ 'I' ],
	     'SO_SNDLOWAT'	=> [ 'I' ],
	     'SO_TYPE'		=> [ 'I' ],
	     'SO_STATE'		=> [ 'I' ],
	     'SO_FAMILY'	=> [ 'I' ],

	     # Finally, one which is a struct

	     'SO_LINGER'	=> [ 'II' ],

	     # Out of known socket options
	     );

__PACKAGE__->initsockopts( SOL_SOCKET(), \%sockopts );


#& _genfh() : returns orphan globref with HV slot.
sub _genfh ()
{
    my $rval = gensym;
    *{$rval} = {};		# initialise a hash slot
    $rval;
}

my $debug = 0;			# module-wide debug hack -- don't use

# On the other hand, per-object debugging isn't so bad....

# can update $debug file variable
#& _debug($this [, $newval]) : oldval
sub _debug : locked
{
    my ($this,$newval) = @_;
    return $this->debug($newval) if ref $this;
    # class method here
    my $oldval = $debug;
    $debug = 0+$newval if defined $newval;
    $oldval;
}

#& debug($self [, $newval]) : oldval
sub debug : locked method
{
    my ($self,$newval) = @_;
    my $oldval = $ {*$self}{Parms}{'debug'} if defined wantarray;
    $self->setparams({'debug'=>$newval}) if defined $newval;
    $oldval;
}

#& _trace($this, \@args, minlevel, [$moretext]) : void
sub _trace
{
    my ($this,$aref,$level,$msg) = @_;
    my $rtn = (caller(1))[3];
#    local $^W=0;		# keep the arglist interpolation from carping
    $msg = '' unless defined $msg;
    print STDERR "${rtn}(@{$aref||[]})${msg}\n"
	if $level and $this->_debug >= $level;
    ${rtn};
}

#& _setdebug($self, $name, $newval) : {'' | "carp string"}
sub _setdebug
{
    my ($self,$what,$val) = @_;
    return '' unless defined $val;
    return "$self->{$what} parameter ($val) must be non-negative integer"
	if $val eq '' or $val =~ /\D/;
    $_[2] += 0;		# force numeric
    '';			# return goodness
}

# try to work even in places where Fcntl.xs doesn't.

my ($F_GETFL,$F_SETFL) =
    eval 'use Fcntl qw(F_GETFL F_SETFL);(F_GETFL,F_SETFL)';
my $nonblock_flag = eval 'pack("I",VAL_O_NONBLOCK)';
my $eagain = eval 'VAL_EAGAIN';

#& _accessor($self, $what [, $newval]) : oldvalue
sub _accessor : locked method
{
    my ($self, $what, $newval) = @_;
    croak "Usage: \$sock->$what or \$sock->$what(\$newvalue),"
	if @_ > 3;
    my $oldval = $self->getparam($what) if defined wantarray;
    $self->setparams({$what=>$newval}) if @_ > 2;
    $oldval;
}

#& _setblocking($self, $name, $newval) : {'' | "carp string"}
sub _setblocking
{
    my ($self,$what,$newval) = @_;
    $newval = 1 unless defined $newval;
    # default previous value, just in case
    $ {*$self}{Parms}{$what} = 1 unless
	defined $ {*$self}{Parms}{$what};
    if ($newval) {
	$_[2] = 1;	# canonicalise the new value
	if (defined $F_GETFL and defined $F_SETFL and
	    defined $nonblock_flag and $self->isopen)
	{
	    if ((CORE::fcntl($self, $F_GETFL, 0) & VAL_O_NONBLOCK) ==
		VAL_O_NONBLOCK)
	    {
		$ {*$self}{Parms}{$what} = 0;  # note previous status
		return 'Failed to clear non-blocking status'
		    unless eval {CORE::fcntl($self, $F_SETFL,
					   CORE::fcntl($self, $F_GETFL, 0) &
					     ~VAL_O_NONBLOCK)};
	    }
	}
    }
    else {
	$_[2] = 0;	# canonicalise the new value
	unless (defined $F_GETFL and defined $F_SETFL and
		defined $nonblock_flag)
	{
	    return 'Non-blocking sockets unavailable in this configuration';
	}
	if ($self->isopen) {
	    if ((CORE::fcntl($self, $F_GETFL, 0) & VAL_O_NONBLOCK) !=
		VAL_O_NONBLOCK)
	    {
		$ {*$self}{Parms}{$what} = 1;  # note previous state
		return 'Failed to set non-blocking status'
		    unless eval {CORE::fcntl($self, $F_SETFL,
					   CORE::fcntl($self, $F_GETFL, 0) |
					     VAL_O_NONBLOCK)};
	    }
	}
    }
    '';		# return goodness if got this far
}

#& blocking($self [, $newval]) : canonical_oldval
sub blocking : locked method
{
    my ($self, $newval) = @_;
    croak 'Usage: $sock->blocking or $sock->blocking(0|1),'
	if @_ > 2;
    my $oldval = $self->getparam('blocking', 1, 1) if defined wantarray;
    $self->setparams({'blocking'=>$newval}) if @_ > 1;
    $oldval;
}

#& _settimeout($self, $what, $newval) : {'' | "carp string"}
sub _settimeout
{
    my ($self,$what,$newval) = @_;
    unless (defined $newval) {
	return '';		# It's always OK to delete a timeout.
    }
    if (!length($newval) or $newval =~ /\D/) {
	"Parameter $what must be a non-negative integer or undefined";
    }
    else {
	'';
    }
}

my @Keys = qw(PF AF type proto dstaddr dstaddrlist srcaddr srcaddrlist
	      maxqueue reuseaddr netgen_fakeconnect reuseport);
my %Codekeys = (
		'debug' => \&_setdebug,
		'blocking' => \&_setblocking,
		'timeout' => \&_settimeout,
	       );
# This hash remembers the original {Keys} settings after the first time.
my %Keys;

# This hash remembers the original socket option settings after the first time.
my %Opts;

#& register_param_keys($self, \@keys)
sub register_param_keys : locked method
{
    my ($self, $names) = @_;
    my $whoami = $self->_trace(\@_,3);
    croak "Invalid arguments to ${whoami}(@_), called"
	if @_ != 2 or ref $names ne 'ARRAY';
    @{$ {*$self}{Keys}}{@$names} =
	@{$ {*$self}{Keys}}{@$names}; # remember the names
    # this form doesn't clobber pre-existing register_param_handlers values
}

sub registerParamKeys;	# helps with -w
*registerParamKeys = \&register_param_keys; # alias form preferred by many

#& register_param_handlers($self, \@keys, [\]@handlers)
#&  -or- ($self, \%key-handlers)
sub register_param_handlers : locked method
{
    my ($self, $names, @handlers, $handlers) = @_;
    my $whoami = $self->_trace(\@_,3);
    if (ref $names eq 'HASH') {
	croak "Invalid parameters to ${whoami}(@_), called"
	    if @_ != 2;
	$handlers = [values %$names];
	$names = [keys %$names];
    }
    else {
	croak "Invalid parameters to ${whoami}(@_), called"
	    if @_ < 3 or ref $names ne 'ARRAY';
	$handlers = \@handlers;	# in case passed as a list
	$handlers = $_[2] if @_ == 3 and ref($_[2]) eq 'ARRAY';
    }
    croak "Invalid handlers in ${whoami}(@_), called"
	if @$handlers != @$names or grep(ref $_ ne 'CODE', @$handlers);
    # finally, all is validated, so set the bloody things
    @{$ {*$self}{Keys}}{@$names} = @$handlers;
}

sub registerParamHandlers;	# helps with -w
*registerParamHandlers = \&register_param_handlers; # alias other form

#& register_options($self, $levelname, $level, \%options)
sub register_options : locked method
{
    my ($self, $levname, $level, $opts) = @_;
    my $whoami = $self->_trace(\@_,3);
    croak "Invalid arguments to ${whoami}(@_), called"
	if ref $opts ne 'HASH';
    $ {*$self}{Sockopts}{$levname} = $opts;
    $ {*$self}{Sockopts}{$level+0} = $opts;
}

sub registerOptions;		# helps with -w
*registerOptions = \&register_options; # alias form preferred by many

# pseudo-subclass for saving parameters (ParamSaver, inspired by SelectSaver)
#& param_saver($self, @params) : restoration_object
sub param_saver : locked method
{
    my ($self, @params) = @_;
    my @delparams =
	# map { exists $ {*$self}{Parms}{$_} ? () : ($_) } @params;
	grep {!exists $ {*$self}{Parms}{$_}} @params;
    my %setparams = $self->getparams(\@params);
    bless [$self, \%setparams, \@delparams], 'Net::Gen::ParamSaver';
}

sub paramSaver;			# aliases
*paramSaver = \&param_saver;
sub ParamSaver;
*ParamSaver = \&param_saver;

sub Net::Gen::ParamSaver::DESTROY
{
    local $!;	# just to be sure we don't clobber it
    $_[0]->[0]->setparams($_[0]->[1]);
    $_[0]->[0]->delparams($_[0]->[2]);
}

#& new(classname [, \%params]) : {$self | undef}
#&  -or- $classname [, @ignored]
sub new
{
    my $whoami = $_[0]->_trace(\@_,1);
    my($pack,$parms) = @_;
    my %parms;
    %parms = ( %$parms ) if $parms and ref $parms eq 'HASH';
    $parms{'debug'} = $pack->_debug unless defined $parms{'debug'};
    $parms{'blocking'} = 1 unless defined $parms{'blocking'};
    if (@_ > 2 and $parms and ref $parms eq 'HASH') {
	croak "Invalid argument format to ${whoami}(@_), called";
    }
    my $class = ref $pack || $pack;
    my $self = _genfh;
    bless $self,$class;
    $pack->_trace(\@_,2,", self=$self after bless");
    $ {*$self}{Parms} = \%parms;
    if (%Keys) {
	$ {*$self}{Keys} = { %Keys };
	$ {*$self}{Sockopts} = { %Opts };
    }
    else {
	$self->register_param_keys(\@Keys); # register our keys
	$self->register_param_handlers(\%Codekeys);
	$self->register_options('SOL_SOCKET', SOL_SOCKET(), \%sockopts);
	%Keys = %{$ {*$self}{Keys}};
	%Opts = %{$ {*$self}{Sockopts}};
    }
    if ($class eq __PACKAGE__) {
	unless ($self->init) {
	    local $!;		# preserve errno
	    undef $self;	# against the side-effects of this
	    undef $self;	# another statement needed for unwinding
	}
    }
    if (($self || $pack)->_debug) {
	if (defined $self) {
	    print STDERR "${whoami} returning self=$self\n";
	}
	else {
	    print STDERR "${whoami} returning undef\n";
	}
    }
    $self;
}

#& setparams($this, \%newparams [, $newonly [, $check]]) : boolean
sub setparams : locked method
{
    my ($self,$newparams,$newonly,$check) = @_;
    my $errs = 0;

    croak "Bad arguments to " . __PACKAGE__ . "::setparams, called"
	unless @_ > 1 and ref $newparams eq 'HASH';
    carp "Excess arguments to " . __PACKAGE__ . "::setparams ignored"
	if @_ > 4;

    $newonly ||= 0;		# undefined or zero is equiv now (-w problem)
    my ($parm,$newval,$pslot);
    while (($parm,$newval) = each %$newparams) {
	print STDERR __PACKAGE__ . "::setparams $self $parm" .
	    (defined $newval ? " $newval" : "") . "\n"
		if $self->debug;
	(carp "Unknown parameter type $parm for a " . (ref $self) . " object")
	    , $errs++, next
		unless exists $ {*$self}{Keys}{$parm};
	$pslot = \$ {*$self}{Parms}{$parm};
	next if $newonly < 0 && defined $$pslot;
	if (!$check)
	{
	    # this ungodly construct brought to you by -w
	    next if
		defined($$pslot) eq defined($newval)
		    and
			!defined($newval) ||
			$$pslot eq $newval ||
			    $$pslot !~ /\D/ &&
			    $newval !~ /\D/ &&
				length($newval) &&
				length($$pslot) &&
				$$pslot == $newval
	    ;
	}
	carp("Overwrite of $parm parameter for ".(ref $self)." object ignored")
	    , $errs++, next
		if $newonly > 0 && defined $$pslot;
	if (defined($ {*$self}{Keys}{$parm}) and
	    (ref($ {*$self}{Keys}{$parm}) eq 'CODE'))
	{
	    my $rval = &{$ {*$self}{Keys}{$parm}}($self,$parm,$newval);
	    (carp $rval), $errs++, next if $rval;
	}
	# not using $$pslot here in case {Parms} hash re-generated
	$ {*$self}{Parms}{$parm} = $newval;
    }

    $errs ? undef : 1;
}
    

#& delparams($self, \@paramnames) : boolean
sub delparams : locked method
{
    $_[0]->_trace(\@_,1);
    my($self,$keysref) = @_;
    my(@k,%k);
    @k = grep(exists $ {*$self}{Parms}{$_}, @$keysref);
    return 1 unless @k;		# if no keys need deleting, succeed vacuously
    @k{@k} = ();		# a hash of undefs for the following
    return undef unless $self->setparams(\%k); # see whether undef is allowed
    delete @{$ {*$self}{Parms}}{@k};
    1;				# return goodness
}

#& checkparams($self) : boolean
sub checkparams : locked method
{
    my $whoami = $_[0]->_trace(\@_,1);
    my $self = shift;
    carp "Excess arguments to ${whoami} ignored"
	if @_;
    my $curparms = $ {*$self}{Parms};
    $curparms = {} unless ref $curparms eq 'HASH';
    # make sure only the valid ones are set when we're done
    $ {*$self}{Parms} = {};
    my(@valkeys) = grep(exists $ {*$self}{Keys}{$_}, keys %$curparms);
    # this assignment allows for inter-key dependencies to be evaluated
    @{$ {*$self}{Parms}}{@valkeys} =
	@{$curparms}{@valkeys};
    # validate all current against the defined keys
    $self->setparams($curparms, 0, 1);
}

#& init($self) : {$self | undef}
sub init
{
    $_[0]->_trace(\@_,1);
    my($self) = @_;
    $self->checkparams ? $self : undef;
}

#& getparam($self, $key [, $default [, $defaultifundef]]) : param_value
sub getparam : locked method
{
    my $whoami = $_[0]->_trace(\@_,2);
    my($self,$key,$defval,$noundef) = @_;
    carp "Excess arguments to ${whoami}($self) ignored"
	if @_ > 4;
    if ($noundef) {
	return $defval unless defined($ {*$self}{Parms}{$key});
    }
    else {
	return $defval unless exists($ {*$self}{Parms}{$key});
    }
    $ {*$self}{Parms}{$key};
}

#& getparams($self, \@keys [, $noundef]) : (%hash)
sub getparams : locked method
{
    my $whoami = $_[0]->_trace(\@_,2);
    my ($self,$aref,$noundef) = @_;
    croak "Insufficient arguments to ${whoami}($self), called"
	if @_ < 2 || !ref $self || ref $aref ne 'ARRAY';
    carp "Excess arguments to ${whoami}($self) ignored"
	if @_ > 3;
    return unless defined wantarray;
    if (wantarray) {
	# the actual list is wanted -- see which way to do it
	if ($noundef) {
	    map {defined $ {*$self}{Parms}{$_} ?
		    ($_, $ {*$self}{Parms}{$_}) :
		    () 
		} @$aref;
	}
	else {
	    map {exists $ {*$self}{Parms}{$_} ?
		    ($_, $ {*$self}{Parms}{$_}) :
		    () 
		} @$aref;
	}
    }
    else {
	# the list count is wanted -- see which way to do it
	if ($noundef) {
	    2 * grep {defined $ {*$self}{Parms}{$_}} @$aref;
	}
	else {
	    2 * grep {exists $ {*$self}{Parms}{$_}} @$aref;
	}
    }
#    my @ret;
#    foreach (@$aref) {
#	push(@ret, $_, $ {*$self}{Parms}{$_})
#	    if exists($ {*$self}{Parms}{$_}) and
#		!$noundef || defined($ {*$self}{Parms}{$_});
#    }
#    wantarray ? @ret : 0+@ret;
}
    

#& condition($self)
sub condition : locked method
{
    my $self = $_[0];
    my $sel = SelectSaver->new;
    CORE::select($self);
    $| = 1;
    # $\ = "\015\012";
    binmode($self);
    vec($ {*$self}{FHVec} = '', CORE::fileno($self), 1) = 1;
    $self->setparams({'blocking'=>$self->getparam('blocking',1,1)},0,1);
}

#& open($self [, @ignore]) : boolean
sub open : locked method
{
    $_[0]->_trace(\@_,2);
    my $self = shift;
    $self->stopio if $self->isopen;
    my($pf,$af,$type,$proto) = \@{$ {*$self}{Parms}}{qw(PF AF type proto)};
    $$pf = PF_UNSPEC unless defined $$pf;
    $$af = AF_UNSPEC unless defined $$af;
    $$type = 0 unless defined $$type;
    $$proto = 0 unless defined $$proto;
    if (($$pf == PF_UNSPEC) && ($$af != AF_UNSPEC)) {
	$$pf = $$af;
    }
    elsif (($$af == AF_UNSPEC) && ($$pf != PF_UNSPEC)) {
	$$af = $$pf;
    }
    if ($ {*$self}{'isopen'} = socket($self,$$pf,$$type,$$proto)) {
	# keep stdio output buffers out of my way
	$self->condition;
    }
    $self->isopen;
}

# sub listen - autoloaded

# hashes for async. connect error values
my %connok = ( EISCONN,1 );
my %connip = ( EWOULDBLOCK,1 , EINPROGRESS,1 , EAGAIN,1 , EALREADY,1 );

#& _valconnect($self, $addr, $timeout) : boolean
sub _valconnect
{
    my ($self,$addr,$timeout) = @_;
    my ($fhvec,$rdvec,$wrvec,$nfound) = $ {*$self}{FHVec};
    # don't block if socket is non-blocking
    $timeout = 0 if
	!defined $timeout && !$ {*$self}{Parms}{'blocking'};
    # assume caller checked for ->isconnecting
    $rdvec = $wrvec = $fhvec;
    $nfound = CORE::select($rdvec, $wrvec, undef, $timeout);
    # If socket is 'ready', then the connect is complete (possibly failed).
    $ {*$self}{'isconnecting'} = 0 if $nfound;
    # If we don't think the connect has finished, just try to invent a
    # reasonable error and bug out.
    if (!$nfound) {
	$! = EINPROGRESS || EWOULDBLOCK || EALREADY || EAGAIN;
	return;
    }
    my $rval;
    # If we can try to find out with SO_ERROR, give it a shot.
    # This won't give valid results with SOCKS.  Tough.
    if ($ {*$self}{Sockopts}{'SOL_SOCKET'}{'SO_ERROR'}) {
	# Don't try the getsockopt if the connect is still pending!
	# Solaris 2.5.1 (at least) hangs the getsockopt in that case.
	# The connect is complete -- figure out whether we believe
	# the status.
	$rval = getsockopt($self,SOL_SOCKET,SO_ERROR);
	return unless defined $rval;
	$rval = unpack("I", $rval);
	if ($rval) {
	    $! = $rval;
	    return;
	}
	return unless defined getpeername($self);
	return 1;
    }
    # Here, we can't use SO_ERROR (it's not available).
    # The canonical test for success here involves a read() attempt, but
    # we can't use that unless we have a stream socket.  SOCK_SEQPACKET and
    # real datagram services would lose their initial transmission to a
    # read check.  So, we try it here only if we think we are SOCK_STREAM.
    my $type = $ {*$self}{Parms}{'type'};
    if ($type && $type==SOCK_STREAM) {
	my $buf = "";
	$rval = sysread($self,$buf,0);
	return unless defined $rval;
	# It succeeded.  Should it have?  If getpeername says so,
	# we still can't be sure, and we'll have to use a second connect().
    }
    return unless defined getpeername($self);
    $rval = CORE::connect($self,$addr);
    return $rval if $rval;
    return 1 if $connok{0+$!};
    $rval;
}

#& _tryconnect($self, $addr, $timeout) : boolean
sub _tryconnect
{
    my ($self,$addr,$timeout) = @_;
    if ($ {*$self}{'isconnecting'}) {
	if ($ {*$self}{Parms}{'dstaddr'} and
	    ($ {*$self}{Parms}{'dstaddr'} ne $addr))
	{
	    carp "$self->_tryconnect: different destination address while ->isconnecting!"
		if $ {*$self}{Parms}{'debug'} > 2;
	    $self->stopio;
	    return undef unless $self->open;
	    if ($self->getparam('srcaddr') || $self->getparam('srcaddrlist')
		and !$self->isbound)
	    {
		return undef unless $self->bind;
	    }
	}
    }
    # Apparently, some versions of Solaris don't like a second connect.
    # So, if we're retrying a non-blocking connect, check by other means
    # before trying to use a second connect to get the status.
    # Warning: This will not work with SOCKS.
    unless ($ {*$self}{'isconnecting'}) {
	# For Solaris, if datagram socket, don't connect if not bound.
	if ($ {*$self}{Parms}{netgen_fakeconnect}) {
	    if (!$self->isbound) {
		$ {*$self}{Parms}{'dstaddr'} = $addr;
		return 1;
	    }
	    else {
		$self->delparams(['netgen_fakeconnect']);
	    }
	}
	my $rval = CORE::connect($self,$addr);
	return $rval if $rval;
	return 1  if $connok{0+$!};
	return $rval unless $connip{0+$!};
	$ {*$self}{'isconnecting'} = 1;
	$ {*$self}{Parms}{'dstaddr'} = $addr;
	return $rval unless defined $timeout;
    }
    &_valconnect;
}

#& connect($self, [@ignored]) : boolean
sub connect : locked method
{
    $_[0]->_trace(\@_,2);
    my $self = shift;
    my $hval = *$self{HASH};
    my $parms = $hval->{Parms};
    $self->close if
	$hval->{'isconnected'} ||
	(!$hval->{'isconnecting'} && $hval->{'wasconnected'});
    return undef unless $self->isopen or $self->open;
    if ($parms->{'srcaddr'} || $parms->{'srcaddrlist'}
	and !$hval->{'isconnecting'} and !$self->isbound)
    {
	return undef unless $self->bind;
    }
    my $rval;
    my $error = 0;	# errno to propagate if failing
    {
	my ($saveblocking,$timeout);
	if (defined ($timeout = $parms->{'timeout'}) && $self->blocking) {
	    $saveblocking = $self->param_saver('blocking');
	    $self->setparams({'blocking'=>0}) or undef $timeout;
	}
	my $dlist = $parms->{dstaddrlist};
	if (defined($dlist) and
	    ref($dlist) eq 'ARRAY' and
	    !$hval->{'isconnecting'})
	{
	    my $tryaddr;
	    foreach $tryaddr (@{$dlist}) {
		$rval = _tryconnect($self, $tryaddr, $timeout);
		$parms->{dstaddr} = $tryaddr  if $rval;
		last if $rval or
		    defined $timeout && !$timeout
		    and $connip{0+$!};
	    }
	}
	else {
	    $rval = _tryconnect($self, $parms->{dstaddr}, $timeout);
	}
	$error = $!+0 unless $rval;
    }
    $hval->{'isconnected'} = $rval;
    $hval->{'wasconnected'} = '0 but true';
    if (!$rval) {
	$! = $error;
	return $rval;
    }
    $self->getsockinfo;
    $self->isconnected;
}

#& getsockinfo($self, [@ignored]) : ?dest sockaddr?
sub getsockinfo : locked method
{
    $_[0]->_trace(\@_,4);
    my $self = shift;
    my ($sad,$dad);

    $self->setparams({dstaddr => $dad}) if defined($dad = getpeername($self));
    $self->setparams({srcaddr => $sad}) if defined($sad = getsockname($self));
    wantarray ?
	((defined($sad) || defined($dad)) ? ($sad, $dad) : ()) :
	$sad && $dad;
}

# 'static' hashes for translating between SHUT_* values and the traditional
# (but off-by-one) 1-3.  Used for marking shutdown progress.  The connect
# code helps in the conspiracy by setting '0 but true' rather than '0'.

my %to_shut_flags = (SHUT_RD,1, SHUT_WR,2, SHUT_RDWR,3);

#& shutdown($self [, $how=SHUT_RDWR]) : boolean
sub shutdown : locked method
{
    $_[0]->_trace(\@_,3);
    my $self = shift;
    return 1 unless $self->isconnected or $self->isconnecting;
    my $how = shift;
    $how = SHUT_RDWR unless defined $how and $how !~ m/\D/ and length $how;
    $how += 0;
    my $xhow = $to_shut_flags{$how};
    ($how = SHUT_RDWR), ($xhow = 3)
	unless $xhow;
    my $was = ($ {*$self}{'wasconnected'} |= $xhow);
    my $rval = CORE::shutdown($self, $how);
    local $!;	# preserve shutdown()'s errno
    $ {*$self}{'isconnecting'} = $ {*$self}{'isconnected'} = 0 if
	$was == 3 or
	(!defined(getpeername($self)) && ($ {*$self}{'wasconnected'} = 3));
    $rval;
}


my @CloseVars = qw(FHVec isopen isbound didlisten wasconnected isconnected
		   isconnecting);
my @CloseKeys = qw(srcaddr dstaddr);

#& close($self [, @ignored]) : boolean
sub close : locked method
{
    $_[0]->_trace(\@_,3);
    my $self = shift;
    $self->shutdown if $self->isopen;
    $self->stopio;
}

sub CLOSE;
*CLOSE = \&close;

#& stopio($self [, @ignored]) : boolean
sub stopio : locked method
{
    $_[0]->_trace(\@_,4);
    my $self = shift;
    my $wasopen = $self->isopen;
    @{*$self}{@CloseVars} = ();	# these flags no longer true
    $self->delparams(\@CloseKeys); # connection values now invalid
    return 1 unless $wasopen;
    CORE::close($self);
}

# I/O enries

# Warning!  No intercepting of SIGPIPE is done, so the output routines
# can abort the program.

# Note that (at least) Solaris 2.5.1 doesn't like connect() on datagram
# sockets, at least not if they're not bound.  So, we fake it here.

#& send($self, $buf, [$flags, [$where]]) : boolean
sub send
{
    my $whoami = $_[0]->_trace(\@_,3);
    my($self,$buf,$flags,$whither) = @_;
    croak "Invalid args to ${whoami}, called"
	if @_ < 2 or !ref $self;
    $flags = 0 unless defined $flags;
    carp "Excess arguments to ${whoami} ignored" if @_ > 4;
    # send(2) requires connect(2)
    if (!(defined $whither or $self->isconnected)) {
	if ($self->getparams([qw(dstaddrlist dstaddr)],1) > 0) {
	    return undef unless $self->connect;
	    if ($ {*$self}{Parms}{netgen_fakeconnect}) {
		$whither = $ {*$self}{Parms}{'dstaddr'};
	    }
	}
	else {
	    if ($flags & MSG_OOB) {
		$whither = $ {*$self}{lastOOBFrom};
	    }
	    else {
		$whither = $ {*$self}{lastRegFrom};
	    }
# Can't short-circuit this--need to get the right errno value.
#	    return undef unless defined $whither or $self->connect;
	}
    }
    elsif ($self->isconnected && $ {*$self}{Parms}{netgen_fakeconnect}) {
	if (defined $whither) {
	    # *sigh* -- what errno should I return?
	    $! = EISCONN || EINVAL;
	    return undef;
	}
	$whither = $ {*$self}{Parms}{'dstaddr'};
    }
    return getsockopt($self,SOL_SOCKET,SO_TYPE) unless
	$self->isopen;		# generate EBADF return if not open
    defined $whither
	? CORE::send($self, $buf, $flags, $whither)
	: CORE::send($self, $buf, $flags);
}

sub SEND;
*SEND = \&send;

#& put($self, @stuff) : boolean
sub put
{
    $_[0]->_trace(\@_,3);
    my($self,@args) = @_;
    print {$self} @args;
}

sub PRINT;			# avoid -w error
*PRINT = \&put;			# alias that may someday be used for tied FH
sub print;			# avoid -w error
*print = \&put;			# maybe-useful alias

#& ckeof($self) : boolean
sub ckeof : locked method
{
    my $saverr = $!+0;
    local $!;			# preserve this over fcntl() and such
    my $whoami = $_[0]->_trace(\@_,3);
    my($self) = @_;
    croak "Invalid args to ${whoami}, called"
	if !@_ or !ref $self;
    # Bug out if we shouldn't have been called.
    return 1 if EOF_NONBLOCK or $saverr != $eagain;
    # Bug out early if not a socket where EOF is possible.
    return 0
	unless unpack('I',getsockopt($self,SOL_SOCKET,SO_TYPE)) == SOCK_STREAM;
    # See whether need to test for non-blocking status.
    my $flags = ($F_GETFL ? CORE::fcntl($self,$F_GETFL,0+0) : undef);
    if ((defined($flags) && defined($nonblock_flag))
	? ($flags & VAL_O_NONBLOCK)
	: 1)
    {
	# *sigh* -- no way to tell, here
	return 0;
    }
    1;				# wrong errno or blocking
}

#& recv($self, [$maxlen, [$flags, [$from]]]) : {$buf | undef}
sub recv : locked method
{
    my $whoami = $_[0]->_trace(\@_,3);
    my($self,$maxlen,$flags) = @_;
    my($buf,$from,$xfrom) = '';
    croak "Invalid args to ${whoami}, called"
	if !@_ or !ref $self;
    carp "Excess arguments to ${whoami} ignored"
	if @_ > 4;
    return getsockopt($self,SOL_SOCKET,SO_TYPE) unless
	$self->isopen or $self->open; # generate EBADF return if not open
    $maxlen = unpack('I',getsockopt($self,SOL_SOCKET,SO_RCVBUF)) ||
	(stat $self)[11] || 8192
	    unless $maxlen;
    $flags = 0 unless defined $flags;
    if (defined($ {*$self}{sockLineBuf}) && !$flags) {
	$buf = $ {*$self}{sockLineBuf};
	if (length($buf) > $maxlen) {
	    $ {*$self}{sockLineBuf} = substr($buf, $maxlen);
	    substr($buf, $maxlen) = '';
	}
	else {
	    undef $ {*$self}{sockLineBuf};
	}
	$_[3] = $ {*$self}{lastRegFrom} if @_ > 3;
	return $buf;
    }
    $! = 0;			# ease EOF checking
    $xfrom = $from = CORE::recv($self,$buf,$maxlen,$flags);
    my $errnum = $!+0;		# preserve possible recv failure
    $xfrom = getpeername($self) if defined($from) and $from eq '';
    $from = $xfrom if defined($xfrom) and $from eq '' and $xfrom ne '';
    $ {*$self}{lastFrom} = $from;
    $_[3] = $from if @_ > 3;
    if ($flags & MSG_OOB) {
	$ {*$self}{lastOOBFrom} = $from;
    }
    else {
	$ {*$self}{lastRegFrom} = $from;
    }
    $! = $errnum;		# restore possible failure in case we return
    return undef if !defined $from and (EOF_NONBLOCK or $errnum != $eagain);
    return $buf if length $buf;
    # At this point, we had a 0-length read with no error (or EAGAIN).
    # Especially for a SOCK_STREAM connection, this may mean EOF.
    $! = $errnum;		# restore possible failure just in case
    unless ($self->ckeof) {
	return defined($from) ? $buf : undef;
    }
    $self->shutdown(SHUT_RD);	# make sure I know about this EOF
    $! = 0;			# no error for EOF
    undef;			# no buffer, either, though
}

sub get;			# (helps with -w)
*get = \&recv;			# a name that works for indirect references

#& getline($self) : like scalar(<$fhandle>)
sub getline : locked method
{
    my $whoami = $_[0]->_trace(\@_,4);
    carp "Excess arguments to ${whoami} ignored"
	if @_ > 1;
    my ($self) = @_;
    croak "Invalid arguments to ${whoami}, called"
	if !@_ or !ref($self);
    my ($rval, $buf, $tbuf);
    $buf = $ {*$self}{sockLineBuf};
    undef $ {*$self}{sockLineBuf}; # keep get from returning this again
    if (!defined($/)) {
	$rval = <$self>;	# return all of the input
	# what about non-blocking sockets here?!?
	# $self->shutdown(SHUT_RD);	# keep track of EOF
	# Above removed because ->recv does it on real EOF already.
	if (defined($buf) and defined($rval)) {
	    return $buf . $rval
	}
	if (defined($buf)) {
	    return $buf
	}
	return $rval
    }
    my $sep = $/;		# get the current separator
    $sep = "\n\n" if $sep eq ''; # account for paragraph mode
    while (!defined($buf) or $buf !~ /\Q$sep/) {
	$rval = $self->get;
	last unless defined $rval;
	if (defined $buf) {
	    $buf .= $rval;
	}
	else {
	    $buf = $rval;
	}
    }
    if (defined($buf) and ($tbuf = index($buf, $sep)) >= 0) {
	$rval = substr($buf, 0, $tbuf + length($sep));
	$tbuf = substr($buf, length($rval));
	# duplicate annoyance of paragraph mode
	$tbuf =~ s/^\n+//s if $/ eq '';
	$ {*$self}{sockLineBuf} = $tbuf if length($tbuf);
	return $rval;
    }
    else {
	return $buf;
    }
}

sub gets;			# an alias for FileHandle:: or POSIX:: compat.
*gets = \&getline;

sub DESTROY
{
    $_[0]->_trace(\@_,1);
}

#& isopen($self [, @ignored]) : boolean
sub isopen
{
    #$_[0]->_trace(\@_,4," - ".($ {*{$_[0]}}{'isopen'} ? "yes" : "no"));
    $ {*{$_[0]}}{'isopen'};
}

#& isconnected($self [, @ignored]) : boolean
sub isconnected
{
    #$_[0]->_trace(\@_,4," - ".($ {*{$_[0]}}{'isconnected'} ? "yes" : "no"));
    $ {*{$_[0]}}{'isconnected'};
}

#& isconnecting($self [, @ignored]) : boolean
sub isconnecting
{
    #$_[0]->_trace(\@_,4," - ".($ {*{$_[0]}}{'isconnecting'} ? "yes" : "no"));
    $ {*{$_[0]}}{'isconnecting'};
}

#& wasconnected($self [, @ignored]) : boolean
sub wasconnected
{
    #$_[0]->_trace(\@_,4," - ".($ {*{$_[0]}}{'wasconnected'} ? "yes" : "no"));
    $ {*{$_[0]}}{'wasconnected'};
}

#& isbound($self [, @ignored]) : boolean
sub isbound
{
    #$_[0]->_trace(\@_,4," - ".($ {*{$_[0]}}{'isbound'} ? "yes" : "no"));
    $ {*{$_[0]}}{'isbound'};
}

1;

# autoloaded methods go after the END clause (& pod) below

__END__

=head1 NAME

Net::Gen - generic sockets interface handling

=head1 SYNOPSIS

    use Net::Gen;

=head1 DESCRIPTION

The C<Net::Gen> module provides basic services for handling
socket-based communications.  It supports no particular protocol
family directly, however, so it is of direct use primarily to
implementors of other modules.  To this end, several housekeeping
functions are provided for the use of derived classes, as well as
several inheritable methods.  The C<Net::Gen> class does inherit
from C<IO::Handle>, thus making its methods available.  See
L<C<IO::Handle::METHODS>|IO::Handle/METHODS>
for details on those methods.  However, some
of those methods are overridden, so be sure to check the methods
described below to be sure.  (In particular, the C<fcntl> and C<ioctl>
methods are overridden.)

Also provided in this distribution are
L<C<Net::Inet>|Net::Inet>,
L<C<Net::TCP>|Net::TCP>,
L<C<Net::TCP::Server>|Net::TCP::Server>,
L<C<Net::UDP>|Net::UDP>,
L<C<Net::UNIX>|Net::UNIX>,
and
L<C<Net::UNIX::Server>|Net::UNIX::Server>,
which are layered atop C<Net::Gen>.

=head2 Public Methods

The public methods are listed alphabetically below.  Here is an
indication of their functional groupings:

=over 4

=item Creation and setup

C<new>, C<new_from_fd>, C<new_from_fh>, C<init>, C<checkparams>,
C<open>, C<connect>, C<bind>, C<listen>

=item Parameter manipulation

C<setparams>, C<setparam>, C<delparams>, C<delparam>, C<getparams>,
C<getparam>, C<param_saver>

=item Low-level control

C<unbind>, C<condition>, C<getsopt>, C<getropt>, C<setsopt>, C<setropt>,
C<fcntl>, C<ioctl>

=item Medium-level control

C<getsockinfo>, C<shutdown>, C<stopio>, C<close>

=item Informational

C<isopen>, C<isconnected>, C<isbound>, C<didlisten>, C<fhvec>, C<getfh>,
C<fileno>

=item I/O

C<send>, C<sendto>, C<put>, C<recv>, C<get>, C<getline>, C<gets>, C<select>,
C<accept>

=item Utility routines

C<format_addr>, C<format_local_addr>, C<format_remote_addr>

=item Tied filehandle support

C<SEND>, C<PRINT>, C<PRINTF>, C<RECV>, C<READLINE>, C<READ>, C<GETC>,
C<WRITE>, C<CLOSE>, C<EOF>, C<BINMODE>, C<FILENO>,
C<TIEHANDLE>

=item Tied scalar support

C<FETCH>, C<STORE>, C<TIESCALAR>

=item Accessors

Any of the I<keys> known to the C<getparam> and C<setparams> methods
may be used as an I<accessor> function.  See L<"Known Object Parameters">
below, and the related sections in the derived classes.  For an example,
see C<blocking>, below.

=back

The descriptions, listed alphabetically:

=over 4

=item accept

Usage:

    $newobj = $obj->accept;

Returns a new object in the same class as the given object if an
accept() call succeeds, and C<undef> otherwise.  If the accept()
call succeeds, the new object is marked as being open, connected,
and bound.  This can fail unexpectedly if the listening socket is
non-blocking or if the object has a C<timeout> parameter.  See the
discussion of non-blocking sockets and timeouts in L</connect> below.

=item bind

Usage:

    $ok = $obj->bind;

Makes a call to the bind() builtin on the filehandle associated
with the object.  The arguments to bind() are determined from the
current parameters of the object.  First, if the filehandle has
previously been bound or connected, it is closed.  Then, if it is
not currently open, a call to the C<open> method is made.  If all
that works (which may be a no-op), then the following list of
possible values is tried for the bind() builtin:  First, the
C<srcaddrlist> object parameter, if its value is an array
reference.  The elements of the array are tried in order until a
bind() succeeds or the list is exhausted.  Second, if the
C<srcaddrlist> parameter is not set to an array reference, if the
C<srcaddr> parameter is a non-null string, it will be used.
Finally, if neither C<srcaddrlist> nor C<srcaddr> is suitably
set, the C<AF> parameter will be used to construct a C<sockaddr>
structure which will be mostly zeroed, and the bind() will be
attempted with that.  If the bind() fails, C<undef> will be
returned at this point.  Otherwise, a call to the C<getsockinfo>
method will be made, and then the value from a call to the
C<isbound> method will be returned.

If all that seems too confusing, don't worry.  Most clients will
never need to do an explicit C<bind> call, anyway.  If you're
writing a server or a privileged client which does need to bind
to a particular local port or address, and you didn't understand
the foregoing discussion, you may be in trouble.  Don't panic
until you've checked the discussion of binding in the derived
class you're using, however.

=item BINMODE

Usage:

    binmode(TIEDFH);

A no-op provided for the tied file handle support of perl 5.005_57.
The sockets managed by this module are always set binmode() anyway.

=item blocking

Usage:

    $isblocking = $obj->blocking;
    $oldblocking = $obj->blocking($newvalue);

The C<blocking> method is an example of an I<accessor> method.  The
above usage examples are (effectively) equivalent to the following code
snippets, respectively:

    $isblocking = $obj->getparam('blocking');

    $oldblocking = $obj->getparam('blocking');
    $obj->setparams({blocking=>$newvalue});

The C<getparam> method call is skipped if the accessor method was
called in void context.

=item checkparams

Usage:

    $ok = $obj->checkparams;

Verifies that all previous parameter assignments are valid.
(Normally called only via the C<init> method, rather than
directly.)

=item close

=item CLOSE

Usage:

    $ok = $obj->close;
    $ok = close(TIEDFH);

The C<close> method is like a call to the C<shutdown> method
followed by a call to the C<stopio> method.  It is the standard
way to close down an object.

=item condition

Usage:

    $obj->condition;

(Re-)establishes the condition of the associated filehandle after
an open() or accept().  (In other words, the C<open> and C<accept>
methods call the C<condition> method.)
Sets the socket to be autoflushed and marks it binmode().
This method attempts to set the socket blocking or non-blocking, depending on
the state of the object's C<blocking> parameter.  (It may update that parameter
if the socket's state cannot be made to match.)
No useful value is returned.

=item connect

Usage:

    $ok = $obj->connect;

Attempts to establish a connection for the object.
[Note the special information for re-trying connects on non-blocking sockets,
later in this section.]

First, if the
object is currently connected or has been connected since the
last time it was opened, its C<close> method is called.  Then, if
the object is not currently open, its C<open> method is called.
If it's not open after that, C<undef> is returned.  If it is
open, and if either of its C<srcaddrlist> or C<srcaddr>
parameters are set to indicate that a bind() is desired, and it
is not currently bound, its C<bind> method is called.  If the
C<bind> method is called and fails, C<undef> is returned.  (Most
of the foregoing is a no-op for simple clients, so don't panic.)

Next, if the C<dstaddrlist> object parameter is set to an array
reference, a call to connect() is made for each element of the
list until it succeeds or the list is exhausted.  If the
C<dstaddrlist> parameter is not an array reference, a single
attempt is made to call connect() with the C<dstaddr> object
parameter.  If no connect() call succeeded, C<undef> is returned.
Finally, a call is made to the object's C<getsockinfo> method,
and then the value from a call to its C<isconnected> method is
returned.

Each of the attempts with the connect() builtin is timed out separately.
If there is no C<timeout> parameter for the object, and the socket is
blocking (which is the default), the timeout period is strictly at the
mercy of your operating system.  If there is no C<timeout> parameter and the
socket is non-blocking, that's effectively the same as having a C<timeout>
parameter value of C<0>.  If there is a C<timeout> parameter, the socket
is made non-blocking temporarily (see L<"param_saver"> below), and the
indicated timeout value will be used to limit the connection attempt.  An
attempt is made to preserve any meaningful $! values when all connection
attempts have failed.  In particular, if the C<timeout> parameter is 0,
then each failed connect returns without completing the processing of
the C<dstaddrlist> object parameter.  This is so that the re-try logic
for connections in progress will be more useful.

If, on entry to the C<connect> method, the object is already marked as
having a connection in progress (C<$obj-E<gt>isconnecting> returns true),
then the connection will be re-tried with a timeout of 0 to see whether it
has succeeded in the meanwhile.  The appropriate success/fail condition
for that check will be returned, with no further processing of the
C<dstaddrlist> object parameter.

Note that the derived classes tend to provide additional
capabilities which make the C<connect> method easier to use than
the above description would indicate.

=item delparam

Usage:

    $ok = $obj->delparam($keyname);

Sugar-coated call to the C<delparams> method.

=item delparams

Usage:

    $ok = $obj->delparams(\@keynames);

Removes the settings for the specified parameters.  Uses the
C<setparams> method (with C<undef> for the values) to validate
that the removal is allowed by the owning object.  If the
invocation of C<setparams> is successful, then the parameters in
question are removed.  Returns 1 if all the removals were
successful, and C<undef> otherwise.

=item didlisten

Usage:

    $ok = $obj->didlisten;

Returns true if the object's C<listen> method has been used
successfully, and the object is still bound.  If this method has
not been overridden by a derived class, the value is C<undef> on
failure and the C<$maxqueue> value used for the listen() builtin
on success.

=item EOF

Usage:

    $iseof = $obj->EOF();
    $iseof = eof(TIEDFH);

Provided for tied filehandle support.  Determines whether select()
says that a read would work immediately, and tries it if so.
If the read was tried and returned an eof condition, 1 is returned.
The return is 0 on read errors or when select() said that a read
would block.  Note that this interferes with use of the select()
built-in, since it has to buffer the read data if the read was
successful.

=item fcntl

Usage:

    $rval = $obj->fcntl($func, $value);

Returns the result of an fcntl() call on the associated I/O stream.

=item FETCH

Usage:

    $data = $TIED_SCALAR;

This is for the support of the C<TIESCALAR> interface.  It returns
the result of a call to the C<READLINE> method on the underlying object.

=item fhvec

Usage:

    $vecstring = $obj->fhvec;

Returns a vector suitable as an argument to the 4-argument select()
call.  This is for use in doing selects with multiple I/O streams.
See also L<"select">.

=item fileno

=item FILENO

Usage:

    $fnum = $obj->fileno;
    $fnum = fileno(TIEDFH);

Returns the actual file descriptor number for the underlying socket.
See L<"getfh"> for some restrictions as to the safety of using this.

=item format_addr

Usage:

    $string = $obj->format_addr($sockaddr);
    $string = format_addr Module $sockaddr;

Returns a formatted representation of the address.  This is a
method so that it can be overridden by derived classes.  It is
used to implement ``pretty-printing'' methods for source and
destination addresses.

=item format_local_addr

Usage:

    $string = $obj->format_local_addr;

Returns a formatted representation of the local socket address
associated with the object.

=item format_remote_addr

Usage:

    $string = $obj->format_remote_addr;

Returns a formatted representation of the remote socket address
associated with the object.

=item get

This is just a sugar-coated way to call the C<recv> method which will
work with indirect-object syntax.  See L<"recv"> for details.

=item GETC

Usage:

    $char = $obj->GETC;
    $char = getc(TIEDFH);

This method uses the C<recv> method with a $flags argument of 0 and
a $maxlen argument of 1 to emulate the getc() builtin.  Like that builtin,
it returns a string representing the character read when successful,
and undef on eof or errors.  This method exists for the support of tied
filehandles.  It's unreliable for non-blocking sockets.

=item getfh

Usage:

    $fhandle = $obj->getfh;

I've strongly resisted giving people direct access to the filehandle
embedded in the object because of the problems of mixing C<stdio> input
calls and traditional socket-level I/O.  However, if you're sure you can
keep things straight, here are the rules under which it's safe to use the
embedded filehandle:

=over 6

=item *

Don't use perl's own C<stdio> calls.  Stick to sysread() and recv().

=item *

Don't use the object's C<getline> method, since that stores a read-ahead
buffer in the object which only the object's own C<get>/C<recv> and
C<getline> methods know to return to you.  (The object's C<select> method
knows about the buffer enough to tell you that a read will succeed if
there's saved data, though.)  Similarly, avoid the object's C<EOF> method.

=item *

Please don't change the state of the socket behind my back.  That
means no close(), shutdown(), connect(), bind(), or listen()
built-ins.  Use the corresponding methods instead, or all bets
are off.  Of course, if you're only using this module to get the
connect() or bind() processing, and you're going to discard the object
after you've done your I/O, then it's OK to use the built-ins for I/O.
Just don't expect my code to know what you did behind my back.

=back

That C<$fh> is a glob ref, by the way, but that doesn't matter for calling
the built-in I/O primitives.

=item getline

Usage:

    $line = $obj->getline;

This is a simulation of C<scalar(E<lt>$filehandleE<gt>)> that doesn't let
stdio confuse the C<get>/C<recv> method.  As such, its return value is
not necessarily a complete line when the socket is non-blocking.

=item getlines

Usage:

    @lines = $obj->getlines;

This is a lot like C<@lines = E<lt>$filehandleE<gt>>, except that it doesn't
let stdio confuse the C<get>/C<recv> method.  It's unreliable on non-blocking
sockets.  It will produce a fatal (but trappable) error if not called in
list context.  (In other words, it uses the die() builtin when not called in
list context.)

=item getparam

Usage:

    $value = $obj->getparam($key, $defval, $def_if_undef);
    $value = $obj->getparam($key, $defval);
    $value = $obj->getparam($key);

Returns the current setting for the named parameter (in the
current object), or the specified default value if the parameter
is not in the object's current parameter list.  If the optional
C<$def_if_undef> parameter is true, then undefined values will be
treated the same as non-existent keys, and thus will return the
supplied default value (C<$defval>).

=item getparams

Usage:

    %hash = $obj->getparams(\@keynames, $noundefs);
    %hash = $obj->getparams(\@keynames);
    $llen = $obj->getparams(\@keynames, $noundefs);
    $llen = $obj->getparams(\@keynames);

Returns a hash as a list (I<not> a reference) consisting of the key-value
pairs corresponding to the specified keyname list.  Only those
keys which exist in the current parameter list of the object will
be returned.  If the C<$noundefs> parameter is present and true,
then existing keys with undefined values will be suppressed as with
non-existent keys.  If called in scalar context, returns the
number of values which would have been returned in list context.
(This is twice the number of key-value pairs, in case that wasn't clear.)

=item getropt

Usage:

    $optsetting = $obj->getropt($level, $option);
    $optsetting = $obj->getropt($optname);

Returns the raw value from a call to the getsockopt() builtin.
If both the C<$level> and C<$option> arguments are given as
numbers, the getsockopt() call will be made even if the given
socket option is not registered with the object.  Otherwise, the
return value for unregistered options will be undef with the
value of $! set as described below for the C<getsopt> method.

=item gets

Usage:

    $line = $obj->gets;

This is a simulation of C<scalar(E<lt>$filehandleE<gt>)> that doesn't let
stdio confuse the C<get>/C<recv> method.  (The C<gets> method is just
an alias for the C<getline> method, for partial compatibility with
the POSIX module.)  This method is deprecated.  Use the C<getline> method
by that name, instead.  The C<gets> method may disappear in a future release.

=item getsockinfo

Usage:

    ($localsockaddr, $peersockaddr) = $obj->getsockinfo;
    $peersockaddr = $obj->getsockinfo;

Attempts to determine connection parameters associated with the
object.  If a getsockname() call on the associated filehandle
succeeds, the C<srcaddr> object parameter is set to that returned
sockaddr.  If a getpeername() call on the associated filehandle
succeeds, the C<dstaddr> parameter is set to that returned
sockaddr.  In scalar context, if both socket addresses were
found, the getpeername() value is returned, otherwise C<undef> is
returned.  In list context, the getsockname() and getpeername()
values are returned, unless both are undefined.

Derived classes normally override this method with one which
provides friendlier return information appropriate to the derived
class, and which establishes more of the object parameters.

=item getsopt

Usage:

    @optvals = $obj->getsopt($level, $option);
    @optvals = $obj->getsopt($optname);

Returns the unpacked values from a call to the getsockopt()
builtin.  In order to do the unpacking, the socket option must
have been registered with the object.  See the additional discussion of
socket options in L</initsockopts> below.

Since registered socket options are known by name as well as by
their level and option values, it is possible to make calls using
only the option name.  If the name is not registered with the object,
the return value is the same as that for C<getsopt $obj -1,-1>,
which is an empty return array and $! set appropriately (should
be C<EINVAL>).

Examples:

    ($sotype) = $obj->getsopt('SO_TYPE');
    @malinger = $obj->getsopt(SOL_SOCKET, SO_LINGER);
    ($sodebug) = $obj->getsopt('SOL_SOCKET', 'SO_DEBUG');

=item init

Usage:

    return undef unless $self->init;

Verifies that all previous parameter assignments are valid (via
C<checkparams>).  Returns the incoming object on success, and
C<undef> on failure.  This method is normally called from the C<new>
method appropriate to the class of the created object.

=item ioctl

Usage:

    $rval = $obj->ioctl($func, $value);

Returns the result of an ioctl() call on the associated I/O stream.

=item isbound

Usage:

    $ok = $obj->isbound;

Returns true if the object's C<bind> method has been used
successfully, and the binding is still in effect.  If this method
has not been overridden by a derived class, the value is the
saved return value of the call to the bind() builtin (if it was
called).

=item isconnected

Usage:

    $ok = $obj->isconnected;

Returns true if the object's C<connect> method has been used
successfully to establish a "session", and that session is still
connected.  If this method has not been overridden by a derived
class, the value is the saved return value of the call to the
connect() builtin (if it was called).

=item isconnecting

Usage:

    $ok = $obj->isconnecting;

Returns true if the object's C<connect> method has been used
with a timeout or on a non-blocking socket, and the connect() did
not complete.  In other words, the failure from the connect() builtin
indicated that the operation was still in progress.  (A rejected
connection or a connection which exceeded the operating system's timeout
is said to have completed unsuccessfully, rather than not to have completed.)

=item isopen

Usage:

    $ok = $obj->isopen;

Returns true if the object currently has a socket attached to its
associated filehandle, and false otherwise.  If this method has
not been overridden by a derived class, the value is the saved
return value of the call to the socket() builtin (if it was
called).

=item listen

Usage:

    $ok = $obj->listen($maxqueue);
    $ok = $obj->listen;

Makes a call to the listen() builtin on the filehandle associated
with the object.  Propagates the return value from listen().  If
the C<$maxqueue> parameter is missing, it defaults to the value
of the object's I<maxqueue> parameter, or the value of C<SOMAXCONN>.
If the C<SOMAXCONN> constant is not available in your
configuration, the default value used for the C<listen> method is
5.  This method will fail if the object is not bound and cannot
be made bound by a simple call to its C<bind> method.

=item new

Usage:

    $obj = $classname->new();
    $obj = $classname->new(\%parameters);

Returns a newly-initialised object of the given class.  If called
for a class other than C<Net::Gen>, no validation of the supplied
parameters will be performed.  (This is so that the derived class
can add the parameter validation it needs to the object before
allowing validation.)

=item new_from_fd

=item new_from_fh

Usage:

    $obj = $classname->new_from_fh(*FH);
    $obj = $classname->new_from_fh(\*FH);
    $obj = $classname->new_from_fd(fileno($fh));

Returns a newly-initialised object of the given class, open on a
newly-dup()ed copy of the given filehandle or file descriptor.
As many of the standard object parameters as possible will be
determined from the passed filehandle.  This is determined (in
part) by calling the corresponding C<new>, C<init>, and
C<getsockinfo> methods for the new object.

Only real filehandles or file descriptor numbers are allowed as
arguments.  This method makes no attempt to resolve filehandle
names.  Yes, despite having two names, there's really just one method.

=item open

Usage:

    $ok = $obj->open;

Makes a call to the socket() builtin, using the current object
parameters to determine the desired protocol family, socket type,
and protocol number.  If the object was already open, its
C<stopio> method will be called before socket() is called again.
The object parameters consulted (and possibly updated) are C<PF>,
C<AF>, C<proto>, C<type>, and C<blocking>.  Returns true if the socket() call
results in an open filehandle, C<undef> otherwise.

=item param_saver

=item paramSaver

Usage:

    my $savedstuff = $obj->param_saver(@param_names);
    my $savedstuff = $obj->paramSaver(@param_names);

Saves the values (or lack thereof) for the indicated parameter names
by wrapping them (and the original object)
in an object blessed into an alternate package.  When this `saver' object
is destroyed (typically because the `my' variable went out of scope),
the previous values of the parameters for the original object will be
restored.  This allows for temporary changes to an object's parameter
settings without the worry of whether an inopportune die() will prevent
the restoration of the original settings.

An example (from the C<connect> method):

    my $saveblocking = $self->param_saver('blocking');

(This is used when there is a C<timeout> parameter for the object.)

=item print

=item PRINT

See L</put> for details, as this method is just an alias for the C<put> method.
The C<PRINT> alias is for the support of tied filehandles.

=item PRINTF

Usage:

    $ok = $obj->PRINTF($format, @args);
    $ok = printf TIEDFH $format, @args;

This method uses the sprintf() builtin and the C<PRINT> method
to send the @args values to the
filehandle associated with the object, using the $format format string.
It exists for the support of tied filehandles.

=item put

Usage:

    $ok = $obj->put(@whatever);
    $ok = put $obj @whatever;

This method uses the print() builtin to send the @whatever
arguments to the filehandle associated with the object.  That
filehandle is always marked for autoflushing by the C<open>
method, so the method is in effect equivalent to this:

    $ok = $obj->send(join($, , @whatever) . $\ , 0);

However, since multiple fwrite() calls are sometimes involved in
the actual use of print(), this method can be more efficient than
the above code sample for large strings in the argument list.
It's a bad idea except on stream sockets (C<SOCK_STREAM>)
though, since the record boundaries are unpredictable through
C<stdio>.  It's also a bad idea on non-blocking sockets, since the amount
of data actually written to the socket is unknown.
This method makes no attempt to trap C<SIGPIPE>.

=item READ

Usage:

    $numread = $obj->READ($buffer, $maxlen);
    $numread = $obj->READ($buffer, $maxlen, $offset);
    $numread = read(TIEDFH, $buffer, $maxlen);
    $numread = read(TIEDFH, $buffer, $maxlen, $offset);

This method uses the C<recv> method (with a flags argument of 0) to
emulate the read() and sysread() builtins.  This is specifically for the
support of tied filehandles.  Like the emulated builtins, this method
returns the number of bytes successfully read, or undef on error.

=item READLINE

Usage:

    $line = $obj->READLINE;
    @lines = $obj->READLINE;
    $line = readline(TIEDFH);	# or $line = <TIEDFH>;
    @lines = readline(TIEDFH);	# or @lines = <TIEDFH>;

This method supports the use of the E<lt>E<gt> (or readline()) operator
on tied filehandles.  In scalar context, it uses the C<getline> method.
In list context, it reads all remaining input on the socket (until eof, which
makes this unsuitable for connectionless socket types such as UDP), and
splits it into lines based on the current value of the $/ variable.
The return value is unreliable for non-blocking sockets.

=item RECV

Usage:

    $from = $obj->RECV($buffer, $maxlen, $flags);
    $from = $obj->RECV($buffer, $maxlen);
    $from = $obj->RECV($buffer);

This method calls the recv() method with the arguments and return
rearranged to match the recv() builtin.  This is for the support of
tied filehandles.

=item recv

Usage:

    $record = $obj->recv($maxlen, $flags, $whence);
    $record = $obj->recv($maxlen, $flags);
    $record = $obj->recv($maxlen);
    $record = $obj->recv;

This method calls the recv() builtin, and returns a buffer (if
one is received) or C<undef> on eof or error.  If an eof is seen
on the socket (as checked with its C<ckeof> method), then $!
will be 0 on return.  If the C<$whence> argument is supplied, it
will be filled in with the sending socket address if possible.
If the C<$flags> argument is not supplied, it defaults to 0.  If
the C<$maxlen> argument is not supplied, it is defaulted to the
receive buffer size of the associated filehandle (if known), or
the preferred blocksize of the associated filehandle (if known,
which it usually won't be), or 8192.

=item select

Usage:

    ($nfound, $timeleft, $rbool, $wbool, $xbool) =
	$obj->select($doread, $dowrite, $doxcept, $timeout);
    $nfound = $obj->select($doread, $dowrite, $doxcept, $timeout);

Issues a 4-argument select() call for the associated I/O stream.  All
arguments are optional.  The $timeout argument is the same as the fourth
argument to the select() builtin.
The first three are booleans, used to determine
whether the method should include the object's I/O stream in the
corresponding parameter to the select() call.  The return in list context is
the standard two values from select(), follwed by booleans indicating
whether the actual select() call found reading, writing, or exception to be
true.  In scalar context, the routine returns only the count of the number
of matching conditions.  This is probably only useful when you're checking
just one of the three possible conditions.

=item SEND

=item send

Usage:

    $ok = $obj->send($buffer, $flags, $destsockaddr);
    $ok = $obj->send($buffer, $flags);
    $ok = $obj->send($buffer);

This method calls the send() builtin (three- or four-argument
form).  The C<$flags> parameter is defaulted to 0 if not
supplied.  If the C<$destsockaddr> value is missing or undefined,
and the socket is connected (C<$obj-E<gt>isconnected> returns true), then
the three-argument form of the send() builtin will be used.  Otherwise, the
C<$destsockaddr> parameter will be defaulted from the last recv()
peer address for the same kind of message (depending on whether
C<MSG_OOB> is set in the C<$flags> parameter).  A defined
C<$destsockaddr> will result in a four-argument send() call.  The
return value from the send() builtin is returned.  This method
makes no attempt to trap C<SIGPIPE>.

=item sendto

Usage:

    $ok = $obj->sendto($buffer, $destsockaddr, $flags);
    $ok = $obj->sendto($buffer, $destsockaddr);

This method calls the send() builtin (four-argument form).  The
C<$flags> parameter is defaulted to 0 if not supplied.  The
return value from the send() builtin is returned.  This method
makes no attempt to trap C<SIGPIPE>.

=item setparam

Usage:

    $ok = $obj->setparam($key, $value, $newonly, $checkup);
    $ok = $obj->setparam($key, $value, $newonly);
    $ok = $obj->setparam($key, $value);

Sets a single new parameter.  Uses the C<setparams> method, and
has the same rules for the handling of the C<$newonly> and
C<$checkup> parameters.  Returns 1 if the set was successful, and
C<undef> otherwise.

=item setparams

Usage:

    $ok = $obj->setparams(\%newparams, $newonly, $checkup);
    $ok = $obj->setparams(\%newparams, $newonly);
    $ok = $obj->setparams(\%newparams);

Sets new parameters from the given hashref, with validation.
This is done in a loop over the I<key, value> pairs from the
C<newparams> parameter.  The precise nature of the validation
depends on the C<$newonly> and C<$checkup> parameters (which are
optional), but in all cases the keys to be set are checked
against those registered with the object.  If the C<$newonly>
parameter is negative, the value from the hashref will only be
set if there is not already a defined value associated with that
key, but the skipping of the setting of the value is silent.  If the
C<$newonly> parameter is not negative or if there is no existing
defined value, if the C<$checkup> parameter is false then the
setting of the new value is skipped if the new value is identical
to the old value.  If those checks don't cause the setting of a
new value to be skipped, then if the C<$newonly> parameter is
positive and there is already a defined value for the specified
key, a warning will be issued and the new value will not be set.

If none of the above checks cause the setting of a new value to
be skipped, but if the specified key has a validation routine,
that routine will be called with the given object, the current
key, and the proposed new value as parameters.  It is allowed for
the validation routine to alter the new-value argument to change
what will be set.  (This is useful when changing a hostname to be
in canonical form, for example.)  If the validation routine
returns a non-null string, that will be used to issue a warning,
and the new value will not be set.  If the validation routine
returns a null string (or if there is no validation routine), the
new value will (finally) get set for the given key.

The C<setparams> method returns 1 if all parameters were
successfully set, and C<undef> otherwise.

=item setropt

Usage:

    $ok = $obj->setropt($level, $option, $rawvalue);
    $ok = $obj->setropt($optname, $rawvalue);

Returns the result from a call to the setsockopt() builtin.  If
the $level and $option arguments are both given as numbers, the
setsockopt() call will be made even if the option is not
registered with the object.  Otherwise, unregistered options will
fail as for the C<setsopt> method, below.

=item setsopt

Usage:

    $ok = $obj->setsopt($level, $option, @optvalues);
    $ok = $obj->setsopt($optname, @optvalues);

Returns the result from a call to the setsockopt() builtin.  In
order to be able to pack the C<@optvalues>, the option must be
registered with the object, just as described in L</getsopt>
above.

=item shutdown

Usage:

    $ok = $obj->shutdown($how);
    $ok = $obj->shutdown;

Calls the shutdown() builtin on the filehandle associated with
the object.  This method is a no-op, returning 1, if the
filehandle is not connected.  The C<$how> parameter is as per the
shutdown() builtin, which in turn should be as described in the
shutdown(2) manpage.  If the C<$how> parameter is not present,
it is assumed to be C<SHUT_RDWR> (which is 2 on most UNIX systems).

Returns 1 if it has nothing to do, otherwise propagates the return from
the shutdown() builtin.

=item stopio

Usage:

    $ok = $obj->stopio;

Calls the close() builtin on the filehandle associated with the
object, unless that filehandle is already closed.  Returns 1 or
the return value from the close() builtin.  This method is
primarily for the use of server modules which need to avoid
C<shutdown> calls at inappropriate times.  This method calls the
C<delparams> method for the keys of C<srcaddr> and C<dstaddr>.

=item STORE

Usage:

    $TIED_SCALAR = $data;

Provided for the support of tied scalars.  Results in a call to the
C<put> method, unless there's exactly one arg and it's C<undef>.
In that case, since this normally results from C<undef $TIED_SCALAR>,
it's ignored.

=item TIEHANDLE

Usage:

    tie *FH, $package, @options or die;
    print FH $out_data;
    print $in_data while defined($in_data = <FH>);
    untie *FH;

Tieing of a filehandle to a network handle is supported by this base
However, this method only succeeds if the related call to the C<new>
method returns an object for which the C<isconnected> method returns
true.  Thus, the most useful example is in
L<C<Net::UDP>|Net::UDP/"TIEHANDLE support">.

=item TIESCALAR

Usage:

    tie $x, $package, @options or die;
    $x = $out_data;
    print $in_data while defined($in_data = $x);
    untie $x;

Tieing of scalars to a network handle is supported by this base class.
However, this method only succeeds if the related call to the C<new>
method returns an object for which the C<isconnected> method returns
true.  Thus, the useful examples are in
L<C<Net::TCP>|Net::TCP/TIESCALAR>
and
L<C<Net::UDP>|Net::UDP/"TIESCALAR support">.

=item unbind

Usage:

    $obj->unbind;

Removes any saved binding for the object.  Unless the object is
currently connected, this will result in a call to its C<close>
method, in order to ensure that any previous binding is removed.
Even if the object is connected, the C<srcaddrlist> object
parameter is removed (via the object's C<delparams> method).  The
return value from this method is indeterminate.

=item wasconnected

Usage:

    $was = $obj->wasconnected;

Returns true if the object has had a successful connect() completion
since it was last opened.  Returns false after a close() or on a new
object.  Also returns true if C<$obj-E<gt>isconnecting> is true.

=item WRITE

Usage:

    $nwritten = $obj->WRITE($buf, $len);
    $nwritten = $obj->WRITE($buf, $len, $offset);
    $nwritten = syswrite(TIEDFH, $buf, $len);
    $nwritten = syswrite(TIEDFH, $buf, $len, $offset);

This method exists for support of syswrite() on tied filehandles.
It calls the syswrite() builtin on the underlying filehandle with the
same parameters.

=back

=head2 Protected Methods

Yes, I know that Perl doesn't really have protected methods as
such.  However, these are the methods which are only useful for
implementing derived classes, and not for the general user.

=over 4

=item ckeof

Usage:

    $wasiteof = $obj->ckeof;

After a 0-length read in the get() routine, it calls this method to
determine whether such a 0-length read meant EOF.  The default method
supplied here checks for non-blocking sockets (if necessary), and
for a C<SOCK_STREAM> socket.  If EOF_NONBLOCK is true, or if the
C<VAL_O_NONBLOCK> flag was not set in the fcntl() flags for the
socket, or if the error code was not VAL_EAGAIN, I<and> the socket
is of type C<SOCK_STREAM>, then this method returns true.  It
returns a false value otherwise.  This method is overridable for
classes like C<Net::Dnet>, which support C<SOCK_SEQPACKET> and
need to make a protocol-family-specific check to tell a 0-length
packet from EOF.

=item initsockopts

Usage:

    $classname->initsockopts($level, \%optiondesc);

Given a prototype optiondesc hash ref, updates it to include all
the data needed for the values it can find, and deletes the ones
it can't.  For example, here's a single entry from such a
prototype optiondesc:

    'SO_LINGER' => ['II'],

Given that, and the $level of C<SOL_SOCKET>, and the incoming
class name of C<Net::Gen>, C<initsockopts> will attempt to
evaluate C<SO_LINGER> in package C<Net::Gen>, and if it succeeds
it will fill out the rest of the information in the associated
array ref, and add another key to the hash ref for the value of
C<SO_LINGER> (which is 128 on my system).  If it can't evaluate
that psuedo-constant, it will simply delete that entry from the
referenced hash.  Assuming a successful evaluation of this entry,
the resulting entries would look like this:

    'SO_LINGER' => ['II', SO_LINGER+0, SOL_SOCKET+0, 2],
    SO_LINGER+0 => ['II', SO_LINGER+0, SOL_SOCKET+0, 2],

(All right, so the expressions would be known values, but maybe
you get the idea.)

A completed optiondesc hash is a set of key-value pairs where the
value is an array ref with the following elements:

    [pack template, option value, option level, pack array len]

Such a completed optiondesc is one of the required arguments to
the C<register_options> method (see below).

=item register_options

=item registerOptions

Usage:

    $obj->register_options($levelname, $level, \%optiondesc);

This method attaches the socket options specified by the given
option descriptions hash ref and the given level (as text and as
a number) to the object.  The registered set of socket options is
in fact a hashref of hashrefs, where the keys are the level names
and level numbers, and the values are the optiondesc hash refs
which get registered.

Example:

    $self->register_options('SOL_SOCKET', SOL_SOCKET+0, \%sockopts);

=item register_param_handlers

=item registerParamHandlers

Usage:

    $obj->register_param_handlers(\@keynames, \@keyhandlers);
    $obj->register_param_handlers(\%key_handler_pairs);

This method registers the referenced keynames (if they haven't
already been registered), and establishes the referenced
keyhandlers as validation routines for those keynames.  Each
element of the keyhandlers array must be a code reference.  When
the C<setparams> method invokes the handler, it will be called
with three arguments: the target object, the keyname in question,
and the proposed new value (which may be C<undef>, especially if
being called from the C<delparams> method).  See the other
discussion of validation routines in the C<setparams> method
description, above.

=item register_param_keys

=item registerParamKeys

Usage:

    $obj->register_param_keys(\@keynames);

This method registers the referenced keynames as valid parameters
for C<setparams> and the like for this object.  The C<new>
methods can store arbitrary parameter values, but the C<init>
method will later ensure that all those keys eventually got
registered.  This out-of-order setup is allowed because of
possible cross-dependencies between the various parameters, so
they have to be set before they can be validated (in some cases).

=item _accessor

Usage:

    $value = $obj->_accessor($what);
    $oldvalue = $obj->_accessor($what, $newvalue);

This method implements the use of the known parameter keys as get/set
methods.  It's used by the customised AUTOLOAD to generate such accessor
functions as they're referenced.  See L<"blocking"> above for an example.

=back

=head2 Known Socket Options

These are the socket options known to the C<Net::Gen> module
itself:

=over 4

=item Z<>

C<SO_ACCEPTCONN>,
C<SO_BROADCAST>,
C<SO_DEBUG>,
C<SO_DONTROUTE>,
C<SO_ERROR>,
C<SO_EXPANDED_RIGHTS>,
C<SO_FAMILY>,
C<SO_KEEPALIVE>,
C<SO_LINGER>,
C<SO_OOBINLINE>,
C<SO_PAIRABLE>,
C<SO_RCVBUF>,
C<SO_RCVLOWAT>,
C<SO_RCVTIMEO>,
C<SO_REUSEADDR>,
C<SO_REUSEPORT>,
C<SO_SNDBUF>,
C<SO_SNDLOWAT>,
C<SO_SNDTIMEO>,
C<SO_STATE>,
C<SO_TYPE>,
C<SO_USELOOPBACK>,
C<SO_XSE>

=back

=head2 Known Object Parameters

These are the object parameters registered by the C<Net::Gen>
module itself:

=over 4

=item AF

Address family (will default from PF, and vice versa).

=item blocking

Set to 0 when a socket has been marked as non-blocking, and to 1
otherwise.  If it's C<undef>, it'll be treated as though it were
set to 1.  The use of anything which even looks like C<stdio>
calls on non-blocking sockets as at your own risk.  If you don't know
how to work with non-blocking sockets already, the results of trying
them may surprise you.

=item dstaddr

The result of getpeername(), or an ephemeral proposed connect() address.

=item dstaddrlist

A reference to an array of socket addresses to try for connect().

=item maxqueue

An override of the default maximum queue depth parameter for
listen().  This will be used if the $maxqueue argument to
listen() is not supplied.

=item netgen_fakeconnect

This parameter is set true to keep the C<connect> method from
really calling the connect() built-in if the socket has not
had an source address specified and it is not bound.  This
is used by the
L<Net::UNIX|Net::UNIX>
and
L<Net::UDP|Net::UDP>
modules to keep
from exercising a bug in some socket implementations with respect
to how datagram sockets are handled.  (This was specifically done
in response to quirks of Solaris 2.5.1.)  Instead, the C<connect>
method simply sets the C<dstaddr> object parameter, which the C<send>
method will respect.

=item PF

Protocol family for this object.  Will default from AF, and vice versa.

=item proto

The protocol to pass to the socket() call (often defaulted to 0).

=item reuseaddr

A boolean, indicating whether the C<bind> method should do a
setsockopt() call to set C<SO_REUSEADDR> to 1.

=item reuseport

A boolean, indicating whether the C<bind> method should do a
setsockopt() call to set C<SO_REUSEPORT> to 1.

=item srcaddr

The result of getsockname(), or an ephemeral proposed bind() address.

=item srcaddrlist

A reference to an array of socket addresses to try for bind().

=item timeout

The maximum time to wait for connect() or accept() attempts to succeed.
See the discussion of timeouts and non-blocking sockets
in L</connect> above.

=item type

The socket type to create (C<SOCK_STREAM>, C<SOCK_DGRAM>, etc.)

=back

=head2 Non-Method Subroutines

=over 4

=item pack_sockaddr

Usage:

    $connect_address = pack_sockaddr($family, $fam_addr);

Returns a packed C<struct sockaddr> corresponding to the provided
$family (which must be a number) and the address-family-specific
$fam_addr (pre-packed).

=item unpack_sockaddr

Usage:

    ($family, $fam_addr) = unpack_sockaddr($packed_address);

The inverse of pack_sockaddr().

=item E*

Various socket-related C<errno> values.  See L<":errnos"> for the list.
These routines will always be defined, but they will return 0 if the
corresponding error symbol was not found on your system.

=item EOF_NONBLOCK

Returns a boolean value depending on whether a read from a
non-blocking socket can distinguish an end-of-file condition from
a no-data-available condition.  This corresponds to the value
available from the C<Config> module as
C<$Config::Config{'d_eofnblk'}>), except that C<EOF_NONBLOCK> is
always defined.

=item RD_NODATA

Gives the integer return value found by the F<Configure> script
for a read() system call on a non-blocking socket which has no
data available.  This is similar to the string representation of
the value available from the C<Config> module as
C<$Config::Config{'rd_nodata'}>.

=item VAL_EAGAIN

Gives the value of the error symbol found by the F<Configure>
script which is set by a non-blocking filehandle when no data is
available.  This differs from the value available from the
C<Config> module (C<$Config::Config{'eagain'}>) in that the
latter is a string, typically C<"EAGAIN">.

=item VAL_O_NONBLOCK

Gives the value found by the F<Configure> script for setting a
filehandle non-blocking.  The value available from the C<Config>
module is a string representing the value found
(C<$Config::Config{'o_nonblock'}>), whereas the value from
C<VAL_O_NONBLOCK> is an integer, suitable for passing to
sysopen() or for eventual use in fcntl().

=back

=head2 Exports

=over 4

=item default

None.

=item exportable

C<AF_APPLETALK> C<AF_CCITT> C<AF_CHAOS> C<AF_CTF> C<AF_DATAKIT>
C<AF_DECnet> C<AF_DLI> C<AF_ECMA> C<AF_HYLINK> C<AF_IMPLINK>
C<AF_INET> C<AF_ISO> C<AF_LAST> C<AF_LAT> C<AF_LINK> C<AF_LOCAL> C<AF_NETMAN>
C<AF_NS> C<AF_OSI> C<AF_PUP> C<AF_ROUTE> C<AF_SNA> C<AF_UNIX>
C<AF_UNSPEC> C<AF_USER> C<AF_WAN> C<AF_X25> C<EADDRINUSE>
C<EADDRNOTAVAIL> C<EAFNOSUPPORT> C<EAGAIN> C<EALREADY> C<EBADF>
C<EBADMSG> C<ECONNABORTED> C<ECONNREFUSED> C<ECONNRESET>
C<EDESTADDRREQ> C<EHOSTDOWN> C<EHOSTUNREACH> C<EINPROGRESS>
C<EINVAL> C<EISCONN> C<EMSGSIZE> C<ENETDOWN> C<ENETRESET>
C<ENETUNREACH> C<ENOBUFS> C<ENODATA> C<ENOENT> C<ENOPROTOOPT>
C<ENOSR> C<ENOSTR> C<ENOTCONN> C<ENOTSOCK> C<EOF_NONBLOCK>
C<EOPNOTSUPP> C<EPFNOSUPPORT> C<EPROTO> C<EPROTONOSUPPORT>
C<EPROTOTYPE> C<ESHUTDOWN> C<ESOCKTNOSUPPORT> C<ETIME>
C<ETIMEDOUT> C<ETOOMANYREFS> C<EWOULDBLOCK> C<pack_sockaddr>
C<PF_APPLETALK> C<PF_CCITT> C<PF_CHAOS> C<PF_CTF> C<PF_DATAKIT>
C<PF_DECnet> C<PF_DLI> C<PF_ECMA> C<PF_HYLINK> C<PF_IMPLINK>
C<PF_INET> C<PF_ISO> C<PF_LAST> C<PF_LAT> C<PF_LINK> C<PF_LOCAL> C<PF_NETMAN>
C<PF_NS> C<PF_OSI> C<PF_PUP> C<PF_ROUTE> C<PF_SNA> C<PF_UNIX>
C<PF_UNSPEC> C<PF_USER> C<PF_WAN> C<PF_X25> C<RD_NODATA>
C<SHUT_RD> C<SHUT_RDWR> C<SHUT_WR> C<SOCK_DGRAM> C<SOCK_RAW>
C<SOCK_RDM> C<SOCK_SEQPACKET> C<SOCK_STREAM> C<SOL_SOCKET>
C<SOMAXCONN> C<SO_ACCEPTCONN> C<SO_BROADCAST> C<SO_DEBUG>
C<SO_DONTROUTE> C<SO_ERROR> C<SO_EXPANDED_RIGHTS> C<SO_FAMILY>
C<SO_KEEPALIVE> C<SO_LINGER> C<SO_OOBINLINE> C<SO_PAIRABLE>
C<SO_RCVBUF> C<SO_RCVLOWAT> C<SO_RCVTIMEO> C<SO_REUSEADDR>
C<SO_REUSEPORT> C<SO_SNDBUF> C<SO_SNDLOWAT> C<SO_SNDTIMEO>
C<SO_STATE> C<SO_TYPE> C<SO_USELOOPBACK> C<SO_XSE>
C<unpack_sockaddr> C<VAL_EAGAIN> C<VAL_O_NONBLOCK>

=item tags

The following I<:tags> are available for grouping exported items
together:

=over 6

=item :af

C<AF_APPLETALK> C<AF_CCITT> C<AF_CHAOS> C<AF_CTF> C<AF_DATAKIT>
C<AF_DECnet> C<AF_DLI> C<AF_ECMA> C<AF_HYLINK> C<AF_IMPLINK>
C<AF_INET> C<AF_ISO> C<AF_LAST> C<AF_LAT> C<AF_LINK> C<AF_LOCAL> C<AF_NETMAN>
C<AF_NS> C<AF_OSI> C<AF_PUP> C<AF_ROUTE> C<AF_SNA> C<AF_UNIX>
C<AF_UNSPEC> C<AF_USER> C<AF_WAN> C<AF_X25>

=item :errnos

C<EADDRINUSE> C<EADDRNOTAVAIL> C<EAFNOSUPPORT> C<EAGAIN>
C<EALREADY> C<EBADF> C<EBADMSG> C<ECONNABORTED> C<ECONNREFUSED>
C<ECONNRESET> C<EDESTADDRREQ> C<EHOSTDOWN> C<EHOSTUNREACH>
C<EINPROGRESS> C<EINVAL> C<EISCONN> C<EMSGSIZE> C<ENETDOWN> C<ENETRESET>
C<ENETUNREACH> C<ENOBUFS> C<ENODATA> C<ENOENT> C<ENOPROTOOPT> C<ENOSR>
C<ENOSTR> C<ENOTCONN> C<ENOTSOCK> C<EOPNOTSUPP> C<EPFNOSUPPORT>
C<EPROTO> C<EPROTONOSUPPORT> C<EPROTOTYPE> C<ESHUTDOWN>
C<ESOCKTNOSUPPORT> C<ETIME> C<ETIMEDOUT> C<ETOOMANYREFS> C<EWOULDBLOCK>

=item :families

The union of the C<:af> and C<:pf> tags.

=item :NonBlockVals

=item :non_block_vals

C<EOF_NONBLOCK> C<RD_NODATA> C<VAL_EAGAIN> C<VAL_O_NONBLOCK>

=item :pf

C<PF_APPLETALK> C<PF_CCITT> C<PF_CHAOS> C<PF_CTF> C<PF_DATAKIT>
C<PF_DECnet> C<PF_DLI> C<PF_ECMA> C<PF_HYLINK> C<PF_IMPLINK>
C<PF_INET> C<PF_ISO> C<PF_LAST> C<PF_LAT> C<PF_LINK> C<PF_LOCAL> C<PF_NETMAN>
C<PF_NS> C<PF_OSI> C<PF_PUP> C<PF_ROUTE> C<PF_SNA> C<PF_UNIX>
C<PF_UNSPEC> C<PF_USER> C<PF_WAN> C<PF_X25>

=item :routines

C<pack_sockaddr> C<unpack_sockaddr>

=item :shutflags

C<SHUT_RD> C<SHUT_WR> C<SHUT_RDWR>

=item :sockopts

C<SO_ACCEPTCONN> C<SO_BROADCAST> C<SO_DEBUG> C<SO_DONTROUTE>
C<SO_ERROR> C<SO_EXPANDED_RIGHTS> C<SO_FAMILY> C<SO_KEEPALIVE>
C<SO_LINGER> C<SO_OOBINLINE> C<SO_PAIRABLE> C<SO_RCVBUF>
C<SO_RCVLOWAT> C<SO_RCVTIMEO> C<SO_REUSEADDR> C<SO_REUSEPORT>
C<SO_SNDBUF> C<SO_SNDLOWAT> C<SO_SNDTIMEO> C<SO_STATE> C<SO_TYPE>
C<SO_USELOOPBACK> C<SO_XSE>

=item :sockvals

C<SOL_SOCKET> C<SOCK_STREAM> C<SOCK_DGRAM> C<SOCK_RAW>
C<SOCK_RDM> C<SOCK_SEQPACKET>

=item :ALL

All of the above.

=back

Z<>

=back

=head1 THREADING STATUS

This module has been tested with threaded perls, and should be as thread-safe
as perl itself.  (As of 5.005_03 and 5.005_57, that's not all that safe
just yet.)  It also works with interpreter-based threads ('ithreads') in
more recent perl releases.

=head1 SEE ALSO

L<Net::Inet(3)|Net::Inet>,
L<Net::UNIX(3)|Net::UNIX>,
Net::Dnet(3)

=head1 AUTHOR

Spider Boardman E<lt>spidb@cpan.orgE<gt>

=cut

#other sections should be added, sigh.

#any real autoloaded methods go after this line

#& setdebug($this, [bool, [norecurse]]) : previous
sub setdebug
{
    $_[0]->_debug($_[1]);
}

# fluff routine to make things easy
#& setparam($self, $name, $value, [newonly, [docheck]]) : boolean
sub setparam
{
    my $whoami = $_[0]->_trace(\@_,1);
    my($self,$key,$val,$newonly,$docheck) = @_;
    carp "Excess arguments to ${whoami} ignored"
	if @_ > 5;
    croak "Invalid arguments to ${whoami}, called"
	if @_ < 3 or not ref $self or not exists $ {*$self}{Keys}{$key};
    $self->setparams({$key => $val}, $newonly, $docheck);
}

#& bind($self [, @ignored]) : boolean
sub bind : locked method
{
    $_[0]->_trace(\@_,2);
    my $self = shift;
    $self->close if
	$self->wasconnected || $self->isconnected || $self->isconnecting ||
	    $self->isbound;
    return $ {*$self}{'isbound'} = undef unless
	$self->isopen or $self->open;
    $self->setsopt('SO_REUSEADDR', 1) if $ {*$self}{Parms}{reuseaddr};
    $self->setsopt('SO_REUSEPORT', 1) if $ {*$self}{Parms}{reuseport};
    my $rval;
    if ($ {*$self}{Parms}{srcaddrlist}) {
	my $tryaddr;
	foreach $tryaddr (@{$ {*$self}{Parms}{srcaddrlist}}) {
	    next unless $rval = CORE::bind($self, $tryaddr);
	    $ {*$self}{Parms}{srcaddr} = $tryaddr;
	    last;
	}
    }
    elsif (defined($ {*$self}{Parms}{srcaddr}) and
	   length $ {*$self}{Parms}{srcaddr})
    {
	$rval = CORE::bind($self, $ {*$self}{Parms}{srcaddr});
    }
    else {
	$rval = CORE::bind($self, pack_sockaddr($ {*$self}{Parms}{AF},''));
    }
    $ {*$self}{'isbound'} = $rval;
    return $rval unless $rval;
    $self->getsockinfo;
    $self->isbound;
}

#& unbind($self [, @ignored])
sub unbind : locked method
{
    $_[0]->_trace(\@_,2);
    my($self) = @_;
    $self->close unless $self->isconnected || $self->isconnecting;
    $self->delparams([qw(srcaddrlist)]);
}

#& delparam($self, @paramnames) : boolean
sub delparam
{
    my ($self,@keys) = @_;
    $self->delparams(\@keys);
}

#& listen($self [, $maxq=SOMAXCONN]) : boolean
sub listen : locked method
{
    my $whoami = $_[0]->_trace(\@_,2);
    my ($self,$maxq) = @_;
    $maxq = $self->getparam('maxqueue',SOMAXCONN,1) unless defined $maxq;
    croak "Invalid args for ${whoami}(@_), called" if
	$maxq =~ /\D/ or !ref $self;
    carp "Excess args for ${whoami}(@_) ignored" if @_ > 2;
    return undef unless $self->isbound or $self->bind;
    $ {*$self}{'didlisten'} = $maxq;
    CORE::listen($self,$maxq) or undef $ {*$self}{'didlisten'};
}

#& didlisten($self [, @ignored]) : boolean
sub didlisten
{
    #$_[0]->_trace(\@_,4," - ".($ {*{$_[0]}}{'didlisten'} ? "yes" : "no"));
    $ {*{$_[0]}}{'didlisten'};
}

sub TIESCALAR
{
    $_[0]->_trace(\@_,2);
    my $class = shift;
    my $self = $class->new(@_);
    $self && $self->isconnected && $self;
}

sub FETCH : locked method
{
    $_[0]->_trace(\@_,2);
    scalar $_[0]->READLINE;
}

sub STORE : locked method
{
    $_[0]->_trace(\@_,2);
    my $self = shift;
    return if @_ == 1 and !defined $_[0];	# "undef $x"
    $self->put(@_);
}

# socket-option routines

#& _findxopt($self, $realp, @args) : ($aref,@subargs)
sub _findxopt
{
    my($self,$realp,@args) = @_;
    my($aref,$level,$what);
    $level = shift @args;	# try input arg as level first
    if ($level =~ /^(0x[\da-f]+|0[0-7]*|[1-9]\d*)$/si) {
	# if numeric, it had better be the level
	$level = ((substr($level, 0, 1) eq '0') ? oct($level) : $level+0);
    }
    $aref = $ {*$self}{Sockopts}{$level};
    if (!$aref) {
	# here, we have to search for the ruddy thing by keyword
	# if level was numeric, punt by trying to force EINVAL
	until ($level =~ /\D/) {
	    # numeric level, check for realp and numeric what
	    last unless $realp;
	    $what = shift @args;
	    last unless $what =~ /^(0x[\da-f]+|0[0-7]*|[1-9]\d*)$/si;
	    $what = ((substr($what, 0, 1) eq '0') ? oct($what) : $what+0);
	    $aref = ['h*', $what, $level, 0+@args];
	    return ($aref,@args);
	}
	return getsockopt($self,-1,-1) unless $level =~ /\D/;
	$what = $level;
	foreach $level (keys %{$ {*$self}{Sockopts}}) {
	    next unless ref($ {*$self}{Sockopts}{$level}) eq 'HASH';
	    last if $aref = $ {*$self}{Sockopts}{$level}{$what};
	}
	$ {*$self}{Sockopts}{$what} = $aref if ref $aref eq 'ARRAY';
    }
    elsif (ref $aref eq 'HASH') {
	$what = shift @args;
	if ($what =~ /^(0x[\da-f]+|0[0-7]*|[1-9]\d*)$/si) {
	    $what = ((substr($what, 0, 1) eq '0') ? oct($what) : $what+0);
	}
	$aref = $$aref{$what};
    }
    # force EINVAL (I hope) if unrecognized value
    return getsockopt($self,-1,-1) unless ref $aref eq 'ARRAY';
    ($aref,@args);
}

#& _getxopt($this, $realp, [$level,] $what) : @values
sub _getxopt : locked method
{
    my($self,$realp,@args) = @_;
    my($aref,$level,$what,$rval,$format);
    @args = $self->_findxopt($realp, @args); # get the array ref
    return unless $aref = shift @args;
    carp "Excess args to getsockopt ignored" if @args;
    $what = $$aref[1];
    $level = $$aref[2];
    $format = $$aref[0];
    $rval = getsockopt($self,$level+0,$what+0);
    if ($self->debug > 3) {
	@args = unpack($format,$rval) if defined $rval;
	print STDERR " - getsockopt $self,$level,$what => ";
	print STDERR (defined $rval ? "@args\n" : "(undef)\n");
    }
    return $rval if $realp;
    return () unless defined $rval;
    unpack($format,$rval);
}

#& getsopt($this, [$level,] $what) : @values
sub getsopt
{
    my($self,@args) = @_;
    $self->_getxopt(0,@args);
}

#& getropt($this, [$level,] $what) : $value
sub getropt
{
    my($self,@args) = @_;
    $self->_getxopt(1,@args);
}

#& _setxopt($this, $realp, [$level,] $what, @vals) : boolean
sub _setxopt : locked method
{
    my($self,$realp,@args) = @_;
    my($aref,$level,$what,$rval,$format);
    @args = $self->_findxopt($realp, @args); # get the array ref and real args
    return undef unless $aref = shift @args;
    $what = $$aref[1];
    $level = $$aref[2];
    $format = $$aref[0];
    if ($realp) {
	$rval = shift @args;
    }
    else {
	$rval = pack($format, @args);
	carp "Excess args to " . join('::',(caller(0))[0,3]) . " ignored"
	    if @args > $$aref[3];
	$rval = undef if !length($rval) and !$$aref[3];
    }
    print STDERR " - setsockopt $self,$level,$what,",
	join($",unpack($format,$rval)),"\n"
	    if $self->debug > 3;
    setsockopt($self,$level+0,$what+0,$rval);
}

#& setsopt($this, [$level,] $what, @vals) : boolean
sub setsopt
{
    $_[0]->_trace(\@_,2);
    my($self,@args) = @_;
    $self->_setxopt(0,@args);
}

#& setropt($this, [$level,] $what, $realvalue) : boolean
sub setropt
{
    $_[0]->_trace(\@_,2);
    my($self,@args) = @_;
    $self->_setxopt(1,@args);
}

#& BINMODE($this)
sub BINMODE : locked method
{
    # Need to allow for PerlIO layers here
    @_ > 1 ? binmode($_[0], $_[1]) : 1;
}

#& FILENO($this) : {$int | undef}
sub FILENO
{
#    $_[0]->_trace(\@_,4);
    CORE::fileno($_[0]);
}

#& fileno($this) : {$int | undef}
sub fileno
{
#    $_[0]->_trace(\@_,4);
    CORE::fileno($_[0]);
}

#& getfh($this) : {$gvref | undef}
sub getfh
{
#    $_[0]->_trace(\@_,4);
    $_[0];
}

#& fhvec($this) : {$fhvec | undef}
sub fhvec
{
    $_[0]->_trace(\@_,4);
    my($self) = @_;
    return getsockopt($self,SOL_SOCKET,SO_TYPE) unless
	$self->isopen and
	    defined(CORE::fileno($self)); # return EBADF unless open
    $ {*$self}{FHVec};		# already setup by condition()
}

#& select($this [[, $read, $write, $xcept, $timeout]]) : $nready | @list
sub select : locked method
{
    $_[0]->_trace(\@_,4);
    my($self,$doread,$dowrite,$doxcept,$timer) = @_;
    my($fhvec,$rvec,$wvec,$xvec,$nfound,$timeleft) = $self->fhvec;
    return unless $fhvec;
    $rvec = $doread ? $fhvec : undef;
    $wvec = $dowrite ? $fhvec : undef;
    $xvec = $doxcept ? $fhvec : undef;
    $timer = 0 if $doread and defined($ {*$self}{sockLineBuf});
    ($nfound, $timeleft) = CORE::select($rvec, $wvec, $xvec, $timer)
	or return ();
    if (defined($ {*$self}{sockLineBuf}) && $doread && ($rvec ne $fhvec)) {
	$nfound++;
	$rvec |= $fhvec;
    }
    wantarray ?
	($nfound, $timeleft,
	    $doread && $rvec eq $fhvec,
	    $dowrite && $wvec eq $fhvec,
	    $doxcept && $xvec eq $fhvec)
	: $nfound;
}

#& ioctl($this, @args) : $scalar
sub ioctl : locked method
{
    my $whoami = $_[0]->_trace(\@_,4);
    croak "Insufficient arguments to ${whoami}(@_), found"
	if @_ < 3;
    carp "Excess arguments to ${whoami} ignored"
	if @_ > 3;
    CORE::ioctl($_[0], $_[1], $_[2]);
}

#& fcntl($this, @args) : $scalar
sub fcntl : locked method
{
    my $whoami = $_[0]->_trace(\@_,4);
    croak "Insufficient arguments to ${whoami}(@_), found"
	if @_ < 3;
    carp "Excess arguments to ${whoami} ignored"
	if @_ > 3;
    CORE::fcntl($_[0], $_[1], $_[2]);
}

#& format_addr($thunk, $sockaddr) : {$string | undef}
sub format_addr
{
    return undef unless defined $_[1];
    my($rval,$fam,$addr);
    ($fam,$addr) = unpack_sockaddr($_[1]) or return undef;
    $rval = "[${fam}]:";
    if (defined($addr) and length($addr)) {
	$rval .= "0x" . unpack('h*', $addr);
    }
    else {
	$rval .= "(null)";
    }
    $rval;
}

#& format_local_addr($this, [@args]) : {$string | undef}
sub format_local_addr
{
    my($self,@args) = @_;
    $self->format_addr($self->getparam('srcaddr'),@args);
}

#& format_remote_addr($this, [@args]) : {$string | undef}
sub format_remote_addr
{
    my($self,@args) = @_;
    $self->format_addr($self->getparam('dstaddr'),@args);
}

#& new_from_fh(classname, $filehandle) : {$obj | undef}
sub new_from_fh
{
    my $whoami = $_[0]->_trace(\@_,2);
    my($pack) = @_;
    if (@_ != 2) {
	croak "Invalid number of arguments to ${whoami}, called";
    }
    my ($fh,$rfh);
    eval {local $SIG{__DIE__}; local $SIG{__WARN__}; $fh=CORE::fileno($_[1])};
    unless(defined $fh) {
	if ($_[1] =~ /\D/ or !length($_[1])) {
	    croak "Invalid filehandle '$_[1]' in ${whoami}, called";
	}
	$fh = 0 + $_[1];
    }
    my $self = $pack->new();
    return undef unless $self;
    unless (CORE::open($self, "+<&$fh")) {
	{
	    local $!;
	    undef $self;
	    undef $self;
	}
	return $self;
    }
    $ {*$self}{'isopen'} = 1;
    $ {*$self}{'isconnected'} = 1 if getpeername($self);
    $rfh = getsockname($self);
    if (defined $rfh and length $rfh) {
	($fh, $rfh) = unpack_sockaddr($rfh);
	$ {*$self}{AF} = $fh if defined $fh and length $fh and $fh ne '0';
	$ {*$self}{'isbound'} = defined $rfh and $rfh =~ /[^\0]/;
    }
    ($rfh) = $self->getsopt('SO_TYPE');
    $ {*$self}{type} = $rfh if defined $rfh;
    $self->getsockinfo;
    $self->isopen && $self;
}

#& accept($self) : {$new_obj | undef}
sub accept
{
    my $whoami = $_[0]->_trace(\@_,2);
    my($self) = @_;
    carp "Excess args to ${whoami}(@_) ignored" if @_ > 1;
    return undef unless $self->didlisten or $self->listen;
    my $ns = $self->new;
    return undef unless $ns;
    $ns->stopio;		# make sure we can use the filehandle
    $ {*$ns}{Parms} = { %{$ {*$self}{Parms}} };
    $ns->checkparams;
    {
	my ($timeout,$fhvec,$saveblocking) =
	    ($ {*$self}{Parms}{'timeout'}, $ {*$self}{FHVec});
	if (defined $timeout and $ {*$self}{Parms}{'blocking'}) {
	    $saveblocking = $self->param_saver('blocking');
	    $self->setparams({'blocking'=>0});
	    my $nfound = CORE::select($fhvec, undef, undef, $timeout);
	}
	unless (CORE::accept($ns, $self)) {
	    {
		local $!;
		undef $ns;
		undef $ns;
	    }
	    return $ns;
	}
    }
    $ {*$ns}{'isopen'} = $ {*$ns}{'isbound'} =
	$ {*$ns}{'isconnected'} = 1;
    $ns->getsockinfo;
    unless ($ns->isconnected) {
	{
	    local $!;
	    undef $ns;
	    undef $ns;
	}
	return $ns;
    }
    $ns->condition;
    $ns;
}

#& RECV($self, $buf [,$maxlen] [,$flags]) : {$from | undef}
sub RECV
{
    my ($from,$buf);
    my $whoami = $_[0]->_trace(\@_,5);
    croak "Invalid arguments to ${whoami}, called"
	if @_ < 2 or @_ > 4 or !ref($_[0]);
    $buf = $_[0]->recv($_[2], $_[3], $from);
    return undef unless defined $buf;
    $_[1] = $buf;
    $from;
}

#& TIEHANDLE($class, $host, $port [,\%options]) : {$new_obj | undef}
sub TIEHANDLE
{				# redirects via $class->new(...)
    $_[0]->_trace(\@_,1);
    my $class = shift;
    my $self;
    if (ref $class and defined fileno($class)) {
	if ($class->isa(__PACKAGE__)) {
	    $self = $class->new_from_fh(@_) || $class->new(@_);
	}
	else {
	    $self = new_from_fh($class,@_) || new($class,@_);
	}
    }
    else {
	$self = $class->new(@_);
	$self && $self->isconnected && $self;
    }
}

#& PRINTF($self, $format [,@args]) : boolean
sub PRINTF
{
    $_[0]->_trace(\@_,5);
    my $self = shift;
    my $fmt = shift;
    local $\ = '';		# currently not per-file
    $self->PRINT(sprintf $fmt,@_);
}

#& READ($self, $buffer, $length [,$offset]) : {$lenread | undef}
sub READ
{
    my $whoami = $_[0]->_trace(\@_,5);
    croak "Invalid args to ${whoami}, called"
	if @_ < 3 or @_ > 4 or !ref($_[0]);
    my $len = $_[2]+0;
    croak "Negative buffer length in ${whoami}, called"
	if $len < 0;
    if (@_ > 3) {
	$_[3] += 0;		# force offset to be numeric
	croak "Buffer offset outside buffer contents in ${whoami}, called"
	    if ($_[3] < 0 and $_[3]+length($_[1]) < 0);
    }
    my $buf = $_[0]->recv($len, 0);
    $_[1] = '' unless defined $_[1];
    unless (defined $buf) {
	return undef if $!;
	return 0;
    }
    my $xbuf;
    $len -= length($buf);
    while ($len > 0) {		# keep trying to fill the specified length
	$xbuf = $_[0]->recv($len, 0);
	last unless defined $xbuf;
	$buf .= $xbuf;
	$len -= length($xbuf);
    }
    if (@_ > 3) {
	substr($_[1], $_[3]) = $buf;
    }
    else {
	$_[1] = $buf;
    }
    length($buf);
}

#& GETC($self) : {$charstr | undef}
sub GETC
{
    my $whoami = $_[0]->_trace(\@_,6);
    carp "Excess arguments to ${whoami} ignored"
	if @_ > 1;
    $_[0]->recv(1,0);
}

#& READLINE($self) : {$line | undef || @lines}
sub READLINE
{
    return $_[0]->getline unless wantarray and defined($/);
    my $whoami = $_[0]->_trace(\@_,5);
    my $self = shift;
    my (@lines, $line);
    carp "Excess arguments to ${whoami} ignored" if @_;
    while (defined($line = $self->getline)) { push(@lines, $line) }
    @lines;
}

#& getlines($self) : @lines
sub getlines
{
    my $whoami = $_[0]->_trace(\@_,6);
    croak "Invalid call to $whoami" unless @_ == 1;
    croak "Not in list context calling $whoami" unless wantarray;
    $_[0]->READLINE;
}
    

#& sendto($self, $buf, $where, [$flags]) : boolean
sub sendto
{
    my $whoami = $_[0]->_trace(\@_,3);
    my($self,$buf,$whither,$flags) = @_;
    croak "Invalid args to ${whoami}, called"
	if @_ < 3 or !ref $self;
    $flags = 0 unless defined $flags;
    carp "Excess arguments to ${whoami} ignored" if @_ > 4;
    return getsockopt($self,SOL_SOCKET,SO_TYPE) unless
	$self->isopen or $self->open;	# generate EBADF return if not open
    if ($ {*$self}{Parms}{netgen_fakeconnect}) {
	return $self->send($buf,$flags,$whither);
    }
    CORE::send($self, $buf, $flags, $whither);
}

#& EOF($self) : boolean
sub EOF
{
    my $whoami = $_[0]->_trace(\@_,3);
    my ($self,$buf) = @_;
    croak "Invalid args to ${whoami}, called" if @_ != 1 or !ref $self;
    return getsockopt($self,SOL_SOCKET,SO_TYPE) unless
	$self->isopen;			# generate EBADF return if not open
    return 0 if defined $ {*$self}{sockLineBuf}; # not EOF if can read
    my $fhvec = $ {*$self}{FHVec};
    my $nfound = CORE::select($fhvec, undef, undef, 0);
    return 0 unless $nfound;
    $buf = $self->recv;
    return 1 if ! $! and !defined $buf;
    $ {*$self}{sockLineBuf} = $buf;
    0;
}

#& WRITE($self,$buffer,$len[,$offset]) : {$length | undef}
sub WRITE
{
    my $whoami = $_[0]->_trace(\@_,3);
    my ($self,$buf,$len,$offset,$blen) = @_;
    croak "Invalid args to ${whoami}, called" if @_ < 2 or @_ > 4 or
	!ref $self;
    $offset = 0 if @_ == 3;
    $blen = length $buf;
    $len = $blen unless defined $len;
    if ($offset < 0) {
	$offset += $blen;
	croak "Offset outside of string in ${whoami}, called" if
	    $offset < 0;
    }
    croak "Offset outside of string in ${whoami}, called" if
	$offset > $blen;
    return getsockopt($self,SOL_SOCKET,SO_TYPE) unless
	$self->isopen;			# generate EBADF return if not open
    $len = $blen - $offset if $len > $blen - $offset;
    syswrite($self, $buf, $len, $offset);
}

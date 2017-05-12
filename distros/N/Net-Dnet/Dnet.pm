# Copyright 1995,1996,1997 Spider Boardman.
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


package Net::Dnet;
require 5.00393;		# new minimum Perl version for this package

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

my $myclass = 'Net::Dnet';
$VERSION = '0.73';
sub Version { "$myclass v$VERSION" }

require Exporter;
require DynaLoader;
use AutoLoader;
use Net::Gen 0.73 qw(/pack_sockaddr$/);
use Socket qw(!/pack_sockaddr/);

@ISA = qw(Exporter DynaLoader Net::Gen);

# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)
@EXPORT = qw(
	dnet_addr
	dnet_htoa
	dnet_ntoa
	dnet_otoa
	endnodeent
	getnodebyaddr
	getnodebyname
	getnodeent
	getobjectbyname
	getobjectbynumber
	setnodeent
);

# Other items we are prepared to export if requested
@EXPORT_OK = qw(
	DN_MAXADDL
);

# exporter tags to make it easier to get blocks of values imported
%EXPORT_TAGS = (
     dnprotos	=> [qw(DNPROTO_EVL DNPROTO_EVR DNPROTO_NML
		       DNPROTO_NSP DNPROTO_NSPT DNPROTO_ROU)],
     linkstates	=> [qw(LL_CONNECTING LL_DISCONNECTING
		       LL_INACTIVE LL_RUNNING)],
     sockopts	=> [qw(DSO_ACCEPTMODE DSO_CONACCEPT
		       DSO_CONACCESS DSO_CONDATA DSO_CONREJECT
		       DSO_DISDATA DSO_LINKINFO DSO_SEQPACKET
		       DSO_STREAM)],
     ioctls	=> [qw(SIOCGNETADDR SIOCSNETADDR
		       OSIOCGNETADDR OSIOCSNETADDR)],
     dnobjects	=> [qw(DNOBJECT_CTERM DNOBJECT_DTERM DNOBJECT_DTR
		       DNOBJECT_EVR DNOBJECT_FAL
		       DNOBJECT_MAIL11 DNOBJECT_MIRROR
		       DNOBJECT_NICE DNOBJECT_PHONE
		       DNOBJ_CTERM DNOBJ_DTERM DNOBJ_DTR
		       DNOBJ_EVR DNOBJ_FAL DNOBJ_MAIL11
		       DNOBJ_MIRROR DNOBJ_NICE DNOBJ_PHONE)],
     sdflags	=> [qw(SDF_PROXY SDF_UICPROXY SDF_V3 SDF_WILD)],
     acceptmode	=> [qw(ACC_DEFER ACC_IMMED)],
);

# incorporate the tags into @EXPORT_OK
{
    local($_);
    foreach (keys %EXPORT_TAGS) {
	push(@EXPORT_OK, @{$EXPORT_TAGS{$_}});
    }
}

# make the routines list known as a tag
$EXPORT_TAGS{routines} = \@EXPORT;

# finally, give masochists a kitchen-sink tag
$EXPORT_TAGS{EVERYTHING} = [@EXPORT, @EXPORT_OK];

sub AUTOLOAD
{
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Net::Dnet macro $constname, used";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}

bootstrap Net::Dnet $VERSION;


# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.

my %sockopts;

# structure templates
my $accessdata_dn = 'Sa40' x 3;
my $optdata_dn = 'SSa16';
my $linkinfo_dn = 'SC';

%sockopts = (
	     # socket options from the list above
	     # simple booleans first

	     DSO_SEQPACKET	=> ['I'],
	     DSO_STREAM		=> ['I'],
	     DSO_CONACCEPT	=> [''], # action-only

	     # enumerated integer options

	     DSO_ACCEPTMODE	=> ['C'], # ACC_{IMMED,DEFER}
	     DSO_CONREJECT	=> ['S'], # DECnet Arch. reject reason number

	     # structured options

	     DSO_CONACCESS	=> [$accessdata_dn],
	     DSO_CONDATA	=> [$optdata_dn],
	     DSO_DISDATA	=> [$optdata_dn],
	     DSO_LINKINFO	=> [$linkinfo_dn],

	     # out of known DECnet options
	     );

;# set up to ensure that all constants have the proper prototype
{
    my $name;
    local ($^W) = 0;		# avoid redef warnings
    no strict 'refs';		# so can do the defined() checks
    for $name (@EXPORT, @EXPORT_OK) {
	eval "sub $name () ;"
	    unless defined(&$name);
    }
}

$myclass->initsockopts( &DNPROTO_NSP(), \%sockopts );

my $debug = 0;

my @nodekeys = qw(thisnode destnode node);
my @nodekeyHandlers = (\&_setnode) x @nodekeys;
my @objkeys = qw(thisservice thisobj destservice destobj service obj);
my @objkeyHandlers = (\&_setobj) x @objkeys;
# Don't include "handled" keys in this list, since that's redundant.
my @Keys = qw(lclnode lcladdr lclservice lclobj
	      destflags thisflags
	      remnode remaddr remservice remobj);

sub new				# $class, [\%params]
{
    print STDERR "${myclass}::new(@_)\n" if $debug;
    my($class,@Args,$self) = @_;
    $self = $class->SUPER::new(@Args);
    print STDERR "${myclass}::new(@_), self=$self after sub-new\n"
	if $debug > 1;
    if ($self) {
	dump if $debug > 1 and
	    ref $self ne $class || "$self" !~ /HASH/;
	# register our keys and their handlers
	$self->registerParamKeys(\@Keys);
	$self->registerParamHandlers(\@objkeys,\@objkeyHandlers);
	$self->registerParamHandlers(\@nodekeys,\@nodekeyHandlers);
	# register our socket options
	$self->registerOptions('DNPROTO_NSP', &DNPROTO_NSP()+0, \%sockopts);
	# set our required parameters
	$self->setparams({PF => PF_DECnet, AF => AF_DECnet,
			  proto => &DNPROTO_NSP()});
	# set our default socket type
	$self->setparams({type => SOCK_STREAM},-1);
	$self = $self->init(@Args) if $class eq $myclass;
    }
    print STDERR "${myclass}::new returning self=$self\n" if $debug;
    $self;
}

sub _nodeobj			# $self, {'this'|'dest'}, [\]@list
{
    my($self,$which,@args,$aref) = @_;
    $aref = \@args;		# assume in-line list unless proved otherwise
    $aref = $args[0] if @args == 1 and ref $args[0] eq 'ARRAY';
    return undef if $which ne 'dest' and $which ne 'this';
    if (@$aref) {		# assume this is ('destnode','destobj')
	my %p;			# where we'll build the params list
	if (@$aref == 3 and ref($$aref[2]) eq 'HASH') {
	    %p = %{$$aref[2]};
	}
	else {
	    %p = splice(@$aref,2); # assume valid params after
	}
	$p{"${which}node"} = $$aref[0] if defined $$aref[0];
	$p{"${which}obj"} = $$aref[1] if defined $$aref[1];
	$self->setparams(\%p) if scalar(keys %p);
    }
    else {
	1;			# succeed vacuously if no work
    }
}

sub init			# $self, [\%params || @speclist]
{				# returns updated $self
    print STDERR "${myclass}::init(@_)\n" if $debug > 1;
    my($self,@args) = @_;
    return $self unless $self = $self->SUPER::init(@args);
    if (@args > 1 or @args == 1 and ref $args[0] ne 'HASH') {
	return undef unless $self->_nodeobj('dest',@args);
    }
    my @r;			# dummy array needed in 5.000
    if ((@r=$self->getparams([qw(type proto)],1)) == 4) { # have type and proto
	return undef		# refuse to make less object than requested
	    unless $self->isopen or $self->open;
    }
    if ($self->getparam('dstaddrlist')) {
	# have enough object already to attempt the connection
	return undef		# make no less object than requested
	    unless $self->isconnected or $self->connect;
    }
    # I think this is all we need here ?
    $self;
}

sub bind			# $self, [\]@([node],[obj])
{
    my($self,@args) = @_;
    return undef if @args and not $self->_nodeobj('this',@args);
    $self->SUPER::bind;
}

sub connect			# $self, [\]@([node],[obj])
{
    my($self,@args) = @_;
    return undef if @args and not $self->_nodeobj('dest',@args);
    $self->SUPER::connect;
}

sub _setnode			# $self,$key,$newval
{
    my($self,$key,$newval) = @_;
    return "Invalid args to ${myclass}::_setnode(@_), called"
	if @_ != 3 or ref($$self{Keys}{$key}) ne 'CODE';
    # check for call from delparams
    if (!defined $newval) {
	my @delkeys;
	if ($key eq 'thisnode') {
	    @delkeys =
		qw(srcaddrlist srcaddr lclnode lcladdr lclobj lclservice);
	}
	elsif ($key eq 'destnode') {
	    @delkeys =
		qw(dstaddrlist dstaddr remnode remaddr remobj remservice);
	}
	splice(@delkeys, 1) if @delkeys and $self->isconnected;
	$self->delparams(@delkeys) if @delkeys;
	return '';		# ok to delete
    }
    # here we're really trying to set some kind of address (we think)
    my ($okey,$obj);
    ($okey = $key) =~ s/node$/obj/;
    my (@addrs,$addr);
    $addr = dnet_addr($newval);
    if (defined $addr) {
	push(@addrs,$addr);
	$addr = dnet_ntoa($addr); # make canonical
    }
    else {
	my(@ninfo) = getnodebyname($newval);
	return "Node $newval not found," unless @ninfo;
	return "Node $newval has strange address family ($ninfo[2]),"
	    if $self->getparam('AF',AF_DECnet,1) != $ninfo[2];
	@addrs = splice(@ninfo,3);
	$addr = $ninfo[0];	# save canonical name for real setup
    }
    # valid so far, get out if can't form addresses yet
    return '' unless
	defined($obj = $$self{Parms}{$okey}) and $obj ne '#0' or
	    !defined $obj and $okey eq 'thisobj'; # allow for 'bind'
    return '' if $key eq 'node'; # don't know yet whether 'dest' or 'this'
    my $af = $self->getparam('AF',AF_DECnet,1);
    my $which = substr($key, 0, 4);
    my $flags = $self->getparam("${which}flags", 0, 1);
    for (@addrs) {
	$_ = pack_sockaddr_dn($af, $flags, $obj, $_);
    }
    $okey = (($key eq 'destnode') ? 'dstaddrlist' : 'srcaddrlist');
    $self->setparams({$okey => [@addrs]});
    # finally, we have validation
    $_[2] = $addr;		# update the canonical representation to store
    print STDERR " - ${myclass}::_setnode $self $key ",
	$self->format_addr($addr,1),"\n"
	    if $debug;
    '';				# return nullstring for goodness
}

sub _setobj			# ($self,$key,$newval)
{
    my($self,$key,$newval) = @_;
    return "Invalid arguments to ${myclass}::_setobj(@_), called"
	if @_ != 3 || !exists($$self{Keys}{$key});
    print STDERR " - ${myclass}::_setobj(@_)\n" if $debug;
    my($skey,$nkey,$okey,$svc,$obj,$proto,$type,$node,$reval,$pname,@serv);
    ($skey = $key) =~ s/obj$/service/;	# a key known to be for a service
    ($okey = $key) =~ s/service$/obj/;	# and one for the obj
    ($nkey = $okey) =~ s/obj$/node/; # another for calling _setnode
    if (!defined $newval) {	# deleting a service or obj
	delete $$self{Parms}{$skey};
	delete $$self{Parms}{$okey} unless
	    $okey ne 'obj' and $self->isconnected;
	my @delkeys;
	if ($okey eq 'thisobj') {
	    @delkeys = qw(srcaddrlist srcaddr);
	}
	elsif ($okey eq 'destobj') {
	    @delkeys = qw(dstaddrlist dstaddr);
	}
	pop(@delkeys) if @delkeys and $self->isconnected;
	$self->delparams(@delkeys) if @delkeys;
	return '';		# ok to delete
    }
    # here, we're trying to set a obj or service
    $pname = $self->getparam('IPproto');
    $proto = $self->getparam('proto'); # try to find our protocol
    if (!defined($pname) && !$proto
	&& defined($type = $self->getparam('type'))) {
	# try to infer protocol from SO_TYPE
	if ($type == SOCK_STREAM) {
	    $proto = &IPPROTO_TCP;
	}
	elsif ($type == SOCK_DGRAM) {
	    $proto = &IPPROTO_UDP;
	}
    }
    if (defined $proto and not defined $pname) {
	$pname = getprotobynumber($proto);
	unless (defined $pname) {
	    if ($proto == &IPPROTO_UDP) {
		$pname = 'udp';
	    }
	    elsif ($proto == &IPPROTO_TCP) {
		$pname = 'tcp';
	    }
	}
    }
    $reval = $newval;		# make resetting $_[2] simple
    $svc = $$self{Parms}{$skey}; # keep earlier values around (to preserve)
    $obj = $$self{Parms}{$okey};
    $obj = undef if
	defined($obj) and $obj =~ /\D/; # but stored objs must be numeric
    if ($skey eq $key || $newval =~ /\D/) { # trying to set a service
	@serv = getservbyname($newval,$pname); # try to find the obj info
    }
    if ($newval !~ /\D/ && !@serv) { # setting a obj number (even if service)
	$obj = $newval+0;	# just in case no servent is found
	@serv = getservbyobj(htons($obj),$pname) if $pname;
    }
    if (@serv) {		# if we resolved name/number input
	$svc = $serv[0];	# save the canonical service name (and number?)
	$obj = 0+$serv[2] unless $key eq $okey and $newval !~ /\D/;
    }
    elsif ($key eq $skey or $newval =~ /\D/) { # setting unknown service
	return "Unknown service $newval, found";
    }
    $reval = (($key eq $skey) ? $svc : $obj); # in case we get that far
    $$self{Parms}{$skey} = $svc if $svc; # in case no obj change
    $_[2] = $reval;
    print STDERR " - ${myclass}::_setobj $self $skey $svc\n" if
	$debug and $svc;
    print STDERR " - ${myclass}::_setobj $self $okey $obj\n" if
	$debug and defined $obj;
    return '' if defined($$self{Parms}{$okey}) and
	$$self{Parms}{$okey} == $obj; # nothing to update if same number
    $$self{Parms}{$okey} = $obj; # in case was service key
    # check for whether we can ask _setnode to set {dst,src}addrlist now
    return '' if $okey eq 'obj'; # not if don't know local/remote yet
    return '' unless
	$node = $$self{Parms}{$nkey} or $nkey eq 'thisnode';
    $node = '0' if !defined $node; # 'thisnode' value was null
    $self->setparams({$nkey => $node},0,1); # try it
    '';				# return goodness from here
}


1;

# these would have been autoloaded, but autoload and inheritance conflict

sub setdebug			# $this, [bool, [norecurse]]
{
    my $prev = $debug;
    my $this = shift;
    $debug = @_ ? $_[0] : 1;
    @_ > 1 && $_[1] ? $prev :
	$prev . $this->SUPER::setdebug(@_);
}

# autoloaded methods go after the END token (& pod) below

__END__

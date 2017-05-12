package Net::Interface;

use strict;
#use lib qw(blib/lib blib/arch);
use vars qw(
	$VERSION
	@ISA
	%EXPORT_TAGS
	@EXPORT_OK
);

#use AutoLoader qw(AUTOLOAD);
require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
require Net::Interface::NetSymbols;		# just for the EXPORT symbol arrays

@EXPORT_OK = (
	@Net::Interface::NetSymbols::EXPORT_OK,
	qw(
		cidr2mask
		full_inet_ntop
		ipV6compress
		mac_bin2hex
		mask2cidr
		net_symbols
		type
		scope
		inet_aton
		inet_ntoa
		inet_pton
		inet_ntop
		_NI_AF_TEST
	)
);

%EXPORT_TAGS = %Net::Interface::NetSymbols::EXPORT_TAGS;
$EXPORT_TAGS{constants} = $EXPORT_TAGS{ifs};	# deprecated form
$EXPORT_TAGS{inet} = [qw(
	inet_aton
	inet_ntoa
	inet_pton
	inet_ntop
)];

$VERSION = do { sprintf "%d.%03d", (q$Revision: 1.16 $ =~ /\d+/g) };

bootstrap Net::Interface $VERSION;

# register the conditionally compiled family modules
Net::Interface::conreg();


# provide AF family data for use in this module

my $AF_inet = eval { 0 + AF_INET() } || 0;
my $AF_inet6 = eval { 0 + AF_INET6() } || 0;

sub af_inet { return $AF_inet; }
sub af_inet6 { return $AF_inet6; }

sub net_symbols() {
  no strict;
  my %sym;
  my $max = AF_MAX();
  foreach (
	@{$EXPORT_TAGS{afs}},
	@{$EXPORT_TAGS{pfs}},
	@{$EXPORT_TAGS{ifs}},
	@{$EXPORT_TAGS{iftype}},
	@{$EXPORT_TAGS{scope}},
  ) {
    my $v = &$_;
    next if $v > $max;
    $sym{$_} = &$_;
  }
  return \%sym;
}

########## begin code ############

*broadcast = \&destination;
  
use overload

	'""'	=> sub { $_[0]->name(); };

our $full_format = "%02X%02X:%02X%02X:%02X%02X:%02X%02X:%02X%02X:%02X%02X:%02X%02X:%02X%02X";
our $ipv6_format = 1;
our $mac_format = "%02X:%02X:%02X:%02X:%02X:%02X";

sub import {
  if (grep { $_ eq ':lower' } @_) {
    $full_format = lc($full_format);
    $ipv6_format = 0;
    $mac_format = lc($mac_format);
    @_ = grep { $_ ne ':lower' } @_;
  }
  if (grep { $_ eq ':upper' } @_) {
    $full_format = uc($full_format);
    $ipv6_format = 1;
    $mac_format = uc($mac_format);
    @_ = grep { $_ ne ':upper' } @_;
  }
  Net::Interface->export_to_level(1,@_);
}

sub DESTROY () {}

#1;
#__END__

# create blessed object for testing
#
sub _bo($) {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  bless {}, $class;
}

=head1 NAME

Net::Interface - Perl extension to access network interfaces

=head1 SYNOPSIS

  use Net::Interface qw(
	cidr2mask
	full_inet_ntop
	ipV6compress
	mac_bin2hex
	mask2cidr
	net_symbols
	type
	scope
	inet_aton
	inet_ntoa
	inet_pton
	inet_ntop
	:afs
	:pfs
	:ifs
	:iffs
	:iffIN6
	:iftype
	:scope
	:constants
	:inet
	:all
	:lower
	:upper
  );

=head2 TAGS
  
  Note:	tags :afs, :pfs, :constants, :ifs
	include all AF_[family names], PF_[family names] and
	IFxxxx values that exist on this architecture.

	:iffs includes only IFF_xxx values
	:iffIN6 includes IN6_IFF_xxx values on BSD flavored OS's

	:inet includes inet_aton, inet_ntoa,
		inet_pton, inet_ntop

  On platforms that support IPV6, :iftype :scope 
  provide additional attribute screening

  :constants is a deprecated synonym for :ifs

See L<Net::Interface::NetSymbols> built specifically for this platform for 
a detailed list and description of all symbols available on this specific
architecture and operating systems version.

By default B<Net::Interface> functions and methods return string IPv6
addresses and MAC addresses in uppercase.  To change that to lowercase:

  use Net::Interface qw(:lower);

To ensure the current string case behavior even if the default
changes:

  use Net::Interface qw(:upper);


=head2 FUNCTIONS and METHODS

  @all_ifs = Net::Interface->interfaces();

  $this_if    = Net::Interface->new('eth0');
  $refresh_if = $any_if->new();
  $refresh_if = $this_if->delete($naddr);

  $create_if  = Net::Interface->new(\%iface_spec);

  @ifnames     = "@all_ifs";
  $if_name_txt = $if->name;

  print $if,"\n";	# prints the name
  print "@all_ifs\n"	# prints all names

 ---------------------------------------------
	WARNING API CHANGE !

    $naddr = $if->address([$family],[$index]);
    $naddr = $if->netmask([$family],[$index]);
    $naddr = $if->destination([$family],[$index]);
	same as
    $naddr = $if->broadcast([$family],[$index]);

    @addresses = $if->address([$family]);
    @netmasks  = $if->netmask([$family]);
    @destinats = $if->destination([$family]);
	same as
    @broaddrs  = $if->broadcast([$family]);

    $bin_mac = $if->hwaddress($hwaddr);
 ---------------------------------------------

  $val = $if->flags($val);
  $val = $if->mtu ($val);
  $val = $if->metric($val);
  $val = $if=>index();

  $cidr = $if->mask2cidr([$naddmsk])
  $cidr = mask2cidr($naddrmsk);
  $naddrmsk = cidr2mask($cidr,[family])

  $mac_txt = if->mac_bin2hex();
  $mac_txt = mac_bin2hex($bin_mac);

  $naddr   = inet_aton($host or $dotquad);
  $dotquad = inet_ntoa($naddr);

  $info = $if->info();

    for ipV6 only
  $type  = $if->type([$naddr6]);
  $type  = type($naddr6);
  $scope = $if->scope([$naddr6]);
  $scope = scope($naddr6);

  $full_ipV6_txt = full_inet_ntop($naddr6);
  $ipV6_txt = inet_ntop($naddr6)
  $naddr6   = inet_pton($ipV6_txt);

=head1 DESCRIPTION

B<Net::Interface> is a module that allows access to the host network
interfaces in a manner similar to I<ifconfig(8)>. Version 1.00 is a complete
re-write and includes support for IPV6 as well as the traditional IPV4.

Both read and write access to network device attributes including the
creation of new logical and physical interfaces is available where
supported by the OS and this module.

NOTE: if your OS is not supported, please feel free to contribute new
capabilities, patches, etc.... see: L<Net::Interface::Developer>

ANOTHER NOTE: Many of the operations of B<Net::Interface>, particularly
those that set interface values require privileged access to OS resources.
Wherever possible, B<Net::Interface> will simply fail I<softly> when there
are not adequate privileges to perform the requested operation or where the
operation is not supported.

=head1 OPERATION

B<Net::Interface> retrieves information about the network devices on its
host in a fashion similar to I<ifconfig(8)> running in a terminal window.
With I<ifconfig(8)>, the information is returned to the screen and
any additional activity on a particular network device goes on without the
knowledge of the user. Similarly, B<Net::Interface> only retrieves
information about network devices when methods I<interfaces> and I<new> are
invoked. Calls to I<interfaces> retrieves information about all network
devices known to the host. Calls to I<new> make the same function call to
the host library but rather than returning all the interface net device
information to the user, it selects out only information for the specified
device. The function call to the OS is the same. This information is cached
in the object returned to the user interface and it is from this object that
data is returned to the user program.

To continually monitor a particular device, it is necessary to issue
repeat calls to I<new>.

=head1 SYMBOLS

B<Net::Interface> provide a large number of network interface symbols
with a module generated on its build host. These symbols include all of the
available AF_xxxx, PF_xxx, IFF_xxx symbols and many more. For a detailed
list of all of these symbols, see L<Net::Interface::NetSymbols>.

=head2 HINTS and TIPS for use SYMBOLS

Most of the symbols provided by B<Net::Interface> have dual values.

1) a numeric value when use in arithmetic context and

2) a text value when used in string/text context

Symbols are actually calls to functions. Because of this certain usage rules
apply that are not necessarily obvious.

If you make it a practice to build your Perl modules using:

  #!/usr/bin/perl
  use strict;

Then usage of symbols will require that they explicitly be called as
functions. i.e.

  $functval = &AF_INET		is OK

  $functval = AF_INET()		is better

The first calling method allows the function to pick up the contents of
B<@_>. This works fine as long as B<@_> is empty. Since symbols do not take
arguments, when B<@_> contains something the symbol call will fail with a
message from Perl about inappropriate calling syntax.

If you do not C<use strict;> (not recommended) then bare symbols will work just fine in your
Perl scripts. You can also imbed your symbols in blocks where B<strict;> is
not enforced.

  {
	no strict;
	$functval = AF_INET
  }

Lastly, to access the numeric value of a symbol unconditionally:

  $numeric = 0 + AF_INET

=head1 WARNING - API CHANGES

The following changes have been made to the API. This may I<BREAK> existing
code. If you have been using a previous version of Net::Interface you should
verify that these API changes do not break your code.

=over 6

B<NO LONGER SUPPORTED>

=item * I<$naddr=$if-E<gt>address($naddr);>

=item * I<$naddr=$if-E<gt>netmask($naddr);>

=item * I<$naddr=$if-E<gt>destination($naddr);>

=item * I<$naddr=$if-E<gt>broadcast($naddr);>

=item * I<$mac = $if->hwaddress($hwaddr);>

=back

Setting address values was never implemented in previous versions of
Net::Interface. With this version (where supported) changing an address
will be implemented using a hash argument containing the required and
optional elements in a manner similar to I<ifconfig(8)>. See:

	Net::Interface->new(\%iface_spec);

=over 6

B<NO LONGER SUPPORTED>

=item * I<($sa_family,$size,$naddr)=$if-E<gt>address($naddr);>

=back

On most platforms, multiple addresses and multiple address families can be
assigned to the same interface. The returned data described above conflicts
with the requirement to report multiple addresses for a particular
interface. In addition, the returned information only reflected the
attributes of the I<FIRST> address assigned to the device where there could
be many of mixed families. i.e. AF_INET, AF_INET6, and perhaps more as the
capabilities of this module are enhanced to support additional address
families.

The API has been changed to reflect this reality and the need to report
multiple addresses on the same interface.

	@addresses = $if->address([$family]);

The new API is described in detail later in this document.

=over 6

B<NO LONGER SUPPORTED>

=item * I<($sa_family,$size,$hwaddr)=$if-E<gt>hwaddress($hwaddr);>

=back

As in the preceding case, it is not possible to accurately report the
address family attributes of an interface which may support assignments
of more than one address from differing address families.

	see: if->info();

=head1 METHODS

Brackets [] indicates an optional parameter.

The return value for I<SET> attempts on systems that do not support the
operation is not settled. Current practice is to silently
ignore the set request. This may change so don't count on this behavior.

Unless otherwise specified, errors for all methods return either B<undef> or and empty array depending
on the expected return context.

=cut

	# *********************************************	*
	#  The information for each interface (IF) is	*
	#  contained in an HV. The name slot of the	*
	#  HV holds the IF name. The args slot points	*
	#  to a hash whose key values represent the	*
	#  last interrogated state of the IF.		*
	#						*
	#   HV {					*
	#	   indx	=>  IV,				*
	#	   flav	=>  IV,				*
	#	   name	=>  interface name;		*
	#	   args	=>  {				*
	#		maci	=> bin string,		*
	#		mtui	=> IV,			*
	#		metk	=> IV,			*
	#		flag	=> NV,			*
	#		afk	=> {			*
	#			size	  => IV,	*
	#			addr	=> [],		*
	#			netm	=> [],		*
	#			dsta	=> [],		*
	#		},				*
	#		afk	=> {			*
	#			size	  => IV,	*
	#			addr	=> [],		*
	#			netm	=> [],		*
	#			dsta	=> [],		*
	#		},				*
	#	    }					*
	#	};					*
	#  Note: for ease of coding, all keys=4 chars	*
	#	 except for 'afk' which is computed	*
	# *********************************************	*

=pod

=over 4

=item * I<-E<gt>interfaces();>

Returns a list of interface objects for each interface that supports IPV4
or IPV6.

On failure, returns an empty list.

    usage:

	@all_ifs = Net::Interface->interfaces();

	foreach my $if (@all_ifs) {
	  $if_name = $if->name;
	    or
	  print $if, "\n";	# (overloaded)
	}

    Get or Set (where supported)
	$old_mtu = $if->mtu($new_mtu);
	$old_metric = $if->metric($new_metric);
    etc...

=back

=item * I<-E<gt>new();> has multiple calling invocations.

This method will refresh the data for an existing interface OR it can modify
and existing interface OR it can create a new interface or alias.

=over 4

=item * $this_if = I<-E<gt>new('eth0');>

Same as I<-E<gt>interfaces> above except for a single known interface. An
interface object is returned for the specific logical device requested.

On failure return B<undef>

=item * $refresh_if = I<-E<gt>new();>

The a new (refreshed) interface object is returned for the same logical
device.

=item * $new_if = I<-E<gt>new(%iface_spec);>

=item * $new_if = I<-E<gt>new(\%iface_spec);>

A logical device is created or updated. The specification is contained in a hash
table that is passed to I<new> either directly or as a reference.

The interface specification is architecture dependent. For example, adding
an address to an existing interface.

	i.e.	Linux

  $iface_spec = {
	name	  => 'eth0:0',
	address	  => inet_aton('192.168.1.2'),
	netmask	  => inet_aton('255.255.255.0),
  # netmask may be optionally specified as:
  #	cidr	  => 24,
	broadcast => inet_aton('192.168.1.255),
  # optional values, defaults shown
	metric	  => 1,
	mtu	  => 1500,
  };

The address family is determined by inspection of the size of the address.

	i.e.	BSD variants

  $iface_spec = {
	name	  => 'eth0',	# primary interface
	alias	  => inet_aton('192.168.1.2'),
	netmask	  => inet_aton('255.255.255.255),
  # netmask may be optionally specified as:
  #	cidr	  => 32,
  # optional values, defaults shown
	metric	  => 1,
	mtu	  => 1500,
  };

The keyword B<alias> says not to change the primary interface but instead to
add an address to the interface.

=item * $refresh_if = I<-E<gt>delete($naddr);>

Removes and address from an interface where supported.

=item * I<-E<gt>name();>

Return the B<name> of the interface.

=cut

sub name ($) {
  return $_[0]->{name};
}

=item * I<-E<gt>address([$family],[$index]);>

B<SCALAR context>

Get the interface specified by the optional C<$family> and C<$index>.

Absent a C<$family> and C<$index>, the first available interface for the
family AF_INET (or if not present AF_INET6) will be returned.

NOTE: this is not a definitive response. The OS may report the interfaces in
any order. Usually the primary interface is reported first but this is not
guaranteed. Use ARRAY context instead to get all addresses.

B<ARRAY context>

Returns a list of addresses assigned to this interface.

If a C<$family> is not specified then AF_INET is assumed or AF_INET6 if
there are no AF_INET addresses present.

=item * I<-E<gt>netmask([$family],[$index]);>

Similar to I<-E<gt>address([$family],[$index]);> above. Netmasks are reported in the
same order as the addresses above, in matching positions in the returned
array.

=item * I<-E<gt>destination([$family],[$index]);>

=item * I<-E<gt>broadcast([$family],[$index]);>

These to methods are identical in execution. The returned address
attribute(s) will be destination or broadcast addresses depending on the
status of the POINTOPOINT flag.

Similar to I<-E<gt>address([$family],[$index]);> above. If an address attribute is
unknown, the array slot will contain I<undef>.

=cut

sub address ($;$$) {
  unshift @_, 'addr';
# can't use 'goto', work around for broken perl 5.80-5.85 @_ bug
  return &_address
	if wantarray;
  return scalar &_address;
}

sub netmask ($;$$) {
  unshift @_, 'netm';
# can't use 'goto', work around for broken perl 5.80-5.85 @_ bug
  return &_address
	if wantarray;
  return scalar &_address;
}

sub destination ($;$$) {
  unshift @_, 'dsta';
# can't use 'goto', work around for broken perl 5.80-5.85 @_ bug
  return &_address
	if wantarray;
  return scalar &_address;
}

sub _address {
  my($k,$if,$f,$i) = @_;
  my $idx = $i || 0;
  $f = 0 unless $f;
  my $fam = 0 + $f;
  unless ($f) {							# if the family is missing
    if (exists $if->{args}->{&af_inet}) {
      $fam = &af_inet;						# select default, AF_INET
    }
    else {
      $fam = &af_inet6;						# or AF_INET6 if present
    }
  }
  if (! exists $if->{args}->{$fam} ||				# there is no such family
	$idx < 0 || $idx > $#{$if->{args}->{$fam}->{addr}}) {	# or the index is out of range
    return () if wantarray;					# PUNT!
    return undef;
  }

  return @{$if->{args}->{$fam}->{$k}}
	if wantarray;
  return $if->{args}->{$fam}->{$k}->[$idx];
}

=item * I<-E<gt>hwaddress([$hwaddr]);>

Returns the binary value of the MAC address for the interface. Optionally, where
supported, it allows setting of the MAC address.

  i.e.	$old_binmac = $if->hwaddress($new_binmac);
	$new_binmac = $if->hwaddress();


=item * I<-E<gt>flags([$new_flags]);>

Get or Set (where supported) the flags on the interface.

	i.e. down an interface.
	$flags	= $if->flags();
	$mask 	= ~IFF_UP;
	$old_fg	= $if->flags($flags & $mask);
	$flags	= $if->flags();

	UPDATES the if object

NOTE: returns undef if the interface is down or not configured.

=item * I<-E<gt>mtu([$new_mtu]);>

Get or Set (where supported) the mtu of the interface.

	$mtu = $if->mtu();
	$old_mtu = $if->mtu($new_mtu);

	UPDATES the if object

NOTE: returns undef if the interface is down or not configured.

=item * I<-E<gt>metric([$new_metric]);>

Get or Set (where supported) the metric for the interface.

	$metric = $if->metric();
	$old_metric = $if->metric($new_metric);

	UPDATES the if object

NOTE: returns undef if the interface is down or not configured.

=item * I<-E<gt>index();>

Get the interface index, not to be confused with the index number of the IP
assigned to a particular index.

There is no provision to SET the index.

	$index = $if->index();

=item * I<-E<gt>mask2cidr([$naddrmsk]);>

=item * $cidr = mask2cidr($naddrmsk);

Returns the CIDR (prefix length) for the netmask C<$naddrmsk>.

When no I<$naddrmsk> is specified the method will return the first address
in the first family starting with AF_INET, AF_INET6, etc... This is
particularly useful for interfaces with only a single address assigned.

May be called as a METHOD or a FUNCTION.

=item * I<-E<gt>mac_bin2hex();>

=item * $mac_txt = mac_bin2hex($bin_mac);

Converts a binary MAC address into hex text.

  i.e. A1:B2:C3:D4:E5:F6

May be called as a METHOD or a FUNCTION.

=item * I<-E<gt>info();>

Returns a pointer to a hash containing information about the interface as
follows:

  $info = {
	name	=> 'eth0',
	index	=> 1,
	mtu	=> 1500,
	metric	=> 1,
	flags	=> 1234,
	mac	=> binary_mac_address,
	$fam0	=> {
		number	=> of_addresses,
		size	=> of_address,
	},
	$fam1	=> etc....
  };

  where $famX is one of AF_INET, AF_INET6, etc...

=cut

sub info ($) {
  my $if = shift;
  my $name = $if->{name};
  my ($mtu,$metric,$flags,$mac,$index) = @{$if->{args}}{qw(mtui metk flag maci indx)};

  my $info = {
	name	=> $name,
	mtu	=> $mtu,
	metric	=> $metric,
	flags	=> $flags,
	mac	=> $mac,
	index	=> $index,
  };
  my $af_inet6 = eval { &af_inet6 } || 0;
  foreach(&af_inet,$af_inet6) {
    next unless $_;
    if (exists $if->{args}->{$_}) {
      $info->{$_}->{size} = $if->{args}->{$_}->{size};
      $info->{$_}->{number} = @{$if->{args}->{$_}->{addr}};
    }
  }
  return $info;
}

=item * I<-E<gt>type([$naddr6]);>

=item * $type = type($naddr6);

B<ipV6> method. Returns attributes of an IPV6 address that may be tested
with these bit masks:

  IPV6_ADDR_ANY			unknown
  IPV6_ADDR_UNICAST		unicast
  IPV6_ADDR_MULTICAST		multicast
  IPV6_ADDR_ANYCAST		anycast
  IPV6_ADDR_LOOPBACK		loopback
  IPV6_ADDR_LINKLOCAL		link-local
  IPV6_ADDR_SITELOCAL		site-local
  IPV6_ADDR_COMPATv4		compat-v4
  IPV6_ADDR_SCOPE_MASK		scope-mask
  IPV6_ADDR_MAPPED		mapped
  IPV6_ADDR_RESERVED		reserved
  IPV6_ADDR_ULUA		uniq-lcl-unicast
  IPV6_ADDR_6TO4		6to4
  IPV6_ADDR_6BONE		6bone
  IPV6_ADDR_AGU			global-unicast
  IPV6_ADDR_UNSPECIFIED		unspecified
  IPV6_ADDR_SOLICITED_NODE	solicited-node
  IPV6_ADDR_ISATAP		ISATAP
  IPV6_ADDR_PRODUCTIVE		productive
  IPV6_ADDR_6TO4_MICROSOFT	6to4-ms
  IPV6_ADDR_TEREDO		teredo
  IPV6_ADDR_ORCHID		orchid
  IPV6_ADDR_NON_ROUTE_DOC	non-routeable-doc

    i.e.  if ($type & $mask) {
	      print $mask,"\n";
	  ...

... will print the string shown to the right of the bit mask.

When no I<$naddr6> is specified the method will return the first AF_INET6
address found. This is particularly useful for interfaces with only a single
address assigned.

May be called as a METHOD or a FUNCTION with an $naddr6 argument.

=item * I<-E<gt>scope([$naddr6]);>

=item * $scope = scope($naddr6);

Returns the RFC-2373 scope of an IPV6 address that may be equated to these
constants.

  RFC2373_GLOBAL	global-scope	0xE
  RFC2373_ORGLOCAL	org-local	0x8
  RFC2373_SITELOCAL	site-local	0x5
  RFC2373_LINKLOCAL	link-local	0x2
  RFC2373_NODELOCAL	loopback	0x1

One additional constant is provided as there is an out of band
scope value mapped returned when determining scope. If you want B<standard>
RFC2373 scope only, && the return value with 0xF

  LINUX_COMPATv4	lx-compat-v4	0x10

    i.e.  if ($scope = $const) {
	      print $const,"\n";
	  ...

... will print the string shown to the right of the constant.

When no I<$naddr6> is specified the method will return the first AF_INET6
address found. This is particularly useful for interfaces with only a single
address assigned.

May be called as a METHOD or a FUNCTION with an $naddr6 argument.

=back

=cut

sub _family {
  my $len = length($_[0]);
  if ($len == 4) {
    return &af_inet;
  }
  elsif ($len == 16) {
    return &af_inet6;
  }
  return 0;
}

=head1 FUNCTIONS

Unless otherwise specified, errors for all methods return either B<undef> or
and empty array depending on the expected return context.



=over 4

=item * $naddr = inet_aton($host or $dotquad);

Converts a hostname or dotquad ipV4 address into a packed network address.

=cut

# if Socket lib is broken in some way, check for overange values
#
my $overange = yinet_aton('256.1') ? 1:0;

sub inet_aton {
  if (! $overange || $_[0] =~ /[^0-9\.]/) {	# hostname
    return &yinet_aton;
  }
  my @dq = split(/\./,$_[0]);
  foreach (@dq) {
    return undef if $_ > 255;
  }
  return &yinet_aton;
}

=item * $dotquad = inet_ntoa($naddr);

Convert a binary IPV4 address into a dotquad text string.

=item * $ipV6_txt = full_inet_ntop($naddr6);

  Returns an uncompressed text string for a net6 address.

  i.e.   FE80:02A0:0000:0000:0000:0000:0123:4567

=item * $minimized = ipV6compress($ipV6_txt);

Compress an ipV6 address to the minimum RFC-1884 format

  i.e.	FE80:02A0:0000:0000:0000:0000:0123:4567
  to	FE80:2A0::123:4567

=cut

sub _ipv6_acommon {
  my($ipv6) = @_;
  return undef unless $ipv6;
  local($1,$2,$3,$4,$5);
  if ($ipv6 =~ /^(.*:)(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) {	# mixed hex, dot-quad
    return undef if $2 > 255 || $3 > 255 || $4 > 255 || $5 > 255;
    $ipv6 = sprintf("%s%X%02X:%X%02X",$1,$2,$3,$4,$5);			# convert to pure hex
  }
  my $c;
  return undef if
	$ipv6 =~ /[^:0-9a-fA-F]/ ||			# non-hex character
	(($c = $ipv6) =~ s/::/x/ && $c =~ /(?:x|:):/) ||	# double :: ::?
	$ipv6 =~ /[0-9a-fA-F]{5,}/;			# more than 4 digits
  $c = $ipv6 =~ tr/:/:/;				# count the colons
  return undef if $c < 7 && $ipv6 !~ /::/;
  if ($c > 7) {						# strip leading or trailing ::
    return undef unless
	$ipv6 =~ s/^::/:/ ||
	$ipv6 =~ s/::$/:/;
    return undef if --$c > 7;
  }
  while ($c++ < 7) {					# expand compressed fields
    $ipv6 =~ s/::/:::/;
  }
  $ipv6 .= 0 if $ipv6 =~ /:$/;
  return $ipv6;
}

sub ipV6compress ($) {
  my $ipv6 = &_ipv6_acommon;
  return undef unless $ipv6;
  my $c = 'X'. join(':',map {				# compression begins
    if ($_ !~ /[a-fA-F1-9]/) {
      0;
    }
    elsif ($_ =~ /^0+(.+)/) {
      $1;
    }
    else {
      $_;
    }} split(/\:/,$ipv6)) .'X';

  my @stuff = ($c =~ /[X\:][0\:]+[X\:]/g);
  unless (@stuff) {
    $c =~ s/X//g;
    return ($ipv6_format) ? uc $c : lc $c;
  }

  my $max = 0;
  my $idx = 0;
  foreach(0..$#stuff) {
    my $len = length($stuff[$_]);
    if ($len > $max) {
      $max = $len;
      $idx = $_;
    }
  }
  if ($max > 3) {
    $c =~ s/$stuff[$idx]/::/;
  }
  $c =~ s/X//g;
  return ($ipv6_format) ? uc $c : lc $c;
}

=item * $ipV6_txt = inet_ntop($naddr6)

  Returns a minimized RFC-1884 IPV6 address

=cut

sub inet_ntop ($) {
  return (ipV6compress(full_inet_ntop($_[0])));
}

=item * $naddr6 = inet_pton($ipV6_txt);

Takes an IPv6 text address of the form described in rfc1884
and returns a naddr6 128 bit binary address string in network order.

=cut

sub inet_pton {
  my $ipv6 = &_ipv6_acommon;
  return undef unless $ipv6;
  my @hex = split(/:/,$ipv6);
  foreach(0..$#hex) {
    $hex[$_] = hex($hex[$_] || 0);
  }
  pack("n8",@hex);
}

=item * $cidr = mask2cidr($naddrmsk);

=item * I<-E<gt>mask2cidr($naddrmsk);>

Returns the CIDR (prefix length) for the netmask C<$naddrmsk>.

May be called as a FUNCTION or a METHOD.

=item * $mac_txt = mac_bin2hex($bin_mac);

=item * I<-E<gt>mac_bin2hex();>

Converts a binary MAC address into hex text.

  i.e. A1:B2:C3:D4:E5:F6

May be called as a FUNCTION or a METHOD.

=item * $type = type($naddr6);

=item * I<-E<gt>type($naddr6);>

B<ipV6> method. Returns attributes of an IPV6 address that may be tested
with the bit masks described in detail in the METHOD section above.

May be called as a FUNCTION or a METHOD with an $naddr6 argument.

=item * $scope = scope($naddr6);

=item * I<-E<gt>scope($naddr6);>

Returns the RFC-2373 scope of an IPV6 address that may be equated module
constants described in detail in the METHOD section above.

May be called as a FUNCTION or a METHOD with an $naddr6 argument.

=item * $symbolptr = net_symbols();

Returns a hash containing most of the network symbols available for this
architecture.

  where $symbolptr = {
	SYMBOL_TEXT => value,
	...
  };

Most all of these symbols have both a numeric and text value. Perl does the
B<right> thing and uses the numeric value in all logic and arithmetic
operations and provides the text value for print requests.

To print the numeric value:

  print (0 + &SYMBOL),"\n";

  i.e.	print (0 + AF_INET()),"\n";

results in the digit B<2> being printed, whereas:

	print AF_INET,"\n";

results in the string "B<inet>" being printed.

  NOTE: that many symbols are OS dependent. Do not use 
	numeric values in your code, instead use the symbol.

  i.e. AF_INET, AF_INET6, AF_LINK, etc...

=back

=head1 PREREQUISITES

To build Net::Interface, it is necessary to have kernel development
libriaries installed on the build system. Systems such as Ubuntu, FreeBSD,
etc... do NOT come with these libraries installed.

Your build system must have a fully populated directory

    /usr/include/sys

Missing header files in the above directory will produce errors saying that
symbols such as AF_INET and PF_INET are missing.

=head1 ACKNOWLEDGEMENTS

This version of Net::Interface has been completely rewritten and updated to
include support for IPV6. Credit should be given to the original author

	Stephen Zander <gibreel@pobox.com>

for conceiving the idea behind Net::Interface and to the work done by 

 	Jerrad Pierce jpierce@cpan.org

on the maintenance and improvements to the original version.

Thanks also go to

	Jens Rehsack <rehsack@web.de>

for inspiring me to create this updated version and for his assistance in
vetting the design concepts and loads of other helpful things.

The following functions are used in whole or in part as include files to
Interface.xs. The copyright (same as Perl itself) is include in the file.

    file:	       functions:

  miniSocketXS.c  inet_aton, inet_ntoa

inet_aton, inet_ntoa are from the perl-5.8.0 release by Larry Wall, copyright
1989-2002. inet_aton, inet_ntoa code is current through perl-5.9.3 release.
Thank you Larry for making PERL possible for all of us.

=head1 COPYRIGHT  2008-2016 Michael Robinton <michael@bizsystems.com>

All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

  a) the GNU General Public License as published by the Free
  Software Foundation; either version 2, or (at your option) any
  later version, or

  b) the "Artistic License" which comes with this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
distribution, in the file named "Artistic".  If not, I'll be glad to provide one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the 

	Free Software Foundation, Inc.
	59 Temple Place, Suite 330
	Boston, MA  02111-1307, USA

or visit their web page on the internet at:

	http://www.gnu.org/copyleft/gpl.html.

=head1 SEE ALSO

ifconfig(8), Net::Interface::NetSymbols,
L<Net::Interface::Developer>

=cut

1;

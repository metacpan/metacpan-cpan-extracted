package Net::DNS::ToolKit;

use strict;
#use warnings;
#use Carp;

use Net::DNS::Codes 0.06 qw(:RRs :constants);
use vars qw(@ISA $VERSION @EXPORT_OK %timeX);

use NetAddr::IP::Util qw(:inet);
require Exporter;
require DynaLoader;
use AutoLoader qw(AUTOLOAD);

@ISA = qw(Exporter DynaLoader);

$VERSION = do { my @r = (q$Revision: 0.48 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
	get1char
	get16
	get32
	put1char
	put16
	put32
	getIPv4
	putIPv4
	getIPv6
	putIPv6
	getstring
	putstring
	dn_comp
	dn_expand
	parse_char
	gethead
	newhead
	getflags
	putflags
	get_qdcount
	get_ancount
	get_nscount
	get_arcount
	put_qdcount
	put_ancount
	put_nscount
	put_arcount
	inet_aton
	inet_ntoa
	ipv6_aton
	ipv6_n2x
	ipv6_n2d
	sec2time
	ttlAlpha2Num
	collapse
	strip
	get_ns
	gettimeofday
);

## stuff for sec2time, ttlAlpha2Num
%timeX = (				# multipliers
	's'	=> 1,			# seconds
	'm'	=> 60,			# minutes
	'h'	=> 60 * 60,		# hours
	'd'	=> 24 * 60 * 60,	# days
	'w'	=> 7 * 24 * 60 * 60,	# weeks
);

#sub AUTOLOAD {
#    # This AUTOLOAD is used to 'autoload' constants from the constant()
#    # XS function.  If a constant is not found then control is passed
#    # to the AUTOLOAD in AutoLoader.
#
#    my $constname;
#    our $AUTOLOAD;
#    ($constname = $AUTOLOAD) =~ s/.*:://;
#    croak "& not defined" if $constname eq 'constant';
#    my $val = constant($constname, @_ ? $_[0] : 0);
#    if ($! != 0) {
#	if ($! =~ /Invalid/ || $!{EINVAL}) {
#	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
#	    goto &AutoLoader::AUTOLOAD;
#	}
#	else {
#	    croak "Your vendor has not defined CTest macro $constname";
#	}
#    }
#    {
#	no strict 'refs';
#	# Fixed between 5.005_53 and 5.005_61
#	if ($] >= 5.00561) {
#	    *$AUTOLOAD = sub () { $val };
#	}
#	else {
#	    *$AUTOLOAD = sub { $val };
#	}
#    }
#    goto &$AUTOLOAD;
#}

bootstrap Net::DNS::ToolKit $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub DESTROY {}

1;
__END__

=head1 NAME

Net::DNS::ToolKit - tools for working with DNS packets

=head1 SYNOPSIS

  use Net::DNS::ToolKit qw(

	get1char
	get16
	get32
	put1char
	put16
	put32
	getIPv4
	putIPv4
	putIPv6
	getIPv6
	getstring
	putstring
	dn_comp
	dn_expand
	parse_char
	gethead
	newhead
	getflags
	putflags
	get_qdcount
	get_ancount
	get_nscount
	get_arcount
	put_qdcount
	put_ancount
	put_nscount
	put_arcount
	inet_aton
	inet_ntoa
	ipv6_aton
	ipv6_n2x
	ipv6_n2d   
	sec2time
	ttlAlpha2Num
	collapse
	strip
	get_ns
	gettimeofday
  );

  $char = get1char(\$buffer,$offset);
  ($int, $newoff)  = get16(\$buffer,$offset);
  ($long, $newoff) = get32(\$buffer,$offset);
  $newoff = put1char(\$buffer,$offset,$u_char);
  $newoff = put16(\$buffer,$offset,$int);
  $newoff = put32(\$buffer,$offset,$long);
  $flags = getflags(\$buffer);
  true = putflags(\$buffer,$flags);
  $int = get_qdcount(\$buffer);
  $int = get_ancount(\$buffer);
  $int = get_nscount(\$buffer);
  $int = get_arcount(\$buffer);
  $newoff = put_qdcount(\$buffer,$int);
  $newoff = put_ancount(\$buffer,$int);
  $newoff = put_nscount(\$buffer,$int);
  $newoff = put_arcount(\$buffer,$int);
  ($netaddr,$newoff)=getIPv4(\$buffer,$offset);
  $newoff = putIPv4(\$buffer,$offset,$netaddr);
  ($ipv6addr,$newoff)=getIPv6(\$buffer,$offset);
  $newoff = putIPv6(\$buffer,$offset,$ipv6addr);
  ($offset,
   $id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
   $qdcount,$ancount,$nscount,$arcount)
	= gethead(\$buffer);
  $newoff = newhead(\$buffer,$id,$flags,
	$qdcount,$ancount,$nscount,$arcount);
  ($b,$h,$d,$a)=parse_char($char);
  ($newoff,$name) = dn_expand(\$buffer,$offset);
  ($newoff,@dnptrs)=dn_comp(\$buffer,$offset,\$name,\@dnptrs);
  $dotquad = inet_ntoa($netaddr);
  $netaddr = inet_aton($dotquad);
  $ipv6addr = ipv6_aton($ipv6_text);
  $hex_text = ipv6_n2x($ipv6addr);
  $dec_text = ipv6_n2d($ipv6addr);
  $timetxt = sec2time($seconds);
  $seconds = ttlAlpha2Num($timetext);
  $shorthost = collapse($zonename,$longhost);
  $tag = strip($P_tag);
  @nameservers = get_ns();
  ($secs,$usecs) = gettimeofday();

=head1 DESCRIPTION

Routines to pick apart, examine and put together DNS packets. They can be
used for diagnostic purposes or as building blocks for DNS applications such
as DNS servers and clients or to allow user applications to interact
directly with remote DNS servers.

  See: Net::DNS::ToolKit:RR and the subdirectory
	lib/Net/DNS/ToolKit/RR/
  for individual Resource Record methods.

  Net::DNS::ToolKit does not handle every type of RR with context
  help for the record format. HOWEVER, it does handle all unknown
  record types per RFC-3597 so if your program can manipulate the
  binary and/or hex representation of the data as proscribed in RFC-3597 this
  module will always work for you.

A good example of full utilization of this module is
L<Net::DNS::Dig>/module.

See: L<Net::DNS::ToolKit::RR> (included in this distribution) for a complete description of how to use this
module and the accompanying Resource Records tools.

=head1 FUNCTIONS

These functions return a value and offset in list context and first value only in
scalar context.

  ($int,$newoff)	= get16(...
  ($long,$newoff)	= get32(...
  ($netaddr,$newoff)	= getIPv4(...
  ($ipv6addr,$newoff)	= getIPv6(...
  ($string,$newoff)	= getstring(...
  ($newoff,$name)	= dn_expand(...
  ($secs,$usecs)	= gettimeofday(...


These functions return only a value or an offset.

  $newoff	= put1char(...
  $newoff	= put16(...  
  $newoff	= put32(...
  $newoff	= put_qdcount(...
  $newoff	= put_ancount(...
  $newoff	= put_nscount(...
  $newoff	= put_arcount(...
  $newoff	= putIPv4(...
  $newoff	= putIPv4(...
  $newoff	= putstring(...
  $newoff	= newhead(...
  $flags	= getflags(...
  true		= putflags(...
  $int		= get_qdcount(...
  $int		= get_ancount(...
  $int		= get_nscount(...
  $int		= get_arcount(...
  $char		= get1char(...
  $dotquad	= inet_ntoa(...
  $netaddr	= inet_aton(...
  $timetxt	= sec2time(...
  $seconds	= ttlAlpha2Num(...
  $tag		= strip(...
  $shorthost	= collapse(...

This function always return list context prefixed by a new offset.

  ($newoff,@dnptrs) = dn_comp(...
  ($offset,@list)   = gethead(...

These functions always return list context.

  @list		= parse_char(...
  @nameservers	= get_ns(...

=over 4

=item * $char = get1char(\$buffer,$offset);

Get a single character from the buffer at $offset

  input:	pointer to buffer,
		offset into buffer
  output:	the "character"   
           or	undef if the pointer
		is outside the buffer

=item * ($int, $newoff)  = get16(\$buffer,$offset);

Get a 16 bit integer from the buffer at $offset. Return 
the value and a new offset pointing at the next character.

Returns and empty array on error.

  input:	pointer to buffer,
		offset into buffer
  returns:	16 bit integer,
		offset + size of int

In SCALAR context, returns just the value.

=item * $newoff = put1char(\$buffer,$offset,$u_char);

Put an unsigned 8 bit value into the buffer at $offset. Return the value of
the new offset pointer to the next char (usually end of buffer).

=item * $newoff = put16(\$buffer,$offset,$int);

Put a 16 bit integer into the buffer at $offset. Return the value of
the new offset pointer to the the next char (usually end of buffer).

  input:	pointer to buffer,
		offset into buffer,
		16 bit integer
  returns:	offset + size of int

=item * ($long, $newoff) = get32(\$buffer,$offset);

Get a 32 bit long from the buffer at $offset. Return the 
long and a new offset pointing at the next character.

Returns and empty array on error.

  input:	pointer to buffer,
		offset into buffer
  returns:	32 bit long,
		offset + size long

In SCALAR context, returns just the value.

=item * $newoff = put32(\$buffer,$offset,$long);

Put a 32 bit long into the buffer at $offset. Return the value of
the new offset pointer to the the next char (usually end of buffer).

  input:	pointer to buffer,
		offset into buffer,
		32 bit long
  returns:	offset + size of int

=item * $flags = getflags(\$buffer);

Get the flag bits from the header

  input:	pointer to buffer,
  returns:	flag bits

=cut

sub getflags {
  my $bp = shift;
  @_ = ($bp,2);
  goto &get16;
}

=item * putflags(\$buffer,$flags);

Put flags bits back in header

  input:	pointer to buffer,
		flags bits
  returns:	n/a

=cut

sub putflags {
  my($bp,$flags) = @_;
  @_ = ($bp,2,$flags);
  goto &put16;
}

=item * $int = get_qdcount(\$buffer);

Get the contents of the qdcount.

  input:	pointer to buffer,
  returns:	16 bit integer,

=cut

sub get_qdcount {
  my $bp = shift;
  @_ = ($bp,4);
  goto &get16;
}

=item * $int = get_ancount(\$buffer);

Get the contents of the ancount.

  input:	pointer to buffer,
  returns:	16 bit integer,

=cut

sub get_ancount {
  my $bp = shift;
  @_ = ($bp,6);
  goto &get16;
}

=item * $int = get_nscount(\$buffer);

Get the contents of the nscount.

  input:	pointer to buffer,
  returns:	16 bit integer,

=cut

sub get_nscount {
  my $bp = shift;
  @_ = ($bp,8);
  goto &get16;
}

=item * $int = get_arcount(\$buffer);

Get the contents of the arcount.

  input:	pointer to buffer,
  returns:	16 bit integer,

=cut

sub get_arcount {
  my $bp = shift;
  @_ = ($bp,10);
  goto &get16;
}

=item * $newoff = put_qdcount(\$buffer,$int);

Put a 16 bit integer into qdcount. Return an offset to ancount.

  input:	pointer to buffer,
		16 bit integer,
  returns:	offset to ancount

=cut

sub put_qdcount {
  my ($bp,$val) = @_;
  @_ = ($bp,4,$val);
  goto &put16;
}


=item * $newoff = put_ancount(\$buffer,$int);

Put a 16 bit integer into ancount. Return an offset to nscount.

  input:	pointer to buffer,
		16 bit integer,
  returns:	offset to nscount

=cut

sub put_ancount {
  my ($bp,$val) = @_;
  @_ = ($bp,6,$val);
  goto &put16;
}


=item * $newoff = put_nscount(\$buffer,$int);

Put a 16 bit chunk into nscount. Return an offset to arcount.

  input:	pointer to buffer,
		16 bit integer,
  returns:	offset to arcount

=cut

sub put_nscount {
  my ($bp,$val) = @_;
  @_ = ($bp,8,$val);
  goto &put16;
}

=item * $newoff = put_arcount(\$buffer,$int);

Put a 16 bit integer into arcount. Return an offset to answer section.

  input:	pointer to buffer,
		16 bit integer,
  returns:	offset to question section

=cut

sub put_arcount {
  my ($bp,$val) = @_;
  @_ = ($bp,10,$val);
  goto &put16;
}

=item * ($netaddr,$newoff)=getIPv4(\$buffer,$offset);

Get an IPv4 network address from the buffer at $offset. Return the 
netaddr and a new offset pointing at the next character beyond.

Returns and empty array on error.

  input:	pointer to buffer,
		offset into buffer
  returns:	netaddr,
		offset + size of ipaddr

In SCALAR context, returns just netaddr.

=item * $newoff = putIPv4(\$buffer,$offset,$netaddr);

Put a netaddr into the buffer. Return the value of the
new offset pointer to the next char (usually end of buffer).

  input:	pointer to buffer,
		offset into buffer,
		packed IPv4 net address
  returns:	pointer to end of buffer

=item * ($ipv6addr,$newoff)=getIPv6(\$buffer,$offset);

Get an IPv6 network address from the buffer at $offset. Return the
ipv6addr and a new offset pointing at the next character beyond.

Returns and empty array on error.

  input:	pointer to buffer,
		offset into buffer
  returns:	ipv6addr,
		offset + size of ipv6addr

IN SCALAR context, returns just ipv6addr.

=item * $newoff = putIPv6(\$buffer,$offset,$ipv6addr);

Put an ipv6addr into the buffer. Return the value of the
new offset pointer to the next char (usually end of buffer).

  input:	pointer to buffer,
		offset into buffer,
		128 bit IPv6 net address
  returns:	pointer to end of buffer

=item * ($string,$newoff) =
	getstring(\$buffer,$offset,$length);

Return a string of $length from the buffer.

  input:	pointer to buffer,
		offset,
		length of string
  returns:	string,
		new offset to end
		off string in buffer

=item * $newoff = putstring(\$buffer,$offset,\$string);

Append a string to $buffer at $offset.

  input:	pointer to buffer,
		offset into buffer,
		pointer to string
  returns:	new offset to end of buffer

=item * ($offset,@headitems) = gethead(\$buffer);

  ($offset,
  $id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
   $qdcount,$ancount,$nscount,$arcount)
        = gethead(\$buffer);

  Get the numeric codes for header variables

    0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
  -------------------------------------------------
   15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  |                      ID                       |
  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  |QR|   Opcode  |AA|TC|RD|RA| Z|AD|CD|   RCODE   |
  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  |                    QDCOUNT                    |
  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  |                    ANCOUNT                    |
  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  |                    NSCOUNT                    |
  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  |                    ARCOUNT                    |
  +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

  The length of this header is NS_HFIXEDSZ

  input:	pointer to message buffer
  returns:	offset to question section,
		array of variables

=item * $newoff=newhead(\$buffer,
  $id,$flags,$qdcount,$ancount,$nscount,$arcount);

Creat a new header and return the offset to question

  input:	\$buffer
		$id,
		$flags,
		$qdcount,
		$ancount,
		$nscount,
		$arcount
  returns:	offset to question = NS_HFIXEDSZ
	    or	undefined on error

  If qdcount, ancount, nscount, arcount are
  not present, then they will be set to zero.

  example dump script:

  use lib qw(blib/lib blib/arch);
  use Net::DNS::Codes qw(:all);
  use Net::DNS::ToolKit::Debug qw(
	print_head
	print_buf
  );
  use Net::DNS::ToolKit qw(
        get1char
        parse_char
        newhead
  );
  my $buffer = '';
  newhead(\$buffer,
        1234,                   # ID
        QR | BITS_QUERY | RD,
        1,                      # questions
        5,                      # answers
        2,                      # ns authority
        3,                      # glue records
  );

  print_head(\$buffer);
  print_buf(\$buffer);

  Will produce the following output:

  ID     => 1234    
  QR      => 1    
  OPCODE  => QUERY
  AA      => 0
  TC      => 0
  RD      => 1
  RA      => 0
  Z       => 0
  AD      => 0
  CD      => 0
  RCODE   => NOERROR
  QDCOUNT => 1
  ANCOUNT => 5
  NSCOUNT => 2
  ARCOUNT => 3
  0     :  0000_0100  0x04    4    
  1     :  1101_0010  0xD2  210    
  2     :  1000_0001  0x81  129    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0101  0x05    5    
  8     :  0000_0000  0x00    0    
  9     :  0000_0010  0x02    2    
  10    :  0000_0000  0x00    0    
  11    :  0000_0011  0x03    3    

=cut

sub newhead {
  my($bp,$id,$flags,$qdcount,$ancount,$nscount,$arcount) = @_;
  return undef unless ref $bp;
  return undef unless defined $id;
  $qdcount = 0 unless $qdcount;
  $ancount = 0 unless $ancount;
  $nscount = 0 unless $nscount;
  $arcount = 0 unless $arcount;
  $$bp = pack("n n n n n n",$id,$flags,$qdcount,$ancount,$nscount,$arcount);
  return NS_HFIXEDSZ;
}

=item * ($b,$h,$d,$a) = parse_char($char);

  return strings for the character in:

    binary    hex   decimal   ascii
  0011_1001  0x39      57      9

  as appropriate. Ascii is only 
  returned if printable.

A simple script using this routine can provide
a view into a DNS packet to examine the bits
and byte. Very useful while writing DNS client
and server routines. See the example below.

=item * ($name,$newoff) = dn_expand(\$buffer,$offset);

Expands a compressed domain name into a full domain name.

  input:	pointer to buffer,
		offset into buffer
  returns:	expanded name,
		pointer to next RR

=item * ($newoff,@dnptrs)=dn_comp(\$buffer,$offset,\$name,\@dnptrs);

Compress a domain name and append it to the buffer.

  input:	pointer to buffer,
		offset to insertion point,
	(usually end of buffer)
		pointer to name,
		pointer to array of offsets of
		  previously compressed names,
  returns:	new offset to end of buffer,
		updated array of offsets to 
		  previous compressed names,

  NOTES:   1)	When the first domain name
		is compressed, the \@dnptrs
		array is ommited. dn_comp
		will return an initialized
		array that can then be used
		for subsequent calls.

	  i.e.	initial call

  ($newoff,@dnptrs)=dn_comp(\$buffer,$offset,\$name);

	   2) if \@dnptrs is null, no compression takes place

=cut

# deprecated, does not see to work
#	   2)	compression can be suppressed
#		for test purposes if the pointer
#		to $name is stored in a glob
#		reference rather than a scalar.
#
#	  i.e.	$name = 'hostname.com';
#		local *glob = \$name;
#
#  ($newoff,@dnptrs)=dn_comp(\$buffer,$offset,\*glob);
#		[use a pointer to *glob]
#

=item * $dotquad = inet_ntoa($netaddr); 

Convert a packed IPv4 network address to a dot-quad IP address.

  input:	packed network address
  returns:	IP address i.e. 10.4.12.123

Imported/Exported from NetAdder::IP::Util

=item * $netaddr = inet_aton($dotquad);

Convert a dot-quad IP address into an IPv4 packed network address.

  input:	IP address i.e. 192.5.16.32
  returns:	packed network address

Imported/Exported from NetAdder::IP::Util

=item * $ipv6addr = ipv6_aton($ipv6_text);

Takes an IPv6 address of the form described in rfc1884
and returns a 128 bit binary RDATA string.

  input:	ipv6 text
  returns:	128 bit RDATA string

Imported/Exported from NetAdder::IP::Util

=item * $hex_text = ipv6_n2x($ipv6addr);

Takes an IPv6 RDATA string and returns an 8 segment IPv6 hex address

  input:	128 bit RDATA string
  returns:	x:x:x:x:x:x:x:x

Imported/Exported from NetAdder::IP::Util

=item * $dec_text = ipv6_n2d($ipv6addr);

Takes an IPv6 RDATA string and returns a mixed hex - decimal IPv6 address
with the 6 uppermost chunks in hex and the lower 32 bits in dot-quad
representation.

  input:	128 bit RDATA string
  returns:	x:x:x:x:x:x:d.d.d.d

Imported/Exported from NetAdder::IP::Util

=item * $timetxt = sec2time($seconds);

Convert numeric seconds into a string of the form

  NNw NNd NNh NNm NNs

for weeks, days, hours, minutes, seconds respectively.

  input:	seconds
  returns:	elapsed time text

=cut

############################################################
# sec2time
# convert seconds to elapsed time notation
#
# input:	seconds
# returns:	elapsed time
#
sub sec2time
{
  my ( $s ) = @_;
  return $s unless $s;
  my $t = '';
  foreach ( 'w', 'd', 'h', 'm' ) {
    my $x = int ( $s / $timeX{$_} );
    $t .= "${x}$_" if $x;
    $s -= $x * $timeX{$_};
  }
  $t .= "${s}s" if $s;
  $t;
}

=item * $seconds = ttlAlpha2Num($timetext);

Convert a string of time text of the form

  NNw NNd NNh NNm NNs

into seconds. Upper case is OK.

  input:	ttl in form numeric
		or alpha numeric
  returns:	seconds

=cut

############################################################
# ttlAlpha2Num
# convert alpha TTL representation to numberic interger
#
# input:	ttl in form [numeric || alpha numeric]
# return:	ttl numeric
#
sub ttlAlpha2Num
{
  my $ttl;
  return 0 unless $_[0];
  ( $ttl = $_[0] ) =~ s/\s//g;
  return 0 unless $ttl;
  return $ttl if ( $ttl !~ /\D/ );	# OK as is
  $ttl = "\L$ttl";			# all lower case
  return $ttl if $ttl =~ /[^0-9smhdw]/;	# err if not allowed
  $ttl =~ s/(\D)/$1x/g;			# insert split character
  my @ttl = split ('x', $ttl);		# extract components
  $ttl = 0;
  foreach my $i ( @ttl ) {		# calculate seconds
    my $act = chop $i;			# get character
    $i *= $timeX{$act}
	if exists $timeX{$act};		# multiply by correct constant
    $ttl += $i;
  }
  $ttl;
}

=item * $shorthost = collapse($zonename,$longhost);

Remove the zone portion of a fully qualified domain name and return the host
portion.

  input:	zone name,
		fqdn
  returns:	short host name

  i.e.	zone = bar.com
	fqdn = foo.bar.com

  foo = collapse(zone,fqdn);

Testing is not case sensitive.
If the fqdn does not end in the zone name then the fqdn is returned.

=cut

sub collapse {
  my($zone,$fqdn) = @_;
  return ($fqdn =~ /\.$zone$/i)
	? $`
	: $fqdn;
}

=item * $tag = strip($P_tag);

Remove the leading character(s) from a type/class label.

  input:     label  # like T_MX or C_IN
  returns:   tag    # MX, IN

=cut

sub strip {
  ($_ = $_[0]) =~ s/[A-Z]+_//;
  $_;
}

=item * @nameservers = get_ns();

Return a list of name server addresses in packed network form for use by this host.

=item * ($secs,$usecs) = gettimeofday();

Returns a time value that is accurate to the nearest
microsecond but also has a range of years.

  input:    none
  returns:  seconds since epoch,
	    microseconds (of current sec)

=cut

sub get_ns {
  local *Rconf;
  my $path = get_path();
  my @ns;
  if ($path && open(Rconf,$path)) {
    my @lines = (<Rconf>);		# slurp lines
    close Rconf;
    foreach(@lines) {
      next if $_ =~ /^\s*#/;
      if ($_ =~ /nameserver\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ &&
		($_ = inet_aton($1))) {
	push @ns, $_;
      }
    }
  }
  unless (@ns || (@ns = lastchance())) {
    goto &get_default;
  }
  return wantarray ? @ns : $ns[0];
}

=back

=head1 INSTALLATION

To install this module, type:

	perl Makefile.PL
	make
	make test
	make install

=head1 DEPENDENCIES

	perl 5.00503
	Net::DNS::Codes 0.06

=head1 EXAMPLES

See the B<scripts> directory in this distribution

=over 4

=item * dig.pl

A script that functions like B<dig> in the BIND distribution. It provides
additional functionality in that it will dump the packet buffer contents for
inspection in debug mode. It is easily modified to add features.

 Syntax:
 dig.pl [@server] [+tcp] [-d] [-p port#] [-t type] name

 server is the name or IP address of the name server to query.  An IPv4
        address can be provided in dotted-decimal notation.  When the
        supplied server argument is a hostname, dig resolves that name
        before querying that name server.

  +tcp  only use TCP protocol

  -d    print the query to the console

  -p    port# is the port number that dig.pl will send its queries 
        instead of the standard DNS port number 53.

  -t    indicates what type of query is required. This script supports
        only A, MX, NS, CNAME, SOA, TXT, and ANY queries as well as
        AXFR record transfers. If no type argument is supplied, dig.pl
        will perform a lookup for an A record

 name   is the name of the resource record that is to be looked up.

=item * rdns_blk.pl

A script to lookup an entire class "C" set of PTR records recursively.
This is useful hunting spam domains where many DNS's do not allow AXFR
record transfers to inspect what is in a range of IP addresses.

 Syntax:
  ./rdns_blk.pl nn.nn.nn[.nn]

  at least the first three groups of 
  dot.quad.addr numbers

  returns PTR results for 1..255 of address range
  skips non-existent records, notes timeouts

=back

=head1 EXPORT

None

=head1 EXPORT_OK

get1char
get16
get32
put1char
put16
put32
getIPv4
putIPv4
getIPv6
putIPv6
getstring
putstring
dn_comp
dn_expand
parse_char
gethead
newhead
getflags
putflags
get_qdcount
get_ancount
get_nscount
get_arcount
put_qdcount
put_ancount
put_nscount
put_arcount
inet_aton
inet_ntoa
ipv6_aton
ipv6_n2x
ipv6_n2d   
sec2time
ttlAlpha2Num
collapse
strip
get_ns
gettimeofday

=head1 BUGS

There have been some reports of the "C" library function for 

  "int res_init(void);

not properly returning the local resolver nameserver configuration
information for certain Perl 5.6 -> 5.8 hosts. This is for the ToolKit function "get_ns()".

I have been unable to duplicate this on any of the ix86 Linux or Sun-Sparc systems that I have. 
If you have a system that exhibits this problem and can provide a user account, I'd
appreciate it if you would contact me so I can fix it.

Update v0.38 Thu Oct  2 14:49:26 PDT 2008
This may be an issue with sharing of the __res_state structure. The update
uses a private __res_state structure rather than the shared one and calling
res_ninit(*private_res). Hopefully this will fix the problem.

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 ACKNOWLEDGEMENTS

The following functions are used in whole or in part as include files to
ToolKit.xs. The copyrights are include in the respective files.

  file:           functions:

  dn_expand.inc   dn_expand

dn_expand is from Michael Fuhr's Net::DNS package (DNS.pm), copyright (c)
1997-2002. Thank you Michael.

=head1 COPYRIGHT

    Copyright 2003 - 2014, Michael Robinton <michael@bizsystems.com>
   
Michael Robinton <michael@bizsystems.com>

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
distribution, in the file named "Artistic".  If not, I'll be glad to provide
one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the 

        Free Software Foundation, Inc.
        59 Temple Place, Suite 330
        Boston, MA  02111-1307, USA

or visit their web page on the internet at:

        http://www.gnu.org/copyleft/gpl.html.

=head1 See also:

Net::DNS::Codes(3), Net::DNS::ToolKit::RR(3), Net::DNS::ToolKit::Debug(3),
Net::DNS::ToolKit::Utilities, NetAdder::IP::Util

=cut

1;

package Net::IPv6Addr;

use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw();
our $VERSION = '0.7';

use Carp;
use Net::IPv4Addr;
use Math::BigInt;
use Math::Base85;



# We get these formats from rfc1884:
#
#	preferred form: x:x:x:x:x:x:x:x
# 
#	zero-compressed form: the infamous double-colon.  
#	Too many pattern matches to describe in this margin.
#
#	mixed IPv4/IPv6 format: x:x:x:x:x:x:d.d.d.d
#
#	mixed IPv4/IPv6 with compression: ::d.d.d.d or ::FFFF:d.d.d.d
#
# And we get these from rfc1924:
#
#	base-85-encoded: [0-9A-Za-z!#$%&()*+-;<=>?@^_`{|}~]{20}
#

my %ipv6_patterns = (
    'preferred' => [
	qr/^(?:[a-f0-9]{1,4}:){7}[a-f0-9]{1,4}$/i,
	\&ipv6_parse_preferred,
    ],
    'compressed' => [		## No, this isn't pretty.
	qr/^[a-f0-9]{0,4}::$/i,
	qr/^:(?::[a-f0-9]{1,4}){1,6}$/i,
	qr/^(?:[a-f0-9]{1,4}:){1,6}:$/i,
	qr/^(?:[a-f0-9]{1,4}:)(?::[a-f0-9]{1,4}){1,6}$/i,
	qr/^(?:[a-f0-9]{1,4}:){2}(?::[a-f0-9]{1,4}){1,5}$/i,
	qr/^(?:[a-f0-9]{1,4}:){3}(?::[a-f0-9]{1,4}){1,4}$/i,
	qr/^(?:[a-f0-9]{1,4}:){4}(?::[a-f0-9]{1,4}){1,3}$/i,
	qr/^(?:[a-f0-9]{1,4}:){5}(?::[a-f0-9]{1,4}){1,2}$/i,
	qr/^(?:[a-f0-9]{1,4}:){6}(?::[a-f0-9]{1,4})$/i,
	\&ipv6_parse_compressed,
    ],
    'ipv4' => [
	qr/^(?:0:){5}ffff:(?:\d{1,3}\.){3}\d{1,3}$/i,
	qr/^(?:0:){6}(?:\d{1,3}\.){3}\d{1,3}$/,
	\&ipv6_parse_ipv4,
    ],
    'ipv4 compressed' => [
	qr/^::(?:ffff:)?(?:\d{1,3}\.){3}\d{1,3}$/i,
	\&ipv6_parse_ipv4_compressed,
    ],
); 

# base-85
if (defined $Math::Base85::base85_digits) {
    my $digits;
    ($digits = $Math::Base85::base85_digits) =~ s/-//;
    my $x = "[" . $digits . "-]";
    my $n = "{20}";
    $ipv6_patterns{'base85'} = [
	qr/$x$n/,
	\&ipv6_parse_base85,
    ];
}

sub mycroak
{
    my ($message) = @_;
    my @caller = caller (1);
    croak __PACKAGE__ . '::' . $caller[3] . ' -- ' . $message;
}



sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $maybe_ip = shift;
    my $parser = ipv6_chkip($maybe_ip);
    if (ref $parser ne 'CODE') {
	mycroak "invalid IPv6 address $maybe_ip";
    }
    my @hexadecets = $parser->($maybe_ip);
    my $self = \@hexadecets;
    bless $self, $class;
    return $self;
}



sub ipv6_parse
{
    my ($ip, $pfx);
    if (@_ == 2) {
	($ip, $pfx) = @_;
    } else {
	($ip, $pfx) = split(m!/!, $_[0])
    }

    unless (ipv6_chkip($ip)) {
	mycroak "invalid IPv6 address $ip\n";
    }

    $pfx =~ s/\s+//g if defined($pfx);

    if (defined $pfx) {
	if ($pfx =~ /^\d+$/) {
	    if (($pfx < 0)  || ($pfx > 128)) {
		mycroak "invalid prefix length $pfx\n";
	    }
	} else {
	    mycroak "non-numeric prefix length $pfx\n";
	}
    } else {
	return $ip;
    }
    wantarray ? ($ip, $pfx) : "$ip/$pfx";
}



sub is_ipv6
{
    my ($ip, $pfx);
    if (@_ == 2) {
	($ip, $pfx) = @_;
    } else {
	($ip, $pfx) = split(m!/!, $_[0])
    }

    unless (ipv6_chkip($ip)) {
	return undef;
    }

    if (defined $pfx) {
        $pfx =~ s/s+//g;
	if ($pfx =~ /^\d+$/) {
	    if (($pfx < 0)  || ($pfx > 128)) {
               return undef;
	    }
	} else {
            return undef;
	}
    } else {
	return $ip;
    }
    wantarray ? ($ip, $pfx) : "$ip/$pfx";
}



sub ipv6_chkip
{
    my $ip = shift; 
    my ($pattern, $parser);
    my @patlist;

    $parser = undef;

TYPE:
    for my $k (keys %ipv6_patterns) {
	@patlist = @{$ipv6_patterns{$k}};
PATTERN:
	for my $pattern (@patlist) {
	    last PATTERN if (ref($pattern) eq 'CODE');
	    if ($ip =~ $pattern) {
		$parser = $patlist[-1];
		last TYPE;
	    }
	}
    }
    return $parser;
}

sub ipv6_parse_preferred
{
    my $ip = shift;
    my @patterns = @{$ipv6_patterns{'preferred'}};
    for my $p (@patterns) {
	if (ref($p) eq 'CODE') {
	    mycroak "invalid address";
	}
	last if ($ip =~ $p);
    }
    my @pieces = split(/:/, $ip);
    splice(@pieces, 8);
    return map { hex } @pieces;
}

sub ipv6_parse_compressed
{
    my $ip = shift;
    my @patterns = @{$ipv6_patterns{'compressed'}};
    for my $p (@patterns) {
	if (ref($p) eq 'CODE') {
	    mycroak "invalid address";
	}
	last if ($ip =~ $p);
    }
    my $colons;
    $colons = ($ip =~ tr/:/:/);
    my $expanded = ':' x (9 - $colons);
    $ip =~ s/::/$expanded/;
    my @pieces = split(/:/, $ip, 8);
    return map { hex } @pieces;
}

sub ipv6_parse_ipv4
{
    my $ip = shift;
    my @patterns = @{$ipv6_patterns{'ipv4'}};
    for my $p (@patterns) {
	if (ref($p) eq 'CODE') {
	    mycroak "invalid address";
	}
	last if ($ip =~ $p);
    }
    my @result;
    my $v4addr;
    my @v6pcs = split(/:/, $ip);
    $v4addr = $v6pcs[-1];
    splice(@v6pcs, 6);
    push @result, map { hex } @v6pcs;
    Net::IPv4Addr::ipv4_parse($v4addr);
    my @v4pcs = split(/\./, $v4addr);
    push @result, unpack("n", pack("CC", @v4pcs[0,1]));
    push @result, unpack("n", pack("CC", @v4pcs[2,3]));
    return @result;
}

sub ipv6_parse_ipv4_compressed
{
    my $ip = shift;
    my @patterns = @{$ipv6_patterns{'ipv4 compressed'}};
    for my $p (@patterns) {
	if (ref($p) eq 'CODE') {
	    mycroak "invalid address";
	}
	last if ($ip =~ $p);
    }
    my @result;
    my $v4addr;
    my $colons;
    $colons = ($ip =~ tr/:/:/);
    my $expanded = ':' x (8 - $colons);
    $ip =~ s/::/$expanded/;
    my @v6pcs = split(/:/, $ip, 7);
    $v4addr = $v6pcs[-1];
    splice(@v6pcs, 6);
    push @result, map { hex } @v6pcs;
    Net::IPv4Addr::ipv4_parse($v4addr);
    my @v4pcs = split(/\./, $v4addr);
    splice(@v4pcs, 4);
    push @result, unpack("n", pack("CC", @v4pcs[0,1]));
    push @result, unpack("n", pack("CC", @v4pcs[2,3]));
    return @result;
}

sub ipv6_parse_base85
{
    my $ip = shift;
    my $r;
    my @patterns = @{$ipv6_patterns{'base85'}};
    for my $p (@patterns) {
	if (ref($p) eq 'CODE') {
	    mycroak "invalid address";
	}
	last if ($ip =~ $p);
    }
    my $bigint = Math::Base85::from_base85($ip);
    my @result;
    while ($bigint > 0) {
	$r = $bigint & 0xffff;
	unshift @result, sprintf("%d", $r);
	$bigint = $bigint >> 16;
    }
    foreach $r ($#result+1..7) {
        $result[$r] = 0;
    }
    return @result;
}



sub to_string_preferred
{
    my $self = shift;
    if (ref $self eq __PACKAGE__) {
	return join(":", map { sprintf("%x", $_) } @$self);
    } 
    return Net::IPv6Addr->new($self)->to_string_preferred();
}



sub to_string_compressed
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_string_compressed();
    }
    my $expanded = join(":", map { sprintf("%x", $_) } @$self);
    $expanded =~ s/^0:/:/;
    $expanded =~ s/:0/:/g;
    if ($expanded =~ s/:::::::/_/ or
	$expanded =~ s/::::::/_/ or
	$expanded =~ s/:::::/_/ or
	$expanded =~ s/::::/_/ or
	$expanded =~ s/:::/_/ or
	$expanded =~ s/::/_/
        ) {
        $expanded =~ s/:(?=:)/:0/g;
	$expanded =~ s/^:(?=[0-9a-f])/0:/;
	$expanded =~ s/([0-9a-f]):$/$1:0/;
	$expanded =~ s/_/::/;
    }
    return $expanded;
}



sub to_string_ipv4
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_string_ipv4();
    }
    if ($self->[0] | $self->[1] | $self->[2] | $self->[3] | $self->[4]) {
	mycroak "not originally an IPv4 address";
    }
    if (($self->[5] != 0xffff) && $self->[5]) {
	mycroak "not originally an IPv4 address";
    }
    my $v6part = join(':', map { sprintf("%x", $_) } @$self[0..5]);
    my $v4part = join('.', $self->[6] >> 8, $self->[6] & 0xff, $self->[7] >> 8,  $self->[7] & 0xff);
    return "$v6part:$v4part";
}



sub to_string_ipv4_compressed
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_string_ipv4_compressed();
    }
    if ($self->[0] | $self->[1] | $self->[2] | $self->[3] | $self->[4]) {
	mycroak "not originally an IPv4 address";
    }
    if (($self->[5] != 0xffff) && $self->[5]) {
	mycroak "not originally an IPv4 address";
    }
    my $v6part;
    if ($self->[5]) {
	$v6part = sprintf("::%x", $self->[5]);
    } else {
	$v6part = ":";
    }
    my $v4part = join('.', $self->[6] >> 8, $self->[6] & 0xff, $self->[7] >> 8,  $self->[7] & 0xff);
    return "$v6part:$v4part";
}




sub to_string_base85
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_string_base85();
    }
    my $bigint = new Math::BigInt("0");
    for my $i (@{$self}[0..6]) {
	$bigint = $bigint + $i;
	$bigint = $bigint << 16;
    }
    $bigint = $bigint + $self->[7];
    return Math::Base85::to_base85($bigint);
}



sub to_bigint
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_bigint();
    }
    my $bigint = new Math::BigInt("0");
    for my $i (@{$self}[0..6]) {
	$bigint = $bigint + $i;
	$bigint = $bigint << 16;
    }
    $bigint = $bigint + $self->[7];
    $bigint =~ s/\+//;
    return  $bigint;
}



sub to_array
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_array();
    }
    return map {sprintf "%04x", $_} @$self;
}


sub to_intarray
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_intarray();
    }
    return @$self;
}



sub to_string_ip6_int
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	return Net::IPv6Addr->new($self)->to_string_ip6_int();
    }
    my $hexdigits = sprintf("%04x" x 8, @$self);
    my @nibbles = ('INT', 'IP6', split(//, $hexdigits));
    my $ptr = join('.', reverse @nibbles);
    return $ptr . ".";
}




sub in_network_of_size
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
      if ($self =~ m!(.+)/(.+)!) {
	unshift @_, $2;
	return Net::IPv6Addr->new($1)->in_network_of_size(@_)->to_string_preferred;
      }
      return Net::IPv6Addr->new($self)->in_network_of_size(@_)->to_string_preferred;
    }
    my $netsize = shift;
    if (!defined $netsize) {
      mycroak "not network size given";
    }
    $netsize =~ s!/!!;
    if ($netsize !~ /^\d+$/ or $netsize < 0 or $netsize > 128) {
      mycroak "not valid network size $netsize";
    }
    my @parts = @$self;
    my $i = $netsize / 16;
    unless ($i == 8) { # netsize was 128 bits; the whole address
      my $j = $netsize % 16;
      $parts[$i] &= unpack("C4",pack("B16", '1' x $j . '0000000000000000'));
      foreach $j (++$i..$#parts) {
	$parts[$j] = 0;
      }
    }
    # https://rt.cpan.org/Ticket/Display.html?id=79325
    return Net::IPv6Addr->new(sprintf("%04x" x 8, @parts));
    #    return Net::IPv6Addr->new(join(':', @parts));
}



sub in_network
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
      return Net::IPv6Addr->new($self)->in_network(@_);
    }
    my ($net,$netsize) = (@_);
    if ($net =~ m!/!) {
      $net =~ s!(.*)/(.*)!$1!;
      $netsize = $2;
    }
    unless (defined $netsize) {
      mycroak "not enough parameters";
    }
    $netsize =~ s!/!!;
    if ($netsize !~ /^\d+$/ or $netsize < 0 or $netsize > 128) {
      mycroak "not valid network size $netsize";
    }
    my @s = $self->in_network_of_size($netsize)->to_intarray;
    $net = Net::IPv6Addr->new($net) unless (ref $net);
    my @n = $net->in_network_of_size($netsize)->to_intarray;
    my $i = int($netsize / 16);
    $i++;
    $i = $#s if ($i > $#s);
    for (0..$i) {
      return 0 unless ($s[$_] == $n[$_]);
    }
    return 1;
}


1;
__END__



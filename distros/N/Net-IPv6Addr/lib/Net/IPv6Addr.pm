package Net::IPv6Addr;

use strict;
use warnings;

our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw(
		       in_network
		       in_network_of_size
		       ipv6_chkip
		       ipv6_parse
		       is_ipv6
		       to_string_preferred
		       to_string_compressed
		       to_bigint
		       to_intarray
		       to_array
		       to_string_ip6_int
		       to_string_base85
		       to_string_ipv4
		       to_string_ipv4_compressed
		       from_bigint
	       );
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $VERSION = '0.96';

use Carp;
use Net::IPv4Addr;
use Math::BigInt '1.999813';
use Math::Base85;

#  ____       _   _                      
# |  _ \ __ _| |_| |_ ___ _ __ _ __  ___ 
# | |_) / _` | __| __/ _ \ '__| '_ \/ __|
# |  __/ (_| | |_| ||  __/ |  | | | \__ \
# |_|   \__,_|\__|\__\___|_|  |_| |_|___/
#                                       

# Match one to four digits of hexadecimal

my $h = qr/[a-f0-9]{1,4}/i;

# Match one to three digits

#my $d = qr/[0-9]{1,3}/;
my $ipv4 = "((25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))";

# base-85

my $digits = $Math::Base85::base85_digits;
$digits =~ s/-//;
my $x = "[" . $digits . "-]";
my $n = "{20}";

my %ipv6_patterns = (
    'preferred' => [
	qr/^(?:$h:){7}$h$/i,
	\&ipv6_parse_preferred,
    ],
    'compressed' => [
	qr/^[a-f0-9]{0,4}::$/i,
	qr/^:(?::$h){1,7}$/i,
	qr/^(?:$h:){1,}:$/i,
	qr/^(?:$h:)(?::$h){1,6}$/i,
	qr/^(?:$h:){2}(?::$h){1,5}$/i,
	qr/^(?:$h:){3}(?::$h){1,4}$/i,
	qr/^(?:$h:){4}(?::$h){1,3}$/i,
	qr/^(?:$h:){5}(?::$h){1,2}$/i,
	qr/^(?:$h:){6}(?::$h)$/i,
	\&ipv6_parse_compressed,
    ],
    'ipv4' => [
	qr/^(?:0:){5}ffff:$ipv4$/i,
	qr/^(?:0:){6}$ipv4$/,
	\&ipv6_parse_ipv4,
    ],
    'ipv4 compressed' => [
	qr/^::(?:ffff:)?$ipv4$/i,
	\&ipv6_parse_ipv4_compressed,
    ],
    'ipv6v4' => [
	qr/^[a-f0-9]{0,4}::$ipv4$/i,
	# ::1:2:3:4:1.2.3.4
	qr/^::(?:$h:){1,5}$ipv4$/i,
	qr/^(?:$h:):(?:$h:){1,4}$ipv4$/i,
	qr/^(?:$h:){2}:(?:$h:){1,3}$ipv4$/i,
	qr/^(?:$h:){3}:(?:$h:){1,2}$ipv4$/i,
	qr/^(?:$h:){4}:(?:$h:){1}$ipv4$/i,
	# 1:2:3:4:5::1.2.3.4
	qr/^(?:$h:){1,5}:$ipv4$/i,
	# 1:2:3:4:5:6:1.2.3.4
	qr/^(?:$h:){6}$ipv4$/i,
	\&parse_mixed_ipv6v4_compressed,
    ],
    'base85' => [
	qr/$x$n/,
	\&ipv6_parse_base85,
    ],
);

#  ____       _            _       
# |  _ \ _ __(_)_   ____ _| |_ ___ 
# | |_) | '__| \ \ / / _` | __/ _ \
# |  __/| |  | |\ V / (_| | ||  __/
# |_|   |_|  |_| \_/ \__,_|\__\___|
#                                 

# Errors which include the package name and the subroutine name. This
# is for consistency with earlier versions of the module.

sub mycroak
{
    my ($message) = @_;
    my @caller = caller (1);
    croak $caller[3] . ' -- ' . $message;
}

# Given one argument with a slash or two arguments, return them as two
# arguments, and check there are one or two arguments.

sub getargs
{
    my ($ip, $pfx);
    if (@_ == 2) {
	($ip, $pfx) = @_;
    }
    elsif (@_ == 1) {
	($ip, $pfx) = split(m!/!, $_[0])
    }
    else {
	mycroak "wrong number of arguments (need 1 or 2)";
    }
    return ($ip, $pfx);
}

# Match $ip against the regexes of type $type, or die.

sub match_or_die
{
    my ($ip, $type) = @_;
    # Instead of trying to construct a gigantic regex which only
    # allows two colons in a row, just check here.
    if ($ip =~ /:::/) {
	mycroak "invalid address $ip for type $type";
    }
    my $patterns = $ipv6_patterns{$type};
    for my $p (@$patterns) {
	# The last thing in the pattern is a code reference, so this
	# match indicates no matches were found.
	if (ref($p) eq 'CODE') {
	    mycroak "invalid address $ip for type $type";
	}
	if ($ip =~ $p) {
	    return;
	}
    }
}

# Make the bit mask for "in_network_of_size".

sub bitmask
{
    my ($j) = @_;
    my $bitmask = '1' x $j . '0' x (16 - $j);
    my $k = unpack("n",pack("B16", $bitmask));
    return $k;
}

#  ____                              
# |  _ \ __ _ _ __ ___  ___ _ __ ___ 
# | |_) / _` | '__/ __|/ _ \ '__/ __|
# |  __/ (_| | |  \__ \  __/ |  \__ \
# |_|   \__,_|_|  |___/\___|_|  |___/
#                                   

# Private parser

sub ipv6_parse_preferred
{
    my $ip = shift;
    match_or_die ($ip, 'preferred');
    my @pieces = split(/:/, $ip);
    splice(@pieces, 8);
    return map { hex } @pieces;
}

# Private parser

sub ipv6_parse_compressed
{
    my $ip = shift;
    my $type = 'compressed';
    match_or_die ($ip, $type);
    my $colons = ($ip =~ tr/:/:/);
    my $expanded = ':' x (9 - $colons);
    $ip =~ s/::/$expanded/;
    my @pieces = split(/:/, $ip, 8);
    return map { hex } @pieces;
}

sub parse_mixed_ipv6v4_compressed
{
    my $ip = shift;
    match_or_die ($ip, 'ipv6v4');
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

# Private parser

sub ipv6_parse_ipv4
{
    my $ip = shift;
    match_or_die ($ip, 'ipv4');
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

# Private parser

sub ipv6_parse_ipv4_compressed
{
    my $ip = shift;
    match_or_die ($ip, 'ipv4 compressed');
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

# Private parser

sub ipv6_parse_base85
{
    my $ip = shift;
    match_or_die ($ip, 'base85');
    my $r;
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

#  ____        _     _ _      
# |  _ \ _   _| |__ | (_) ___ 
# | |_) | | | | '_ \| | |/ __|
# |  __/| |_| | |_) | | | (__ 
# |_|    \__,_|_.__/|_|_|\___|
#                            

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


sub ipv6_chkip
{
    my $ip = shift; 

    my $parser = undef;

    TYPE:
    for my $k (keys %ipv6_patterns) {
	my @patlist = @{$ipv6_patterns{$k}};
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


sub ipv6_parse
{
    my ($ip, $pfx) = getargs (@_);

    if (! ipv6_chkip($ip)) {
	mycroak "invalid IPv6 address $ip";
    }

    if (! defined $pfx) {
	return $ip;
    }

    $pfx =~ s/\s+//g;

    if ($pfx =~ /^[0-9]+$/) {
	if ($pfx > 128) {
	    mycroak "invalid prefix length $pfx";
	}
    }
    else {
	mycroak "non-numeric prefix length $pfx";
    }

    if (wantarray ()) {
	return ($ip, $pfx);
    }
    return "$ip/$pfx";
}


sub is_ipv6
{
    my $r;
    eval {
	$r = ipv6_parse (@_);
    };
    if ($@) {
	return undef;
    }
    return $r;
}


sub to_string_preferred
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	$self = Net::IPv6Addr->new ($self);
    }
    return v6part (@$self);
}


sub to_string_compressed
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	$self = Net::IPv6Addr->new ($self);
    }
    my $expanded = v6part (@$self);
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

sub bytes
{
    my ($in) = @_;
    my $low = $in & 0xff;
    my $high = $in >> 8;
    return ($high, $low);
}

sub v4part
{
    my ($t, $b) = @_;
    return join('.', bytes ($t), bytes ($b));
}

sub v6part
{
    return join(':', map { sprintf("%x", $_) } @_);
}

sub to_string_ipv4
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	$self = Net::IPv6Addr->new ($self);
    }
    my $v6part = v6part (@$self[0..5]);
    my $v4part = v4part (@$self[6, 7]);
    return "$v6part:$v4part";
}


sub to_string_ipv4_compressed
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	$self = Net::IPv6Addr->new ($self);
    }
    my $v6part = v6part (@$self[0..5]);
    $v6part .= ':';
    $v6part =~ s/(^|:)(0:)+/::/;
    my $v4part = v4part (@$self[6, 7]);
    return "$v6part$v4part";
}


sub to_string_base85
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	$self = Net::IPv6Addr->new ($self);
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
	$self = Net::IPv6Addr->new ($self);
    }
    my $bigint = new Math::BigInt("0");
    for my $i (@{$self}[0..6]) {
	$bigint = $bigint + $i;
	$bigint = $bigint << 16;
    }
    $bigint = $bigint + $self->[7];
    $bigint =~ s/\+//;
    return $bigint;
}


sub to_array
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	$self = Net::IPv6Addr->new ($self);
    }
    return map {sprintf "%04x", $_} @$self;
}


sub to_intarray
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	$self = Net::IPv6Addr->new ($self);
    }
    return @$self;
}


sub to_string_ip6_int
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	$self = Net::IPv6Addr->new ($self);
    }
    my $hexdigits = sprintf("%04x" x 8, @$self);
    my @nibbles = ('INT', 'IP6', split(//, $hexdigits));
    my $ptr = join('.', reverse @nibbles);
    return $ptr . ".";
}

# Private - validate a given netsize

sub validate_netsize
{
    my ($netsize) = @_;
    if ($netsize !~ /^[0-9]+$/ || $netsize > 128) {
	mycroak "invalid network size $netsize";
    }
}


sub in_network_of_size
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	if ($self =~ m!(.+)/(.+)!) {
	    unshift @_, $2;
	    $self = $1;
	}
	$self = Net::IPv6Addr->new($self);
    }
    my $netsize = shift;
    if (! defined $netsize) {
	mycroak "network size not given";
    }
    $netsize =~ s!/!!;
    validate_netsize ($netsize);
    my @parts = @$self;
    my $i = int ($netsize / 16);
    if ($i < 8) {
	my $j = $netsize % 16;
	if ($j) {
	    # If $netsize is not a multiple of 16, truncate the lowest
	    # 16-$j bits of the $ith element of @parts.
	    $parts[$i] &= bitmask ($j);
	    # Jump over this element.
	    $i++;
	}
	# Set all the remaining lower parts to zero.
	for ($i..$#parts) {
	    $parts[$_] = 0;
	}
    }
    return bless \@parts;
}


sub in_network
{
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
	$self = Net::IPv6Addr->new ($self);
    }
    my ($net, $netsize) = getargs (@_);
    unless (defined $netsize) {
	mycroak "not enough parameters, need netsize";
    }
    $netsize =~ s!/!!;
    validate_netsize ($netsize);
    if (! ref $net) {
	$net = Net::IPv6Addr->new($net);
    }
    my @s = $self->in_network_of_size($netsize)->to_intarray;
    my @n = $net->in_network_of_size($netsize)->to_intarray;
    my $i = int ($netsize / 16) + 1;
    if ($i > $#s) {
	$i = $#s;
    }
    for (0..$i) {
	if ($s[$_] != $n[$_]) {
	    return undef;
	}
    }
    return 1;
}

sub from_bigint
{
    my ($big) = @_;
    # Input is a scalar or a Math::BigInt object.
    if (! ref ($big)) {
	$big = Math::BigInt->new ($big);
    }
    if (ref ($big) ne 'Math::BigInt') {
	mycroak "Cannot process non-scalar, non-Math::BigInt input";
    }
    # Convert the number to a hexadecimal string
    my $hex = $big->to_hex ();
    # Pad if necessary for the colon placement
    if (length ($hex) < 32) {
	my $leading = '0' x (32 - length ($hex));
	$hex = $leading . $hex;
    }
    # Reversing the string makes adding colons with a substitution
    # operator easier.
    my $ipr = reverse $hex;
    $ipr =~ s/(....)/$1:/g;
    $ipr = reverse $ipr;
    # Remove the excess colon.
    $ipr =~ s/^://;
    # Should be OK now, let "new" handle any further issues.
    return Net::IPv6Addr->new ($ipr);
}

1;

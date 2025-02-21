package Net::DNS::RR::OPT;

use strict;
use warnings;
our $VERSION = (qw$Id: OPT.pm 2005 2025-01-28 13:22:10Z willem $)[2];

use base qw(Net::DNS::RR);


=head1 NAME

Net::DNS::RR::OPT - DNS OPT resource record

=cut

use integer;

use Carp;
use Net::DNS::Parameters qw(:rcode :ednsoption);

use constant UTIL => scalar eval { require Scalar::Util; Scalar::Util->can('isdual') };

use constant OPT => Net::DNS::Parameters::typebyname qw(OPT);

require Net::DNS::DomainName;
require Net::DNS::RR::A;
require Net::DNS::RR::AAAA;
require Net::DNS::Text;


sub _decode_rdata {			## decode rdata from wire-format octet string
	my ( $self, $data, $offset ) = @_;

	my $class = delete $self->{class};			# OPT redefines CLASS and TTL fields
	$self->udpsize($class) if defined $class;

	my $ttl = delete $self->{ttl};
	$self->_ttl($ttl) if defined $ttl;

	my $limit = $offset + $self->{rdlength} - 4;
	while ( $offset <= $limit ) {
		my ( $code, $length ) = unpack "\@$offset nn", $$data;
		my $value = unpack "\@$offset x4 a$length", $$data;
		my @value = map { ref($_) ? @$_ : defined($_) ? $_ : () } $self->{option}{$code}, $value;
		$self->{option}{$code} = ( scalar(@value) == 1 ) ? $value : \@value;
		$offset += $length + 4;
	}
	return;
}


sub _encode_rdata {			## encode rdata as wire-format octet string
	my $self = shift;

	my $option = $self->{option} || {};
	my @option = $self->options;
	foreach my $item (@option) {
		my @value = map { ref($_) ? @$_ : $_ } $option->{$item};
		$item = join '', map { pack( 'nna*', $item, length($_), $_ ) } @value;
	}
	return join '', @option;
}


sub encode {				## override RR method
	my $self = shift;
	my $data = $self->_encode_rdata;
	return pack 'C n n N na*', 0, OPT, $self->udpsize, $self->_ttl, length($data), $data;
}


sub string {				## override RR method
	my @line = split /[\r\n]+/, shift->json;
	return join '', map {";;$_\n"} @line;
}

sub class {				## override RR method
	my ( $self, @value ) = @_;
	$self->_deprecate(qq[please use "UDPsize()"]);
	return $self->udpsize(@value);
}

sub ttl {				## override RR method
	my ( $self, @value ) = @_;
	$self->_deprecate(qq[please use "flags()", "rcode()" or "version()"]);
	return $self->_ttl(@value);
}

sub _ttl {
	my ( $self, @value ) = @_;
	for (@value) {
		@{$self}{qw(rcode version flags)} = unpack 'C2n', pack( 'N', $_ );
		$self->{rcode} = $self->{rcode} << 4;
		return;
	}
	return unpack 'N', pack( 'C2n', $self->rcode >> 4, $self->version, $self->flags );
}

sub generic {				## override RR method
	my $self = shift;
	local $self->{class} = $self->udpsize;
	my @xttl = ( $self->rcode >> 4, $self->version, $self->flags );
	local $self->{ttl} = unpack 'N', pack( 'C2n', @xttl );
	return $self->SUPER::generic;
}

sub token {				## override RR method
	return grep { !m/^[()]$/ } split /\s+/, &generic;
}

sub json {
	my $self = shift;					# uncoverable pod

	my $version = $self->version;
	unless ( $version == 0 ) {
		my $content = unpack 'H*', $self->encode;
		return <<"QQ";
 {	"EDNS-VERSION":	$version,
	"BASE16":	"$content"
	}
QQ
	}

	my $flags  = $self->flags;
	my $rcode  = $self->rcode;
	my $size   = $self->udpsize;
	my @format = map { join( "\n\t\t\t", $self->_format_option($_) ) } $self->options;
	my @indent = scalar(@format) ? "\n\t\t" : ();
	my @option = join ",\n\t\t", @format;

	return <<"QQ";
 {	"EDNS-VERSION":	$version,
	"FLAGS":	$flags,
	"RCODE":	$rcode,
	"UDPSIZE":	$size,
	"OPTIONS":	[@indent@option ]
	}
QQ
}


sub version {
	my ( $self, @value ) = @_;
	for (@value) { $self->{version} = 0 + $_ }
	return $self->{version} || 0;
}


sub udpsize {
	my ( $self, @value ) = @_;				# uncoverable pod
	for (@value) { $self->{udpsize} = ( $_ > 512 ) ? $_ : 0 }
	return $self->{udpsize} || 0;
}

sub size {
	my ( $self, @value ) = @_;				# uncoverable pod
	$self->_deprecate(qq[size() is an alias of "UDPsize()"]);
	return $self->udpsize(@value);
}


sub rcode {
	my ( $self, @value ) = @_;
	for (@value) { $self->{rcode} = ( $_ < 16 ) ? 0 : $_ }	# discard non-EDNS rcodes 1 .. 15
	return $self->{rcode} || 0;
}


sub flags {
	my ( $self, @value ) = @_;
	for (@value) { $self->{flags} = 0 + $_ }
	return $self->{flags} || 0;
}


sub options {
	my $self   = shift;
	my $option = $self->{option} || {};
	@{$self->{index}} = sort { $a <=> $b } keys %$option unless defined $self->{index};
	return @{$self->{index}};
}

sub option {
	my ( $self, $name, @value ) = @_;
	my $number = ednsoptionbyname($name);
	return $self->_get_option($number) unless scalar @value;
	my $value = $self->_set_option( $number, @value );
	return $@ ? croak( ( split /\sat/i, $@ )[0] ) : $value;
}


########################################

sub _get_option {
	my ( $self, $number ) = @_;

	my $options = $self->{option} || {};
	my @payload = map { ref($_) ? @$_ : $_ } $options->{$number};
	return shift @payload unless wantarray;
	my $optname = ednsoptionbyval($number);
	my $package = join '::', __PACKAGE__, $optname;
	$package =~ s/-/_/g;
	my $structured = $package->can('_decompose');
	foreach my $value (@payload) {
		my @value;
		if ( length $value ) {
			@value = eval { $package->_decompose($value) } if $structured;
			@value = {BASE16 => unpack 'H*', $value} unless scalar @value;
			warn $@ if $@;
		} else {
			@value = $structured ? {'OPTION-LENGTH' => 0} : '';
		}
		$value = {$optname => @value};
	}
	return @payload;
}


sub _set_option {
	my ( $self, $number, @value ) = @_;
	my ($arg) = @value;

	my $options = $self->{option} || {};
	delete $options->{$number};
	delete $self->{index};
	delete $self->{option} unless scalar( keys %$options );

	return unless defined $arg;
	$self->{option} = $options;

	if ( ref($arg) eq 'HASH' ) {
		for ( keys %$arg ) { $$arg{uc $_} = $$arg{$_} } # tolerate mixed case
		my $length = $$arg{'OPTION-LENGTH'};
		my $octets = $$arg{'OPTION-DATA'};
		$octets = pack 'H*', $$arg{'BASE16'} if defined $$arg{'BASE16'};
		$octets = '' if defined($length) && $length == 0;
		return $options->{$number} = $octets if defined $octets;
	}

	my $option  = ednsoptionbyval($number);
	my $package = join '::', __PACKAGE__, $option;
	$package =~ s/-/_/g;
	return eval { $options->{$number} = $package->_compose(@value) } if length($arg) && $package->can('_compose');

	croak "unable to compose option $number" if ref($arg);
	return $options->{$number} = $arg;
}


sub _specified {
	my $self = shift;
	return scalar grep { $self->{$_} } qw(udpsize flags rcode option);
}


sub _format_option {
	my ( $self, $number ) = @_;
	my @option = $self->_get_option($number);
	return map { Net::DNS::RR::_wrap( _JSONify($_) ) } @option;
}


sub _JSONify {
	my $value = shift;
	return 'null' unless defined $value;

	if ( ref($value) eq 'HASH' ) {
		my @tags = sort keys %$value;
		my $tail = pop @tags;
		for ( $$value{BASE16} ) { $_ = pack( 'U0a*', $_ ) if defined }	  # mark as UTF-8
		my @body = map { my @x = ( qq("$_":), _JSONify( $$value{$_} ) ); $x[-1] .= ','; @x } @tags;
		push @body, ( qq("$tail":), _JSONify( $$value{$tail} ) );
		$body[0] = '{' . $body[0];
		$body[-1] .= '}';
		return @body;
	}

	if ( ref($value) eq 'ARRAY' ) {
		my @array = @$value;
		my @tail  = map { _JSONify($_) } grep {defined} pop @array;
		my @body  = map { my @x = _JSONify($_); $x[-1] .= ','; @x } @array;
		return ( '[', @body, @tail, ']' );
	}

	my $string = "$value";		## stringify, then use isdual() as discriminant
	return $string if UTIL && Scalar::Util::isdual($value); # native numeric representation
	for ($string) {
		unless ( utf8::is_utf8($value) ) {
			return $_ if /^-?\d+$/;			# integer (string representation)
			return $_ if /^-?\d+\.\d+$/;		# non-integer
			return $_ if /^-?\d+(\.\d+)?e[+-]\d\d?$/i;
		}
		s/\\/\\\\/g;					# escaped escape
		s/^"(.*)"$/$1/;					# strip enclosing quotes
		s/"/\\"/g;					# escape interior quotes
	}
	return qq("$string");
}


## no critic ProhibitMultiplePackages
package Net::DNS::RR::OPT::NSID;				# RFC5001

sub _compose {
	my ( undef, @argument ) = map { ref($_) ? %$_ : $_ } @_;
	return pack 'H*', pop @argument;
}

sub _decompose { return pack 'U0a*', unpack 'H*', pop @_ }	# mark as UTF-8


package Net::DNS::RR::OPT::DAU;					# RFC6975

sub _compose {
	my ( undef, @argument ) = map { ref($_) ? @$_ : $_ } @_;
	return pack 'C*', @argument;
}

sub _decompose { return [unpack 'C*', pop @_] }


package Net::DNS::RR::OPT::DHU;					# RFC6975
our @ISA = qw(Net::DNS::RR::OPT::DAU);

package Net::DNS::RR::OPT::N3U;					# RFC6975
our @ISA = qw(Net::DNS::RR::OPT::DAU);


package Net::DNS::RR::OPT::CLIENT_SUBNET;			# RFC7871

my %family = qw(1 Net::DNS::RR::A	2 Net::DNS::RR::AAAA);
my @field8 = qw(FAMILY SOURCE-PREFIX SCOPE-PREFIX ADDRESS);

sub _compose {
	shift @_;
	my %argument = ( map( ( $_ => 0 ), @field8 ), map { ref($_) ? %$_ : $_ } @_ );
	my $family   = $family{$argument{FAMILY}} || die 'unrecognised address family';
	my $bitmask  = $argument{'SOURCE-PREFIX'};
	my $address  = bless( {}, $family )->address( $argument{ADDRESS} );
	return pack 'a* B*', pack( 'nC2', @argument{@field8} ), unpack "B$bitmask", $address;
}

sub _decompose {
	my %object;
	@object{@field8} = unpack 'nC2a*', pop @_;
	my $family = $family{$object{FAMILY}} || die 'unrecognised address family';
	for ( $object{ADDRESS} ) {
		$_ = bless( {address => $_}, $family )->address;
		s/:[:0]+$/::/;
	}
	return \%object;
}


package Net::DNS::RR::OPT::EXPIRE;				# RFC7314

sub _compose {
	my ( undef, @argument ) = map { ref($_) ? %$_ : $_ } @_;
	return pack 'N', pop @argument;
}

sub _decompose {
	my $argument = pop @_;
	return {'EXPIRE-TIMER' => unpack 'N', $argument};
}


package Net::DNS::RR::OPT::COOKIE;				# RFC7873

my @field10 = qw(CLIENT SERVER);

sub _compose {
	my ( undef, @argument ) = @_;
	for ( ref( $argument[0] ) ) {
		/HASH/	&& ( @argument = @{$argument[0]}{@field10} );
		/ARRAY/ && ( @argument = @{$argument[0]} );
	}
	return pack 'a8a*', map { pack 'H*', $_ || '' } @argument;
}

sub _decompose {
	my %object;
	@object{@field10} = map { pack 'U0a*', $_ } unpack 'H16H*', pop @_;    # mark as UTF-8
	return \%object;
}


package Net::DNS::RR::OPT::TCP_KEEPALIVE;			# RFC7828

sub _compose {
	my ( undef, @argument ) = map { ref($_) ? %$_ : $_ } @_;
	return pack 'n', pop @argument;
}

sub _decompose {
	my $argument = pop @_;
	return {'TIMEOUT' => unpack 'n', $argument};
}


package Net::DNS::RR::OPT::PADDING;				# RFC7830

sub _compose {
	my ( undef, @argument ) = map { ref($_) ? %$_ : $_ } @_;
	my $length = pop(@argument) || 0;
	return pack "x$length";
}

sub _decompose {
	my $argument = pop @_;
	return {'OPTION-LENGTH' => length $argument} if $argument =~ /^\000*$/;
	return {'BASE16'	=> unpack 'H*', $argument};
}


package Net::DNS::RR::OPT::CHAIN;				# RFC7901

sub _compose {
	my ( undef, @argument ) = map { ref($_) ? %$_ : $_ } @_;
	return Net::DNS::DomainName->new( pop @argument )->encode;
}

sub _decompose {
	my $argument = pop @_;
	return {'CLOSEST-TRUST-POINT' => Net::DNS::DomainName->decode( \$argument )->string};
}


package Net::DNS::RR::OPT::KEY_TAG;				# RFC8145

sub _compose {
	my ( undef, @argument ) = map { ref($_) ? @$_ : $_ } @_;
	return pack 'n*', @argument;
}

sub _decompose { return [unpack 'n*', pop @_] }


package Net::DNS::RR::OPT::EXTENDED_ERROR;			# RFC8914

sub _compose {
	my ( undef, @arg ) = @_;
	my %arg	 = ref( $arg[0] ) ? %{$arg[0]} : @arg;
	my $text = join '', Net::DNS::RR::OPT::_JSONify( $arg{'EXTRA-TEXT'} || '' );
	return pack 'na*', $arg{'INFO-CODE'}, Net::DNS::Text->new($text)->raw;
}

sub _decompose {
	my ( $code, $text ) = unpack 'na*', pop @_;
	my $error = $Net::DNS::Parameters::dnserrorbyval{$code};
	my @error = defined($error) ? ( 'ERROR' => $error ) : ();
	my $extra = Net::DNS::Text->decode( \$text, 0, length $text );
	for ( $extra->value ) {
		last unless /^[\[\{]/;
		s/([\$\@])/\\$1/g;	## Here be dragons!
		my $REGEX = q/("[^"]*"|[\[\]{}:,]|[-0-9.Ee+]+)|\s+|(.)/;
		my @split = grep { defined && length } split /$REGEX/o;
		my $value = eval join( ' ', 'no integer;', map { s/^:$/=>/; $_ } @split );
		return {'INFO-CODE' => $code, @error, 'EXTRA-TEXT' => $value} if ref($value);
	}
	return {'INFO-CODE' => $code, @error, 'EXTRA-TEXT' => $extra->value};
}


package Net::DNS::RR::OPT::REPORT_CHANNEL;			# RFC9567

sub _compose {
	my ( undef, @argument ) = map { ref($_) ? %$_ : $_ } @_;
	return Net::DNS::DomainName->new( pop @argument )->encode;
}

sub _decompose {
	my $argument = pop @_;
	return {'AGENT-DOMAIN' => Net::DNS::DomainName->decode( \$argument )->string};
}


package Net::DNS::RR::OPT::ZONEVERSION;				# RFC9660

my @field19 = qw(LABELCOUNT TYPE VERSION);

sub _compose {
	my ( undef, @argument ) = @_;
	for ( ref( $argument[0] ) ) {
		/HASH/	&& ( @argument = @{$argument[0]}{@field19} );
		/ARRAY/ && ( @argument = @{$argument[0]} );
	}
	return scalar(@argument) ? pack( 'C2H*', @argument ) : '';
}

sub _decompose {
	my %object;
	my ( $l, $t, $v ) = unpack 'C2H*', pop @_;
	@object{@field19} = ( $l, $t, pack 'U0a*', $v );	# mark hex data as UTF-8
	return \%object;
}

########################################


1;
__END__


=head1 SYNOPSIS

	use Net::DNS;
	my $packet = Net::DNS::Packet->new( ... );

	$packet->header->do(1);		# extended header flag 

	$packet->edns->UDPsize(1232);	# UDP payload size

	$packet->edns->option( 'NSID' => {'OPTION-DATA' => 'rawbytes'} );
	$packet->edns->option( 'DAU'  => [8, 10, 13, 14, 15, 16] );
	$packet->edns->option( 'TCP-KEEPALIVE' => 200 );
	$packet->edns->option( 'EXTENDED-ERROR' => {'INFO-CODE' => 123} );
	$packet->edns->option( '65023' => {'BASE16' => '076578616d706c6500'} );

	$packet->edns->print;

	;; {	"EDNS-VERSION":	0,
	;;	"FLAGS":	32768,
	;;	"RCODE":	0,
	;;	"UDPSIZE":	1232,
	;;	"OPTIONS":	[
	;;		{"NSID": "7261776279746573"},
	;;		{"DAU": [ 8, 10, 13, 14, 15, 16 ]},
	;;		{"TCP-KEEPALIVE": {"TIMEOUT": 200}},
	;;		{"EXTENDED-ERROR": {"INFO-CODE": 123, "EXTRA-TEXT": ""}},
	;;		{"65023": {"BASE16": "076578616d706c6500"}} ]
	;;	}

=head1 DESCRIPTION

EDNS OPT pseudo resource record.

The OPT record supports EDNS protocol extensions and is not intended to be
created, accessed or modified directly by user applications.

All EDNS features are performed indirectly by operations on the objects
returned by the $packet->header and $packet->edns creator methods.
The underlying mechanisms are, or should be, entirely hidden from the user.

=head1 METHODS

The available methods are those inherited from the base class augmented
by the type-specific methods defined in this package.

Use of undocumented package features or direct access to internal data
structures is discouraged and could result in program termination or
other unpredictable behaviour.


=head2 version

	$version = $packet->edns->version;

The version of EDNS supported by this OPT record.

=head2 UDPsize

	$size = $packet->edns->UDPsize;
	$packet->edns->UDPsize($size);

UDPsize() advertises the maximum size (octets) of UDP packet that can be
reassembled in the network stack of the originating host.

=head2 rcode

	$extended_rcode = $packet->header->rcode;

The 12 bit extended RCODE. The most significant 8 bits are obtained from
the OPT record. The least significant 4 bits reside in the packet
header.

=head2 flags

	$do = $packet->header->do;
	$packet->header->do(1);

	$edns_flags = $packet->edns->flags;

16 bit field containing EDNS extended header flags.

=head2 options

	my @options = $packet->edns->options;

When called in a list context, options() returns a list of option codes
found in the OPT record.


=head2 option

	my $octets = $packet->edns->option('COOKIE');
	my $base16 = unpack 'H*', $octets;

When called in a scalar context with a single argument,
option() returns the value of the specified option as
an  uninterpreted octet string.
The method returns undef if the option is absent.

	$packet->edns->option( 'COOKIE'	=> {'OPTION-DATA' => $octets} );
	$packet->edns->option( '10'	=> {'BASE16' => $base16} );

An option can be added or replaced by providing the (name,value) pair.
The option is deleted if the value is undefined.


	my ($structure) = $packet->edns->option("DAU");
	my $array	= $$structure{"DAU"};
	my @algorithms	= @$array;

	my ($structure) = $packet->edns->option(15);
	my $table	= $$structure{"EXTENDED-ERROR"};
	my $info_code	= $$table{'INFO-CODE'};
	my $extra_text	= $$table{'EXTRA-TEXT'};

When called in a list context with a single argument,
option() returns a structured representation of the specified option.


Similar forms of array or hash syntax may be used to construct the
option value:

	$packet->edns->option( 'DAU' => [8, 10, 13, 14, 15, 16] );

	$packet->edns->option( 'EXTENDED-ERROR' => {
					'INFO-CODE'  => 123,
					'EXTRA-TEXT' => ""
					} );


=head1 COPYRIGHT

Copyright (c)2001,2002 RIPE NCC.  Author Olaf M. Kolkman.

Portions Copyright (c)2012,2017-2024 Dick Franks.

All rights reserved.

Package template (c)2009,2012 O.M.Kolkman and R.W.Franks.


=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the original copyright notices appear in all copies and that both
copyright notice and this permission notice appear in supporting
documentation, and that the name of the author not be used in advertising
or publicity pertaining to distribution of the software without specific
prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.


=head1 SEE ALSO

L<perl> L<Net::DNS> L<Net::DNS::RR>
L<RFC6891|https://iana.org/go/rfc6891>
L<RFC3225|https://iana.org/go/rfc3225>

=cut

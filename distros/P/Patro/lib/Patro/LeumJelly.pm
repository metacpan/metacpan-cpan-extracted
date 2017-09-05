package Patro::LeumJelly;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use Storable;
use MIME::Base64 ();

our $VERSION = '0.11';

sub isProxyRef {
    my ($pkg) = @_;
    return $pkg eq 'Patro::N1' || $pkg eq 'Patro::N2' || $pkg eq 'Patro::N3';
}

sub handle {
    my ($proxy) = @_;
    if (CORE::ref($proxy) eq 'Patro::N2') {
	return $proxy;
    } else {
	return ${$proxy};
    }
}

sub serialize {
    return MIME::Base64::encode_base64( 
	Storable::freeze( $_[0] ), "");
}

sub deserialize {
    if ($Patro::SERVER_VERSION && $Patro::SERVER_VERSION <= 0.10) {
	# Data::Dumper was used before v0.11
	my $VAR1;
	eval $_[0];
	$VAR1;
    } else {
	return Storable::thaw(
	    MIME::Base64::decode_base64($_[0]));
    }
}

# return a Patro::N1 or Patro::N2 object appropriate for the
# object metadata (containing id, ref, reftype values) and client.
sub getproxy {
    my ($objdata,$client) = @_;
    croak "getproxy: insufficient metadata to construct proxy"
	unless $objdata->{id} && $objdata->{ref} && $objdata->{reftype};
    my $proxy = { %$objdata };
    if ($objdata->{overload}) {
	$proxy->{overloads} = { map {; $_ => 1 } @{$objdata->{overload}} };
    }
    $proxy->{client} = $client;
    $proxy->{socket} = $client->{socket};
    if ($proxy->{reftype} eq 'SCALAR') {
	require Patro::N2;
	tie my $s, 'Patro::Tie::SCALAR', $proxy;
	$proxy->{scalar} = \$s;
	return bless $proxy, 'Patro::N2';
    }

    if ($proxy->{reftype} eq 'ARRAY') {
	require Patro::N1;
	tie my @a, 'Patro::Tie::ARRAY', $proxy;
	$proxy->{array} = \@a;
	return bless \$proxy, 'Patro::N1';
    }

    if ($proxy->{reftype} eq 'HASH') {
	require Patro::N1;
	tie my %h, 'Patro::Tie::HASH', $proxy;
	$proxy->{hash} = \%h;
	return bless \$proxy, 'Patro::N1';
    }

    if ($proxy->{reftype} eq 'CODE' ||
	$proxy->{reftype} eq 'CODE*') {
	require Patro::N3;
	$proxy->{sub} = sub {
	    return proxy_request( $proxy,
	        {
		    context => defined(wantarray) ? 1 + wantarray : 0,
		    topic => 'CODE',
		    has_args => @_ > 0,
		    args => [ @_ ],
		    command => 'invoke',
		    id => $proxy->{id}
		} );
	};
	return bless \$proxy, 'Patro::N3';
    }

    croak "unsupported remote object reftype '$objdata->{reftype}'";
}

# make a request through a Patro::N's client, return the response
sub proxy_request {
    my ($proxy,$request) = @_;
    my $socket = $proxy->{socket};
    if (!defined $request->{context}) {
	$request->{context} = defined(wantarray) ? 1 + wantarray : 0;
    }
    if (!defined $request->{id}) {
	$request->{id} = $proxy->{id};
    }

    if ($request->{has_args}) {
	# if there are any Patro'N items in $request->{args},
	# we should convert it to ... what?
	foreach my $arg (@{$request->{args}}) {
	    if (isProxyRef(ref($arg))) {
		my $id = handle($arg)->{id};
		$arg = bless \$id, '.Patroon';
	    }
	}
    }

    my $sreq = serialize($request);
    my $resp;
    if ($proxy->{_DESTROY}) {
	no warnings 'closed';
	print {$socket} $sreq . "\n";
	$resp = readline($socket);
    } else {
	print {$socket} $sreq . "\n";
	$resp = readline($socket);
    }
    if (!defined $resp) {
	return serialize({context => 0, response => ""});
    }
    croak if ref($resp);
    $resp = deserialize_response($resp, $proxy->{client});
    if ($resp->{error}) {
	croak $resp->{error};
    }
    if (exists $resp->{disconnect_ok}) {
	return $resp;
    }
    if ($resp->{context} == 0) {
	return;
    }
    if ($resp->{context} == 1) {
	return $resp->{response};
    }
    if ($resp->{context} == 2) {
	if ($request->{context} == 2) {
	    return @{$resp->{response}};
	} else {
	    return $resp->{response}[0];
	}
    }
    croak "invalid response context";
}

sub deserialize_response {
    my ($response,$client) = @_;
    $response = deserialize($response);

    # Does the response contain SCALAR references?
    # Does the response have meta information for these
    # dereferenced SCALAR values?
    # Then they must be converted to Patro::Nx objects.

    if ($response->{context}) {
	if ($response->{context} == 1) {
	    $response->{response} = depatrol($client,
					     $response->{response},
					     $response->{meta})
	} elsif ($response->{context} == 2) {
	    $response->{response} = [ map depatrol($client,
						   $_, $response->{meta}),
				      @{$response->{response}} ];
	}
    }
    return $response;
}

sub depatrol {
    my ($client, $obj, $meta) = @_;
    if (ref($obj) ne 'SCALAR') {
	return $obj;
    }
    my $id = $$obj;
    if ($meta->{$id}) {
	return $client->{proxies}{$id} = getproxy($meta->{$id}, $client);
    } elsif (defined $client->{proxies}{$id}) {
	return $client->{proxies}{$id};
    }
    warn "depatrol: reference $id $obj is not referred to in meta";
    return $obj;
}

# overload handling for Patro::N1 and Patro::N2

my %numeric_ops = map { $_ => 1 }
qw# + - * / % ** << >> += -= *= /= %= **= <<= >>= <=> < <= > >= == != ^ ^=
    & &= | |= neg ! not ~ ++ -- atan2 cos sin exp abs log sqrt int 0+ #;

# non-numeric ops:
#  x . x= .= cmp lt le gt ge eq ne ^. ^.= ~. "" qr -X ~~

sub overload_handler {
    my ($ref, $y, $swap, $op) = @_;
    my $handle = handle($ref);
    my $overloads = $handle->{overloads};
    if ($overloads && $overloads->{$op}) {
	# operation is overloaded in the remote object.
	# ask the server to compute the operation result
	return proxy_request( $handle,
	    { id => $handle->{id},
	      topic => 'OVERLOAD',
	      command => $op,
	      has_args => 1,
	      args => [$y, $swap] } );
    }

    # operation is not overloaded on the server.
    # Do something sensible.
    return 1 if $op eq 'bool';
    return if $op eq '<>';  # nothing sensible to do for this op
    my $str = overload::StrVal($ref);
    if ($numeric_ops{$op}) {
	my $num = hex($str =~ /x(\w+)/);
	return $num if $op eq '0+';
	return cos($num) if $op eq 'cos';
	return sin($num) if $op eq 'sin';
	return exp($num) if $op eq 'exp';
	return log($num) if $op eq 'log';
	return sqrt($num) if $op eq 'sqrt';
	return int($num) if $op eq 'int';
	return abs($num) if $op eq 'abs';
	return -$num if $op eq 'neg';
	return $num+1 if $op eq '++';
	return $num-1 if $op eq '--';
	return !$num if $op eq '!' || $op eq 'not';
	return ~$num if $op eq '~';

	# binary op
	($num,$y)=($y,$num) if $swap;
	return atan2($num,$y) if $op eq 'atan2';
	return $ref if $op eq '=' || $op =~ /^[^<=>]=/;
	return eval "$num $op \$y";
    }

    # string operation
    return $str if $op eq '""';
    return $ref if $op eq '=' || $op =~ /^[^<=>]=/;
    return qr/$str/ if $op eq 'qr';
    return eval "-$y \$str" if $op eq '-X';
    ($str,$y) = ($y,$str) if $swap;
    return eval "\$str $op \$y";
}


1;

=head1 NAME

Patro::LeumJelly - functions that make Patro easier to use

=head1 DESCRIPTION

A collection of functions useful for the L<Patro> distribution.
This package is for internal functions that are not of general
interest to the users of L<Patro>.

=head1 LICENSE AND COPYRIGHT

MIT License

Copyright (c) 2017, Marty O'Brien

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

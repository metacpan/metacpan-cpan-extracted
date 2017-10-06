package Patro::LeumJelly;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use Storable;
use MIME::Base64 ();
no overloading '%{}', '${}';

our $VERSION = '0.16';

my %proxyClasses = (
    'Patro::N1' => 0,    # HASH
    'Patro::N2' => 1,    # SCALAR
    'Patro::N3' => 0,    # CODE
    'Patro::N4' => 0,    # ARRAY
    'Patro::N5' => 0,    # GLOB
    'Patro::N6' => 1,);  # REF

sub isProxyRef {
    my ($pkg) = @_;
    return defined $proxyClasses{$pkg};
}

sub handle {
    my ($proxy) = @_;
    my $ref = CORE::ref($proxy);
    if ($proxyClasses{$ref}) {
	return $proxy;
    } elsif (defined $proxyClasses{$ref}) {
	return ${$proxy};
    } else {
	croak "Not a Patro proxy object";
    }
}

########################################

# bonus discovery about Storable serialization --
# storage order is deterministic

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

########################################

# return a Patro::Nx object appropriate for the
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

    if ($proxy->{reftype} eq 'REF') {
	require Patro::N6;
	bless $proxy, 'Patro::N6';
	return $proxy;
    }
    
    if ($proxy->{reftype} eq 'ARRAY') {
	require Patro::N4;
	tie my @a, 'Patro::Tie::ARRAY', $proxy;
	$proxy->{array} = \@a;
	return bless \$proxy, 'Patro::N4';
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
		}, @_ );
	};
	return bless \$proxy, 'Patro::N3';
    }

    if ($proxy->{reftype} eq 'GLOB') {
	require Patro::N5;
	require Symbol;
	my $fh = Symbol::gensym();
	tie *$fh, 'Patro::Tie::HANDLE', $proxy;
	$proxy->{handle} = \*$fh;
	return bless \$proxy, 'Patro::N5';
    }

    croak "unsupported remote object reftype '$objdata->{reftype}'";
}

# make a request through a Patro::N's client, return the response
sub proxy_request {
    my $proxy = shift;
    my $request = shift;
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
	    if (isProxyRef(CORE::ref($arg))) {
		my $id = handle($arg)->{id};
		$arg = bless \$id, '.Patroon';
	    }
	}
    }

    my $sreq = serialize($request);
    my $resp;
    my $socket = $proxy->{socket};
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
    if ($resp->{_fatal}) {
	# for debugging - for some errors in the server we want
	# a stack trace in the client
	Carp::cluck("Request caused a fatal error in the server:\n"
		    . $resp->{_fatal});
	exit;
    }
    if ($resp->{error}) {
	croak $resp->{error};
    }
    if ($resp->{warn}) {
	carp $resp->{warn};
    }
    if (exists $resp->{disconnect_ok}) {
	return $resp;
    }

    # before returning, handle side effects
    if ($resp->{out} && ref($resp->{out}) eq 'ARRAY') {
	for (my $i=0; $i<@{$resp->{out}}; ) {
	    my $index = $resp->{out}[$i++];
	    my $val = $resp->{out}[$i++];
	    eval { $_[$index] = $val };
	    if ($@) {
		next if $resp->{sideA} &&
		    $@ =~ /Modification of a read-only .../ &&
		    $_[$index] eq $val;
		::xdiag("failed ",[ $_[$index], $val ]);
		croak $@;
	    }
	}
    }
    if (defined $resp->{errno}) {
	# the remote call set $!
	$! = $resp->{errno};
    }
    if (defined $resp->{child_error}) {
	# the remote call set $?
	$? = $resp->{child_error};
    }
    if (defined $resp->{eval_error}) {
	# the remote call set $@
	$@ = $resp->{eval_error};
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
	    $response->{response} = unpatrofy($client,
					     $response->{response},
					     $response->{meta})
	} elsif ($response->{context} == 2) {
	    $response->{response} = [ map unpatrofy($client,
						   $_, $response->{meta}),
				      @{$response->{response}} ];
	}
    }
    if ($response->{out}) {
	$response->{out} = [ map unpatrofy($client,$_,$response->{meta}),
			     @{$response->{out}} ];
    }
    return $response;
}

sub unpatrofy {
    my ($client, $obj, $meta) = @_;
    if (CORE::ref($obj) ne '.Patrobras') {
	return $obj;
    }
    my $id = $$obj;
    if ($meta->{$id}) {
	return $client->{proxies}{$id} = getproxy($meta->{$id}, $client);
    } elsif (defined $client->{proxies}{$id}) {
	return $client->{proxies}{$id};
    }
    warn "unpatrofy: reference $id $obj is not referred to in meta";
    bless $obj, 'SCALAR';
    return $obj;
}

# overload handling for Patro::N1, Patro::N2, and Patro::N4. N3 and N5 too?

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

sub deref_handler {
    my $obj = shift;
    my $op = pop;

    my $handle = handle($obj);
    my $overloads = $handle->{overloads};
    if ($overloads && $overloads->{$op}) {
	# operation is overloaded in the remote object.
	# ask the server to compute the operation result
	return proxy_request( $handle,
	    { id => $handle->{id},
	      topic => 'OVERLOAD',
	      command => $op,
	      has_args => 0 } );
    }
    if ($op eq '@{}') { croak "Not an ARRAY reference" }
    if ($op eq '%{}') { croak "Not a HASH reference" }
    if ($op eq '&{}') { croak "Not a CODE reference" }
    if ($op eq '${}') { croak "Not a SCALAR reference" }
    if ($op eq '*{}') { croak "Not a GLOB reference" }
    croak "Patro: invalid dereference $op";
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

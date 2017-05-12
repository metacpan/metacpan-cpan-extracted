package Net::Curl::Simple;

use strict;
use warnings; no warnings 'redefine';
use Net::Curl 0.17;
use Net::Curl::Easy qw(/^CURLOPT_(PROXY|POSTFIELDS)/ /^CURLPROXY_/);
use Scalar::Util qw(looks_like_number);
use URI;
use URI::Escape qw(uri_escape);
use base qw(Net::Curl::Easy);

our $VERSION = '0.13';

use constant
	curl_features => Net::Curl::version_info()->{features};

use constant {
	can_ipv6 => ( curl_features & Net::Curl::CURL_VERSION_IPV6 ) != 0,
	can_ssl => ( curl_features & Net::Curl::CURL_VERSION_SSL ) != 0,
	can_libz => ( curl_features & Net::Curl::CURL_VERSION_LIBZ ) != 0,
	can_asynchdns => ( curl_features & Net::Curl::CURL_VERSION_ASYNCHDNS ) != 0,
};

use Net::Curl::Simple::Async;

my @common_options = (
	connecttimeout => 60,
	followlocation => 1,
	# just to avoid loops
	maxredirs => 50,
	# there are to many broken servers to care about it by default
	ssl_verifypeer => 0,
	# enable cookie session
	cookiefile => '',
	useragent => __PACKAGE__ . ' v' . $VERSION,
	headerfunction => \&_cb_header,
	httpheader => [
		'Accept: */*',
	],
	# sets Accept-Encoding to all values supported by libcurl
	encoding => '',
);

my %proxytype = (
	http	=> CURLPROXY_HTTP,
	socks4	=> CURLPROXY_SOCKS4,
	socks5	=> CURLPROXY_SOCKS5,
	socks	=> CURLPROXY_SOCKS5,
);
{
	# introduced later in 7.18.0 and 7.19.4
	eval {
		$proxytype{socks4a} = CURLPROXY_SOCKS4A();
		$proxytype{socks5h} = CURLPROXY_SOCKS5_HOSTNAME();
	};
	eval {
		$proxytype{http10} = CURLPROXY_HTTP_1_0();
	};
}

# options that accept either a single constant or a bitmask of constants
my %optlong2constprefix = (
	http_version	=> 'CURL_HTTP_VERSION_',
	ipresolve		=> 'CURL_IPRESOLVE_',
	netrc			=> 'CURL_NETRC_',
	postredir		=> 'CURL_REDIR_POST_',
	rtsp_request	=> 'CURL_RTSPREQ_',
	sslversion		=> 'CURL_SSLVERSION_',
	timecondition	=> 'CURL_TIMECOND_',
	httpauth		=> 'CURLAUTH_',
	proxyauth		=> 'CURLAUTH_',
	ftpsslauth		=> 'CURLFTPAUTH_',
	ftp_filemethod	=> 'CURLFTPMETHOD_',
	tlsauth_type	=> 'CURLOPT_TLSAUTH_',
	protocols		=> 'CURLPROTO_',
	redir_protocols	=> 'CURLPROTO_',
	ssh_auth_types	=> 'CURLSSH_AUTH_',
	use_ssl			=> 'CURLUSESSL_',
);

{
	my %optcache;
	my %optlongcache;

	sub setopt
	{
		my ( $easy, $opt, $val, $temp ) = @_;

		unless ( looks_like_number( $opt ) ) {
			if ( exists $optlong2constprefix{ $opt } ) {
				# convert option value to a number
				# FROM: protocols => "http, file"
				# TO: CURLOPT_PROTOCOLS => CURLPROTO_HTTP | CURLPROTO_FILE
				unless ( looks_like_number( $val ) ) {
					unless ( exists $optlongcache{ $opt }->{ $val } ) {
						my $value = 0;
						my $prefix = $optlong2constprefix{ $opt };
						foreach ( ref $val ? @$val : split /[\|, ]+/, $val ) {
							my $const = $prefix . uc $_;
							# only constants with lowercase letters:
							# CURL_SSLVERSION_TLSv1, CURL_SSLVERSION_SSLv2...
							$const =~ s/V(\d+)$/v$1/
								if $prefix eq "CURL_SSLVERSION_";
							eval "\$value |= Net::Curl::Easy::$const";
							die "unrecognized literal value: $_ for option $opt\n"
								if $@;
						}
						$optlongcache{ $opt }->{ $val } = $value;
					}
					$val = $optlongcache{ $opt }->{ $val };
				}
			}
			# convert option name to option number
			unless ( exists $optcache{ $opt } ) {
				eval "\$optcache{ \$opt } = Net::Curl::Easy::CURLOPT_\U$opt";
				die "unrecognized literal option: $opt\n"
					if $@;
			}
			$opt = $optcache{ $opt };
		}

		if ( $opt == CURLOPT_PROXY ) {
			# guess proxy type from proxy string
			my $type = ( $val =~ m#^([a-z0-9]+)://# );
			if ( defined $type and exists $proxytype{ $type } ) {
				$easy->setopt( CURLOPT_PROXYTYPE, $proxytype{ $type }, $temp );
			}
		} elsif ( $opt == CURLOPT_POSTFIELDS ) {
			# perl knows the size, but libcurl may be wrong
			$easy->setopt( CURLOPT_POSTFIELDSIZE, length $val, $temp );
		}

		my $stash = $easy->{options_temp};
		unless ( $temp ) {
			delete $stash->{ $opt };
			$stash = $easy->{options};
		}
		$stash->{ $opt } = $val;
		$easy->SUPER::setopt( $opt => $val );
	}
}

sub setopts
{
	my $easy = shift;

	while ( my ( $opt, $val ) = splice @_, 0, 2 ) {
		$easy->setopt( $opt => $val );
	}
}

sub setopts_temp
{
	my $easy = shift;

	while ( my ( $opt, $val ) = splice @_, 0, 2 ) {
		$easy->setopt( $opt => $val, 1 );
	}
}


{
	my %infocache;

	sub getinfo
	{
		my ( $easy, $info ) = @_;

		unless ( looks_like_number( $info ) ) {
			# convert option name to option number
			unless ( exists $infocache{ $info } ) {
				eval "\$infocache{ \$info } = Net::Curl::Easy::CURLINFO_\U$info";
				die "unrecognized literal info: $info\n"
					if $@;
			}
			$info = $infocache{ $info };
		}

		$easy->SUPER::getinfo( $info );
	}
}

sub getinfos
{
	my $easy = shift;
	my @out;

	foreach my $arg ( @_ ) {
		my $ret = undef;
		eval {
			$ret = $easy->getinfo( $arg );
		};
		push @out, $ret;
	}
	return @out;
}

sub _cb_header
{
	my ( $easy, $data, $uservar ) = @_;
	push @{ $easy->{headers} }, $data;
	return length $data;
}

sub new
{
	my $class = shift;

	my $easy = $class->SUPER::new(
		{
			body => '',
			headers => [],
			options => {},
			options_temp => {},
		}
	);
	# some sane defaults
	$easy->setopts(
		writeheader => \$easy->{headers},
		file => \$easy->{body},
		@common_options,
		@_,
	);

	return $easy;
}

sub _finish
{
	my ( $easy, $result ) = @_;
	$easy->{referer} = $easy->getinfo( 'effective_url' );
	$easy->{in_use} = 0;
	$easy->{code} = $result;

	my $perm = $easy->{options};
	foreach my $opt ( keys %{ $easy->{options_temp} } ) {
		my $val = $perm->{$opt};
		$easy->setopt( $opt => $val, 0 );
	}

	my $cb = $easy->{cb};
	eval { $cb->( $easy ) } if $cb;
}

sub ua
{
	return (shift)->share();
}

sub _start_perform($);
sub _perform
{
	my ( $easy, $uri, $cb ) = splice @_, 0, 3;
	if ( $easy->{in_use} ) {
		die "this handle is already in use\n";
	}
	if ( $easy->{referer} ) {
		$easy->setopt( referer => $easy->{referer} );
		$uri = URI->new( $uri )->abs( $easy->{referer} )->as_string;
	}

	$easy->setopts_temp( @_ ) if @_;
	$easy->setopt( url => $uri );

	$easy->{uri} = $uri;
	$easy->{cb} = $cb;
	$easy->{body} = '';
	$easy->{headers} = [];
	$easy->{in_use} = 1;

	Net::Curl::Simple::Async::multi->add_handle( $easy );

	# block unless we've got a callback
	$easy->join unless $cb;

	return $easy;
}

*join = sub ($)
{
	my $easy = shift;
	if ( not ref $easy ) {
		# no object, wait for first easy that finishes
		$easy = Net::Curl::Simple::Async::multi->get_one();
		return $easy;
	} else {
		return $easy unless $easy->{in_use};
		Net::Curl::Simple::Async::multi->get_one( $easy );
		return $easy;
	}
};

# results
sub code
{
	return (shift)->{code};
}

sub headers
{
	return @{ (shift)->{headers} };
}

sub content
{
	return (shift)->{body};
}

# get some uri
sub get
{
	my ( $easy, $uri ) = splice @_, 0, 2;
	my $cb = @_ & 1 ? pop : undef;

	$easy->_perform( $uri, $cb,
		@_,
		httpget => 1,
	);
}

# request head on some uri
sub head
{
	my ( $easy, $uri ) = splice @_, 0, 2;
	my $cb = @_ & 1 ? pop : undef;

	$easy->_perform( $uri, $cb,
		@_,
		nobody => 1,
	);
}

# post data to some uri
sub post
{
	my ( $easy, $uri, $post ) = splice @_, 0, 3;
	my $cb = @_ & 1 ? pop : undef;

	my @postopts;
	if ( not ref $post ) {
		@postopts = ( postfields => $post );
	} elsif ( UNIVERSAL::isa( $post, 'Net::Curl::Form' ) ) {
		@postopts = ( httppost => $post );
	} elsif ( ref $post eq 'HASH' ) {
		# handle utf8 ?
		my $postdata = join '&',
			map { uri_escape( $_ ) . '=' . uri_escape( $post->{ $_ } ) }
			sort keys %$post;
		@postopts = ( postfields => $postdata );
	} else {
		die "don't know how to convert $post into a valid post\n";
	}
	$easy->_perform( $uri, $cb,
		@_,
		post => 1,
		@postopts
	);
}

# put some data
sub put
{
	my ( $easy, $uri, $put ) = splice @_, 0, 3;
	my $cb = @_ & 1 ? pop : undef;

	my @putopts;
	if ( not ref $put ) {
		die "Cannot put file $put\n"
			unless -r $put;
		open my $fin, '<', $put;
		@putopts = (
			readfunction => sub {
				my ( $easy, $maxlen, $uservar ) = @_;
				sysread $fin, my ( $r ), $maxlen;
				return \$r;
			},
			infilesize_large => -s $put
		);
	} elsif ( ref $put eq 'SCALAR' ) {
		my $data = $$put;
		use bytes;
		@putopts = (
			readfunction => sub {
				my ( $easy, $maxlen, $uservar ) = @_;
				my $r = substr $data, 0, $maxlen, '';
				return \$r;
			},
			infilesize_large => length $data
		);
	} elsif ( ref $put eq 'CODE' ) {
		@putopts = (
			readfunction => $put,
		);
	} else {
		die "don't know how to put $put\n";
	}
	$easy->_perform( $uri, $cb,
		@_,
		upload => 1,
		@putopts
	);
}


1;

__END__

=head1 NAME

Net::Curl::Simple - simplified Net::Curl interface

=head1 SYNOPSIS

 use Net::Curl::Simple;

 Net::Curl::Simple->new->get( $uri, \&finished );

 sub finished
 {
     my $curl = shift;
     print "document body: $curl->{body}\n";

     # reuse connection to get another file
     $curl->get( '/other_file', \&finished2 );
 }

 sub finished2 { }

 # wait until all requests are finished
 1 while Net::Curl::Simple->join;

=head1 WARNING

B<This module is under development.> Its interface may change yet.

=head1 DESCRIPTION

C<Net::Curl::Simple> is a thin layer over L<Net::Curl>. It simplifies
many common tasks, while providing access to full power of L<Net::Curl>
when its needed.

L<Net::Curl> excells in asynchronous operations, thanks to a great design of
L<libcurl(3)>. To take advantage of that power C<Net::Curl::Simple> interface
allways uses asynchronous mode. If you want a blocking request, you must either
set callback to C<undef> or call join() method right away.

=head1 CONSTRUCTOR

=over

=item new( [%PERMANENT_OPTIONS] )

Creates new Net::Curl::Simple object.

 my $curl = Net::Curl::Simple->new( timeout => 60 );

See also L<Net::Curl::Simple::UserAgent> which will allow you to create
connected C<Net::Curl::Simple> objects.

=back

=head1 METHODS

=over

=item setopt( NAME, VALUE, [TEMPORARY] )

Set some option. Either permanently or only for next request if TEMPORARY is
true. NAME can be a string: name of the CURLOPT_* constants, without CURLOPT_
prefix, preferably in lower case. VALUE should be an appropriate value for that
constant, as described in L<curl_easy_setopt(3)>.

 $curl->setopt( url => $some_uri );

Some options, those that require a constant or a bitmask as their value, can
have a literal value specified instead of the constant. Bitmask values must
be separated by commas, spaces, or combination of both; arrayrefs are accepted
as well. Value names must be written without prefix common for all of values
of this type.

 # single constant
 $curl->setopt( http_version => "1_0" );
 $curl->setopt( ipresolve => "v4" );

 # converted to a bitmask
 $curl->setopt( protocols => "http, https, ftp, file" );
 $curl->setopt( httpauth => "digest, gssnegotiate, ntlm" );

=item setopts( %PERMANENT_OPTIONS )

Set multiple options, permanently.

=item setopts_temp( %TEMPORARY_OPTIONS )

Set multiple options, only for next request.

=item getinfo( NAME )

Get connection information.

 my $value = $curl->getinfo( 'effective_url' );

=item getinfos( @INFO_NAMES )

Returns multiple getinfo values.

 my ( $v1, $v2 ) = $curl->getinfos( 'name1', 'name2' );

=item ua

Returns parent L<Net::Curl::Simple::UserAgent> object.

=item get( URI, [%TEMPORARY_OPTIONS], [&CALLBACK] )

Issue a GET request.

CALLBACK will be called upon finishing with one argument:
the C<Net::Curl::Simple> object. CALLBACK can be set to C<undef>, in which case
the request will block and wait until it finishes.

If URI is incomplete, full uri will be constructed using $curl->{referer}
as base. Net::Curl::Simple updates $curl->{referer} after every request.
TEMPORARY_OPTIONS will be set for this request only.

 $curl->get( "http://full.uri/", sub {
     my $curl = shift;
     my $result = $curl->code;
     die "get() failed: $result\n" unless $result == 0;

     $curl->get( "/partial/uri", sub {} );
 } );

Returns the object itself to allow chaining.

 $curl->get( $uri, \&finished )->join();

=item head( URI, [%TEMPORARY_OPTIONS], [&CALLBACK] )

Issue a HEAD request. Otherwise it is exactly the same as get().

=item post( URI, POST, [%TEMPORARY_OPTIONS], [&CALLBACK] )

Issue a POST request. POST value can be either a scalar, in which case it will
be sent literally, a HASHREF - will be uri-encoded, or a L<Net::Curl::Form>
object (L<Net::Curl::Simple::Form> is OK as well).

 $curl->post( $uri,
     { username => "foo", password => "bar" },
     \&finished
 );

=item put( URI, PUTDATA, [%TEMPORARY_OPTIONS], [&CALLBACK] )

Issue a PUT request. PUTDATA value can be either a file name, in which case the
file contents will be uploaded, a SCALARREF -- refered data will be uploaded,
or a CODEREF -- sub will be called like a C<CURLOPT_READFUNCTION> from
L<Net::Curl::Easy>, you should specify "infilesize" option in the last
case.

 $curl1->put( $uri, "filename", \&finished );
 $curl2->put( $uri, \"some data", \&finished );
 $curl3->put( $uri, sub {
         my ( $curl, $maxsize, $uservar ) = @_;
         read STDIN, my ( $r ), $maxsize;
         return \$r;
     },
     infilesize => EXPECTED_SIZE,
     \&finished
 );

=item code

Return result code. Zero means we're ok.

=item headers

Return a list of all headers. Equivalent to C<< @{ $curl->{headers} } >>.

=item content

Return transfer content. Equivalent to C<< $curl->{body} >>.

=item join

Wait for this download "thread" to finish.

 $curl->join;

It can be called without an object to wait for any download request. It will
return the C<Net::Curl::Simple> that just finished. It is not guaranteed to
return once for each request, if two requests finish at the same time only the
first one will be notified.

 while ( my $curl = Net::Curl::Simple->join ) {
     my $result = $curl->code;
     warn "curl request finished: $result\n";
 }

It should not normally be used, only if you don't provide an event loop
on your own.

=back

=head1 CONSTANTS

=over

=item can_ipv6

Bool, indicates whether libcurl has IPv6 support.

=item can_ssl

Bool, indicates whether libcurl has SSL support.

=item can_libz

Bool, indicates whether libcurl has compression support.

=item can_asynchdns

Bool, indicates whether libcurl can do asynchronous DNS requests.

=back

=head1 OPTIONS

Options can be either CURLOPT_* values (import them from Net::Curl::Easy),
or literal names, preferably in lower case, without the CURLOPT_ preffix.
For description of available options see L<curl_easy_setopt(3)>.

Names for getinfo can also be either CURLINFO_* values or literal names
without CURLINFO_ preffix.

=head1 SEE ALSO

L<Net::Curl::Simple::examples>,
L<Net::Curl::Simple::UserAgent>,
L<Net::Curl::Simple::Async>,
L<Net::Curl::Easy>

=head1 COPYRIGHT

Copyright (c) 2011 Przemyslaw Iskra <sparky at pld-linux.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as perl itself.

=cut

# vim: ts=4:sw=4

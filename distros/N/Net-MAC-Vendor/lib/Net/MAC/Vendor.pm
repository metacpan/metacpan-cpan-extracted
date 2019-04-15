package Net::MAC::Vendor; # git description: v1.264-2-gda20c47
# ABSTRACT: Look up the vendor for a MAC

use strict;
use warnings;
use 5.010;

use Net::SSLeay;

#pod =head1 SYNOPSIS
#pod
#pod 	use Net::MAC::Vendor;
#pod
#pod 	my $mac = "00:0d:93:29:f6:c2";
#pod
#pod 	my $array = Net::MAC::Vendor::lookup( $mac );
#pod
#pod You can also run this as a script with as many arguments as you
#pod like. The module realizes it is a script, looks up the information
#pod for each MAC, and outputs it.
#pod
#pod 	perl Net/MAC/Vendor.pm 00:0d:93:29:f6:c2 00:0d:93:29:f6:c5
#pod
#pod =head1 DESCRIPTION
#pod
#pod The Institute of Electrical and Electronics Engineers (IEEE) assigns
#pod an Organizational Unique Identifier (OUI) to manufacturers of network
#pod interfaces. Each interface has a Media Access Control (MAC) address
#pod of six bytes. The first three bytes are the OUI.
#pod
#pod This module allows you to take a MAC address and turn it into the OUI
#pod and vendor information. You can, for instance, scan a network,
#pod collect MAC addresses, and turn those addresses into vendors. With
#pod vendor information, you can often guess at what what you are looking
#pod at (I<e.g.> an Apple product).
#pod
#pod You can use this as a module as its individual functions, or call it
#pod as a script with a list of MAC addresses as arguments. The module can
#pod figure it out.
#pod
#pod The IEEE moves the location of its OUI file. If they do that again, you
#pod can set the C<NET_MAC_VENDOR_OUI_URL> environment variable to get the new
#pod URL without updating the code.
#pod
#pod Here are some of the old URLs, which also flip-flop schemes:
#pod
#pod 	http://standards.ieee.org/regauth/oui/oui.txt
#pod 	https://standards.ieee.org/regauth/oui/oui.txt
#pod 	http://standards-oui.ieee.org/oui.txt
#pod 	http://standards-oui.ieee.org/oui/oui.txt
#pod
#pod There are older copies of the OUI file in the GitHub repository.
#pod
#pod These files are large (about 4MB), so you might want to cache a copy.
#pod
#pod A different source of information is linuxnet.ca that publishes sanitized
#pod and compressed versions of the list, such as:
#pod
#pod         http://linuxnet.ca/ieee/oui.txt.bz2
#pod
#pod The module can read and decompress compressed versions (as long as the url
#pod reflects the compression type in the filename as the linuxnet.ca links do).
#pod
#pod =head2 Functions
#pod
#pod =over 4
#pod
#pod =cut

use Exporter qw(import);

__PACKAGE__->run( @ARGV ) unless caller;

use Carp ();
use Mojo::URL;
use Mojo::UserAgent;

our $VERSION = '1.265';

#pod =item run( @macs )
#pod
#pod If I call this module as a script, this class method automatically
#pod runs. It takes the MAC addresses and prints the registered vendor
#pod information for each address. I can pass it a list of MAC addresses
#pod and run() processes each one of them. It prints out what it
#pod discovers.
#pod
#pod This method does try to use a cache of OUI to cut down on the
#pod times it has to access the network. If the cache is fully
#pod loaded (perhaps using C<load_cache>), it may not even use the
#pod network at all.
#pod
#pod =cut

sub run {
	my $class = shift;

	foreach my $arg ( @_ ) {
		my $lines = lookup( $arg );
		return unless defined $lines;

		unshift @$lines, $arg;

		print join "\n", @$lines, '';
		}

	return 1;
	}

#pod =item ua
#pod
#pod Return the Mojo::UserAgent object used to fetch resources.
#pod
#pod =cut

sub ua {
	state $ua = Mojo::UserAgent->new->max_redirects(3);
	$ua;
	}

#pod =item lookup( MAC )
#pod
#pod Given the MAC address, return an anonymous array with the vendor
#pod information. The first element is the vendor name, and the remaining
#pod elements are the address lines. Different records may have different
#pod numbers of lines, although the first two should be consistent.
#pod
#pod This makes a direct request to the IEEE website for that OUI to return
#pod the information for that vendor.
#pod
#pod The C<normalize_mac()> function explains the possible formats
#pod for MAC.
#pod
#pod =cut

sub lookup {
	my $mac   = shift;

	   $mac   = normalize_mac( $mac );
	my $lines = fetch_oui( $mac );

	return $lines;
	}

#pod =item normalize_mac( MAC )
#pod
#pod Takes a MAC address and turns it into the form I need to
#pod send to the IEEE lookup, which is the first six bytes in hex
#pod separated by hyphens. For instance, 00:0d:93:29:f6:c2 turns
#pod into 00-0D-93.
#pod
#pod The input string can be a separated by colons or hyphens. They
#pod can omit leading 0's (which might make things look odd). We
#pod only need the first three bytes
#pod
#pod 	00:0d:93:29:f6:c2   # usual form
#pod
#pod 	00-0d-93-29-f6-c2   # with hyphens
#pod
#pod 	00:0d:93            # first three bytes
#pod
#pod 	0:d:93              # missing leading zero
#pod
#pod 	:d:93               # missing all leading zeros
#pod
#pod The input string can also be a blessed L<NetAddr::MAC> object.
#pod
#pod =cut

sub normalize_mac {
	no warnings 'uninitialized';

	my $input = shift;

	return uc($input->as_microsoft)
	    if ref $input eq 'NetAddr::MAC';

	$input = uc $input;

	do {
		Carp::carp "Could not normalize MAC [$input]";
		return
		} if $input =~ m/[^0-9a-f:-]/i;

	my @bytes =
		grep { /^[0-9A-F]{2}$/ }
		map { sprintf "%02X", hex }
		grep { defined }
		( split /[:-]/, $input )[0..2];

	do {
		Carp::carp "Could not normalize MAC [$input]";
		return
		} unless @bytes == 3;

	my $mac = join "-", @bytes;

	return $mac;
	}

#pod =item fetch_oui( MAC )
#pod
#pod Looks up the OUI information on the IEEE website, or uses a cached
#pod version of it. Pass it the result of C<normalize_mac()> and you
#pod should be fine.
#pod
#pod The C<normalize_mac()> function explains the possible formats for
#pod MAC.
#pod
#pod To avoid multiple calls on the network, use C<load_cache> to preload
#pod the entire OUI space into an in-memory cache. This can take a long
#pod time over a slow network, though; the file is about 60,000 lines.
#pod
#pod Also, the IEEE website has been flaky lately, so loading the cache is
#pod better. This distribution comes with several versions of the complete
#pod OUI data file.
#pod
#pod =cut

sub fetch_oui {
	# fetch_oui_from_custom( $_[0] )    ||
		fetch_oui_from_cache( $_[0] ) ||
		fetch_oui_from_ieee( $_[0] );
	}

#pod =item fetch_oui_from_custom( MAC, [ URL ] )
#pod
#pod Looks up the OUI information from the specified URL or the URL set
#pod in the C<NET_MAC_VENDOR_OUI_SOURCE> environment variable.
#pod
#pod The C<normalize_mac()> function explains the possible formats for
#pod MAC.
#pod
#pod =cut

sub fetch_oui_from_custom {
	my $mac = normalize_mac( shift );
	my $url = shift // $ENV{NET_MAC_VENDOR_OUI_SOURCE};

	return unless defined $url;

	my $html = __PACKAGE__->_fetch_oui_from_url( $url );
	unless( defined $html ) {
		Carp::carp "Could not fetch data from the IEEE!";
		return;
		}

	parse_oui(
		extract_oui_from_html( $html, $mac )
		);
	}

#pod =item fetch_oui_from_ieee( MAC )
#pod
#pod Looks up the OUI information on the IEEE website. Pass it the result
#pod of C<normalize_mac()> and you should be fine.
#pod
#pod The C<normalize_mac()> function explains the possible formats for
#pod MAC.
#pod
#pod =cut

sub _search_url_base {
# https://services13.ieee.org/RST/standards-ra-web/rest/assignments/download/?registry=MA-L&format=html&text=00-0D-93
	state $url = Mojo::URL->new(
		'https://services13.ieee.org/RST/standards-ra-web/rest/assignments/download/?registry=MA-L&format=html'
		);

	$url;
	}

sub _search_url {
	my( $class, $mac ) = @_;
	my $url = $class->_search_url_base->clone;
	$url->query->merge( text => $mac );
	$url;
	}

sub fetch_oui_from_ieee {
	my $mac = normalize_mac( shift );

	my @urls = __PACKAGE__->_search_url( $mac );

	my $html;
	URL: foreach my $url ( @urls ) {
		$html = __PACKAGE__->_fetch_oui_from_url( $url );
		next URL unless defined $html;
		last;
		}

	unless( defined $html ) {
		Carp::carp "Could not fetch data from the IEEE!";
		return;
		}

	parse_oui(
		extract_oui_from_html( $html, $mac )
		);
	}

sub _fetch_oui_from_url {
	state $min_ssl = 0x10_00_00_00;
	my( $class, $url ) = @_;
	my $tries = 0;

	my $ssl_version =  Net::SSLeay::SSLeay();
	my $ssl_version_string = Net::SSLeay::SSLeay_version();

	if( $ssl_version < $min_ssl ) {
		Carp::carp "Fetching OUI might fail with older OpenSSLs. You have [$ssl_version_string] and may need 1.x";
		}

	return unless defined $url;

	TRY: {
		my $tx = __PACKAGE__->ua->get( $url );
		if( $tx->error ) {
			if( $tries > 3 ) {
				my $error  = $tx->error;
				my @messages = (
					"Failed fetching [$url] HTTP status [$error->{code}]",
					"message [$error->{message}]"
					);
				push @messages, "You may need to upgrade OpenSSL to 1.x. You have [$ssl_version_string]"
					if $ssl_version < $min_ssl;

				Carp::carp join "\n", @messages;
				return;
				}

			$tries++;
			sleep 1 * $tries;
			redo TRY;
			}

		my $html = $tx->res->body;
		unless( defined $html ) {
			Carp::carp "No content in response for [$url]!";
			return;
			}

		return $html;
		}
	}

#pod =item fetch_oui_from_cache( MAC )
#pod
#pod Looks up the OUI information in the cached OUI information (see
#pod C<load_cache>).
#pod
#pod The C<normalize_mac()> function explains the possible formats for
#pod MAC.
#pod
#pod To avoid multiple calls on the network, use C<load_cache> to preload
#pod the entire OUI space into an in-memory cache.
#pod
#pod If it doesn't find the MAC in the cache, it returns nothing.
#pod
#pod =cut

sub fetch_oui_from_cache {
	my $mac = normalize_mac( shift );

	__PACKAGE__->get_from_cache( $mac );
	}

#pod =item extract_oui_from_html( HTML, OUI )
#pod
#pod Gets rid of the HTML around the OUI information. It may still be
#pod ugly. The HTML is the search results page of the IEEE ouisearch
#pod lookup.
#pod
#pod Returns false if it could not extract the information. This could
#pod mean unexpected input or a change in format.
#pod
#pod =cut

sub extract_oui_from_html {
	my $html = shift;
	my $lookup_mac = normalize_mac( shift );

	my( $record ) = $html =~ m|<pre>(<b>$lookup_mac</b>.*?)</pre>|is;
	$record =~ s|</?b>||g;

	return unless defined $record;
	return $record;
	}

#pod =item parse_oui( STRING )
#pod
#pod Takes a string that looks like this:
#pod
#pod 	00-03-93   (hex)            Apple Computer, Inc.
#pod 	000393     (base 16)        Apple Computer, Inc.
#pod 								20650 Valley Green Dr.
#pod 								Cupertino CA 95014
#pod 								UNITED STATES
#pod
#pod and turns it into an array of lines. It discards the first
#pod line, strips the leading information from the second line,
#pod and strips the leading whitespace from all of the lines.
#pod
#pod With no arguments, it returns an empty anonymous array.
#pod
#pod =cut

sub parse_oui {
	my $oui = shift;
	return [] unless $oui;
	$oui =~ s|</?b>||g;
	my @lines = map { s/^\s+//; $_ ? $_ : () } split /\s*$/m, $oui;
	chomp @lines;
	splice @lines, 1, 1, (); # should have documented this!

	$lines[0] =~ s/\S+\s+\S+\s+//;
	return \@lines;
	}

#pod =item oui_url
#pod
#pod =item oui_urls
#pod
#pod Returns the URLs of the oui.txt resource. The IEEE likes to move this
#pod around. These are the default URL that C<load_cache> will use, but you
#pod can also supply your own with the C<NET_MAC_VENDOR_OUI_URL> environment
#pod variable.
#pod
#pod =cut

sub oui_url { (grep { /\Ahttp:/ } &oui_urls)[0] }

sub oui_urls {
	my @urls = 'http://standards-oui.ieee.org/oui.txt';

	unshift @urls, $ENV{NET_MAC_VENDOR_OUI_URL}
		if defined $ENV{NET_MAC_VENDOR_OUI_URL};

	@urls;
	}

#pod =item load_cache( [ SOURCE[, DEST ] ] )
#pod
#pod Downloads the current list of all OUIs in SOURCE, parses it with
#pod C<parse_oui()>, and stores it in the cache. The C<fetch_oui()> will
#pod use this cache if it exists.
#pod
#pod By default, this uses the URL from C<oui_url>, but given an argument,
#pod it tries to use that.
#pod
#pod If the url indicates that the data is compressed, the response content
#pod is decompressed before being stored.
#pod
#pod If C<load_cache> cannot load the data, it issues a warning and returns
#pod nothing.
#pod
#pod This previously used DBM::Deep if it was installed, but that was much
#pod too slow. Instead, if you want persistence, you can play with
#pod C<$Net::MAC::Vendor::Cached> yourself.
#pod
#pod If you want to store the data fetched for later use, add a destination
#pod filename to the request. To fetch from the default location and store,
#pod specify C<undef> as source.
#pod
#pod =cut

sub load_cache {
	my( $source, $dest ) = @_;

	my $data = do {;
		if( defined $source ) {
			unless( -e $source ) {
				Carp::carp "Net::Mac::Vendor cache source [$source] does not exist";
				return;
				}

			do { local( @ARGV, $/ ) = $source; <> }
			}
		else {
			#say time . " Fetching URL";
			my $url = oui_url();
			my $tx = __PACKAGE__->ua->get( $url );
			#say time . " Fetched URL";
			#say "size is " . $tx->res->headers->header( 'content-length' );
			($url =~ /\.bz2/) ? _bunzip($tx->res->body) :
			($url =~ /\.gz/)  ? _gunzip($tx->res->body) :
			                    $tx->res->body;
			}
		};

	if( defined $dest ) {
		if( open my $fh, '>:utf8', $dest ) {
			print { $fh } $data;
			close $fh;
			}
		else { # notify on error, but continue
			Carp::carp "Could not write to '$dest': $!";
			}
		}


	# The PRIVATE entries fill in a template with no
	# company name or address, but the whitespace is
	# still there. We need to split on a newline
	# followed by some potentially horizontal whitespace
	# and another newline
	my $CRLF = qr/(?:\r?\n)/;
	my @entries = split /[\t ]* $CRLF [\t ]* $CRLF/x, $data;
	shift @entries;

	my $count = '';
	foreach my $entry ( @entries ) {
		$entry =~ s/^\s+//;
		my $oui = substr $entry, 0, 8;
		__PACKAGE__->add_to_cache( $oui, parse_oui( $entry ) );
		}

	return 1;
	}

sub _bunzip {
	my $content = shift;
	if (eval { +require Compress::Bzip2; 1 }) {
		return Compress::Bzip2::memBunzip($content);
		}
	else {
		require File::Temp;
		my ($tempfh, $tempfilename) = File::Temp::tempfile( UNLINK => 1 );
		binmode $tempfh, ':raw';
		print $tempfh $content;
		close $tempfh;

		open my $unzipfh, "bunzip2 --stdout $tempfilename |"
			or die "cannot pipe to bunzip2: $!";
		local $/;
		return <$unzipfh>;
		}
	}

sub _gunzip {
	my $content = shift;
	if (eval { +require Compress::Zlib; 1 }) {
		return Compress::Zlib::memGunzip($content);
		}
	else {
		require File::Temp;
		my ($tempfh, $tempfilename) = File::Temp::tempfile( UNLINK => 1 );
		binmode $tempfh, ':raw';
		print $tempfh $content;
		close $tempfh;

		open my $unzipfh, "gunzip --stdout $tempfilename |"
			or die "cannot pipe to gunzip: $!";
		local $/;
		return <$unzipfh>;
		}
	}

#pod =back
#pod
#pod =head1 Caching
#pod
#pod Eventually I want people to write their own caching classes so I've
#pod created some class methods for this.
#pod
#pod =over 4
#pod
#pod =cut

BEGIN {
my $Cached = {};

#pod =item add_to_cache( OUI, PARSED_DATA )
#pod
#pod Add to the cache. This is mostly in place for a future expansion to
#pod full objects so you can override this in a subclass.
#pod
#pod =cut

sub add_to_cache {
	my( $class, $oui, $parsed ) = @_;

	$Cached->{ $oui } = $parsed;
	}

#pod =item get_from_cache( OUI )
#pod
#pod Get from the cache. This is mostly in place for a future expansion to
#pod full objects so you can override this in a subclass.
#pod
#pod =cut

sub get_from_cache {
	my( $class, $oui ) = @_;

	$Cached->{ $oui };
	}

#pod =item get_cache_hash()
#pod
#pod Get the hash the built-in cache uses. You should only use this if you
#pod were using the old C<$Cached> package variable.
#pod
#pod =cut

sub get_cache_hash { $Cached }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::MAC::Vendor - Look up the vendor for a MAC

=head1 VERSION

version 1.265

=head1 SYNOPSIS

	use Net::MAC::Vendor;

	my $mac = "00:0d:93:29:f6:c2";

	my $array = Net::MAC::Vendor::lookup( $mac );

You can also run this as a script with as many arguments as you
like. The module realizes it is a script, looks up the information
for each MAC, and outputs it.

	perl Net/MAC/Vendor.pm 00:0d:93:29:f6:c2 00:0d:93:29:f6:c5

=head1 DESCRIPTION

The Institute of Electrical and Electronics Engineers (IEEE) assigns
an Organizational Unique Identifier (OUI) to manufacturers of network
interfaces. Each interface has a Media Access Control (MAC) address
of six bytes. The first three bytes are the OUI.

This module allows you to take a MAC address and turn it into the OUI
and vendor information. You can, for instance, scan a network,
collect MAC addresses, and turn those addresses into vendors. With
vendor information, you can often guess at what what you are looking
at (I<e.g.> an Apple product).

You can use this as a module as its individual functions, or call it
as a script with a list of MAC addresses as arguments. The module can
figure it out.

The IEEE moves the location of its OUI file. If they do that again, you
can set the C<NET_MAC_VENDOR_OUI_URL> environment variable to get the new
URL without updating the code.

Here are some of the old URLs, which also flip-flop schemes:

	http://standards.ieee.org/regauth/oui/oui.txt
	https://standards.ieee.org/regauth/oui/oui.txt
	http://standards-oui.ieee.org/oui.txt
	http://standards-oui.ieee.org/oui/oui.txt

There are older copies of the OUI file in the GitHub repository.

These files are large (about 4MB), so you might want to cache a copy.

A different source of information is linuxnet.ca that publishes sanitized
and compressed versions of the list, such as:

        http://linuxnet.ca/ieee/oui.txt.bz2

The module can read and decompress compressed versions (as long as the url
reflects the compression type in the filename as the linuxnet.ca links do).

=head2 Functions

=over 4

=item run( @macs )

If I call this module as a script, this class method automatically
runs. It takes the MAC addresses and prints the registered vendor
information for each address. I can pass it a list of MAC addresses
and run() processes each one of them. It prints out what it
discovers.

This method does try to use a cache of OUI to cut down on the
times it has to access the network. If the cache is fully
loaded (perhaps using C<load_cache>), it may not even use the
network at all.

=item ua

Return the Mojo::UserAgent object used to fetch resources.

=item lookup( MAC )

Given the MAC address, return an anonymous array with the vendor
information. The first element is the vendor name, and the remaining
elements are the address lines. Different records may have different
numbers of lines, although the first two should be consistent.

This makes a direct request to the IEEE website for that OUI to return
the information for that vendor.

The C<normalize_mac()> function explains the possible formats
for MAC.

=item normalize_mac( MAC )

Takes a MAC address and turns it into the form I need to
send to the IEEE lookup, which is the first six bytes in hex
separated by hyphens. For instance, 00:0d:93:29:f6:c2 turns
into 00-0D-93.

The input string can be a separated by colons or hyphens. They
can omit leading 0's (which might make things look odd). We
only need the first three bytes

	00:0d:93:29:f6:c2   # usual form

	00-0d-93-29-f6-c2   # with hyphens

	00:0d:93            # first three bytes

	0:d:93              # missing leading zero

	:d:93               # missing all leading zeros

The input string can also be a blessed L<NetAddr::MAC> object.

=item fetch_oui( MAC )

Looks up the OUI information on the IEEE website, or uses a cached
version of it. Pass it the result of C<normalize_mac()> and you
should be fine.

The C<normalize_mac()> function explains the possible formats for
MAC.

To avoid multiple calls on the network, use C<load_cache> to preload
the entire OUI space into an in-memory cache. This can take a long
time over a slow network, though; the file is about 60,000 lines.

Also, the IEEE website has been flaky lately, so loading the cache is
better. This distribution comes with several versions of the complete
OUI data file.

=item fetch_oui_from_custom( MAC, [ URL ] )

Looks up the OUI information from the specified URL or the URL set
in the C<NET_MAC_VENDOR_OUI_SOURCE> environment variable.

The C<normalize_mac()> function explains the possible formats for
MAC.

=item fetch_oui_from_ieee( MAC )

Looks up the OUI information on the IEEE website. Pass it the result
of C<normalize_mac()> and you should be fine.

The C<normalize_mac()> function explains the possible formats for
MAC.

=item fetch_oui_from_cache( MAC )

Looks up the OUI information in the cached OUI information (see
C<load_cache>).

The C<normalize_mac()> function explains the possible formats for
MAC.

To avoid multiple calls on the network, use C<load_cache> to preload
the entire OUI space into an in-memory cache.

If it doesn't find the MAC in the cache, it returns nothing.

=item extract_oui_from_html( HTML, OUI )

Gets rid of the HTML around the OUI information. It may still be
ugly. The HTML is the search results page of the IEEE ouisearch
lookup.

Returns false if it could not extract the information. This could
mean unexpected input or a change in format.

=item parse_oui( STRING )

Takes a string that looks like this:

	00-03-93   (hex)            Apple Computer, Inc.
	000393     (base 16)        Apple Computer, Inc.
								20650 Valley Green Dr.
								Cupertino CA 95014
								UNITED STATES

and turns it into an array of lines. It discards the first
line, strips the leading information from the second line,
and strips the leading whitespace from all of the lines.

With no arguments, it returns an empty anonymous array.

=item oui_url

=item oui_urls

Returns the URLs of the oui.txt resource. The IEEE likes to move this
around. These are the default URL that C<load_cache> will use, but you
can also supply your own with the C<NET_MAC_VENDOR_OUI_URL> environment
variable.

=item load_cache( [ SOURCE[, DEST ] ] )

Downloads the current list of all OUIs in SOURCE, parses it with
C<parse_oui()>, and stores it in the cache. The C<fetch_oui()> will
use this cache if it exists.

By default, this uses the URL from C<oui_url>, but given an argument,
it tries to use that.

If the url indicates that the data is compressed, the response content
is decompressed before being stored.

If C<load_cache> cannot load the data, it issues a warning and returns
nothing.

This previously used DBM::Deep if it was installed, but that was much
too slow. Instead, if you want persistence, you can play with
C<$Net::MAC::Vendor::Cached> yourself.

If you want to store the data fetched for later use, add a destination
filename to the request. To fetch from the default location and store,
specify C<undef> as source.

=back

=head1 Caching

Eventually I want people to write their own caching classes so I've
created some class methods for this.

=over 4

=item add_to_cache( OUI, PARSED_DATA )

Add to the cache. This is mostly in place for a future expansion to
full objects so you can override this in a subclass.

=item get_from_cache( OUI )

Get from the cache. This is mostly in place for a future expansion to
full objects so you can override this in a subclass.

=item get_cache_hash()

Get the hash the built-in cache uses. You should only use this if you
were using the old C<$Cached> package variable.

=back

1;
__END__

=head1 SEE ALSO

L<Net::MacMap>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Net-MAC-Vendor>
(or L<bug-Net-MAC-Vendor@rt.cpan.org|mailto:bug-Net-MAC-Vendor@rt.cpan.org>).

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

brian d foy <bdfoy@cpan.org>

=head1 CONTRIBUTORS

=for stopwords brian d foy Karen Etheridge Frank Maas openstrike Dean Hamstead

=over 4

=item *

brian d foy <brian.d.foy@gmail.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Frank Maas <maas.frank@gmail.com>

=item *

openstrike <git@openstrike.co.uk>

=item *

Dean Hamstead <dean@fragfest.com.au>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2004 by brian d foy.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

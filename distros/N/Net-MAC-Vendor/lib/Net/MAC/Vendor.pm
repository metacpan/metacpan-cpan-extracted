package Net::MAC::Vendor;
use strict;

use v5.10;

=encoding utf8

=head1 NAME

Net::MAC::Vendor - look up the vendor for a MAC

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
can set the C<NET_MAC_VENDER_OUI_URL> environment variable to get the new
URL without updating the code.

Here are some of the old URLs, which also flip-flop schemes:

	http://standards.ieee.org/regauth/oui/oui.txt
	https://standards.ieee.org/regauth/oui/oui.txt
	http://standards-oui.ieee.org/oui.txt

There are older copies of the OUI file in the GitHub repository.

These files are large (about 4MB), so you might want to cache a copy.

=head2 Functions

=over 4

=cut

use Exporter qw(import);

__PACKAGE__->run( @ARGV ) unless caller;

use Carp;
use Mojo::URL;
use Mojo::UserAgent;

our $VERSION = '1.26';

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

=cut

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

=item ua

Return the Mojo::UserAgent object used to fetch resources.

=cut

sub ua {
	state $ua = Mojo::UserAgent->new->max_redirects(3);
	$ua;
	}

=item lookup( MAC )

Given the MAC address, return an anonymous array with the vendor
information. The first element is the vendor name, and the remaining
elements are the address lines. Different records may have different
numbers of lines, although the first two should be consistent.

This makes a direct request to the IEEE website for that OUI to return
the information for that vendor.

The C<normalize_mac()> function explains the possible formats
for MAC.

=cut

sub lookup {
	my $mac   = shift;

	   $mac   = normalize_mac( $mac );
	my $lines = fetch_oui( $mac );

	return $lines;
	}

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

=cut

sub normalize_mac {
	no warnings 'uninitialized';

	my $input = uc shift;

	do {
		carp "Could not normalize MAC [$input]";
		return
		} if $input =~ m/[^0-9a-f:-]/i;

	my @bytes =
		grep { /^[0-9A-F]{2}$/ }
		map { sprintf "%02X", hex }
		grep { defined }
		( split /[:-]/, $input )[0..2];

	do {
		carp "Could not normalize MAC [$input]";
		return
		} unless @bytes == 3;

	my $mac = join "-", @bytes;

	return $mac;
	}

=item fetch_oui( MAC )

Looks up the OUI information on the IEEE website, or uses a cached
version of it. Pass it the result of C<normalize_mac()> and you
should be fine.

The C<normalize_mac()> function explains the possible formants for
MAC.

To avoid multiple calls on the network, use C<load_cache> to preload
the entire OUI space into an in-memory cache. This can take a long
time over a slow network, though; the file is about 60,000 lines.

Also, the IEEE website has been flaky lately, so loading the cache is
better. This distribution comes with several versions of the complete
OUI data file.

=cut

sub fetch_oui {
	# fetch_oui_from_custom( $_[0] )    ||
		fetch_oui_from_cache( $_[0] ) ||
		fetch_oui_from_ieee( $_[0] );
	}

=item fetch_oui_from_custom( MAC, [ URL ] )

Looks up the OUI information from the specified URL or the URL set
in the C<NET_MAC_VENDOR_OUI_SOURCE> environment variable.

The C<normalize_mac()> function explains the possible formants for
MAC.

=cut

sub fetch_oui_from_custom {
	my $mac = normalize_mac( shift );
	my $url = shift // $ENV{NET_MAC_VENDOR_OUI_SOURCE};

	return unless defined $url;

	my $html = get( $url );
	unless( defined $html ) {
		carp "Could not fetch data from the IEEE!";
		return;
		}

	parse_oui(
		extract_oui_from_html( $html, $mac )
		);
	}

=item fetch_oui_from_ieee( MAC )

Looks up the OUI information on the IEEE website. Pass it the result
of C<normalize_mac()> and you should be fine.

The C<normalize_mac()> function explains the possible formants for
MAC.

=cut

sub _search_url_base {
	state $url = Mojo::URL->new(
		'http://standards.ieee.org/cgi-bin/ouisearch'
		);
	$url;
	}

sub _search_url {
	my( $class, $mac ) = @_;
	my $url = $class->_search_url_base->clone;
	$url->query( $mac );
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
		carp "Could not fetch data from the IEEE!";
		return;
		}

	parse_oui(
		extract_oui_from_html( $html, $mac )
		);
	}

sub _fetch_oui_from_url {
	my( $class, $url ) = @_;
	my $tries = 0;

	return unless defined $url;

	TRY: {
		my $tx = __PACKAGE__->ua->get( $url );
		unless( $tx->success ) {
			if( $tries > 3 ) {
				carp "Failed fetching [$url]: " . $tx->res->code;
				return;
				}

			$tries++;
			sleep 1 * $tries;
			redo TRY;
			}

		my $html = $tx->res->body;
		unless( defined $html ) {
			carp "No content in response for [$url]!";
			return;
			}

		return $html;
		}
	}

=item fetch_oui_from_cache( MAC )

Looks up the OUI information in the cached OUI information (see
C<load_cache>).

The C<normalize_mac()> function explains the possible formats for
MAC.

To avoid multiple calls on the network, use C<load_cache> to preload
the entire OUI space into an in-memory cache.

If it doesn't find the MAC in the cache, it returns nothing.

=cut

sub fetch_oui_from_cache {
	my $mac = normalize_mac( shift );

	__PACKAGE__->get_from_cache( $mac );
	}

=item extract_oui_from_html( HTML, OUI )

Gets rid of the HTML around the OUI information. It may still be
ugly. The HTML is the search results page of the IEEE ouisearch
lookup.

Returns false if it could not extract the information. This could
mean unexpected input or a change in format.

=cut

sub extract_oui_from_html {
	my $html = shift;
	my $lookup_mac = normalize_mac( shift );

	my( $record ) = $html =~ m|<pre>(<b>$lookup_mac</b>.*?)</pre>|is;
	$record =~ s|</?b>||g;

	return unless defined $record;
	return $record;
	}

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

=cut

sub parse_oui {
	my $oui = shift;
	return [] unless $oui;
	$oui =~ s|</?b>||g;
	my @lines = map { s/^\s+//; $_ ? $_ : () } split /$/m, $oui;
	splice @lines, 1, 1, ();

	$lines[0] =~ s/\S+\s+\S+\s+//;
	return \@lines;
	}

=item oui_url

=item oui_urls

Returns the URLs of the oui.txt resource. The IEEE likes to move this
around. These are the default URL that C<load_cache> will use, but you
can also supply your own with the C<NET_MAC_VENDOR_OUI_URL> environment
variable.

=cut

sub oui_url { (grep { /\Ahttp:/ } &oui_urls)[0] }

sub oui_urls {
	my @urls = 'http://standards-oui.ieee.org/oui.txt';

	unshift @urls, $ENV{NET_MAC_VENDOR_OUI_URL}
		if defined $ENV{NET_MAC_VENDOR_OUI_URL};

	@urls;
	}

=item load_cache( [ SOURCE[, DEST ] ] )

Downloads the current list of all OUIs in SOURCE, parses it with C<parse_oui()>,
and stores it in the cache. The C<fetch_oui()> will use this cache if it exists.

By default, this uses the URL from C<oui_url>,
but given an argument, it tries to use that. To load from a local
file, use the C<file://> scheme.

If C<load_cache> cannot load the data, it issues a warning and returns
nothing.

This previously used DBM::Deep if it was installed, but that was much
too slow. Instead, if you want persistence, you can play with
C<$Net::MAC::Vendor::Cached> yourself.

If you want to store the data fetched for later use, add a destination
filename to the request. To fetch from the default location and store,
specify C<undef> as source.

=cut

sub load_cache {
	my( $source, $dest ) = @_;

	my $data = do {;
		if( defined $source ) {
			unless( -e $source ) {
				carp "Net::Mac::Vendor cache source [$source] does not exist";
				return;
				}

			do { local( @ARGV, $/ ) = $source; <> }
			}
		else {
			#say time . " Fetching URL";
			my $tx = __PACKAGE__->ua->get( oui_url() );
			#say time . " Fetched URL";
			#say "size is " . $tx->res->headers->header( 'content-length' );
			$tx->res->body;
			}
		};

	if( defined $dest ) {
		if( open my $fh, '>:utf8', $dest ) {
			print { $fh } $data;
			close $fh;
			}
		else { # notify on error, but continue
			carp "Could not write to '$dest': $!";
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
		__PACKAGE__->add_to_cache( parse_oui( $entry ) );
		}

	return 1;
	}

=back

=head1 Caching

Eventually I want people to write their own caching classes so I've
created some class methods for this.

=over 4

=cut

BEGIN {
my $Cached = {};

=item add_to_cache

Add to the cache. This is mostly in place for a future expansion to
full objects so you can override this in a subclass.

=cut

sub add_to_cache {
	my( $class, $oui, $parsed ) = @_;

	$Cached->{ $oui } = $parsed;
	}

=item get_from_cache

Get from the cache. This is mostly in place for a future expansion to
full objects so you can override this in a subclass.

=cut

sub get_from_cache {
	my( $class, $oui ) = @_;

	$Cached->{ $oui };
	}

=item get_cache_hash

Get the hash the built-in cache uses. You should only use this if you
were using the old C<$Cached> package variable.

=cut

sub get_cache_hash { $Cached }
}

=back

=head1 SEE ALSO

L<Net::MacMap>

=head1 SOURCE AVAILABILITY

The source is in Github:

	git://github.com/briandfoy/net-mac-vendor.git

=head1 AUTHOR

brian d foy C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2004-2015, brian d foy C<< <bdfoy@cpan.org> >>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

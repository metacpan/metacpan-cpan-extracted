package Net::iTMS::Request;
#
# Written by Thomas R. Sibley, <http://zulutango.org:82/>
#
#   Information on properly fetching the URLs and decrypting
#   the content thanks to Jason Rohrer.
#
use warnings;
use strict;

use vars '$VERSION';
$VERSION = '0.14';

use LWP::UserAgent;
use HTTP::Request;

use URI::Escape qw//;

use Crypt::CBC;
use Crypt::Rijndael;
use Digest::MD5;

use XML::Twig;

use Net::iTMS::Error;

=head1 NAME

Net::iTMS::Request - Library for making requests to the iTMS

=head1 DESCRIPTION

Net::iTMS::Request handles the fetching, decrypting, and uncompressing of
content from the iTunes Music Store.

=head1 METHODS

All methods return C<undef> on error and (should) set an error message,
which is available through the C<error> method.  (Unless noted otherwise.)

=over 12

=item C<< new([ debug => 1, [...] ]) >>

Takes an argument list of C<key => value> pairs.  The options available
are:

=over 24

=item C<< debug => 0 or 1 >>

If set to a true value, debug messages to be printed to STDERR.

=item C<< show_xml => 0 or 1 >>

If set to a true value, the XML fetched during each request will printed
to STDERR.  The C<debug> option must also be set to true for the XML to
print.

=back

Returns a blessed hashref (object) for Net::iTMS::Request.

=cut
sub new {
    my ($class, %opt) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent('iTunes/4.2 (Macintosh; U; PPC Mac OS X 10.2)');
    
    return bless {
        error   => '',
        debug   => defined $opt{debug} ? $opt{debug} : 0,
        show_xml=> defined $opt{show_xml} ? $opt{show_xml} : 0,
        _ua     => $ua,
        _parser => 'XML::Twig',
        _url    => {
            search => 'http://phobos.apple.com/WebObjects/MZSearch.woa/wa/com.apple.jingle.search.DirectAction/search?term=',
            viewAlbum => 'http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wa/viewAlbum?playlistId=',
            advancedSearch => 'http://phobos.apple.com/WebObjects/MZSearch.woa/wa/advancedSearchResults?',
            # Albums ordered by best-sellers
            viewArtist => 'http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wa/viewArtist?sortMode=2&artistId=',
            biography => 'http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wa/com.apple.jingle.app.store.DirectAction/biography?artistId=',
            influencers => 'http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wa/com.apple.jingle.app.store.DirectAction/influencers?artistId=',
            browseArtist => 'http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wa/com.apple.jingle.app.store.DirectAction/browseArtist?artistId=',
        },
    }, $class;
}

=item C<< url($url, [$append ,[{ gunzip => 1, decrypt => 0 }]]) >>

This is one of the lower-level methods used internally.

It takes a URL (that should be for the iTMS) as the first argument.
If the first argument does NOT start with "http", then it will
be taken as a key to the internal hash of URLs (C<< $request->{_url} >>)
and the appropriate stored URL will be used.

The optional second argument is appended to the URL; this is useful
pretty much only when the first argument isn't a real URL and you
want to append query values to the end of the stored URL.

The optional third argument is a hashref of options.  In most cases
it is not needed, however, the available options are:

=over 24

=item C<< gunzip => 0 or 1 >>

A true value means the (presumably) gzipped content is gunzipped.  A false
value means it is not.

Default is 1 (unzip content).

=item C<< decrypt => 0, 1, or 2 >>

A true value other than 2 means the content retrieved from the URL is first
decrypted after fetching if it appears to be encrypted (that is, if no
initialization vector was passed as a response header for the request).
A false value means no decryption is done at all.  A value of 2 means
decryption will be forced no matter what.

Default is 1 ("intelligent" decrypt), which should work for most, if not all,
cases.

=back

=cut
sub url {
    my ($self, $url, $args) = @_;
    
    my $opt = defined $_[3] ? $_[3] : { };
    
    $url = $self->{_url}->{$url}
        unless $url =~ /^http/;
    
    if (defined $args) {
        if (ref $args eq 'HASH') {
            my $i = 0;
            for my $key (keys %$args) {
                $url .= ($i < 1 ? "" : "&")
                        . URI::Escape::uri_escape($key)
                        . "="
                        . URI::Escape::uri_escape($args->{$key});
                $i++;
            }
        }
        else {
            $url .= URI::Escape::uri_escape($args);
        }
    }
    
    my $xml = $self->_fetch_data($url, $opt)
                or return undef;
    
    $self->_debug($xml)
        if $self->{show_xml};
    $self->_debug("Parsing $url");
    
    return $self->{_parser}->new->parse($xml)
                || $self->_set_error('Error parsing XML!');
}

sub _fetch_data {
    my ($self, $url, $userOpt) = @_;
    
    return $self->_set_error('No URL specified!')
            if not $url;
    
    $self->_debug('URL: ' . $url);
    
    my $opt = { gunzip => 1, decrypt => 1 };
    if (defined $userOpt) {
        for (qw/gunzip decrypt/) {
            $opt->{$_} = $userOpt->{$_} if exists $userOpt->{$_};
        }
    }
    
    $self->_debug('Sending HTTP request...');
    # Create and send request
    my $req = HTTP::Request->new(GET => $url);
    $self->_set_request_headers($req);
    
    my $res = $self->{_ua}->request($req);

    if (not $res->is_success) {
        return $self->_set_error('HTTP request failed!' . "\n\n" . $req->as_string);
    }

    $self->_debug('Successful request!');
    
    if ($opt->{decrypt}) {
        $self->_debug('Decrypting content...');
        
        # Since the key is static, we can just hard-code it here
        my $iTunesKey = pack 'H*', '8a9dad399fb014c131be611820d78895';

        #
        # Create the AES CBC decryption object using the iTunes key and the
        # initialization vector (x-apple-crypto-iv)
        #
        my $cbc = Crypt::CBC->new({
                        key             => $iTunesKey,
                        cipher          => 'Rijndael',
                        iv              => pack ('H*', $res->header('x-apple-crypto-iv')),
                        regenerate_key  => 0,
                        padding         => 'standard',
                        prepend_iv      => 0,
                  });

        # Try to intelligently determine whether content is actually
        # encrypted.  If it isn't, skip the decryption unless the caller
        # explicitly wants us to decrypt (the decrypt option = 2).
        
        my $decrypted;
        
        if ($opt->{decrypt} == 2 or $res->header('x-apple-crypto-iv')) {
            $decrypted = $cbc->decrypt($res->content);
        } else {
            $self->_debug('  Content looks unencrypted... skipping decryption');
            $decrypted = $res->content;
        }

        if ($opt->{gunzip}) {
            $self->_debug('Uncompressing content...');

            return $self->_gunzip_data($decrypted);
        } else {
            return $decrypted;
        }
    }
    elsif ($opt->{gunzip}) {
        $self->_debug('Uncompressing content...');
        
        return $self->_gunzip_data($res->content);
    }
    else {
        return $res->content;
    }
}

sub _gunzip_data {
    my ($self, $data) = @_;
    
    # Use Compress::Zlib to decompress it
    use Compress::Zlib qw();
    
    my $xml = Compress::Zlib::memGunzip($data);

    if (not defined $xml) {
        return $self->_set_error('Error while uncompressing gzipped data: "',
                                    $Compress::Zlib::gzerrno, '"');
    }

    return $xml;
}

sub _set_request_headers {
    my $req = $_[1];
    $req->header('Accept-Language'  => 'en-us, en;q=0.50');
    $req->header('Cookie'           => 'countryVerified=1');
    $req->header('Accept-Encoding'  => 'gzip, x-aes-cbc');
}

=back

=head1 LICENSE

Copyright 2004, Thomas R. Sibley.

You may use, modify, and distribute this package under the same terms as Perl itself.

=head1 AUTHOR

Thomas R. Sibley, L<http://zulutango.org:82/>

=head1 SEE ALSO

L<Net::iTMS>, L<XML::Twig>

=cut

42;

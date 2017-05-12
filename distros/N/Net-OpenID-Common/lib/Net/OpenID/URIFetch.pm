#!/usr/bin/perl

=head1 NAME

Net::OpenID::URIFetch - fetch and cache content from HTTP URLs

=head1 VERSION

version 1.20

=head1 DESCRIPTION

This is roughly based on Ben Trott's URI::Fetch module, but
URI::Fetch doesn't cache enough headers that Yadis can be implemented
with it, so this is a lame copy altered to allow Yadis support.

Hopefully one day URI::Fetch can be modified to do what we need and
this can go away.

This module is tailored to the needs of Net::OpenID::Consumer and probably
isn't much use outside of it. See URI::Fetch for a more general module.

=cut

package Net::OpenID::URIFetch;
$Net::OpenID::URIFetch::VERSION = '1.20';
use HTTP::Request;
use HTTP::Status;
use strict;
use warnings;
use Carp();

use constant URI_OK                => 200;
use constant URI_MOVED_PERMANENTLY => 301;
use constant URI_NOT_MODIFIED      => 304;
use constant URI_GONE              => 410;

# Fetch a document, either from cache or from a server
#    URI -- location of document
#    CONSUMER -- where to find user-agent and cache
#    CONTENT_HOOK -- applied to freshly-retrieved document
#      to normalize it into some particular format/structure
#    PREFIX -- used as part of the cache key, distinguishes
#      different content formats and must change whenever
#      CONTENT_HOOK is switched to a new format; this way,
#      cache entries from a previous run of this server that
#      are using a different content format will not kill us.
sub fetch {
    my ($class, $uri, $consumer, $content_hook, $prefix) = @_;
    $prefix ||= '';

    if ($uri eq 'x-xrds-location') {
        Carp::confess("Buh?");
    }

    my $ua = $consumer->ua;
    my $cache = $consumer->cache;
    my $ref;

    my $cache_key = "URIFetch:${prefix}:${uri}";

    if ($cache) {
        if (my $blob = $cache->get($cache_key)) {
            $ref = Storable::thaw($blob);
        }
    }
    my $cached_response = sub {
        return Net::OpenID::URIFetch::Response->new(
            status => 200,
            content => $ref->{Content},
            last_modified => $ref->{LastModified},
            headers => $ref->{Headers},
            final_uri => $ref->{FinalURI},
        );
    };

    # We just serve anything from the last 60 seconds right out of the cache,
    # thus avoiding doing several requests to the same URL when we do
    # Yadis, then HTML discovery.
    # TODO: Make this tunable?
    if ($ref && $ref->{CacheTime} > (time() - 60)) {
        $consumer->_debug("Cache HIT for $uri");
        return $cached_response->();
    }
    else {
        $consumer->_debug("Cache MISS for $uri");
    }

    my $req = HTTP::Request->new(GET => $uri);
    $req->header('Accept-Encoding', scalar HTTP::Message::decodable());
    if ($ref) {
        if (my $etag = ($ref->{Headers}->{etag})) {
            $req->header('If-None-Match', $etag);
        }
        if (my $ts = $ref->{LastModified}) {
            $req->if_modified_since($ts);
        }
    }

    my $res = $ua->request($req);

    # There are only a few headers that OpenID/Yadis care about
    my @useful_headers = qw(last-modified etag content-type x-yadis-location x-xrds-location);

    my %response_fields;

    if ($res->code == HTTP::Status::RC_NOT_MODIFIED()) {
        $consumer->_debug("Server says it's not modified. Serving from cache.");
        return $cached_response->();
    }
    else {
        my $final_uri = $res->request->uri->as_string();
        my $final_cache_key = "URIFetch:${prefix}:${final_uri}";

        my $content = $res->decoded_content             # Decode content-encoding and charset
            || $res->decoded_content(charset => 'none') # Decode content-encoding
            || $res->content;                           # Undecoded content

        if ($content_hook) {
            $content_hook->(\$content);
        }

        my $headers = {};
        foreach my $k (@useful_headers) {
            $headers->{$k} = $res->header($k);
        }

        my $ret = Net::OpenID::URIFetch::Response->new(
            status => $res->code,
            last_modified => $res->last_modified,
            content => $content,
            headers => $headers,
            final_uri => $final_uri,
        );

        if ($cache && $res->code == 200) {
            my $cache_data = {
                LastModified => $ret->last_modified,
                Headers => $ret->headers,
                Content => $ret->content,
                CacheTime => time(),
                FinalURI => $final_uri,
            };
            my $cache_blob = Storable::freeze($cache_data);
            $cache->set($final_cache_key, $cache_blob);
            $cache->set($cache_key, $cache_blob);
        }

        return $ret;
    }

}

package Net::OpenID::URIFetch::Response;
$Net::OpenID::URIFetch::Response::VERSION = '1.20';
use strict;
use constant FIELDS => [qw(final_uri status content headers last_modified)];
use fields @{FIELDS()};
use Carp();

sub new {
    my ($class, %opts) = @_;
    my $self = fields::new($class);
    @{$self}{@{FIELDS()}} = delete @opts{@{FIELDS()}};
    Carp::croak("Unknown option(s): " . join(", ", keys %opts)) if %opts;
    return $self;
}

BEGIN {
    foreach my $field_name (@{FIELDS()}) {
        no strict 'refs';
        *{__PACKAGE__ . '::' . $field_name}
          = sub { return $_[0]->{$field_name}; };
    }
}

sub header {
    return $_[0]->{headers}{lc($_[1])};
}

1;

package Plack::Middleware::ESI;
use strict;
use warnings;
our $VERSION = '0.1';
use parent qw(Plack::Middleware);
use Plack::Util;
use Plack::Request;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Message::PSGI;

sub call {
    my ($self, $env) = @_;
    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = shift;
        my $h = Plack::Util::headers($res->[1]);
        my $r = Plack::Request->new($env);
        my $ct = $h->get('Content-Type');
        if ($ct =~ /^text\// || $ct =~ /^application\/xh?t?ml\b/) { #"{}
            return sub {
                my $chunk = shift;
                return unless defined $chunk;
                return $self->_process_esi($chunk, $r);
            };
        }
    });
}

sub _process_esi {
    my ($self, $chunk, $r) = @_;
    my $chk_rx = qr{<esi:|<!--esi}; #"{}
    return $chunk unless $chunk =~ $chk_rx;
    my $rem_rx = qr{<esi:remove>.*?</esi:remove>}; #"{}
    my $cmt_rx = qr{<!--esi\s(.*?)-->}; #"{}
    my $inc_rx = qr{(<esi:include[^>]+?src="([^"]+)"[^>]*/>)}; #"{}
    $chunk =~ s/$rem_rx//gs;
    $chunk =~ s/$cmt_rx/$1/gs;
	while ($chunk =~ $inc_rx) {
		my $esi = $1;
		my $url = $2;
        my $content = $self->_get_content($url, $r);
        $chunk =~ s/\Q$esi\E/$content/g;
	}
    return $chunk;
}

sub _expand_url {
    my ($self, $url, $r) = @_;
    my $prefix = $r->scheme . '://localhost:' . $r->port;
    if ($url =~ m{^/}) {
        return $prefix . $url;
    }
    else {
        my $path = $r->path;
        $path .= '/' unless $path =~ /\/$/;
        return $prefix . $path . $url;
    }
}

sub _get_content {
    my ($self, $url, $r) = @_;
    my $expanded_url = $url;
    unless ($url =~ m{^https?://}) {
        $expanded_url = $self->_expand_url($url, $r);
    }
    my $content = '';
    eval {
        if ($url ne $expanded_url) { # internal request
            my $httpreq = HTTP::Request->new(GET=>$url);
            $httpreq->uri->scheme('http') unless defined $httpreq->uri->scheme;
            $httpreq->uri->host('localhost') unless defined $httpreq->uri->host;
            my $reqenv = $httpreq->to_psgi;
            my $resp = HTTP::Response->from_psgi($self->app->($reqenv));
            $resp->request($httpreq);
            $content = $resp->content if $resp->code == 200;
        }
        unless ($content) { # external request (or retrying an apparently internal req)
            my $resp = $self->_ua->get($expanded_url);
            if ($resp->code == 200) {
                $content = $resp->content;
            }
            elsif ($r->logger) {
                $r->logger->({level=>'warning', message=>"ESI: URL $expanded_url returned non-OK status code " . $resp->code});
            }
        }
    };
    if ($@) {
        if ($r->logger) {
            $r->logger->({level=>'warning', message=>"ESI: ERROR while fetching $url: $@"});
        }
    }
    return $content;
}

sub _ua {
    my $self = shift;
    return $self->{_ua} if $self->{_ua};
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $self->{_ua} = $ua;
    return $ua;
}


1;

__END__

=pod

=head1 NAME

Plack::Middleware::ESI - PSGI middleware for Edge Side Includes (ESI)

=head1 VERSION

version 0.1

=head1 SYNOPSIS

  use Plack::Builder;

  my $app = sub {
      return [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [
          "The Google front page as plaintext: ",
          '<esi:include src="http://google.com/" />',
          "And a local request might be nice: ",
          '<esi:include src="/userinfo/" />',
        ]
      ];
  };

  builder {
      enable "ESI";
      $app;
  };

=head1 DESCRIPTION

This module provides rudimentary support for using Edge Side Includes in PSGI
applications.

The primary aim is to support the same subset of features as the Varnish
caching proxy server. Essentially, this means support for three ESI tags:

=over 4

=item

C<<esi:include src="..." /E<gt>> - Include the contents of a remote or a local
URL. Please note that the C<alt> and C<onerror> attributes are not supported.

=item

C<<esi:removeE<gt>...</esi:removeE<gt>> - Remove a section of the document.

=item

C<<!--esi ...--E<gt>> - Unhide whataver is inside the HTML/XML comment
(which is normally the result of applying an ESI include tag).

=back

The module only filters responses with a Content-Type of C<text/*>,
C<application/xml>, or C<application/xhtml+xml>. This obviously means that the
Content-Type output header must have been set further down in the middleware
stack (or, of course, in the original PSGI app itself), before the ESI
middleware is applied.

=head1 AUTHOR

Baldur Kristinsson <bk@mbl.is>

=head1 SEE ALSO

=over 4

=item

Varnish ESI support: L<http://www.varnish-cache.org/trac/wiki/ESIfeatures>

=item

ESI 1.0 Specification: L<http://www.w3.org/TR/esi-lang>

=back

=cut
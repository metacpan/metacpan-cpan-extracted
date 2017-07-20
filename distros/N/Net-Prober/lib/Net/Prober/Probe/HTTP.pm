package Net::Prober::Probe::HTTP;
$Net::Prober::Probe::HTTP::VERSION = '0.17';
use strict;
use warnings;

use base 'Net::Prober::Probe::TCP';

use Carp ();
use Digest::MD5 ();
use LWPx::ParanoidAgent ();

sub defaults {
    my ($self) = @_;
    my $defaults = $self->SUPER::defaults;

    my %http_defaults = (
        %{ $defaults },
        headers      => undef,
        md5          => undef,
        method       => 'GET',
        port         => 80,
        scheme       => 'http',
        url          => '/',
        match        => undef,
        body         => undef,
        up_status_re => '^[23]\d\d$',
    );

    return \%http_defaults;
}

sub agent {

    my $ua = LWPx::ParanoidAgent->new();
    my $ver = $Net::Prober::VERSION || 'dev';
    $ua->agent("Net::Prober/$ver");
    $ua->max_redirect(0);

    return $ua;
}

sub _prepare_request {
    my ($self, $args) = @_;

    my ($host, $port, $timeout, $scheme, $url, $method, $body, $headers) =
        $self->parse_args($args, qw(host port timeout scheme url method body headers));

    $method ||= "GET";

    if (defined $scheme) {
        if ($scheme eq 'http') {
            $port ||= 80;
        }
        elsif ($scheme eq 'https') {
            $port ||= 443;
        }
    }

    if (defined $port) {
        $scheme = $port == 443 ? "https" : "http";
    }

    $url =~ s{^/+}{};

    # We don't want to add :80 or :443 because some pesky Asian CDN
    # doesn't like when Host header contains those default ports
    my $probe_url = "$scheme://$host/$url";
    if ($port != 80 && $port != 443) {
        $probe_url = "$scheme://$host:$port/$url";
    }

    my @req_args = ($method, $probe_url);

    if ($headers && ref $headers eq "ARRAY") {
        my $req_headers = HTTP::Headers->new();
        $req_headers->header(@{ $headers });
        push @req_args, $req_headers;
    }

    if ($body) {
        push @req_args, $body;
    }

    return HTTP::Request->new(@req_args);
}

sub probe {
    my ($self, $args) = @_;

    my ($expected_md5, $content_match, $up_status_re, $timeout) =
        $self->parse_args($args, qw(md5 match up_status_re timeout));

    $self->time_now();

    my $ua = $self->agent();

    if (defined $timeout && $timeout > 0) {
        $ua->timeout($timeout);
    }

    my $req = $self->_prepare_request($args);

    # Fire in the hole!
    my $resp = $ua->request($req);

    my $elapsed = $self->time_elapsed();
    my $content = $resp->content();
    my $status = $resp->code();

    my $good = 0;
    my $reason;

    if (! $up_status_re || ! defined $status || ! $status) {
        $good = $resp->is_redirect() || $resp->is_success();
        if (! $good) {
            $reason = "Response HTTP status code wasn't successful (2xx or 3xx)";
        }
    }
    elsif ($up_status_re && defined $status) {
        my $match_re;
        eval {
            $match_re = qr{$up_status_re}ms;
        } or do {
            Carp::croak("Invalid regex for HTTP status match '$up_status_re'\n");
        };
        $good = $status =~ $match_re;
        if (! $good) {
            $reason = "Response HTTP status code didn't match the specified regex ('$up_status_re')";
        }
    }

    if ($good and defined $expected_md5) {
        my $md5 = Digest::MD5::md5_hex($content);
        if ($md5 ne $expected_md5) {
            $good = 0;
            $reason = "Response body MD5 sum wasn't the expected ($expected_md5)";
        }
    }

    if ($good and defined $content_match) {
        my $match_re;
        eval {
            $match_re = qr{$content_match}ms;
        } or do {
            Carp::croak("Invalid regex for http content match '$content_match'\n");
        };
        if ($content !~ $match_re) {
            $good = 0;
            $reason = "Content didn't match the specified '$content_match' regex";
        }
    }

    my %status = (
        status => $resp->status_line,
        content => $content,
        elapsed => $elapsed,
    );

    my $md5 = $content
        ? Digest::MD5::md5_hex($content)
        : undef;

    $status{md5} = $md5 if $md5;
    $status{reason} = $reason if defined $reason;

    if ($good) {
        return $self->probe_ok(%status);
    }

    return $self->probe_failed(%status);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Prober::Probe::HTTP

=head1 VERSION

version 0.17

=head1 AUTHOR

Cosimo Streppone <cosimo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Cosimo Streppone.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

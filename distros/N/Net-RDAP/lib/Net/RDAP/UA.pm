package Net::RDAP::UA;
use base qw(LWP::UserAgent);
use File::stat;
use File::Slurp;
use HTTP::Date;
use HTTP::Request::Common;
use Mozilla::CA;
use constant DEFAULT_CACHE_TTL => 300;
use vars qw($DEBUG);
use strict;
use warnings;

$DEBUG = exists($ENV{'NET_RDAP_UA_DEBUG'});

#
# create a new object, which is just an LWP::UserAgent with
# some additional options set by default
#
sub new {
    my ($package, %options) = @_;

    $options{'agent'} = sprintf('%s/%f', $package, $Net::RDAP::VERSION) unless (exists($options{'agent'}));
    $options{'ssl_opts'} = {}                                           unless (exists($options{'ssl_opts'}));
    $options{'ssl_opts'}->{'verify_hostname'} = 1                       unless (exists($options{'ssl_opts'}->{'verify_hostname'}));
    $options{'ssl_opts'}->{'SSL_ca_file'} = Mozilla::CA::SSL_ca_file()  unless (exists($options{'ssl_opts'}->{'SSL_ca_file'}));

    return bless($package->SUPER::new(%options), $package);
}

sub request {
    my $self = shift;

    print STDERR $_[0]->as_string if ($DEBUG);

    my $response = $self->SUPER::request(@_);

    print STDERR $response->as_string."\n" if ($DEBUG);

    return $response;
}

#
# usage: $ua->mirror($url, $file, $ttl, $accept_language);
#
# this re-implements the parent mirror() method to avoid a network roundtrip if
# a locally-cached copy of the resource is less than $ttl seconds old.
#
sub mirror {
    my ($self, $url, $file, $ttl, $accept_language) = @_;

    my $response;

    my $request = GET($url);
    $request->header('Accept-Language' => $accept_language) if ($accept_language);

    if (-e $file && time() < stat($file)->mtime + (defined($ttl) ? $ttl : DEFAULT_CACHE_TTL)) {
        print STDERR $request->as_string if (exists($ENV{NET_RDAP_UA_DEBUG}));

        $response = HTTP::Response->new(304);
        $response->header(q{X-Internally-Generated} => q{true});

        print STDERR $response->as_string if (exists($ENV{NET_RDAP_UA_DEBUG}));

    } else {
        $request->header(q{If-Modified-Since} => HTTP::Date::time2str(stat($file)->mtime)) if (-e $file && $ttl > 0);

        $response = $self->request($request);

        if (200 == $response->code) {
            write_file($file, $response->decoded_content);
            chmod(0600, $file);

        } elsif (304 == $response->code) {
            my $mtime = time();

            foreach my $header (qw(expires date)) {
                if ($response->header($header)) {
                    my $time = HTTP::Date::str2time($response->header($header));
                    if (defined($time)) {
                        $mtime = $time;
                        last;
                    }
                }
            }

            utime($mtime, $mtime, $file);
            chmod(0600, $file);
        }
    }

    return $response;
}

1;

__END__

=pod

=head1 NAME

L<Net::RDAP::UA> - a module which provides an RDAP user agent, based on
L<LWP::UserAgent>.

=head1 DESCRIPTION

This module extends L<LWP::UserAgent> in order to inject various
RDAP-related configuration settings and HTTP request headers. Nothing
should ever need to use it.

=head1 DEBUGGING HTTP TRANSACTIONS

If you ever want to see what L<Net::RDAP::UA> sends and receives, set the
L<Net::RDAP::UA::DEBUG> variable to a true value, or set the
C<NET_RDAP_UA_DEBUG> environment variable. This will cause all HTTP requests
and responses to be printed to C<STDERR>.

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024-2025 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

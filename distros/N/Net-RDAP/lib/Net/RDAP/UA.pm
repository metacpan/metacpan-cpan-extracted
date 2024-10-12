package Net::RDAP::UA;
use base qw(LWP::UserAgent);
use Carp;
use File::stat;
use HTTP::Date;
use Mozilla::CA;
use constant DEFAULT_CACHE_TTL => 300;
use strict;
use warnings;

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

#
# usage: $ua->mirror($url, $file, $ttl);
#
# this overrides the parent mirror() method to avoid a network roundtrip if a
# locally-cached copy of the resource is less than $ttl seconds old. If not
# provided, the default value for $ttl is 300 seconds.
#
sub mirror {
    my ($self, $url, $file, $ttl) = @_;

    if (-e $file) {
        my $expires = stat($file)->mtime + ($ttl || DEFAULT_CACHE_TTL);
        return HTTP::Response->new(304) unless (time() > $expires);
    }

    my $response;

    eval {
        $response = $self->SUPER::mirror($url, $file);
    };

    if ($@) {
        chomp($@);
        carp($@);
        return HTTP::Response->new(500, $@);
    }

    carp($response->status_line) unless ($response->is_success || 304 == $response->code);

    if (-e $file) {
        my $mtime = time();

        foreach my $header (qw(expires date)) {
            if ($response->header($header)) {
                my $time = HTTP::Date->str2time($response->header($header));
                if (defined($time)) {
                    $mtime = $time;
                    last;
                }
            }
        }

        utime(undef, $mtime, $file);
        chmod(0600, $file);
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

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

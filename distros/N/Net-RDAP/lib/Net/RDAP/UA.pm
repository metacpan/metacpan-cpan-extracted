package Net::RDAP::UA;
use base qw(LWP::UserAgent);
use Carp;
use File::stat;
use HTTP::Date;
use Mozilla::CA;
use constant DEFAULT_CACHE_TTL => 300;
use strict;

#
# create a new object, which is just an LWP::UserAgent with
# some additional options set by default
#
sub new {
    my ($package, %options) = @_;

    $options{'agent'} = sprintf('%s/%f', $package, $Net::RDAP::VERSION)     unless (defined($options{'agent'}));
    $options{'ssl_opts'} = {}                                               unless (defined($options{'ssl_opts'}));
    $options{'ssl_opts'}->{'verify_hostname'} = 1                           unless (defined($options{'ssl_opts'}->{'verify_hostname'}));
    $options{'ssl_opts'}->{'SSL_ca_file'} = Mozilla::CA::SSL_ca_file()      unless (defined($options{'ssl_opts'}->{'SSL_ca_file'}));

    return bless($package->SUPER::new(%options), $package);
}

#
# usage: $ua->mirror($url, $file, $ttl);
#
# this overrides the parent mirror() method to avoid a network roundtrip if a locally-
# cached copy of the resource is less than $ttl seconds old. If not provided, the default
# value for $ttl is 300 seconds.
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
        my $mtime = (HTTP::Date->str2time($response->header('Expires') || $response->header('Date')) || time());
        utime(undef, $mtime, $file);
        chmod(0600, $file);
    }

    return $response;
}

1;

__END__

=pod

=head1 NAME

L<Net::RDAP::UA> - an RDAP user agent, based on L<LWP::UserAgent>.

=head1 DESCRIPTION

This module extends L<LWP::UserAgent> in order to inject various
RDAP-related configuration settings and HTTP request headers. Nothing
should ever need to use it.

=head1 COPYRIGHT

Copyright CentralNic Ltd. All rights reserved.

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

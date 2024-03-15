package Net::RDAP::Registry;
use Carp qw(croak);
use File::Basename qw(basename);
use File::Slurp;
use File::Spec;
use File::stat;
use JSON;
use Net::RDAP::UA;
use Net::RDAP::Registry::IANARegistry;
use vars qw($UA $REGISTRY);
use constant {
    IP4_URL             => 'https://data.iana.org/rdap/ipv4.json',
    IP6_URL             => 'https://data.iana.org/rdap/ipv6.json',
    DNS_URL             => 'https://data.iana.org/rdap/dns.json',
    ASN_URL             => 'https://data.iana.org/rdap/asn.json',
    TAG_URL             => 'https://data.iana.org/rdap/object-tags.json',
    CACHE_TTL           => 86400,
};
use strict;

our $UA;

our $REGISTRY = {};

=pod

=head1 NAME

L<Net::RDAP::Registry> - an interface to the IANA RDAP registries.

=head1 SYNOPSIS

    use Net::RDAP::Registry;
    use Net::IP;
    use Net::ASN;

    $url = Net::RDAP::Registry->get_url(Net::DNS::Domain->new('example.com'));
    $url = Net::RDAP::Registry->get_url(Net::IP->new('192.168.0.1'));
    $url = Net::RDAP::Registry->get_url(Net::IP->new('2001:DB8::/32'));
    $url = Net::RDAP::Registry->get_url(Net::ASN->new(65536));
    $url = Net::RDAP::Registry->get_url('ABC123-TAG');

=head1 DESCRIPTION

RFC 7484 describes how RDAP clients can find the authoritative RDAP
service for a given internet resource using one of several IANA
registries.

This module provides an interface to these registries, and will return
a L<URI> object corresponding to the URL for a resource obtained from
them.

L<Net::RDAP::Registry> downloads the registry files from the IANA
website and will maintain up-to-date copies of those files locally.

=head1 METHODS

    $url = Net::RDAP::Registry->get_url($resource);

This method returns a L<URI> object corresponding to the authoritative
RDAP URL for the given resource. C<$resource> may be one of the
following:

=over

=item * a L<Net::IP> object representing an IPv4 or IPv6 address or
address range;

=item * a L<Net::ASN> object representing an Autonymous System;

=item * a L<Net::DNS::Domain> object representing a domain name.

=item * a string containing a tagged entity handle

=back

This method requires objects to be passed to ensure that the resource
identifiers have been properly validated.

If no URL can be found in the IANA registry, then C<undef> is returned.

=cut

sub get_url {
    my ($package, $object) = @_;

    if ('Net::IP' eq ref($object)) {
        return $package->ip($object);

    } elsif ('Net::ASN' eq ref($object)) {
        return $package->autnum($object);

    } elsif ('Net::DNS::Domain' eq ref($object)) {
        return $package->domain($object);

    } elsif ($object =~ /-/) {
        return $package->entity($object);

    } else {
        croak("Unable to deal with '$object'");

    }
}

#
# get URL for IP
#
sub ip {
    my ($package, $ip) = @_;
    croak(sprintf('Argument to %s->ip() must be a Net::IP', $package)) unless ('Net::IP' eq ref($ip));

    my $registry = $package->load_registry(4 == $ip->version ? IP4_URL : IP6_URL);
    return undef if (!$registry);

    my %matches;
    SERVICE: foreach my $service ($registry->services) {
        VALUE: foreach my $value ($service->registries) {
            my $range = Net::IP->new($value);

            if ($range->overlaps($ip)) {
                $matches{$value} = $package->get_best_url($service->urls);
                last VALUE;
            }
        }
    }

    return undef if (scalar(keys(%matches)) < 1);

    # prefer the service with the longest prefix length
    my $longest = (sort { Net::IP->new($b)->prefixlen <=> Net::IP->new($a)->prefixlen } keys(%matches))[0];

    return $package->assemble_url($matches{$longest}, 'ip', split(/\//, $ip->prefix));
}

#
# get URL for AS Number
#
sub autnum {
    my ($package, $autnum) = @_;
    croak(sprintf('Argument to %s->autnum() must be a Net::ASN', $package)) unless ('Net::ASN' eq ref($autnum));

    my $registry = $package->load_registry(ASN_URL);
    return undef if (!$registry);

    my %matches;
    SERVICE: foreach my $service ($registry->services) {
        VALUE: foreach my $value ($service->registries) {
            if ($value == $autnum->toasplain) {
                # exact match, create an entry for NNNN-NNNN where both sides are
                # the same (simplifies sorting later)
                $matches{sprintf('%d-%d', $value, $value)} = $package->get_best_url($service->urls);
                last SERVICE;

            } elsif ($value =~ /^(\d+)-(\d+)$/) {
                if ($1 <= $autnum->toasplain && $autnum->toasplain <= $2) {
                    $matches{sprintf('%d-%d', $value, $value)} = $package->get_best_url($service->urls);
                    last VALUE;
                }
            }
        }
    }

    return undef if (scalar(keys(%matches)) < 1);

    my @ranges = keys(%matches);

    # convert array of NNNN-NNNN strings to array of array refs
    my @pairs = map { [ split(/-/, $_, 2) ] } @ranges;

    # sort by descending order of the "width" of the range
    my @sorted = sort { $b->{1} - $b->{0} <=> $a->{1} - $a->{0} } @pairs;

    # prefer the narrowest (more specific) range
    my $closest = sprintf('%d-%d', @{$sorted[0]});

    return $package->assemble_url($matches{$closest}, 'autnum', $autnum->toasplain);
}

#
# get URL for domain
#
sub domain {
    my ($package, $domain) = @_;
    croak(sprintf('Argument to %s->domain() must be a Net::DNS::Domain', $package)) unless ('Net::DNS::Domain' eq ref($domain));

    my $is_tld = (1 == scalar($domain->label));

    my $registry = $package->load_registry(DNS_URL);
    return undef if (!$registry);

    my %matches;
    SERVICE: foreach my $service ($registry->services) {
        VALUE: foreach my $value ($service->registries) {

            if ($is_tld && '' eq $value) {
                #
                # the RDAP server for the root zone is identified by an empty
                # string (see RFC 9224 § 4):
                #
                $matches{$value} = $package->get_best_url($service->urls);

                last VALUE;

            } else {
                if ($domain->name =~ /\.$value$/i) {
                    $matches{$value} = $package->get_best_url($service->urls);

                    last VALUE;
                }
            }
        }
    }

    if (scalar(keys(%matches)) < 1) {
        if ($domain->name =~ /\.(in-addr|ip6)\.arpa$/) {
            # special workaround for the lack of .arpa in the RDAP registry
            return $package->reverse_domain($domain);

        } else {
            return undef;

        }

    } else {
        # prefer the service with the longest domain name
        my $parent = (sort { length($b) <=> length($a) } keys(%matches))[0];

        return $package->assemble_url($matches{$parent}, 'domain', $domain->name);
    }
}

#
# construct the RDAP URL for a reverse domain. as of writing there's
# nothing in the IANA registry for the reverse tree so we work around
# that by by constructing the CIDR prefix that corresponds to the
# domain, resolving the RDAP URL for that, and then munging it to
# obtain the URL for the domain. clever, eh?
#
sub reverse_domain {
    my ($package, $domain) = @_;

    my @labels = reverse($domain->label);
    shift(@labels); # discard 'arpa'

    my $ip;
    if ('ip6' eq shift(@labels)) {
        # @labels is an array of hex digits, we want an array of 4-hex digit parts
        my @parts;
        push(@parts, join('', splice(@labels, 0, 4))) while (scalar(@labels) > 0);

        # remove any trailing parts that are zero
        pop(@parts) while (0 == hex($parts[-1]));

        # compute prefix length
        my $prefixlen = 16 * (scalar(@parts));

        $ip = Net::IP->new(sprintf(
            '%s:%s:%s:%s:%s:%s:%s:%s/%u',
            shift(@parts) || 0,
            shift(@parts) || 0,
            shift(@parts) || 0,
            shift(@parts) || 0,
            shift(@parts) || 0,
            shift(@parts) || 0,
            shift(@parts) || 0,
            shift(@parts) || 0,
            $prefixlen,
        ));

    } else {
        pop(@labels) while (0 == $labels[-1]);

        my $prefixlen = 8 * (scalar(@labels));

        $ip = Net::IP->new(sprintf(
            '%u.%u.%u.%u/%u',
            shift(@labels) || 0,
            shift(@labels) || 0,
            shift(@labels) || 0,
            shift(@labels) || 0,
            $prefixlen,
        ));
    }

    return undef if (!$ip);

    my $url = $package->ip($ip);

    return undef if (!$url);

    return URI->new_abs(sprintf('../../domain/%s', $domain->name), $url);
}

#
# get URL for a tagged entity
#
sub entity {
    my ($package, $handle) = @_;

    my @parts = split(/-/, $handle);
    my $tag = pop(@parts);

    my $registry = $package->load_registry(TAG_URL);
    return undef if (!$registry);

    foreach my $service ($registry->services) {
        foreach my $value ($service->registries) {
            # unlike the other registries we are only looking for an exact match, as there is no hierarchy:
            return $package->assemble_url($package->get_best_url($service->urls), 'entity', $handle) if (lc($value) eq lc($tag));
        }
    }

    return undef;
}

#
# load a registry. uses (in order of preference) an in-memory cache, a JSON file on disk,
# or a resource on the IANA website. returns a Net::RDAP::Registry::IANARegistry object
# (or undef)
#
sub load_registry {
    my ($package, $url) = @_;

    if (!defined($REGISTRY->{$url})) {
        $package =~ s/:+/-/g;

        my $file = sprintf('%s/%s-%s', File::Spec->tmpdir, $package, basename($url));

        #
        # $UA may have been injected by Net::RDAP->ua()
        #
        $UA = Net::RDAP::UA->new unless(defined($UA));

        $UA->mirror($url, $file, CACHE_TTL);

        $REGISTRY->{$url} = Net::RDAP::Registry::IANARegistry->new(from_json(read_file($file))) if (-e $file);
    }

    return $REGISTRY->{$url};
}

#
# RDAP services can have multiple URLs, we pick the best by
# simply preferring the first one with the "https" scheme.
#
sub get_best_url {
    my ($package, @urls) = @_;

    my @https = grep { 'https' eq lc($_->scheme) } @urls;

    if (scalar(@https)) {
        return shift(@https);

    } else {
        return shift(@urls);

    }
}

#
# concatenate a URL with a bunch of path segments
# this method deals with URI objects which have
# trailing slashes
#
sub assemble_url {
    my ($package, $url, @segments) = @_;

    $url->path_segments(grep { length > 0 } ($url->path_segments, @segments));

    return $url;
}

1;

__END__

=pod

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

# $Id: Results.pm,v 1.4 2003/07/21 15:37:59 matt Exp $

package Net::SenderBase::Results;
use strict;
use vars qw($AUTOLOAD);

sub cons {
    my $class = shift;
    my ($ip, $data) = @_;

    my $self = bless {}, $class;

    $self->{ip} = $ip;
    $self->{raw_data} = $data;

    $self->parse_data;

    return $self;
}

my %keys = (
    0 => 'version_number',
    1 => 'org_name',
    2 => 'org_daily_magnitude',
    3 => 'org_monthly_magnitude',
    4 => 'org_id',
    5 => 'org_category',
    6 => 'org_first_message',
    7 => 'org_domains_count',
    8 => 'org_ip_controlled_count',
    9 => 'org_ip_used_count',
    10 => 'org_fortune_1000',
    
    20 => 'hostname',
    21 => 'domain_name',
    22 => 'hostname_matches_ip',
    23 => 'domain_daily_magnitude',
    24 => 'domain_monthly_magnitude',
    25 => 'domain_first_message',
    26 => 'domain_rating',
    
    40 => 'ip_daily_magnitude',
    41 => 'ip_monthly_magnitude',
    43 => 'ip_average_magnitude',
    44 => 'ip_30_day_volume_percent',
    45 => 'ip_in_bonded_sender',
    46 => 'ip_cidr_range',
    47 => 'ip_blacklist_score',
    
    50 => 'ip_city',
    51 => 'ip_state',
    52 => 'ip_postal_code',
    53 => 'ip_country',
    54 => 'ip_longitude',
    55 => 'ip_latitude',
);

my %methods = (ip => 1, raw_data => 1, reverse(%keys));

sub parse_data {
    my $self = shift;
    
    foreach my $part (split(/\|/, $self->{raw_data})) {
        my ($key, $value) = split(/=/, $part, 2);
        if (exists($keys{$key})) {
            $self->{$keys{$key}} = $value;
        }
        else {
            # new key - please inform AUTHOR!
            $self->{"key_$key"} = $value;
        }
    }
}

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    die "No such method: $method" unless exists($methods{$method});
    return $self->{$method};
}

1;
__END__

=head1 NAME

Net::SenderBase::Results - Results of a senderbase query

=head1 SYNOPSIS

  print "Results for: ", $results->ip, "\n",
        "Monthly Average Magnitude: ", 
           $results->ip_monthly_magnitude, "\n",
        "Daily Average Magnitude: ",
           $results->ip_daily_magnitude, "\n";

=head1 DESCRIPTION

This module is a read-only results object, giving you access to
the results of a senderbase query. The only way to construct one
of these objects is from a query.

=head1 API

Some of the items here are future enhancements to senderbase that are
not yet implemented. See L<http://www.senderbase.org/dnsresponses.html>
for further details.

=head2 C<ip>

Returns the IP address you queried.

=head2 C<raw_data>

Returns the raw data for the query, as returned by senderbase.

=head2 C<version_number>

The senderbase version number. Supports upgrade path to future
versions of SenderBase DNS responses

=head2 C<org_name>

Organization Name - An entity controlling a group of mail servers and one or many domains

=head2 C<org_daily_magnitude>

A measure of message volume calculated using a log scale with a base of 10. The maximum theoretical value of the scale is set to 10 (100% of the world's message vol.)

=head2 C<org_monthly_magnitude>

Same as Response L</org_daily_magnitude>, except based on monthly percentages instead of daily percentages.

=head2 C<org_id>

10 digit unique numeric identifier for an organization.

=head2 C<org_category>

Category of organization (e.g, ISP, Airline, News, Adult, Commercial Bank, etc). Assigned by IronPort, using external sources like OneSource where appropriate.

=head2 C<org_first_message>

Date as standard UNIX time format (seconds since epoch). (New, high-volume organizations may be suspicious)

=head2 C<org_domains_count>

# of domains closely associated with this organization

=head2 C<org_ip_controlled_count>

# of IP's an organization controls

=head2 C<org_ip_used_count>

Every IP we track in SenderBase that has sent mail and is closely associated with this org

=head2 C<org_fortune_1000>

Either C<"Y"> or C<"N">.

F1000 = less likely to be spam.

=head2 C<hostname>

hostname (just the part preceeding the domain name, e.g., "smtp." in the case of "smtp.ironport.com")

=head2 C<domain_name>

=head2 C<hostname_matches_ip>

Do a reverse then forward DNS lookup. If successful, then C<"Y">, otherwise C<"N">.

=head2 C<domain_daily_magnitude>

Same as L</org_daily_magnitude>, except based on domains.

=head2 C<domain_monthly_magnitude>

Same as L</org_monthly_magnitude>, except based on domains.

=head2 C<domain_first_message>

Date of the first message from this domain. Date is in standard unix time format, i.e. number of seconds since the epoch.

=head2 C<domain_rating>

IronPort's editorial opinion on the quality of mail sent by a domain (Uses scale of AAA, AA, A, similar to credit rating services)

=head2 C<ip_daily_magnitude>

Same as L</org_daily_magnitude>, except based on IPs.

=head2 C<ip_monthly_magnitude>

Same as L</org_monthly_magnitude>, except based on IPs.

=head2 C<ip_average_magnitude>

The average magnitude for this IP since SenderBase began tracking volumes.

=head2 C<ip_30_day_volume_percent>

The last 30 days of volume as a percentage of total historical volume.

=head2 C<ip_in_bonded_sender>

C<"Y"> if the IP address is in bonded sender, otherwise C<"N">. Also
returns C<"Y+"> on some occasions - no idea why ;-)

=head2 C<ip_cidr_range>

The CIDR range associated with this IP in whois.

=head2 C<ip_blacklist_score>

# positive blacklist responses / # blacklists tracked by SenderBase

=head2 C<ip_city>

The city associated with this IP

=head2 C<ip_state>

The US state associated with this IP

=head2 C<ip_postal_code>

The postal code associated with this IP

=head2 C<ip_country>

The country associated with this IP

=head2 C<ip_longitude>

The longitude associated with this IP

=head2 C<ip_latitude>

The latitude associated with this IP

=cut

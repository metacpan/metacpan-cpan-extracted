package Net::DNS::CloudFlare::DDNS;
# ABSTRACT: Object Orientated Dynamic DNS Interface to CloudFlare DNS

use Modern::Perl '2012';
use autodie      ':all';
no  indirect     'fatal';
use namespace::autoclean;

use Moose; use MooseX::StrictConstructor;
use Types::Standard                   qw( Bool Str);
use Net::DNS::CloudFlare::DDNS::Types qw( CloudFlareClient LWPUserAgent);
use TryCatch;
use Carp;
use Readonly;

use List::Util 'shuffle';
# first dotted decimal version and args as hash interface
use CloudFlare::Client 'v0.55.1';

our $VERSION = 'v0.63.1'; # VERSION

has 'verbose' => ( is => 'rw', isa => Bool);
# CF credentials
has '_user' => ( is => 'ro', isa => Str, required => 1, init_arg => 'user');
has '_key' => (  is => 'ro', isa => Str, required => 1, init_arg => 'apikey');
# Configuration of zones, and their domains, to update
has '_config' => ( is  => 'ro', required => 1, init_arg => 'zones');

# Provides CF access
sub _buildApi { CloudFlare::Client::->new( user   => $_[0]->_user,
                                           apikey => $_[0]->_key)}
has '_api' => ( is => 'ro', isa => CloudFlareClient, builder => '_buildApi',
                lazy => 1, init_arg => undef);

# Fetch zone IDs for a single zone
# The api call can fail and this will die
# Returns a map of domain => id
sub _getDomainIds {
    Readonly my $self => shift; Readonly my $zone => shift;

    # Query CloudFlare
    say "Trying domain IDs lookup for $zone" if $self->verbose;
    Readonly my $info => $self->_api->rec_load_all( z => $zone);
    # Filter to just A records and get a list of [domain => id]
    my @pairs = map { $_->{type} eq 'A' ? [ $_->{name} => $_->{rec_id} ]
                                        : () } @{ $info->{recs}{objs}};
    # Localise hostnames to within zone, set zone itself to undef
    map { $_->[0] eq $zone ? $_->[0] = undef : $_->[0] =~ s/\.$zone$//}
        @pairs;

    # Build into a hash of domain => id
    my $map; foreach (@pairs) {
        my ($domain, $id) = @$_;
        carp "Duplicate domain $domain found in $zone - ",
             'this is probably a mistake' if exists $map->{$domain};
        $map->{$domain} = $id}
    return $map
}
# Build a mapping of zones to domain ID mappings from CF
# Zones will be missing if their fetch fails but the show must go on
sub _buildDomIds {
    Readonly my $self => shift;
    # $zone is a hash of config info
    my $map; for my $zone (@{ $self->_config }) {
        Readonly my $name    => $zone->{zone};
        Readonly my $domains => $zone->{domains};
        # Try to fetch domain ids for this zone
        my $zoneMap; try { $zoneMap = $self->_getDomainIds($name)}
        catch (CloudFlare::Client::Exception::Upstream $e) {
            carp "Fetching zone IDs for $name failed because the " ,
                 'CloudFlare API threw an error: ', $e->errorCode, ' ',
                 $e->message}
        catch (CloudFlare::Client::Exception::Connection $e) {
            carp "Fetching zone IDs for $name failed because the " ,
                 'connection to the CloudFlare API failed: ', $e->status, ' ',
                 $e->message}
        # Install ids into map under
        $map->{\$_} = $zoneMap->{$_} foreach @$domains}
    return $map
}
# For storing domain IDs
# A map of domain ref => IP
has '_domIds' => (
    is => 'ro', init_arg => undef,
    # Clear this and use lazy rebuilding to update IDs each run
    clearer => '_clearDomIds', builder => '_buildDomIds', lazy => 1);

# For keeping track of what we last set the IPs to
# A hash of domain ref -> IP
sub _buildLastIps { {} }
has _lastIps => ( is => 'rw', init_arg => undef, builder  => '_buildLastIps');

# Used for fetching the IP
Readonly my $UA_STRING => __PACKAGE__ . "/$VERSION";
sub _buildUa { Readonly my $ua => LWP::UserAgent::->new;
               $ua->agent($UA_STRING);
               return $ua}
has _ua => ( is => 'ro', isa => LWPUserAgent, builder => '_buildUa',
             init_arg => undef);

# Get an IP from any of a number of web services
# each of which return just an IP
Readonly my @IP_URLS => map { "http://$_" } (
    'icanhazip.com',
    'ifconfig.me/ip',
    'curlmyip.com');
sub _getIp {
    Readonly my $self => shift;
    say 'Trying to get current IP' if $self->verbose;

    # Try each service till we get an IP
    # Randomised order for balancing
    for my $serviceUrl (shuffle @IP_URLS) {
        say "Trying IP lookup at $serviceUrl" if $self->verbose;
        # Get and return IP
        Readonly my $res => $self->_ua->get($serviceUrl);
        if($res->is_success) {
            # Chop off the newline
            chomp(my $ip = $res->decoded_content);
            say "IP lookup at $serviceUrl returned $ip" if $self->verbose;
            return $ip
        }
        # Else log this lookup as failing and try another service
        carp "IP lookup at $serviceUrl failed: ", $res->status_line;
    }
    # All lookups have failed
    carp 'Could not lookup IP'; return
}

Readonly my $REC_TYPE => 'A';
Readonly my $TTL      => '1';
sub update {
    Readonly my $self => shift;
    # Try to get the current IP address
    carp "Cannot update records without an IP" and return unless
        Readonly my $ip => $self->_getIp;
    # Try to update each zone
    for my $zone (@{ $self->_config }) {
        # Try to update each domain
        say "Trying to update records for $zone->{zone}" if $self->verbose;
        for my $dom (@{ $zone->{domains} }) {
            # Skip update unless there is a change in IP
            do { no warnings 'uninitialized';
                 if ($self->_lastIps->{\$dom} eq $ip) {
                     say "IP not changed for $dom, skipping update" if
                         $self->verbose;
                     next}};
            # Cannot update if domain ID couldn't be found
            # At this point new domain IDs will be pulled in from CF
            warn "Domain ID not found for $dom, cannot update" and next
                unless defined $self->_domIds->{\$dom};
            # Update IP
            say "Trying to update IP for $dom" if $self->verbose;
            try { $self->_api->rec_edit(
                      z       => $zone->{zone},
                      type    => $REC_TYPE,
                      id      => $self->_domIds->{\$dom},
                      name    => $dom,
                      content => $ip,
                      ttl     => $TTL,);
                  # Record the new IP - won't happen if we fail above
                  $self->_lastIps->{\$dom} = $ip}
            catch (CloudFlare::Client::Exception::Upstream $e) {
                carp "Updating IP for $dom in $zone->{zone} failed ",
                     'because the CloudFlare API threw an error: ',
                     $e->errorCode, ' ', $e->message}
            catch (CloudFlare::Client::Exception::Connection $e) {
                carp "Updating IP for $dom in $zone->{zone} failed ",
                     'because the connection to the CloudFlare API failed: ',
                     $e->status, ' ', $e->message}}}
    # Flush domain IDs so they're updated next run
    $self->_clearDomIds
}

1; # End of Net::DNS::CloudFlare::DDNS

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DNS::CloudFlare::DDNS - Object Orientated Dynamic DNS Interface to CloudFlare DNS

=head1 VERSION

version v0.63.1

=for test_synopsis my ($CF_USER, $CF_KEY, $ZONE_CONF);

=head1 SYNOPSIS

Provides an object orientated dynamic DNS interface for CloudFlare

    use Net::DNS::CloudFlare::DDNS;

    my $ddns = Net::DNS::CloudFlare::DDNS->new(
        user   => $CF_USER,
        apikey => $CF_KEY,
        zones  => $ZONE_CONF
    );
    $ddns->update();
    ...

=head1 ATTRIBUTES

=head2 verbose

Whether or not the object should be verbose

    # Verbosity on
    $ddns->verbose(1);

    # Verbosity off
    $ddns->verbose(0);

    # Print current verbosity
    say $ddns->verbose;

=head1 METHODS

=head2 new

Create a new Dynamic DNS object

    my $ddns = Net::DNS::CloudFlare::DDNS->new(
        # Required
        user    => $CF_USER,
        apikey  => $CF_KEY,
        zones   => $ZONE_CONF,
        # Optional
        verbose => $VERB_LVL
    );

The zones specifies the zones and records which will be updated. Its structure
is as follows

    # Array of
    [
        # Hashes of
        {
            # DNS Zone
            zone    => $zone_name_1,
            # Domains to be updated in this zone
            domains => [
                $domain_1, ..., $domain_n
            ]
        },
        ...
        {
            zone    => $zone_name_n,
            domains => [
                $domain_1, ..., $domain_n
            ]
        }
    ]

Each domain is an A record within a zone or undef for the zone itself

=head2 update

Updates CloudFlare DNS with the current IP address if necessary

    $ddns->update

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-dns-cloudflare-ddns
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-DNS-CloudFlare-DDNS>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Net::DNS::CloudFlare::DDNS

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Net-DNS-CloudFlare-DDNS>

=back

=head2 Email

You can email the author of this module at C<me+dev@peter-r.co.uk> asking for help with any problems you have.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/pwr22/Net-DNS-CloudFlare-DDNS>

  git clone git://github.com/pwr22/Net-DNS-CloudFlare-DDNS.git

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/pwr22/Net-DNS-CloudFlare-DDNS/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 CONTRIBUTOR

=for stopwords Peter Roberts

Peter Roberts <me@peter-r.co.uk>

=head1 AUTHOR

Peter Roberts <me+dev@peter-r.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Peter Roberts.

This is free software, licensed under:

  The MIT (X11) License

=cut

#!/usr/bin/perl
# Copyright 2006 JanRain Inc.  Licensed under LGPL
# Author: Dag Arneson <dag@janrain.com>

package Net::Yadis;

use warnings;
use strict;

our $VERSION = "1.0";

use XML::XPath;

eval "use LWPx::ParanoidAgent;";
my $userAgentClass;
if($@) {
    warn "consider installing more secure LWPx::ParanoidAgent\n";
    use LWP::UserAgent;
    $userAgentClass = "LWP::UserAgent";
}
else {
    $userAgentClass = "LWPx::ParanoidAgent";
}
sub _userAgentClass { # Mainly for testing.  Needs to be able to get and post
    my $agent = shift;
    $userAgentClass = $agent if $agent;
    return $userAgentClass;
}

# finds meta http-equiv tags
use Net::Yadis::HTMLParse qw(parseMetaTags);

# must be lowercase.
my $YADIS_HEADER = 'x-xrds-location'; # this header is in the 1.0 yadis spec
# The following header was in an early version of the spec, and was 
# still in wide use at the time of writing
my $COMPAT_YADIS_HEADER = 'x-yadis-location';

=head1 Net::Yadis

This package performs the Yadis service discovery protocol, and parses
XRDS xml documents.

=head2 Methods

=head3 discover

This constructor performs the discovery protocol on a url and returns
a yadis object that parses the XRDS document for you.

 eval {
   $yadis=Net::Yadis->discover($url);
 }
 warn "Yadis failed: $@" if $@;
 
Will die on errors: HTTP errors, missing Yadis magic, malformed XRDS

=cut

sub discover {
    my $caller = shift;
    my $uri = shift;

    my $ua = $userAgentClass->new;
    my $resp = $ua->get($uri, 'Accept' => 'application/xrds+xml');

    die "Failed to fetch $uri" unless $resp->is_success;
    $uri = $resp->base;
    my ($xrds_text, $xrds_uri);
    my $ct = $resp->header('content-type');
    if ($ct and $ct eq 'application/xrds+xml') {
        $xrds_text = $resp->content;
        $xrds_uri = $resp->base;
    }
    else {
        my $yadloc = $resp->header($YADIS_HEADER) || $resp->header($COMPAT_YADIS_HEADER);
        
        unless($yadloc) {
            my $equiv_headers = parseMetaTags($resp->content);
            $yadloc = $equiv_headers->{$YADIS_HEADER} || $equiv_headers->{$COMPAT_YADIS_HEADER};
        }
        if($yadloc) {
            my $resp2 = $ua->get($yadloc);
            die "Bad Yadis URL: $uri - Could not fetch $yadloc" unless $resp2->is_success; 
            $xrds_text = $resp2->content;
            $xrds_uri = $resp2->base; # but out of spec if not equal to $yadloc
        }
        else {
            die "$uri is not a YADIS URL";
        }
    }
    $caller->new($uri, $xrds_uri, $xrds_text)
}

=head3 new

You may also skip discovery and go straight to xrds parsing with the C<new>
constructor.

 $yadis = Net::Yadis->new($yadis_url, $xrds_url, $xml);

=over

=item $yadis_url

the identity URL

=item $xrds_url

where we got the xrds document

=item $xml

the XRDS xml as text

=back

We don't trap death from XML::XPath; malformed xml causes this

=cut

sub new {
    my $caller = shift;
    my ($yadis_url, $xrds_url, $xml) = @_;

    my $class = ref($caller) || $caller;

    my $xrds;
    $xrds = XML::XPath->new(xml => $xml);
    $xrds->set_namespace("xrds", 'xri://$xrds');
    $xrds->set_namespace("xrd", 'xri://$xrd*($v*2.0)');
    
    my @svc_nodes = sort byPriority
            $xrds->findnodes("/xrds:XRDS/xrd:XRD[last()]/xrd:Service");
    my @services;
    for(@svc_nodes) {
        push @services, Net::Yadis::Service->new($xrds, $_);
    }
    
    my $self = {
        yadis_url     => $yadis_url,
        xrds_url => $xrds_url,
        xrds    => $xrds,
        xml     => $xml,
        services => \@services,
        };

    bless ($self, $class);
}

=head3 Accessor methods

=over

=item xml

The XML text of the XRDS document.

=item url

The Yadis URL.

=item xrds_url

The URL where the XRDS document was found.

=item xrds_xpath

The XML::XPath object used internally is made available to allow custom
XPath queries.

=item services

An array of Net::Yadis::Service objects representing the services
advertised in the XRDS file.

=back

=cut

sub xml {
    my $self = shift;
    $self->{xml};
}
sub url {
    my $self = shift;
    $self->{yadis_url};
}
sub xrds_url {
    my $self = shift;
    $self->{xrds_url};
}
sub xrds_xpath {
    my $self = shift;
    $self->{xrds};
}

# sorting helper function for xpath nodes
# I wonder if doing the random order for the services significantly
# increases the running time of this function.
sub byPriority {
    my $apriori = $a->getAttribute('priority');
    my $bpriori = $b->getAttribute('priority');
    srand;
    # a defined priority comes before an undefined priority.
    if (not defined($apriori)) { # we assume nothing
        return defined($bpriori) || ((rand > 0.5) ? 1 : -1);
    }
    elsif (not defined($bpriori)) {
        return -1;
    }
    int($apriori) <=> int($bpriori) || ((rand > 0.5) ? 1 : -1);
}

# using a sorting helper from another package doesn't work, so
# we use this function when sorting URIs in the service object
sub _triage {
    sort byPriority @_;
}

sub services {
    my $self = shift;
    return @{$self->{services}} 
}

=head3 filter_services

Pass in a filter function reference to this guy.  The filter function
must take a Net::Yadis::Service object, and return a scalar of some sort
or undef.  The scalars returned from the filter will be returned in an
array from this method.

=head4 Example

    my $filter = sub {
        my $service = shift;
        if ($service->is_type($typere)) {
            # here we simply return the service object, but you may return
            # something else if you wish to extract the data and discard
            # the xpath object contained in the service object.
            return $service;
        }
        else {
            return undef;
        }
    };

    my $typeservices = $yadis->filter_services($filter);

=cut

sub filter_services {
    my $self = shift;
    my $filter = shift;
    
    my @allservices = $self->services;
    my @filteredservices;
    for my $service (@allservices) {
        my $filtered_service = &$filter($service);
        push @filteredservices, $filtered_service if defined($filtered_service);
    }

    return @filteredservices;
}

=head3 services_of_type

A predefined filtering method that takes a regexp for filtering service
types.

=cut

# here is an example using a filter function
sub services_of_type {
    my $self = shift;
    my $typere = shift;
    
    my $filter = sub {
        my $service = shift;
        if ($service->is_type($typere)) {
            # here we simply return the service object, but you may return
            # something else if you wish to extract the data and discard
            # the xpath object contained in the service object.
            return $service;
        }
        else {
            return undef;
        }
    };
    return $self->filter_services($filter);
}

=head3 service_of_type

Hey, a perl generator! sequential calls will return the services one 
at a time, in ascending priority order with ties randomly decided.
make sure that the type argument is identical for each call, or the list
will start again from the top.  You'll have to store the yadis object in
a session for this guy to be useful.

=cut

sub service_of_type {
    my $self = shift;
    my $typere = shift;

    # remaining services of type
    my $rsot = $self->{rsot};
    my @remaining_services;
    if (defined($rsot->{$typere})) {
        @remaining_services = @{$rsot->{$typere}};
    }
    else {
        @remaining_services = $self->services_of_type($typere);
    }
    my $service = shift @remaining_services;
    $rsot->{$typere} = \@remaining_services;
    $self->{rsot}=$rsot;
    return $service;
}

1;

package Net::Yadis::Service;

=head1 Net::Yadis::Service

An object representing a service tag in an XRDS document.

=head2 Methods

=head3 is_type

Takes a regexp or a string and returns a boolean value: do any of the
C<< <Type> >> tags in the C<< <Service> >> tag match this type?

=cut

#typere: regexp or string
sub is_type {
    my $self = shift;
    my $typere = shift;
     
    my $xrds = $self->{xrds};
    my $typenodes = $xrds->findnodes("./xrd:Type", $self->{node});
    my $is_type = 0;
    while($typenodes->size) {
        # string_value contains the first node's value <shrug>
        if ($typenodes->string_value =~ qr{$typere}) {
            $is_type = 1;
            last;
        }
        $typenodes->shift;
    }
    return $is_type;
}

=head3 types

Returns a list of the contents of the C<< <Type> >> tags of this service
element.

=cut

sub types {
    my $self = shift;
    
    my $xrds = $self->{xrds};
    my @typenodes = $xrds->findnodes("./xrd:Type", $self->{node});
    my @types;
    for my $tn (@typenodes) {
        push @types, $xrds->getNodeText($tn);
    }
    return @types;
}

=head3 uris

Returns a list of the contents of the C<< <URI> >> tags of this service
element, in priority order, ties randomly decided.

=cut


sub uris {
    my $self = shift;
    
    my $xrds = $self->{xrds};
    my @urinodes = Net::Yadis::_triage $xrds->findnodes("./xrd:URI", $self->{node});
    my @uris;
    for my $un (@urinodes) {
        push @uris, $xrds->getNodeText($un);
    }
    return @uris;
}

=head3 uri

another perl 'generator'. sequential calls will return the uris one 
at a time, in ascending priority order with ties randomly decided

=cut

sub uri {
    my $self = shift;
    my @untried_uris;
    if (defined($self->{untried_uris})) {
        @untried_uris = @{$self->{untried_uris}};
    } else {
        @untried_uris = $self->uris;
    }
    my $uri = shift (@untried_uris);
    $self->{untried_uris} = \@untried_uris;
    return $uri;
}

=head3 getAttribute

Get an attribute of the service tag by name.

 $priority = $service->getAttribute('priority');

=cut

sub getAttribute {
    my $self = shift;
    my $key = shift;
    my $node = $self->{node};
    $node->getAttribute($key);
}

=head3 findTag

Get the contents of a child tag of the service tag.

 $service->findTag($tag_name, $namespace);

For example:

 $delegate = $service->findTag('Delegate', $OPENID_NS);

=cut

sub findTag {
    my $self = shift;
    my $tagname = shift;
    my $namespace = shift;

    my $xrds = $self->{xrds};
    my $svcnode = $self->{node};
    
    my $value;
    if($namespace) {
        $xrds->set_namespace("asdf", $namespace);
        $value = $xrds->findvalue("./asdf:$tagname", $svcnode);
    }
    else {
        $value = $xrds->findvalue("./$tagname", $svcnode);
    }
    
    return $value;
}

=head3 xrds

Returns the xrds document as an XML::XPath for custom XPath queries.

=cut

sub xrds {
    my $self = shift;
    return $self->{xrds};
}

=head3 node

Returns the XPath node of the C<< <Service> >> tag, for custom XPath queries.

=cut

sub node {
    my $self = shift;
    return $self->{node};
}

sub new {
    my $caller = shift;
    my ($xrds, $node) = @_;

    my $class = ref($caller) || $caller;

    my $self = {
        xrds => $xrds,
        node => $node,
    };

    bless($self, $class);
}

1;


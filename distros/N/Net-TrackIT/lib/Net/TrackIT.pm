# $Id: TrackIT.pm,v 1.1.1.1 2006/11/28 22:09:18 dtikhonov Exp $
#
# This module is an interface to DHL's TrackIT interface.
#
# Author: Dmitri Tikhonov <dtikhonov@vonage.com>
# Date: November 28, 2006

package Net::TrackIT;

use strict;
use warnings;

our $VERSION = '0.01';

use HTTP::Request;
use LWP::UserAgent;
use XML::Simple qw(XMLin);

sub new {
    my $class = shift;

    bless {
        # This can be overridden, obviously.
        URI => 'https://ecommerce.airborne.com/APILanding.asp',

        # You can use this to test before getting access to the
        # production tracking database.
        # URI => 'https://ecommerce.airborne.com/APILandingTest.asp',

        @_,
    }, ref($class) || $class;
}

sub track {
    my ($self, $number) = @_;

    my $req = HTTP::Request->new(
        'POST', $self->URI, undef, $self->_req_xml($number),
    );
    my $resp = $self->_ua->request($req);

    unless ($resp->is_success) {
        die "Connection error: " . $resp->status_line;
    }

    XMLin($resp->content);
}

sub _ua {
    my $self = shift;
    my %opts;
    
    if ('HASH' eq ref($self->{lwp_options})) {
        %opts = %{$self->{lwp_options}};
    }

    LWP::UserAgent->new(
        agent => ref($self) . '/' . $self->VERSION,
        %opts,
    );
}

sub _req_xml {
    my ($self, $tracking_number) = @_;

    # Simple but effective way of constructing XML requests.
    my $xml=<<'XML';
<?xml version='1.0'?>
<ECommerce action='Request' version='1.1'>
    <Requestor>
        <ID>%s</ID>
        <Password>%s</Password>
    </Requestor>
    <Track action='Get' version='1.0'>
        <Shipment>
            <TrackingNbr>%s</TrackingNbr>
        </Shipment>
    </Track>
</ECommerce>
XML

    sprintf($xml, $self->ID, $self->password, $tracking_number);
}

# Auto-generate accessors/mutators:
for my $method (qw(URI ID password)) {
    no strict 'refs';

    *{$method} = sub {
        my $self = shift;
        if (@_) {
            $self->{$method} = shift;
        }
        return $self->{$method};
    };
}

1;

__END__

=head1 NAME

Net::TrackIT -- interface to DHL's TrackIT web services

=head1 SYNOPSYS

  my $trackit = Net::TrackIT->new(
    ID => 'Your customer ID',
    password => 'Your password',
  );
  my $result = $trackit->track($tracking_number);

=head1 DESCRIPTION

This module is a simple interface to DHL's (formerly Airborne Express)
tracking web services.

=head1 BUGS

Not much error checking is done.

=head1 VERSION

This is version 0.01 of the client.

=head1 AUTHOR

Dmitri Tikhonov E<lt>dtikhonov@vonage.comE<gt>

=head1 CREDITS

Loosely based on TrackIT.pm module (author unknown)
found on P3P web site:
http://www.p3ptools.com/perl.htm

=cut

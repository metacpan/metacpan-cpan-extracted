package Net::TrackUPS;

use strict;
use warnings;

our $VERSION = '0.01';

use HTTP::Request;
use LWP::UserAgent;
use XML::Simple qw(XMLin);

sub new {
    my $class = shift;

    bless {
        # Production Tracking URL, this can be overridden.
        URI => 'https://www.ups.com/ups.app/xml/Track',

        # This URL should be used for testing and integration
        # URI => 'https://wwwcie.ups.com/ups.app/xml/Track',

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
<AccessRequest xml:lang='en-US'>
    <AccessLicenseNumber>%s</AccessLicenseNumber>
    <UserId>%s</UserId>
    <Password>%s</Password>
</AccessRequest>
<?xml version="1.0" ?>
<TrackRequest>
    <Request>
        <RequestAction>Track</RequestAction>
        <RequestOption>%s</RequestOption>
    </Request>
    <TrackingNumber>%s</TrackingNumber>
</TrackRequest>
XML

    sprintf($xml, $self->access_key, $self->ID, $self->password, $self->request_option, $tracking_number);
}

# Auto-generate accessors/mutators:
for my $method (qw(URI ID password access_key request_option)) {
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

Net::TrackUPS -- Interface to UPS's Tracking Web Services

=head1 SYNOPSYS

  my $track = Net::TrackUPS->new(
    access_key => 'UPS Access License Number',
    ID => 'Your customer ID',
    password => 'Your password',
    request_option => 'empty, 'none' or '0' to request most recent activity;
                      'activity' or '1' to request all activities',
  );
  my $result = $track->track($tracking_number);

=head1 DESCRIPTION

This module is a simple interface to UPS's tracking web services.

=head1 BUGS

Not much error checking is done.

=head1 VERSION

This is version 0.01 of the client.

=head1 AUTHOR

David Grizzanti E<lt>dgrizzanti@gmail.comE<gt>

=head1 CREDITS

Based on Net::TrackIT (author Dmitri Tikhonov)
Thanks Dmitri!

=cut

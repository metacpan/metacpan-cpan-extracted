package Net::PostcodeNL::WebshopAPI;

use strict;
use warnings;

use LWP::UserAgent;
use JSON::XS;
use URI::Template;

use Net::PostcodeNL::WebshopAPI::Response;

our $VERSION = '0.2';

my $AGENT = __PACKAGE__ . '/' . $VERSION;

sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};

    $self->{user_agent} = $args{user_agent} ? $args{user_agent} : $AGENT;

    $self->{api_key} = $args{api_key};
    $self->{api_secret} = $args{api_secret};

    $self->{api_url} = URI::Template->new($args{api_url} || 'https://api.postcode.nl/rest/addresses{/zipcode,number,addition}');

    my $ua = LWP::UserAgent->new;
    $ua->agent($self->{user_agent});
    $self->{ua} = $ua;

    return bless $self, $class;
}

sub ua {
    my $self = shift;
    return $self->{ua};
}

sub lookup {
    my $self = shift;

    my ($zipcode, $number, $addition) = @_;

    my $uri = $self->api_url($zipcode, $number, $addition);

    my $ua = $self->ua;
    $ua->credentials($uri->host_port, 'REST Endpoint', $self->{api_key}, $self->{api_secret}); 
    my $resp = $ua->get($uri);

    if ($resp->code == 200 && $resp->header('Content-Type') eq 'application/json') {
        return Net::PostcodeNL::WebshopAPI::Response->new(decode_json($resp->decoded_content));
    }
    return Net::PostcodeNL::WebshopAPI::Response->new(decode_json($resp->decoded_content));
}

sub api_url {
    my $self = shift;
    my ($zipcode, $number, $addition) = @_;
    return $self->{api_url}->process({zipcode => $zipcode,number=> $number, addition => $addition });
}

1;

=head1 NAME

Net::PostcodeNL::WebshopAPI - Postcode.nl Webshop API

=head1 SYNOPSYS

    use Net::PostcodeNL::WebshopAPI;

    my $api = Net::PostcodeNL::WebshopAPI->new(
        api_key    => 'insert api key',
        api_secret => 'insert api secret',
    );

    my $zipcode = '';
    my $number = '';
    my $addition = '';

    my $r = $api->lookup($zipcode, $number, $addition);

    if ($r->is_error) {
        die $r->err_str;
    }
    else {
        say $r->street;
        say $r->houseNumber;
        say $r->houseNumberAddition;
    }

=head1 DESCRIPTION

Retrieves information about a zipcode from Postcode.nl

You need to apply for a key and secret from L<http://api.postcode.nl>.

=head1 METHODS

=head2 $r = $self->lookup($zipcode, $number, $addition);

Returns a L<Net::PostcodeNL::WebshopAPI::Response> for the combination of
C<$zipcode>, C<$number> and C<$addition>.

=head1 SEE ALSO

L<Net::PostcodeNL::WebshopAPI::Response>

=head1 AUTHOR

Peter Stuifzand <peter@stuifzand.eu>

=head1 LICENSE

GPL version 3 or later.

=cut

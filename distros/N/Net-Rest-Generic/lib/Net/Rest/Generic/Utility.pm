package Net::Rest::Generic::Utility;

use 5.006;
use strict;
use warnings FATAL => 'all';

use LWP::UserAgent;
use HTTP::Request::Common;

=head1 NAME

Net::Rest::Generic::Utility - Utility methods for arbitrary api functionality

=cut

sub _doRestCall {
        my ($api, $method, $url, $args) = @_;
        $method = uc($method);
        $args ||= {};
        if ($api->{useragent_options} && ref($api->{useragent_options}) eq 'HASH') {
                $api->{ua} ||= LWP::UserAgent->new(%{$api->{useragent_options}});
        }
        else {
                $api->{ua} ||= LWP::UserAgent->new();
        }
        my ($request, @params) = _generateRequest($api, $method, $url, $args);
        $api->{ua}->request( $request, @params );
}

sub _generateRequest {
        my ($api, $method, $url, $args) = @_;

        my $ua = $api->{ua};
        my @parameters = ($url, %{$api->{_params}}, %{$args});
        my $parameterOffset;
        if ($method eq 'PUT'||$method eq 'POST') {
                $parameterOffset = ref($parameters[1])? 2 : 1;
        }
        else {
                $parameterOffset = 1;
        }

        my @stuff = $ua->_process_colonic_headers(\@parameters, 0);
        {
                no strict qw(refs);
                my $request = &{"HTTP::Request::Common::${method}"}( @parameters );
                $request->authorization_basic(
                        $api->{authorization_basic}{username},
                        $api->{authorization_basic}{password}
                ) if $api->{authorization_basic}{username};
                $request->content($api->{request_content}) if $api->{request_content};

                return ($request, @stuff);
        }

}

1;

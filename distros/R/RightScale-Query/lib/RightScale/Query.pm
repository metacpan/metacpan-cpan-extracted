package RightScale::Query;
# Author: Matthew Mallard
# Website: www.q-technologies.com.au
# Date: 25th May 2016

# ABSTRACT: Query RightScale for server instances


use URI;
use JSON;
use HTTP::Headers;
use LWP::UserAgent;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(rs_get_access_token run_rs_query rs_find_instance);


our $api_url;
our $internet_proxy;
our $internet_proxy_timeout = 30;

sub rs_get_access_token {
    my $refresh_token = shift;
    my $form = {
                 grant_type => 'refresh_token',
                 refresh_token => $refresh_token,
               };
    my $headers = HTTP::Headers->new(
                                        'X-API-Version' => '1.5',
                                    );
    my $path = "oauth2";
    my $token_request = run_rs_query( $headers, $form, $path, "POST" );
    return $token_request->{access_token};
}


sub run_rs_query {
    my $headers = shift;
    my $form = shift;
    my $path = shift;
    my $type = shift;
    my $uri = URI->new("$api_url/$path");
    $uri->query_form($form) if $type eq "GET";
    my $ua = LWP::UserAgent->new();
    $ua->default_headers( $headers );
    $ua->timeout( $internet_proxy_timeout );
    $ua->proxy( 'https', "connect://$internet_proxy/") if $internet_proxy;
    my $response;
    if( $type eq "GET" ) {
        $response = $ua->get($uri ) ;
    } elsif( $type eq "POST" ){
        $response = $ua->post($uri, $form );
    } else {
        die "Unsupported request type";
    }
    my $output;
    if ($response->is_success) {
        $output =  $response->decoded_content;
    } else {
        die $response->status_line;
    }
    return decode_json( $output );
}


sub rs_find_instance {
    my $instance_id = shift;
    my $rs_cloud_id = shift;
    my $access_token = shift;
    my $form = {
                 "filter[]" => "resource_uid==$instance_id",
               };
    my $headers = HTTP::Headers->new(
                                        'X-API-Version' => '1.5',
                                        'Authorization' => "Bearer $access_token",
                                    );
    my $path = "clouds/$rs_cloud_id/instances";
    my $instance_request = run_rs_query( $headers, $form, $path, "GET" );
    # Return first element of the array as we should only get one answer
    return $instance_request->[0] if @$instance_request > 0;
}

# Connect to RightScale and get the temporary access token using the refresh token
sub rs_get_access_token_curl {
    my $refresh_token = shift;
    my $api_url = shift;
    my $curl1 = <<CURL;
    curl -s \\
        --connect-timeout 10 \\
        -H "X-API-Version:1.5" \\
        --request POST "$api_url/oauth2" \\
        -d "grant_type=refresh_token" \\
        -d "refresh_token=$refresh_token"
CURL

    my $token_request = decode_json `$curl1`;
    return $token_request->{access_token};
}

# Connect to RightScale and look for the specified instance
# if it's found we will have a hash array of data about the instance
# if not found - the hash will be undef
sub rs_find_instance_curl {
    my $instance_id = shift;
    my $rs_cloud_id = shift;
    my $access_token = shift;
    my $api_url = shift;
    my $curl2 = <<CURL;
    curl -s \\
        --connect-timeout 10 \\
        -H "X-API-Version:1.5" \\
        -H "Authorization: Bearer $access_token" \\
        -d "filter[]=resource_uid==$instance_id" \\
        --request GET "$api_url/clouds/$rs_cloud_id/instances"
CURL

    my $instance_request = decode_json `$curl2`;
    return $instance_request;
}





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RightScale::Query - Query RightScale for server instances

=head1 VERSION

version 0.201

=head1 SYNOPSIS

Query the RightScale service for information about server instances.  It can be used
to query for other objects, but at this stage it only provides a helper function to find server instances

    use RightScale::Query;

    # Package Globals
    $RightScale::Query::api_url = 'https://us-4.rightscale.com/api';
    $RightScale::Query::internet_proxy = 'http://proxy.example.com';
    $RightScale::Query::internet_proxy_timeout = 30;

    # Get an access token
    my $refresh_token = 'afd983762efabcd9823209cbdefa9819832dcbea';
    my $access_token = rs_get_access_token( $refresh_token );

    # Check whether we can find the instance
    my $instance_id   = $server_data->{'instance_id'};
    my $rs_cloud_id   = $server_data->{'rs_cloud_id'};
    my $rs_account_id   = $server_data->{'rs_account_id'};
    my $instance_details = rs_find_instance(  $instance_id, $rs_cloud_id, $access_token );

=head1 GLOBAL VARIABLES

C<$RightScale::Query::api_url> needs to be set to match the URL of the RightScale API.

These variables can be set if you need to pass through a proxy (these are passed to L<LWP::UserAgent>):

=over

=item * C<RightScale::Query::internet_proxy> - The hostname of the proxy server

=item * C<RightScale::Query::internet_proxy_timeout> - The proxy timeout

=back

=head1 EXPORTED FUNCTIONS

=head2 rs_get_access_token

This provides the RightScale temporary access token when the refresh token is provided

    my $access_token = rs_get_access_token( $refresh_token );

=head2 run_rs_query

Connect to the RightScale API, run a query and return the result

    my $instance_id = $server_data->{'instance_id'};
    my $form = {
                 "filter[]" => "resource_uid==$instance_id",
               };
    my $headers = HTTP::Headers->new(
                                        'X-API-Version' => '1.5',
                                        'Authorization' => "Bearer $access_token",
                                    );
    my $rs_cloud_id = $server_data->{'rs_cloud_id'};
    my $path = "clouds/$rs_cloud_id/instances";
    my $instance_request = run_rs_query( $headers, $form, $path, "GET" );

This is a low level function that allows most queries to be constructed.  This particular example
if wrapped up by the C<rs_find_instance> function.

=head2 rs_find_instance

Look for the specified instance in RightScale, if it's found we will have a hash array of data about the instance,
if not found - the hash will be B<undef>.

    # Check whether we can find the instance
    my $instance_id   = $server_data->{'instance_id'};
    my $rs_cloud_id   = $server_data->{'rs_cloud_id'};
    my $rs_account_id   = $server_data->{'rs_account_id'};
    my $instance_details = rs_find_instance(  $instance_id, $rs_cloud_id, $access_token );

=head1 BUGS/FEATURES

This module should be converted to be OO, but it's not actively being using anymore, so incentive is low to
rewrite, but I want make it available for others anyway.

Please report any bugs or feature requests in the issues section of GitHub: 
L<https://github.com/Q-Technologies/perl-Log-MixedColor>. Ideally, submit a Pull Request.

=head1 AUTHOR

Matthew Mallard <mqtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Matthew Mallard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

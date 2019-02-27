# NAME

RightScale::Query - Query RightScale for server instances

# VERSION

version 0.200

# SYNOPSIS

Query the RightScale service for information about server instances.  It can be used
to query for other objects, but at this stage it only provides a helper function to find server instances

    use RightScale;

    # Package Globals
    $RightScale::api_url = 'https://us-4.rightscale.com/api';
    $RightScale::internet_proxy = 'http://proxy.example.com';
    $RightScale::internet_proxy_timeout = 30;

    # Get an access token
    my $refresh_token = 'afd983762efabcd9823209cbdefa9819832dcbea';
    my $access_token = rs_get_access_token( $refresh_token );

    # Check whether we can find the instance
    my $instance_id   = $server_data->{'instance_id'};
    my $rs_cloud_id   = $server_data->{'rs_cloud_id'};
    my $rs_account_id   = $server_data->{'rs_account_id'};
    my $instance_details = rs_find_instance(  $instance_id, $rs_cloud_id, $access_token );

# GLOBAL VARIABLES

`$RightScale::api_url` needs to be set to match the URL of the RightScale API.

These variables can be set if you need to pass through a proxy (these are passed to [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)):

- `RightScale::internet_proxy` - The hostname of the proxy server
- `RightScale::internet_proxy_timeout` - The proxy timeout

# EXPORTED FUNCTIONS

## rs\_get\_access\_token

This provides the RightScale temporary access token when the refresh token is provided

    my $access_token = rs_get_access_token( $refresh_token );

## run\_rs\_query

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
if wrapped up by the `rs_find_instance` function.

## rs\_find\_instance

Look for the specified instance in RightScale, if it's found we will have a hash array of data about the instance,
if not found - the hash will be **undef**.

    # Check whether we can find the instance
    my $instance_id   = $server_data->{'instance_id'};
    my $rs_cloud_id   = $server_data->{'rs_cloud_id'};
    my $rs_account_id   = $server_data->{'rs_account_id'};
    my $instance_details = rs_find_instance(  $instance_id, $rs_cloud_id, $access_token );

# BUGS/FEATURES

This module should be converted to be OO, but it's not actively being using anymore, so incentive is low to
rewrite, but I want make it available for others anyway.

Please report any bugs or feature requests in the issues section of GitHub: 
[https://github.com/Q-Technologies/perl-Log-MixedColor](https://github.com/Q-Technologies/perl-Log-MixedColor). Ideally, submit a Pull Request.

# AUTHOR

Matthew Mallard <mqtech@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Matthew Mallard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

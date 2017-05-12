# NAME

Net::Amazon::SignatureVersion4 - Signs requests using Amazon's Signature Version 4.

# VERSION

version 0.005

# SYNOPSIS

    use Net::Amazon::SignatureVersion4;

    my $sig=new Net::Amazon::SignatureVersion4();
    my $hr=HTTP::Request->new('GET','http://glacier.us-west-2.amazonaws.com/-/vaults', [ 
				   'Host', 'glacier.us-west-2.amazonaws.com', 
				   'Date', strftime("%Y%m%dT%H%M%SZ",gmtime(time())) , 
				   'X-Amz-Date', strftime("%Y%m%dT%H%M%SZ",gmtime(time())) , 
				   'x-amz-glacier-version', '2012-06-01',
			       ]);
    $hr->protocol('HTTP/1.1');

    $sig->set_request($request); # $request is HTTP::Request
    $sig->set_region('us-west-2');
    $sig->set_service('glacier'); # Must be service you are accessing
    $sig->set_Access_Key_ID('AKIDEXAMPLE'); # Replace with your ACCESS_KEY_ID
    $sig->set_Secret_Access_Key('wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY'); # Replace with your SECRET_KEY
    my $authorized_request=$sig->get_authorized_request();
    my $agent = LWP::UserAgent->new( agent => 'perl-Net::Amazon::SignatureVersion4-Testing');
    my $response = $agent->request($authorized_request);
    if ($response->is_success) {
        say("List of vaults");
        say($response->decoded_content);  # or whatever
        say("Connected to live server");
    }else {
        say($response->status_line);
        use Data::Dumper;
        say("Failed Response");
        say(Data::Dumper->Dump([ $response ]));
    }

# DESCRIPTION

This module implements Amazon's Signature Version 4 as documented at
http://docs.amazonwebservices.com/general/latest/gr/signature-version-4.html

The tests for this module are taken from the test suite provided by
Amazon.  This implementation does not yet pass all the tests.  The
following test is failing:

get-header-value-multiline: Amazon did not supply enough files for
this test.  The test may be run, but the results can not be validated.

# METHODS

## get\_authorized\_request

    This method does most of the work for the user.  After setting the
    request, region, service, access key, and secret access key, this
    method will return a copy of the request headers with
    authorization.

## get\_authorization

    This method gets the authorization line that should be added to
    the headers.  It is likely never to be used by the end user.  It
    is here as a convenient test.

## get\_derived\_signing\_key

    This method implements the derived signing key required for
    version 4. It is likely never to be used by the end user.  It is
    here as a convenient test.

## get\_string\_to\_sign

    This method returns the string to sign.  It is likely never to be
    used by the end user.  It is here as a convenient test.

## get\_canonical\_request

    This method returns the canonical request.  It is likely never to
    be used by the end user.  It is here as a convenient test.

# AUTHOR

Charles A. Wimmer <charles@wimmer.net>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Charles A. Wimmer.

This is free software, licensed under:

    The (three-clause) BSD License

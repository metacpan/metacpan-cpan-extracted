package Net::OpenMicroBlogging;
use warnings;
use strict;
use base 'Net::OAuth';

our $VERSION = '0.01';

=head1 NAME

Net::OpenMicroBlogging - OpenMicroBlogging protocol support

=head1 SYNOPSIS

    # Consumer sends Request Token Request

    use Net::OpenMicroBlogging;
    use HTTP::Request::Common;
    my $ua = LWP::UserAgent->new;

    my $request = Net::OpenMicroBlogging->request("request token")->new(
        consumer_key => 'dpf43f3p2l4k3l03',
        consumer_secret => 'kd94hf93k423kf44',
        request_url => 'https://ublog.example.net/request_token',
        request_method => 'POST',
        signature_method => 'HMAC-SHA1',
        timestamp => '1191242090',
        nonce => 'hsu94j3884jdopsl',
        omb_listener => 'http://ublog.example.net/bob',
    );

    $request->sign;

    my $res = $ua->request(POST $request->to_url); # Post message to the Service Provider
    
    if ($res->is_success) {
        my $response = Net::OpenMicroBlogging->response('request token')->from_post_body($res->content);
        print "Got Request Token ", $response->token, "\n";
        print "Got Request Token Secret ", $response->token_secret, "\n";
    }
    else {
        die "Something went wrong";
    }
    
    # Etc..

    # Service Provider receives Request Token Request
    
    use Net::OpenMicroBlogging;
    use CGI;
    my $q = new CGI;
    
    my $request = Net::OpenMicroBlogging->request("request token")->from_hash($q->Vars,
        request_url => 'https://photos.example.net/request_token',
        request_method => $q->request_method,
        consumer_secret => 'kd94hf93k423kf44',
    );

    if (!$request->verify) {
        die "Signature verification failed";
    }
    else {
        # Service Provider sends Request Token Response

        my $response = Net::OpenMicroBlogging->response("request token")->new( 
            token => 'abcdef',
            token_secret => '0123456',
        );

        print $response->to_post_body;
    }	

    # Etc..


=head1 ABSTRACT

The purpose of OpenMicroBlogging is 

"To allow users of one microblogging service to publish notices to users of another service, given the other users' permission."

Please refer to the OpenMicroBlogging spec: L<http://openmicroblogging.org/>

OpenMicroBlogging is based on OAuth - familiarity with OAuth is highly recommended before diving into OpenMicroBlogging

Net::OpenMicroBlogging is a thin wrapper around L<Net::OAuth> - basically it augments Net::OAuth
message classes with additional OMB parameters, and defines a couple message types unique to
OMB.  Please refer to the L<Net::OAuth> documentation for the details of how to create, manipulate,
sign and verify messages.

=back

=head1 DESCRIPTION

=head2 OMB MESSAGES

An OpenMicroBlogging message is a set of key-value pairs.  The following message types are supported:

Requests

=over

=item * Request Token (Net::OpenMicroBlogging::RequestTokenRequest)

=item * Access Token (Net::OpenMicroBlogging::AccessTokenRequest)

=item * User Authentication (Net::OpenMicroBlogging::UserAuthRequest)

=item * Protected Resource (Net::OpenMicroBlogging::ProtectedResourceRequest)

=item * Posting a Notice (Net::OpenMicroBlogging::PostNoticeRequest)

=item * Updating a Profile (Net::OpenMicroBlogging::UpdateProfileRequest)

=back

Responses

=over

=item * Request Token (Net::OpenMicroBlogging::RequestTokenResponse)

=item * Access Token (Net::OpenMicroBlogging:AccessTokenResponse)

=item * User Authentication (Net::OpenMicroBlogging::UserAuthResponse)

=back

=head1 SEE ALSO

L<http://openmicroblogging.org>

=head1 AUTHOR

Keith Grennan, C<< <kgrennan at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Keith Grennan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
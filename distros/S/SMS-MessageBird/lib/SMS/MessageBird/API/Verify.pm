package SMS::MessageBird::API::Verify;

use strict;
use warnings;

use parent 'SMS::MessageBird::API';

=head1 NAME

SMS::MessageBird::API::Verify - Sub-module for the SMS::MessageBird distribution.


=head1 SYNOPSIS

This is a sub-module which is part of the SMS::MessageBird distribution.

While this module can be used directly, it's designed to be used via
L<SMS::MessageBird>


=head1 DESCRIPTION

This module provides the interface to the Verify methods of the MessageBird
JSON API.

The methods implmented acceept the paramteres as named in the MessageBird API
documentation which can be found at the L<MessageBird Developer Documentation|https://www.messagebird.com/en-gb/developers>.
If you're using this distribution you should be familiar with the API
documentation.

=head2 Response Data

Every method returns a standardised hashref containin the following keys:

=over

=item ok

Value of 0 or 1. Indicates if the request was completed successfully or not.
This value is based on LWP::UserAgent's is_success() method.

=item code

This is the HTTP code returned by the API. In the event of ok => 0 - it's
possible that the request was a 401 etc. So this is provided for sanity
checking.

=item content

This is a Perl hashref data structure decoded from the API's response JSON
as-is.

Please see the L<MessageBird Developer Documentation|https://www.messagebird.com/en-gb/developers>
for more information on the expected structure.

=back


=head1 METHODS

=head2 request

  In:  %params   - Hash of params accepted by the MessageBird API.
  Out: $response - Hashref of response data. See "Response Data" above.

This method implements the POST /verify route of the API.

Requests creation and sending of a verification link to the supplied MSISDN.

Accepted parameters are listed in the MessageBird API documentation.

Require parameters are as follows:

=over

=item recipient

The MSISDN formatted telephone number to do send the verification link to.

=back

All other parameters are optional.

Please see the L<MessageBird Developer Documentation|https://www.messagebird.com/en-gb/developers>
for more information.

=cut

sub request {
    my ($self, %params) = @_;

    return $self->_no_param_supplied('recipient') if !exists $params{recipient};

    return $self->_api_request(
        post => "/verify",
        \%params,
    );
}


=head2 verify

  In:  $verification_id - The verification ID returned by the request call.
  In:  $token           - The token to attempt to verify.
  Out: $response - Hashref of response data. See "Response Data" above.

This method implements the GET /verify/{verification_id}?token={token} route of
the API.

Attempts to verify a sent verification token.

Please see the L<MessageBird API Documentation|https://www.messagebird.com/en-gb/developers>
for more information.

=cut

sub verify {
    my ($self, $verify_id, $token) = @_;

    return $self->_no_param_supplied('verify_id') if !$verify_id;
    return $self->_no_param_supplied('verification token') if !$token;

    return $self->_api_request(
        get   => "/verify/$verify_id",
        token => $token,
    );
}


=head2 get

  In:  $verification_id - The verification ID returned by the request call.
  Out: $response - Hashref of response data. See "Response Data" above.

This method implements the GET /verify/{verification_id} route of the API.

Returns the existing verification object identified by $verification_id.

=cut

sub get {
    my ($self, $verify_id) = @_;

    return $self->_no_param_supplied('verify_id') if !$verify_id;

    return $self->_api_request(
        get => "/verify/$verify_id"
    );
}


=head2 remove

  In:  $verification_id - The verification ID returned by the request call.
  Out: $response - Hashref of response data. See "Response Data" above.

This method implements the DELETE /verify/{verification_id} route of the API.

Deletes an existing verification object identified by $verification_id.

=cut

sub remove {
    my ($self, $verify_id) = @_;

    return $self->_no_param_supplied('verify ID') if !$verify_id;

    my $response = $self->_api_request( delete => "/verify/$verify_id" );
    $response->{ok} = 1 if $response->{code} == 204;

    return $response;
}


=head2 del

Synonym for the L<remove()|/"remove"> method.

=cut

sub del {
    my ($self, $verify_id) = @_;

    return $self->remove($verify_id);
}


=head1 AUTHOR

James Ronan, C<< <james at ronanweb.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sms-messagebird at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-MessageBird>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

Alternatively you can raise an issue on the source code which is available on
L<GitHub|https://github.com/jamesronan/SMS-MessageBird>.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 James Ronan.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;


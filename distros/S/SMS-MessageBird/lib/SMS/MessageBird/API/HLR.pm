package SMS::MessageBird::API::HLR;

use strict;
use warnings;

use parent 'SMS::MessageBird::API';

=head1 NAME

SMS::MessageBird::API::HLR - Sub-module for the SMS::MessageBird distribution.


=head1 SYNOPSIS

This is a sub-module which is part of the SMS::MessageBird distribution.

While this module can be used directly, it's designed to be used via
L<SMS::MessageBird>


=head1 DESCRIPTION

This module provides the interface to the HLR related methods of the MessageBird
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

This method implements the POST /hlr route of the API.

Requests an HLR lookup for a given MSISDN.

Accepted parameters are listed in the MessageBird API documentation.

Require parameters are as follows:

=over

=item msisdn

The MSISDN formatted telephone number to do the network query on.

=item reference

A client reference string for human reference.

=back

=cut

sub request {
    my ($self, %params) = @_;

    return $self->_api_request(
        post => "/hlr",
        \%params,
    );
}


=head2 get

  In:  $hlr_id   - The HLR ID returned by the request call.
  Out: $response - Hashref of response data. See "Response Data" above.

This method implements the GET /hlr/{hlr_id} route of the API.

Attempts to retrieve the result of a previously requested HLR.

Please see the L<MessageBird API Documentation|https://www.messagebird.com/en-gb/developers>
for more information.

=cut

sub get {
    my ($self, $hlr_id) = @_;

    my $route = ($hlr_id) ? "/hlr/$hlr_id"
                          : '/hlr';

    return $self->_api_request( get => $route );
}


=head2 remove

  In:  $hlr_id   - The HLR ID returned by the request call.
  Out: $response - Hashref of response data. See "Response Data" above.

This method implements the DELETE /hlr/{hlr_id} route of the API.

Deletes the result of a previously requested HLR.

Please see the L<MessageBird API Documentation|https://www.messagebird.com/en-gb/developers>
for more information.

=cut

sub remove {
    my ($self, $hlr_id) = @_;

    return $self->_no_param_supplied('HLR ID') if !$hlr_id;

    return $self->_api_request( delete => "/hlr/$hlr_id" );
}


=head2 del

Synonym for the L<remove()|/"remove"> method.

=cut

sub del {
    my ($self, $hlr_id) = @_;

    return $self->remove($hlr_id);
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


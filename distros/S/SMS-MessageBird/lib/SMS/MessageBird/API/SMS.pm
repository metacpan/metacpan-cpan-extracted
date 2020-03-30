package SMS::MessageBird::API::SMS;

use strict;
use warnings;

use parent 'SMS::MessageBird::API';

=head1 NAME

SMS::MessageBird::API::SMS - Sub-module for the SMS::MessageBird distribution.


=head1 SYNOPSIS

This is a sub-module which is part of the SMS::MessageBird distribution.

While this module can be used directly, it's designed to be used via
L<SMS::MessageBird>


=head1 DESCRIPTION

This module provides the interface to the SMS sending methods of the MessageBird
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


=head2 send

  In:  %params   - Hash of params accepted by the MessageBird API.
  Out: $response - Hashref of response data. See "Response Data" above.

This method implements the POST /messages route of the API.

Accepted parameters are listed in the MessageBird API documentation.

Require parameters are as follows:

=over

=item originator

The originator parameter is required but can be omitted if set when
instantiating the SMS::MessageBird module.

=item recipients

The recipients parameter is required and can be either a scalar containing a
single MSISDN (mobile number) or an arrayref containing many recipients.

=item body

The body parameter is required. Scalar containing the text of the message.

=back

All other parameters are optional.

Please see the L<MessageBird API Documentation|https://www.messagebird.com/en-gb/developers>
for more information.

=cut

sub send {
    my ($self, %params) = @_;

    if (!exists $params{originator}) {
        $params{originator} = $self->{originator};
    }

    return $self->_api_request(
        post => '/messages',
        \%params
    );
}


=head2 receive

  In:  $mesasge_id - Optional ID of the message to recieve.
  Out: $response   - Hashref of response data. See "Response Data" above.

This method implements the GET /messages/{message_id} route of the API.

If supplied with a $message_id, that one message will be returned. If omitted,
a complete list of messages will be returned.

Please see the L<MessageBird API Documentation|https://www.messagebird.com/en-gb/developers>
for more information.

=cut

sub receive {
    my ($self, $message_id) = @_;

    my $route = ($message_id) ? "/messages/$message_id"
                              : '/messages';

    return $self->_api_request( get => $route );
}


=head2 get

Synonym for the L<receive()|/"receive"> method.

=cut

sub get {
    my ($self, $message_id) = @_;
    return $self->receive($message_id);
}


=head2 search

 In: %filters - Hashref of filter key / data pairs
 Out: $response - Hashref of reponse data. See "Response Data" above.

Search sent messages by criterion rather than getting a specifc message by id.

Please see the L<MessageBird API Documentation for message filtering|https://developers.messagebird.com/api/sms-messaging#list-messages>
for a complete list of filters.

B<Fair warning>: MessageBird's API seems to ignore the documented "searchterm"
paramter - which isn't an option via their portal, so perhaps doesn't work. It
will, however, allow you to filter by status, recipient and originator. So it's
of some use. Limit has a minimum of 10.

=cut

sub search {
    my ($self, %filters) = @_;

    return $self->_api_request( get => '/messages', \%filters );
}


=head2 remove

  In: $message_id - The message_id to remove.
  Out: $response   - Hashref of response data. See "Response Data" above.

This method implements the DELETE /messages/{message_id} route of the API.

Deletes the SMS with identifier $message_id.

Please see the L<MessageBird API Documentation|https://www.messagebird.com/en-gb/developers>
for more information.

=cut

sub remove {
    my ($self, $message_id) = @_;

    return $self->_no_param_supplied('message ID') if !$message_id;

    return $self->_api_request( delete => "/messages/$message_id" );
}


=head2 del

Synonym for the L<remove()|/"remove"> method.

=cut

sub del {
    my ($self, $message_id) = @_;

    return $self->remove($message_id);
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


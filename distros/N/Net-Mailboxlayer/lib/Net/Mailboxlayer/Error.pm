package Net::Mailboxlayer::Error;

use strict;
use warnings;

$Net::Mailboxlayer::Error::VERSION = '0.001';

sub new
{
    my ($class, %props) = @_;

    my $self = bless \%props, $class;

    return $self;
}
sub has_error {return 1}
sub success   {return $_[0]->{success}}
sub type      {return $_[0]->{error}->{type}}
sub info      {return $_[0]->{error}->{info}}
sub code      {return $_[0]->{error}->{code}}
sub response  {return $_[0]->{_response}}

1;

__END__

=encoding utf-8

=head1 NAME

Net::Mailboxlayer::Error - Encapsulates an error response from mailboxlayer.com's REST API.

=head1 SYNOPSIS

 use Net::Mailboxlayer;

 my $mailboxlayer = Net::Mailboxlayer->new(access_key => 'YOUR_ACCESS_KEY', email_address => 'support@apilayer.com');
 my $result = $mailboxlayer->check;

 if ($result->has_error)
 {
   # $result is a F<Net::Mailboxlayer::Error> object.
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Net::Mailboxlayer>'s check method.

The errors provided are developer oriented, you probably don't want to pass them onto your users.

For API errors, see the official docs (https://mailboxlayer.com/documentation) for more information.

It is also possible that the errors are generated from $user_agent->get(), so you may also want to see the F<HTTP::Response> documentation.

=head2 new

Returns a new Net::Mailboxlayer::Error object.

=head2 has_error

This is a convenience method that allows you to determine if the result object had an error or not.  For this module if will always be 1 (true).

=head2 success

This is always set to 0 for the F<Net::Mailboxlayer::Error> object, but it is not available in the F<Net::Mailboxlayer::Response> object.  C<has_error> is the preferred way to check for success.

 print $response->success; # 0

=head2 type

An internal error type.

=head2 info

A short text description of the error which may contain suggestions.

=head2 code

The numeric code of the API Error.  In addition to the API errors, you can also get errors from your useragent

=head2 response

Provides access to the return value of $user_agent->get().  In typical usage, this would be a F<HTTP::Response> object.  You do not normally need to access this.

 print $result->response->decoded_content; # prints the JSON return from the api call.


=head1 AUTHOR

Tom Heady <cpan@punch.net>

=head1 COPYRIGHT & LICENSE

Copyright 2016 Tom Heady.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
    Software Foundation; either version 1, or (at your option) any
    later version, or

=item * the Artistic License.

=back

=cut

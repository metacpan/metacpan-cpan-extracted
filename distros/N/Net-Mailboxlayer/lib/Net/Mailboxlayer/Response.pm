package Net::Mailboxlayer::Response;

use strict;
use warnings;

$Net::Mailboxlayer::Response::VERSION = '0.003';

sub new
{
    my ($class, %props) = @_;
    my $self = bless \%props, $class;
    return $self;
}

sub has_error    {return 0}
sub email        {return $_[0]->{email}}
sub did_you_mean {return $_[0]->{did_you_mean}}
sub user         {return $_[0]->{user}}
sub domain       {return $_[0]->{domain}}
sub format_valid {return $_[0]->{format_valid}}
sub mx_found     {return $_[0]->{mx_found}}
sub smtp_check   {return $_[0]->{smtp_check}}
sub catch_all    {return $_[0]->{catch_all}}
sub role         {return $_[0]->{role}}
sub disposable   {return $_[0]->{disposable}}
sub free         {return $_[0]->{free}}
sub score        {return $_[0]->{score}}
sub response     {return $_[0]->{_response}}

1;

__END__

=encoding utf-8

=head1 NAME

Net::Mailboxlayer::Response - Encapsulates a response from mailboxlayer.com's REST API.

=head1 SYNOPSIS

 use Net::Mailboxlayer;

 my $mailboxlayer = Net::Mailboxlayer->new(access_key => 'YOUR_ACCESS_KEY', email_address => 'support@apilayer.com');
 my $result = $mailboxlayer->check;

 if (not $result->has_error)
 {
   # $result is a F<Net::Mailboxlayer::Response> object.
   print $result->score . "\n";
 }

=head1 DESCRIPTION

You would not normally be calling this module directly, it is one of the possible return objects from a call to F<Net::Mailboxlayer>'s check method.

=head2 new

Returns a new Net::Mailboxlayer::Response object.

=head2 has_error

This is a convenience method that allows you to determine if the result object had an error or not.  For this module if will always be 0 (false).

=head2 email

Contains the exact email address requested

 print $result->email; # support@apilayer.com

=head2 did_you_mean

Contains a did-you-mean suggestion in case a potential typo has been detected.

 print $result->did_you_mean; # ""

=head2 user

Returns the local part of the request email address. (e.g. "paul" in "paul@company.com")

 print $result->user; # support

=head2 domain

Returns the domain of the requested email address. (e.g. "company.com" in "paul@company.com")

 print $result->domain; # apilayer.net

=head2 format_valid

Returns true or false depending on whether or not the general syntax of the requested email address is valid.

 print $result->format_valid; # 1

=head2 mx_found

Returns true or false depending on whether or not MX-Records for the requested domain could be found.

 print $result->mx_found; # 1

=head2 smtp_check

Returns true or false depending on whether or not the SMTP check of the requested email address succeeded.

 print $result->smtp_check; # 1

=head2 catch_all

Returns true or false depending on whether or not the requested email address is found to be part of a catch-all mailbox.

 print $result->catch_all; # undef

Note that as of 2016-08-12 this will always be undef for free accounts.

=head2 role

Returns true or false depending on whether or not the requested email address is a role email address. (e.g. "support@company.com", "postmaster@company.com")

 print $result->role; # 1

=head2 disposable

Returns true or false depending on whether or not the requested email address is a disposable email address. (e.g. "user123@mailinator.com")

 print $result->disposable; # 0

=head2 free

Returns true or false depending on whether or not the requested email address is a free email address. (e.g. "user123@gmail.com", "user123@yahoo.com")

 print $result->free; # 0

=head2 score

Returns a numeric score between 0 and 1 reflecting the quality and deliverability of the requested email address.

 print $result->score; # 0.8

=head2 response

Provides access to the return value of $user_agent->get().  You would not normally need to access this.

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

package Net::RDAP::Error;
use base qw(Net::RDAP::Object);
use strict;
use warnings;

=head1 NAME

L<Net::RDAP::Error> - a module representing an RDAP error.

=head1 DESCRIPTION

L<Net::RDAP::Object::Error> represents an error. This could
be either an error returned by an RDAP server, or an internally
generated error.

L<Net::RDAP::Object::Error> inherits from L<Net::RDAP::Object> so has
access to all that module's methods.

=head1 METHODS

    $code = $error->errorCode;

Returns the error code number (corresponding to the HTTP response
code). Internally generated errors are usually C<400> if the arguments
passed to L<Net::RDAP> are invalid in some way, and C<500> if the
response from the server is invalid or cannot be reached.

    $title = $error->title;

Returns a string containing a short summary of the error.

    @description = $error->description;

Returns a (potentially empty) array of lines of descriptive text.

=cut

sub errorCode   { $_[0]->{'errorCode'} }
sub title       { $_[0]->{'title'} }
sub description { $_[0]->{'description'} ? @{$_[0]->{'description'}} : () }

=pod

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024-2025 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;

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

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. All rights reserved.

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1;

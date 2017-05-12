package Net::Delicious::Constants::Uri;
use strict;

# $Id: Uri.pm,v 1.11 2008/03/03 16:55:04 asc Exp $
$Net::Delicious::Constants::Uri::VERSION = '1.14';

use URI;

=head1 NAME

Net::Delicious::Constants::Uri - constant variables for del.icio.us URIs

=head1 SYNOPSIS

 use Net::Delicious::Constants qw (:uri)

=head1 DESCRIPTION

Constant variables for del.icio.us URIs.
cut

=head1 CONSTANTS

=cut

=head2 URI_DELICIOUS

String.

=cut

use constant URI_DELICIOUS => URI->new("http://del.icio.us");

=head2 URI_API

String.

=cut

use constant URI_API => URI->new("https://api.del.icio.us/v1/"); 

BEGIN {
  use vars qw (@EXPORT_OK);

  @EXPORT_OK = qw (URI_DELICIOUS
		   URI_API);
}

=head1 VERSION

1.13

=head1 DATE

$Date: 2008/03/03 16:55:04 $

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 SEE ALSO

L<Net::Delicious>

L<Net::Delicious::Constants>

=head1 LICENSE

Copyright (c) 2004-2008 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;

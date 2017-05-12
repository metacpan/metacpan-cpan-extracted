package Net::Delicious::Constants::Response;
use strict;

# $Id: Response.pm,v 1.12 2008/03/03 16:55:04 asc Exp $

=head1 NAME

Net::Delicious::Constants::Response - constant variables for del.icio.us response messages

=head1 SYNOPSIS

 use Net::Delicious::Constants qw (:response)

=head1 DESCRIPTION

Constant variables for del.icio.us response messages.

=cut

$Net::Delicious::Constants::Response::VERSION = '1.14';

=head1 CONSTANTS

=cut

=head2 RESPONSE_ERROR

String.

=cut

use constant RESPONSE_ERROR => "something went wrong";

=head2 RESPONSE_DONE

String.

=cut

use constant RESPONSE_DONE  => "done";

use constant RESPONSE_OK => "ok";

BEGIN {
    use vars qw (@EXPORT_OK);

    @EXPORT_OK = qw (RESPONSE_ERROR
		     RESPONSE_DONE
		     RESPONSE_OK);
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

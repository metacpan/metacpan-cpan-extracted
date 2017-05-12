# Copyright (c) 1993 - 2002 RIPE NCC
#
# All Rights Reserved
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose and without fee is hereby granted,
# provided that the above copyright notice appear in all copies and that
# both that copyright notice and this permission notice appear in
# supporting documentation, and that the name of the author not be
# used in advertising or publicity pertaining to distribution of the
# software without specific, written prior permission.
#
# THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
# ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS; IN NO EVENT SHALL
# AUTHOR BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
# DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
# AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

#
# $Id: Response.pm,v 1.7 2003/08/01 13:46:16 peter Exp $
#

=head1 NAME

Net::Whois::RIPE::Syncupdates::Response - Subclass to encapsulate Syncupdates responses

=head1 SYNOPSIS

=head1 CONSTANTS [TODO]

The HTTP response codes coming from the LWP call as a result of the HTTP
transaction.
        
    200 Acknowledgement follows
    413 Data exceeds maximum allowed size
    418 No input
    419 Command not understood
    506 Generic syncupdates error

=head1 METHODS

=over 4

=cut

package Net::Whois::RIPE::Syncupdates::Response;

use strict;
use warnings;
use Data::Dumper;

our $VERSION = '$Revision: 1.7 $ ' =~ /\$Revision:\s+([^\s]+)/;

=item new ( RAW_RESPONSE )

C<Net::Whois::RIPE::Syncupdates::Response> expects a string containing the result
of a syncupdates HTTP transaction.  It should contain full HTTP headers as well as
the backend's response in the body.

=cut

sub new {
    my $class = shift;
    my $raw_response = shift;

    die "Net::Whois::RIPE::Syncupdates::Response got empty response" unless $raw_response;

    my $self = {
        raw_response => $raw_response,
        http_code => '',
        messages => [],
    };
    bless $self, $class;
    $self->_parse_response($raw_response);

    return $self;
}

=item getCode ( )

Returns the HTTP response code.

=cut

sub getCode {
    my $self = shift;
    $self->_get('http_code');
}

=item asString ( )

=item as_string ( )

Returns the raw response string as it was supplied to new().  For debugging
purposes.

=cut

sub asString {
    my $self = shift;
    $self->_get('sup_message');
}

sub as_string { my $self = shift; $self->asString }

# Private methods

sub _parse_response {
    my $self = shift;
    my $sup_response = shift;

    my ($http_header, $sup_message) = $sup_response =~ /^(.*?)\n\n(.*)$/s;

    $self->_set('sup_message', $sup_message);

    my ($http_code, $http_msg) = $http_header =~ /^HTTP\S+\s+(\d+)\s+(.*)$/m;

    $self->_set('http_code', $http_code);
    $self->_set('http_message', $http_msg);

    return;

    return unless $sup_response;

    foreach ( split (/\n/, $sup_response) ){
        next if /^==+/;      # PGP line
        next if /^\s*$/;     # empty line
        s/\s*$//;            # chomp trailing whitespace

        if( /^Update ([A-Z]+): (.+)$/ ){
            my($result, $message) = ($1, $2);
        } else {
        }
    }
    return;
}

sub _get {
    my $self = shift;
    my $attr = shift;
    return $self->{$attr};
}

sub _set {
    my $self = shift;
    my $attr = shift;
    my $value = shift || '';

    return unless $attr;

    $self->{$attr} = $value;
    return $self->_get($attr);
}


1;



__END__

=back

=head1 AUTHOR

Peter Banik E<lt>peter@ripe.netE<gt>, Ziya Suzen E<lt>peter@ripe.netE<gt>

=head1 SEE ALSO

C<Net::Whois::RIPE::Syncupdates>
C<Net::Whois::RIPE::Syncupdates::Response>

=head1 VERSION

$Id: Response.pm,v 1.7 2003/08/01 13:46:16 peter Exp $

=head1 BUGS

Please report bugs to E<lt>swbugs@ripe.netE<gt>.

=head1 COPYRIGHT

Copyright (c) 1993 - 2003 RIPE NCC

All Rights Reserved

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be
used in advertising or publicity pertaining to distribution of the
software without specific, written prior permission.

THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS; IN NO EVENT SHALL
AUTHOR BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

=cut


package Nginx::Log::Entry;
use strict;
use warnings;
use Time::Piece;
use Nginx::ParseLog;
use HTTP::BrowserDetect;

our $VERSION = 0.05;

=head1 NAME

Nginx::Log::Entry - This class represents a single line from the Nginx combined access log (the default access log format). It provides methods to extract information from the log entry, such as the browser, operating system, request type, ip address and more. If you want to gather statistics about an Nginx log, consider using L<Nginx::Log::Statistics> which uses this class.

=cut

=head1 SYNOPSIS

    use Nginx::Log::Entry;
    my $entry = Nginx::Log::Entry->new(q{66.108.215.71 - - [24/Mar/2013:10:00:58 -0400] "GET / HTTP/1.1" 200 727 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:19.0) Gecko/20100101 Firefox/19.0"});
    print $entry->get_ip;
    # 66.108.215.71
    
    print $entry->get_os;
    # Linux

=cut

=head1 METHODS

=head2 new

Instantiates a new entry object, requires a line from the Nginx access.log as a string argument.

=cut

sub new {
    my ( $class, $log_line ) = @_;
    die "Error: no log string was passed to new" unless $log_line;
    my $self = Nginx::ParseLog::parse($log_line);
    $self->{detector} = HTTP::BrowserDetect->new( $self->{user_agent} );
    return bless $self, $class;
}

=head2 get_ip

Returns the requestor's ip address.

=cut

sub get_ip {
    my $self = shift;
    return $self->{ip};
}

=head2 get_datetime_obj

Returns a L<Time::Piece> object of the request datetime.

=cut

sub get_datetime_obj {
    my $self = shift;
    unless ( exists $self->{datetime_obj} ) {
        my $date_string = substr( $self->{time}, 0, -6 );
        $self->{datetime_obj} =
          Time::Piece->strptime( $date_string, "%d/%b/%Y:%H:%M:%S" );
    }
    return $self->{datetime_obj};
}

=head2 get_timezone

Returns the timezone GMT modifier, e.g. -400.

=cut

sub get_timezone {
    my $self = shift;
    return substr( $self->{time}, -5 );
}

=head2 was_robot

Returns 1 if the useragent string was a known robot, else returns 0.

=cut

sub was_robot {
    my $self = shift;
    return $self->{detector}->robot;
}

=head2 get_status

Returns the http status number of the request.

=cut

sub get_status {
    my $self = shift;
    return $self->{status};
}

=head2 get_request

Returns the request string.

=cut

sub get_request {
    my $self = shift;
    return $self->{request};
}

=head2 get_request_type

Returns the http request type, e.g. GET.

=cut

sub get_request_type {
    my $self = shift;
    my @request = split( ' ', $self->get_request );
    return $request[0];
}

=head2 get_request_url

Returns the requested url (excluding the base).

=cut

sub get_request_url {
    my $self = shift;
    my @request = split( ' ', $self->get_request );
    return $request[1];
}

=head2 get_request_http_version

Returns http/1 or http/1.1.

=cut

sub get_request_http_version {
    my $self = shift;
    my @request = split( ' ', $self->get_request );
    return $request[2];
}

=head2 was_request_successful

Returns 1 if the http status is a 200 series number (e.g. 200, 201, 202 etc), else returns 0.

=cut

sub was_request_successful {
    my $self   = shift;
    my $status = $self->get_status;
    return substr( $status, 0, 1 ) == 2 ? 1 : 0;
}

=head2 get_useragent

Returns the useragent string.

=cut

sub get_useragent {
    my $self = shift;
    return $self->{user_agent};
}

=head2 get_os

Returns the operating system, e.g. Windows.

=cut

sub get_os {
    my $self = shift;
    return $self->{detector}->os_string;
}

=head2 get_browser

Returns the browser type, e.g. Firefox.

=cut

sub get_browser {
    my $self = shift;
    return $self->{detector}->browser_string;
}

=head2 get_referer

Returns the referer, e.g. google.com.

=cut

sub get_referer {
    my $self = shift;
    return $self->{referer};
}

=head2 get_bytes

Returns the number of bytes sent, e.g. 754.

=cut

sub get_bytes {
    my $self = shift;
    return $self->{bytes_send};
}

=head2 get_remote_user

Returns the remote username. This is usually not set, and if not, returns '-' instead.

=cut

sub get_remote_user {
    my $self = shift;
    return $self->{remote_user};
}

=head1 AUTHOR

David Farrell, C<< <davidnmfarrell at gmail.com> >>, L<perltricks.com|http://perltricks.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nginx-log-statistics at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nginx-Log-Entry>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Nginx::Log::Entry


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Nginx-Log-Entry>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Nginx-Log-Entry>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Nginx-Log-Entry>

=item * Search CPAN

L<http://search.cpan.org/dist/Nginx-Log-Entry/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 David Farrell.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;

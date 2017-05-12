package Net::Tomcat::Connector::Scoreboard::Entry;

use strict;
use warnings;

our @ATTR       = qw(stage time client vhost request b_sent b_recv);

foreach my $attr ( @ATTR ) {{
        no strict 'refs';
        *{ __PACKAGE__ . "::$attr" } = sub {
                my ( $self, $val ) = @_;
                $self->{$attr} = $val if $val;

                return $self->{$attr} }
}}

sub new {
        my ( $class, %args )    = @_;
        
        my $self                = bless {}, $class;
        $self->{$_}             = $args{$_} for @ATTR;

        return $self
}

sub bytes_sent          { return $_[0]->{b_sent}        }

sub bytes_received      { return $_[0]->{b_recv}        }

1;

__END__

=head1 NAME

Net::Tomcat::Connector::Scoreboard::Entry - Utility class for representing 
Tomcat Connector scoreboard entries.

=head1 SYNOPSIS

A Net::Tomcat::Connector::Scoreboard object is an abstract collection of
L<Net::Tomcat::Connector::Scoreboard::Entry> objects.  This class exists
to provide higher level functions and syntactic sugar for accessing the
aforementioned objects.

=head1 METHODS

=head2 new

Constructor - creates a new Net::Tomcat::Connector::Statistics object.  Note 
that you should not normally need to call the constructor method directly as a 
Net::Tomcat::Connector::Statistics object will be created for you on invoking 
methods in parent classes.

=head2 bytes_sent

Returns the bytes sent for this scoreboard entry.

=head2 bytes_received

Returns the bytes received for this scoreboard entry.

=head2 client

Returns the client for the scoreboard entry - this may be either an IP address
or a FQDN.

=head2 request

Returns the request string.

=head2 stage

Returns the current stage of the request as a single character - one of either;

=over 4

=item R - Ready

=item P - Parsing

=item S - Servicing

=item F - Finishing

=item K - KeepAlive

=back

=head2 time

Returns the time spent servicing the request.

=head2 vhost

Returns the virtual host servicing the request.

=cut

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-tomcat-connector-statistics 
at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Tomcat-Connector-Statistics>.
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Tomcat::Server::Connector::Scoreboard::Entry

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Tomcat-Connector-Scoreboard-Entry>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Tomcat-Connector-Scoreboard-Entry>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Tomcat-Connector-Scoreboard-Entry>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Tomcat-Connector-Scoreboard-Entry/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Luke Poskitt.

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

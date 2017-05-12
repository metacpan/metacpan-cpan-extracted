package Net::Tomcat::Server;

use strict;
use warnings;

our @ATTR       = qw(jvm_vendor jvm_version os_architecture os_name os_version tomcat_version);

foreach my $attr ( @ATTR ) {{
        no strict 'refs';
        *{ __PACKAGE__ . '::' . $attr } = sub { my $self = shift; return $self->{$attr} }
}}

sub new {
        my ( $class, %args ) = @_;
        my $self = bless {}, $class;
        $self->{$_} = $args{$_} for @ATTR;
        $self->{__timestamp} = time;

        return $self;
}

sub __timestamp { return $_[0]->{__timestamp} }

1;

__END__

=head1 NAME

Net::Tomcat::Server - Utility class for representing Apache Tomcat Server objects.

=head1 SYNOPSIS

Net::Tomcat is a utility class for representing Apache Tomcat server objects.

        use Net::Tomcat;

        # Create a new Net::Tomcat object
        my $tc = Net::Tomcat->new(
                                username => 'admin',
                                password => 'password',
                                hostname => 'web-server-01.company.com'
                              ) 
                or die "Unable to create new Net::Tomcat object: $!\n";

        # Print the Tomcat server version and JVM version information
        print "Tomcat version: " . $tc->server->version . "\n"
            . "JVM version: " . $tc->server->jvm_version . "\n";


=head1 METHODS

=head2 jvm_vendor

Returns the JVM vendor information.

=head2 jvm_version

Returns the JVM version.

=head2 os_architecture

Returns the OS architecture.

=head2 os_name

Returns the OS name.

=head2 os_version

Returns the OS version.

=head2 tomcat_version

Returns the Apache Tomcat version.

=cut

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 REPOSITORY

L<https://github.com/ltp/Net-Tomcat>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-tomcat-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Tomcat-Server>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<Net::Tomcat>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Tomcat::Server

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Tomcat-Server>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Tomcat-Server>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Tomcat-Server>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Tomcat-Server/>

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

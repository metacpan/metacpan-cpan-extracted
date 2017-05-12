package Net::Tomcat::Connector::Statistics;

use strict;
use warnings;

our @ATTR       = qw(max_threads current_thread_count current_thread_busy max_processing_time 
                        processing_time request_count error_count bytes_received bytes_sent);

foreach my $attr ( @ATTR ) {{
        no strict 'refs';
        *{ __PACKAGE__ . "::$attr" } = sub { my $self = shift; return $self->{$attr} }
}}

sub new {
        my ( $class, %args ) = @_;

        my $self = bless {}, $class;
        $self->{$_}     = $args{$_} for @ATTR;
        
        return $self
}

1;
__END__

=head1 NAME

Net::Tomcat::Connector::Statistics - Utility class for representing Tomcat 
Connector statistics objects.

=head1 SYNOPSIS

Net::Tomcat::Connector::Statistics is a utility class for representing Tomcat 
Connector statistics.

        use Net::Tomcat;

        # Create a new Net::Tomcat object
        my $tc = Net::Tomcat->new(
                                username => 'admin',
                                password => 'password',
                                hostname => 'web-server-01.company.com'
                              ) 
                or die "Unable to create new Net::Tomcat object: $!\n";

        # Retrieve a Net::Tomcat::Connector::Statistics object by explicit
        # connector name
        my $stats = $tc->connector('http-8080')->stats;

        # Print the bytes received and sent
        printf( "Bytes received: %-20d\nBytes sent: %-20d\n",
                $stats->bytes_received,
                $stats->bytes_sent );

        # Retrieve a statistics value explicitly
        print "Request count: " 
                . $tc->connector('http-8080')
                      ->stats
                      ->request_count
                . "\n";




=head1 METHODS

=head3 new

Constructor - creates a new Net::Tomcat::Connector::Statistics object.  Note 
that you should not normally need to call the constructor method directly as a 
Net::Tomcat::Connector::Statistics object will be created for you on invoking 
methods in parent classes.

=head3 max_threads

Returns the number of maximum threads available for the connector.

=head3 current_thread_count

Returns the number of threads currently in use by the connector.

=head3 current_thread_busy

Returns the number of threads currently marked busy by the connector.

=head3 max_processing_time

Returns the maximum request processing time for the connector.

=head3 processing_time

Returns the total request processing time for the connector.

=head3 request_count

Returns the total number of requests processed for the connector.

=head3 error_count

Returns the total error count for the connector.

=head3 bytes_received

Returns the total number of bytes received by the connector.

=head3 bytes_sent

Returns the total number of bytes sent by the connector.

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

    perldoc Net::Tomcat::Connector::Statistics


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Tomcat-Connector-Statistics>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Tomcat-Statistics>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Tomcat-Connector-Statistics>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Tomcat-Connector-Statistics/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

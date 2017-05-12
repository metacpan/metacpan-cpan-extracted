package Net::Tomcat::Connector;

use strict;
use warnings;

use overload 
        ( '""' => \&name );

our @ATTR       = qw(name stats scoreboard);

foreach my $attr ( @ATTR ) {{
        no strict 'refs';
        *{ __PACKAGE__ . "::$attr" } = sub { 
                my $self = shift; return $self->{$attr} 
        }
}}

sub new {
        my ( $class, %args ) = @_;
        my $self = bless {}, $class;

        $self->{name}         = $args{name};
        $self->{stats}        = $args{stats};
        $self->{scoreboard}   = $args{scoreboard};

        return $self;
}

1;

__END__

=head1 NAME

Net::Tomcat::Connector - Utility class for representing Tomcat Connector objects

=head1 SYNOPSIS

Net::Tomcat::Connector is a utility class for representing Tomcat Connector objects.

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

        # Get all connectors as an array of Net::Tomcat::Connector objects
        my @connectors = $tc->connectors;

        # Print the connector names, and request and error counts
        foreach my $connector ( @connectors ) {
                print "Name: " . $connector->name . "\n"
                    . "Request Count: ".$connector->stats->request_count . "\n"
                    . "Error Count: ".$connector->stats->error_count . "\n\n"
        }

        # Directly access a connector by name
        print "http-8080 error count: " 
                . $tc->connector('http-8080')->stats->error_count . "\n";

=head1 METHODS

=head3 new

Constructor - creates a new Net::Tomcat::Connector.  Note that you should not
normally need to call the constructor method directly as a Net::Tomcat::Connector
object will be created for you on invoking methods in parent classes.

=head3 name

Returns the connector name.  Note that Net::Tomcat::Connector objects also use
this method to implement stringification as an overloaded method.

        # Print the connector name
        print "My connector name: " . $connector->name . "\n";
        # Or
        print "My connector name: $connector\n";

=head3 stats

Returns a L<Net::Tomcat::Connector::Statistics> object containing statistics
for the Tomcat connector.

=head3 scoreboard

Returns a L<Net::Tomcat::Connector::Scoreboard> object containing the server
scoreboard information for the connector.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-tomcat-connector at 
rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Tomcat-Connector>.  I 
will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Tomcat::Connector


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Tomcat-Connector>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Tomcat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Tomcat-Connector>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Tomcat-Connector/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

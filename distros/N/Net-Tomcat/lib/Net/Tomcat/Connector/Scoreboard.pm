package Net::Tomcat::Connector::Scoreboard;

use strict;
use warnings;

use overload ( '""' => \&pretty_print );

use  Net::Tomcat::Connector::Scoreboard::Entry;

our %STATES     = (     
                        R => 'ready', 
                        P => 'parse', 
                        S => 'service', 
                        F => 'finish',
                        K  => 'keepalive'
                );

foreach my $state ( keys %STATES ) {{
        no strict 'refs';
        *{ __PACKAGE__ . '::threads_' . $STATES{ $state } } = sub { 
                my $self = shift;
                return grep { $_->{stage} eq $state } @{ $self->{__threads} }
        }
}}

sub new {
        my ( $class, @args ) = @_;
        my $self = bless {}, $class;
        $self->{__timestamp} = time;
        my @h = @{ shift @args };

        for ( @args ) {
                my %a;
                @a{ @h } = @{ $_ };
                push @{ $self->{__threads} }, Net::Tomcat::Connector::Scoreboard::Entry->new( %a );
        }

        return $self;
}

sub threads             { return @{ $_[0]->{__threads } }       }

sub thread_count        { return scalar @{ $_[0]->{__threads} } }

sub threads_for_client {
        my ( $self, $client ) = @_;
        return grep { $_->{client} eq $client } @{ $self->{__threads} };
}

sub threads_for_vhost {
        my ( $self, $vhost ) = @_;
        return grep { $_->{vhost} eq $vhost } @{ $self->{__threads} };
}

sub __timestamp         { return $_[0]->{__timestamp}           }

sub pretty_print {
        my $self = shift;
        print <<PP;
+----------+----------+----------+----------+--------------------+--------------------+----------------------------------------+
|  Stage   |   Time   |  B Sent  |  B Recv  |       Client       |        VHost       |                Request                 |
+----------+----------+----------+----------+--------------------+--------------------+----------------------------------------+
PP
        map {
                printf( "|%9s |%9s |%9s |%9s |%19s |%19s |%39s |\n",
                        $_->stage,
                        $_->time,
                        $_->bytes_sent,
                        $_->bytes_received,
                        $_->client,
                        $_->vhost,
                        $_->request
                )
        } $self->threads;

print "+----------+----------+----------+----------+--------------------+--------------------+----------------------------------------+\n";
}

1;

__END__

=head1 NAME

Net::Tomcat::Connector::Scoreboard - Utility class for representing abstract 
Tomcat Connector scoreboard objects.

=head1 SYNOPSIS

A Net::Tomcat::Connector::Scoreboard object is an abstract collection of
L<Net::Tomcat::Connector::Scoreboard::Entry> objects.  This class exists
to provide higher level functions and syntactic sugar for accessing the
aforementioned objects.

        use Net::Tomcat;

        # Create a new Net::Tomcat object
        my $tc = Net::Tomcat->new(
                                username => 'admin',
                                password => 'password',
                                hostname => 'web-server-01.company.com'
                              ) 
                or die "Unable to create new Net::Tomcat object: $!\n";

        # Retrieve a Net::Tomcat::Connector::Scoreboard object by explicit
        # connector name
        my $sb = $tc->connector('http-8080')->scoreboard;

        # Extract or apply an interesting function to each of our
        # scoreboard threads (requests).
	my @threads_for_vhost = $sb->threads_for_vhost('myvhost');

	# Print out a graphical representation of the scoreboard.
	$sb->pretty_print;

	# Or, using the overloaded stringification
	print $sb;

=head1 METHODS

=head3 new

Constructor - creates a new Net::Tomcat::Connector::Statistics object.  Note 
that you should not normally need to call the constructor method directly as a 
Net::Tomcat::Connector::Statistics object will be created for you on invoking 
methods in parent classes.

=head3 threads

Returns an array of L<Net::Tomcat::Connector::Scoreboard::Entry> objects where
each object represents a thread currently being serviced by the connector.

=head3 thread_count

Returns the number of threads currently being services by the connector.

=head3 threads_ready

Returns the number of threads currently in a ready state.

=head3 threads_service

Returns the number of threads currently servicing a request.

=head3 threads_parse

Returns the number of threads currently in a parsing state.

=head3 threads_keepalive

Returns the number of threads currently in a keepalive state.

=head3 threads_finish

Returns the number of threads currently in a finish state.

=head3 threads_for_client ( $CLIENT )

	# Returns all threads for the client 10.80.8.8 on connector 'http-8080'
	my @threads = $tc->connector('http-8080')->scoreboard->threads_for_client( '10.80.8.8' );

Returns an array of L<Net::Tomcat::Connector::Scoreboard::Entry> objects where
each object represents a current thread servicing the client identified by the 
value of the $CLIENT parameter (usually an IP address).

=head3 threads_for_vhost ( $VHOST )
	
	# Return all threads for the virtual host 'www-4.company.com'
	my @threads = $tc->connector('http-8080')->scoreboard->threads_for_vhost( 'www-4.company.com' );

Returns an array of L<Net::Tomcat::Connector::Scoreboard::Entry> objects for
the virtual host (vhost) as defined by the value of the $VHOST parameter.

=head3 pretty_print

Prints an ascii representation of the scoreboard to standard out.

Note that this module also stringifies to this method.

=cut

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-tomcat-connector-statistics 
at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Tomcat-Connector-Statistics>.
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.
__END__


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Tomcat::Connector::Scoreboard


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Tomcat-Connector-Scoreboard>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Tomcat-Connector-Scoreboard>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Tomcat-Connector-Scoreboard>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Tomcat-Connector-Scoreboard/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

package Net::Tomcat;

use strict;
use warnings;

use LWP;
use Net::Tomcat::JVM;
use Net::Tomcat::Server;
use Net::Tomcat::Connector;
use Net::Tomcat::Connector::Scoreboard;
use Net::Tomcat::Connector::Statistics;

our $VERSION = '0.02';
our @ATTR = qw(username password hostname);
our $ATTR = {
	username		=>	{ required => 1					},
	password		=>	{ required => 1					},
	hostname		=>	{ required => 1					},
	port			=>	{ required => 0, default => 8080		},
	proto			=>	{ required => 0, default => 'http'		},
	app_status_url		=>	{ required => 0, default => '/manager/html/list'},
	server_status_url	=>	{ required => 0, default => '/manager/status/all'},
	refresh_interval	=>	{ required => 0, default => 3600		},
};

sub new {
	my ( $class, %args )  = @_;
	my $self        = bless {}, $class;

	for ( keys %{ $ATTR } ) {
		$ATTR->{$_}->{required} and ( defined $args{$_} or die "Mandatory parameter $_ not supplied in constructor\n" );
		$self->{$_} = ( $args{$_} or $ATTR->{$_}->{default} )
	}

	$self->{__ua}	= LWP::UserAgent->new();

	return $self
}

sub __request {
	my ( $self, $url ) = @_;

	my $res         = $self->{__ua}->get( "$self->{proto}://$self->{username}:$self->{password}"
						. "\@$self->{hostname}:$self->{port}$url" );

	$res->is_success and return $res->content;

	$self->{error}	= 'Unable to retrieve content: ' . $res->status_line;

	return 0
}

sub __is_valid {
	my ( $self, $o ) = @_;
	return ( defined $o and ( time - $o->{__timestamp} < $self->{refresh_interval} ) ? 1 : 0 )
}

sub server {
        my $self = shift;
        $self->__is_valid( $self->{__server} ) or $self->__get_server_status;
        return $self->{__server}
}

sub jvm {
	my $self = shift;
	$self->__is_valid( $self->{__jvm} ) or $self->__get_jvm_status;
	return $self->{__jvm}
}

sub connector {
        my ( $self, $connector ) = @_;

        for ( $self->connectors ) {
                return $_ if ( $_->name eq $connector )
        }

        warn "Connector '$connector' not defined\n";
}

sub connectors {
        my $self = shift;
        defined $self->{__connectors} 
                and ( time - $self->{__connector_timestamp} < $self->{refresh_interval} )
                or $self->__get_server_status;

	return @{ $self->{__connectors} }
}

sub __get_server_status {
	my $self = shift;
	$self->__parse_server_status ( $self->__request( $self->{server_status_url} ) );
}

sub __get_jvm_status {
	my $self = shift;
	$self->__parse_server_status ( $self->__request( $self->{server_status_url} ) );
}

sub __get_app_list {
	my $self = shift;
	my $s = $self->__request( $self->{app_status_url} )
}

sub __parse_server_status {
        my ( $self, $s ) = @_;
        
        grep { /Server Status/ } $s or return ( $self->{error} = 'Unable to retrieve server status' );

        my @c = split /<\/table>/, $s;

        $self->__process_server_information(            grep { /Server Information/        } @c );
        $self->__process_jvm_information(               grep { /<h1>JVM<\/h1>/             } @c );
        $self->__process_connector_information(         grep { /<h1>JVM<\/h1>/             } split /\n/, $s );
}

sub __process_server_information {
        my ( $self, $s ) = @_;

        my @c = grep { /<td/ } ( split /\n/, $s );
        my ( @k, @v, %a );
        
        for ( @c ) {
                if ( /header-center/ )  { push @k, __strip_and_clean( $_ )      }
                if ( /row-center/    )  { push @v, __strip( $_ )                }
        }

        @a{ @k } = @v;
        $self->{__server} = Net::Tomcat::Server->new( %a );
}

sub __process_jvm_information {
        my ( $self, $s ) = @_;

        ( $s ) = grep { /JVM/ } ( split /<\/p>/, $s );
        $self->{__jvm} = Net::Tomcat::JVM->new( __extract_fields( $s ) );
}

sub __process_connector_information {
        my ( $self, $s ) = @_;
        my @c = grep { /<\/table>/ } split /<h1>/, $s;

        for ( @c ) {
                next unless /<.*/;
                my ( $c_name, $c_stats ) = split /<\/h1>/;
                ( $c_stats, my $c_scoreboard ) = split /<\/p>/, $c_stats;
                $c_name         = __strip( $c_name );
                $c_stats        = Net::Tomcat::Connector::Statistics->new( __extract_fields( $c_stats ) );
                $c_scoreboard   = __process_scoreboard( $c_scoreboard );
                push @{ $self->{__connectors} }, 
                        Net::Tomcat::Connector->new(
                                name            => $c_name,
                                stats           => $c_stats,
                                scoreboard      => $c_scoreboard
                        );
                $self->{__connector_timestamp} = time;
        }
}

sub __process_scoreboard {
        my $s = shift;
        my @c = grep { !/<\/table>/ } split /<\/tr>/, $s;
        my @v = split /<\/th>/, ( shift @c );
        @v = [ map { __strip_and_clean( $_ ) } @v ];
        my ( %a );
        
        for ( @c ) {
                my @f = split /<\/td>/;
                @f = map { __strip( $_ ) } @f;
                push @v, [ @f ]
        }

        return Net::Tomcat::Connector::Scoreboard->new( @v )
}

sub __extract_fields {
        my $s = shift;
        $s =~ s/([A-Z]{1}[a-z]{1})/_$1/g;
        my @c = ( split /_/, $s );
        my ( @k, @v, %a );

        for ( @c ) {
                my ( $k, $v ) = split /:/;
                next unless $k and $v;
                push @k, __strip_and_clean( $k );
                push @v, __strip( $v );
        }
        
        @a{ @k } = @v;
        return %a
}

sub __strip {
        my $s = shift;
        $s =~ s|<.+?>||g;
        $s =~ s/^\s+|\s+$//g;
        return $s
}

sub __strip_and_clean {
        my $s = shift;
        $s = __strip( $s );
        $s =~ s| |_|g;
        $s = lc( $s );
        return $s
}

1; 

__END__

=head1 NAME

Net::Tomcat - A Perl API for monitoring Apache Tomcat.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Net::Tomcat is a Perl API for monitoring Apache Tomcat instances.

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
                    . "Request Count: ".$connector->request_count . "\n"
                    . "Error Count: ".$connector->error_count . "\n\n"
        }

        # Directly access a connector by name
        print "http-8080 error count: " 
                . $tc->connector('http-8080')->stats->error_count . "\n";

	# Retrieve a Net::Tomcat::Connector::Scoreboard object
	# representing the request scoreboard of the connector.
	my $scoreboard = $tc->connector('http-8080')->scoreboard;

	# Get all threads in a servicing state as 
	# Net::Tomcat::Connector::Scoreboard::Entry objects.
	my @threads = $scoreboard->threads_service;


=head1 METHODS

=head2 new ( %ARGS )

Constructor - creates a new Net::Tomcat object.  This method takes three
mandatory parameters and accepts six optional parameters.

=over 3

=item username

A valid username of a user account with access to the Tomcat management pages.

=item password

The password for the user account given for the username parameter above.

=item hostname

The resolvable hostname or IP address of the target Tomcat server.

=item port

The target port on the target Tomcat server on which to connect.

If this parameter is not specified then it defaults to port 8080.

=item proto

The protocol to use when connecting to the target Tomcat server.

If this parameter is not specified then it defaults to HTTP.

=item app_status_url

The relative URL of the Tomcat Web Application Manager web page.

This parameter is optional and if not provided will default to a value of 
'/manager/html/list'.

If this parameter is provided then it should be a relative URL in respect
to the hostname parameter.

=item server_status_url

The relative URL of the Tomcat Web Server Status web page.

This parameter is optional and if not provided will default to a value of 
'/manager/status/all'.

If this parameter is provided then it should be a relative URL in respect
to the hostname parameter.

=item refresh_interval

The interval in seconds after which any retrieved results should be regarded
as invalid and discarded.  After this period has elapsed, subsequent requests
for cached values will be issued to the Tomcat instance and the results will
be cached for the duration of the refresh_interval period.

Note that the refresh interval applies to all objects individually - that is;
a L<Net::Tomcat::Connector> object may have a different refresh interval than
a L<Net::Tomcat::Connector::Scoreboard> object.

This parameter is optional and defaults to 3600s.  Caution shoudl be exercised
when setting this parameter to avoid potential inconsistency in sequential
calls to assumed immutable objects.

=back

=head2 connector ( $CONNECTOR )

	# Print connector error count.
	my $connector = $tc->connector( 'http-8080' );
	print "Connecter http-8080 error count: " 
		. $connector->stats->error_count . "\n";

	# Or
	printf( "Connector %s error count: %s\n",
		$tc->connector('http-8080')->name,
		$tc->connector('http-8080')->stats->error_count
	);

Returns a L<Net::Tomcat::Connector> object where the connector name is
identified by the named $CONNECTOR parameter.

=head2 connectors

Returns an array of L<Net::Tomcat::Connector> objects representing all
connector instances on the server.

=head2 server

Returns a L<Net::Tomcat::Server> object for the current instance.

=head2 jvm

Returns a L<Net::Tomcat::JVM> object for the current instance.

=cut

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 REPOSITORY

L<https://github.com/ltp/Net-Tomcat>

=head1 SEE ALSO

L<Net::Tomcat::Server>
L<Net::Tomcat::Connector>
L<Net::Tomcat::Scoreboard>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-tomcat at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Tomcat>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Tomcat

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Tomcat>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Tomcat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Tomcat>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Tomcat/>

=back


=head1 ACKNOWLEDGEMENTS


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

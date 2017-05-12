package Nagios::Scrape;

use warnings;
use strict;

use CGI;
use LWP::UserAgent;
use Error;

=head1 NAME

Nagios::Scrape - Scrapes and Parses the status.cgi page of a Nagios installation

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This module uses LWP to retrieve the status.cgi page of a Nagios installation, parses
the data into a manageable format, and then makes it accessible.

This is a more lightweight solution to Nagios installations where the status.dat file
can reach 1+mb in size.

    use Nagios::Scrape;

    my $foo = Nagios::Scrape->new(username => $username, password => $password, url => $url);
    @service_alerts = $foo->get_service_status();
    @host_alerts = $foo->get_host_status();

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new class given a username and password.

    my $nagios = Nagios::Scrape->new(username => $username, password => $password, url => $url);

=cut

sub new {
    my ( $class, %attrs ) = @_;

    throw Error::Simple("Username is required") if ( !defined( $attrs{username} ) );
    throw Error::Simple("Password is required") if ( !defined( $attrs{password} ) );
    throw Error::Simple("URL is required")      if ( !defined( $attrs{url} ) );

    throw Error::Simple("Invalid URL. Example: http://localhost/cgi-bin/status.cgi")
      if ( ( $attrs{url} !~ m/^http/ ) || ( $attrs{url} !~ m/status.cgi$/ ) );

    # Sets default values for host and service states
    $attrs{host_state}    = 12;
    $attrs{service_state} = 28;

    bless \%attrs, $class;

}

=head2 host_state

This method allows you to filter certain host states. The table is as follows:

Hosts:
    PENDING     1
    UP          2
    DOWN        4
    UNREACHABLE 8

Add the number for each state that you want to see. For example, to see DOWN
and UNREACHABLE states, set this value to 12. (Default value).

=cut

sub host_state {
    my ( $self, $state ) = @_;
    $self->{host_state} = $state if ( defined($state) );
    return $self->{host_state};
}

=head2 service_state

This method allows you to filter certain service states. The table is as follows:

Services:
    PENDING     1
    OK          2
    WARNING     4
    UNKNOWN     8
    CRITICAL    16

Add the number for each state you would like to see. For example, to see WARNING,
UNKNOWN, and CRITICAL states, set the number to 28. (Default value).

=cut

sub service_state {
    my ( $self, $state ) = @_;
    $self->{service_state} = $state if ( defined($state) );
    return $self->{service_state};
}

=head2 get_service_status

Connects to given URL and retrieves the requested service statuses

=cut

sub get_service_status {
    my $self = shift;
    my $ua   = LWP::UserAgent->new;
    my $req =
      HTTP::Request->new( GET => $self->{url}
          . '?host=all&noheader=yes&servicestatustypes='
          . $self->{service_state} );
    $req->authorization_basic( $self->{username}, $self->{password} );
    my $response = $ua->request($req);

    if ( !$response->is_success ) {
        die(    "Could not connect to "
              . $self->{url} . " "
              . $response->status_line
              . "\n" );
    }

    return $self->parse_service_content( $response->content );

}

=head2 get_host_status

Connects to given url and retrieves host statuses

=cut

sub get_host_status {
    my $self = shift;
    my $ua   = LWP::UserAgent->new;
    my $req =
      HTTP::Request->new( GET => $self->{url}
          . '?hostgroup=all&noheader=yes&style=hostdetail&hoststatustypes='
          . $self->{host_state} );
    $req->authorization_basic( $self->{username}, $self->{password} );
    my $response = $ua->request($req);

    if ( !$response->is_success ) {
        die(    "Could not connect to "
              . $self->{url} . " "
              . $response->status_line
              . "\n" );
    }

    return $self->parse_host_content( $response->content );
}


=head2 parse_service_content

Will parse the service status page into a manageable array of hashed service details.

=cut

sub parse_service_content {
    my ( $self, $content ) = @_;

    my @alerts;
    my $host;

    while (
        $content =~ m%
            (?:<TD\s+align=left\s+valign=center\s+CLASS='status(?:Even|Odd|HOST[A-Z]+)'>
             <A\s+HREF='extinfo.cgi
             .+?
             #  Host name - will be empty TD pair if this is a continuation
             #  of a host with multiple alerts
             '>([^<]+)</A>|<TD></TD>)
             .+?
             #  ' Service description
             >([^<]+)</A>
             .+?
             #  Status
             CLASS='status[A-Z]+'>([A-Z]+)</TD>
             .+?
             #  ' Time
             nowrap>([^<]+)</TD>
             .+?
             #  Duration
             nowrap>([^<]+)</TD>
             .+?
             #  Attempts
             >([^<]+)</TD>
             .+?
             #  Status Information
             >([^<]+)</TD>
             .+?
           %xsmgi
      )
    {

        #  Host might be empty if this is a host with multiple alerts
        $host = $1 if (defined($1));

        my $alert = {
            'type'        => 'service',
            'host'        => $self->decode_html($host),
            'service'     => $self->decode_html($2),
            'status'      => $self->decode_html($3),
            'time'        => $self->decode_html($4),
            'duration'    => $self->decode_html($5),
            'attempts'    => $self->decode_html($6),
            'information' => $self->decode_html($7)
        };

        push( @alerts, $alert );

    }

    return @alerts;
}

=head2 parse_host_content

Will parse the host status page into a manageable array of hashed service details.

=cut

sub parse_host_content {
    my ($self, $content) = @_;
    my @alerts;

    while ($content =~ m%
             <TD\s+align=left\s+valign=center\s+CLASS='statusHOST[A-Z]+'>
             .+?
             #  Host name
             >([^<]+)</A>
             .+?
             #  Status
             <TD\s+CLASS='statusHOST[A-Z]+'>([^<]+)</TD>
             .+?
             #  Time
             nowrap>([^<]+)</TD>
             .+?
             #  Duration
             nowrap>([^<]+)</TD>
             .+?
             #  Status Information
             >([^<]+)</TD>
             .+?
           %xsmgi) {

        my $alert = {
            'type' => 'host',
            'host' => $self->decode_html($1),
            'status' => $self->decode_html($2),
            'time' => $self->decode_html($3),
            'duration' => $self->decode_html($4),
            'information' => $self->decode_html($5)
        };
        push(@alerts, $alert);
    }

    return @alerts;
}

=head2 decode_html

Simple helper method that smooths out HTML strings from Nagios status.cgi page

=cut

sub decode_html {
    my ( $self, $string ) = @_;
    $string = CGI::unescapeHTML($string);
    $string =~ s/nbsp//g;

    return $string;
}

=head1 AUTHOR

Joe Topjian, C<< <joe at terrarum.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nagios-scrape at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nagios-Scrape>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Nagios::Scrape


=head1 ACKNOWLEDGEMENTS

Some of this code was taken from www.nagios3book.com/nagios-3-enm/tts/nagios-ttsd.pl which is no longer online.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Joe Topjian.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Nagios::Scrape

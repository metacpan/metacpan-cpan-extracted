package Monit::HTTP;

=head1 NAME

Monit::HTTP - an OOP interface to Monit.

=cut

use LWP::UserAgent;
use XML::Bare;
use Error qw(:try);

use warnings;
use strict;

use constant {
    TYPE_FILESYSTEM => 0,
    TYPE_DIRECTORY  => 1,
    TYPE_FILE       => 2,
    TYPE_PROCESS    => 3,
    TYPE_HOST       => 4,
    TYPE_SYSTEM     => 5,
    TYPE_FIFO       => 6,
    TYPE_STATUS     => 7,

    ACTION_STOP      => 'stop',
    ACTION_START     => 'start',
    ACTION_RESTART   => 'restart',
    ACTION_MONITOR   => 'monitor',
    ACTION_UNMONITOR => 'unmonitor',
};

use Exporter;

our @EXPORT_OK = (
    'TYPE_FILESYSTEM',
    'TYPE_DIRECTORY', 
    'TYPE_FILE', 
    'TYPE_PROCESS',
    'TYPE_HOST',
    'TYPE_SYSTEM',
    'TYPE_FIFO',

    'ACTION_STOP',
    'ACTION_START',
    'ACTION_RESTART',
    'ACTION_MONITOR',
    'ACTION_UNMONITOR',
    );

our %EXPORT_TAGS = ( constants => [
    'TYPE_FILESYSTEM',
    'TYPE_DIRECTORY', 
    'TYPE_FILE', 
    'TYPE_PROCESS',
    'TYPE_HOST',
    'TYPE_SYSTEM',
    'TYPE_FIFO',

    'ACTION_STOP',
    'ACTION_START',
    'ACTION_RESTART',
    'ACTION_MONITOR',
    'ACTION_UNMONITOR',
    ]);

our @ISA = qw(Exporter);
our @EXPORT = qw(get_services command_run);


=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module exposes an interface to talk with Monit via its HTTP interface.
You can use it to get the status of all the monitored services on that particular
host such as CPU and Memory usage, current PID, parent PID, current running status, 
current monitoring status and so on.
The module can be used also for performing actions like:

=over

=item * Start/Stop/Restart services

=item * Monitor/Unmonitor services

    use Monit::HTTP ':constants';

    my $hd = new Monit::HTTP(
            hostname => '127.0.0.1',
            port     => '2812',
            use_auth => 1,
            username => 'admin', 
            password => 'monit',
            );

    eval {
        my @processes = $hd->get_services(TYPE_PROCESS);
        $hd->command_run($processes[0], ACTION_STOP);
        my $service_status_href = $hd->service_status($processes[0]);
    } or do {
            print $@;
    };


=back

=head1 EXPORTED CONSTANTS

This module exports a set of constants:

    TYPE_FILESYSTEM
    TYPE_DIRECTORY
    TYPE_FILE
    TYPE_PROCESS
    TYPE_HOST
    TYPE_SYSTEM
    TYPE_FIFO

    ACTION_STOP
    ACTION_START
    ACTION_RESTART
    ACTION_MONITOR
    ACTION_UNMONITOR

They are meant to be used as arguments of the methods.

=head1 METHODS

=head2 C<$monit = new Monit::HTTP (...)>

Constructor.
Create a new C<Monit::HTTP> object.
This constructor can be called passing a list of various parameters:

    my $monit = new Monit::HTTP (
                    hostname => localhost,
                    port => 2812,
                    use_auth => 1,
                    username => admin,
                    password => monit );

The values showed above are the default values in case no argument
is passed to the constructor.
If use_auth is equal to 1 (true) and username and password are not null the http 
request will be peformed using those usernames and password (basic http auth).
Be aware that if you provide username and password and you don't set
use_auth to be 1 authentication won't work.

=cut

sub new {
    my ($class, %self) = @_;

    # OOP stuff
    $class = ref($class) || $class;
    my $self = \%self;
    bless $self, $class;

    # set some defaults, if not already set
    $self->{hostname} ||= "localhost";
    $self->{port} ||= 2812;
    $self->{status_url} = 
        "http://".$self->{hostname}.":".$self->{port}."/_status?format=xml";
    $self->{use_auth} ||= 0;
    if($self->{use_auth}) {
        $self->{username} ||= "admin";
        $self->{password} ||= "monit";
    }

    return $self;
}

=head2 C<Monit::HTTP-E<gt>set_hostname($hostname)>

Set the hostname of the monit instance

=cut

sub set_hostname {
    my ($self, $hostname) = @_;
    $self->{hostname} = $hostname;
    $self->{status_url} = 
        "http://".$self->{hostname}.":".$self->{port}."/_status?format=xml";
}

=head2 C<Monit::HTTP-E<gt>set_port($port)>

Set the tcp port of the monit instance

=cut

sub set_port {
    my ($self, $port) = @_;
    $self->{port} = $port;
    $self->{status_url} = 
        "http://".$self->{hostname}.":".$self->{port}."/_status?format=xml";
}

=head2 C<Monit::HTTP-E<gt>set_username($username)>

Set the username to be used in thee basic http authentication

=cut

sub set_username {
    my ($self, $username) = @_;
    $self->{username} = $username;
}

=head2 C<Monit::HTTP-E<gt>set_password($password)>

Set the password to be used in thee basic http authentication

=cut

sub set_password {
    my ($self, $password ) = @_;
    $self->{password} = $password;
}

=head2 C<$res = Monit::HTTP-E<gt>_fetch_info()>

Called bye C<Monit::HTTP->get_services()>.
Does not need to be called by user. This is a private (internal) method
This private function connects via http (GET) to the monit server.

URL requested is http://<hostname>:<port>/_status?format=xml

An XML file is returned and parsed using XML::Bare.

The raw XML data is stored in the object using the _set_xml() method.
The raw XML data can be retrieved using _get_xml.

An hash reference of the XML data (as the one returned by the parse_xml function of
XML::Bare) is stored in the object.

=cut

sub _fetch_info {
    my ($self) = @_;

    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->agent("Perl Monit::HTTP/$VERSION");

    my $req = HTTP::Request->new(GET => $self->{status_url});
    if (defined $self->{username} and defined $self->{password} and $self->{use_auth}) {
        $req->authorization_basic($self->{username},$self->{password});
    }

    try {
        my $res = $self->{ua}->request($req);
        if ($res->is_success) {
            $self->_set_xml($res->content);
            my $xml = new XML::Bare(text => $self->_get_xml);
            $self->{xml_hash} = $xml->parse();
        } else {
            my $err = "Error while connecting to ".
                $self->{status_url}." !\nError details: $@";
            throw Error::Simple($err);
        }
    } 
    catch Error with {
        my $ex = shift;
        $ex->throw();
    };
}

=head2 C<$res = Monit::HTTP-E<gt>get_services()>

Return an array of services configured on the remote monit daemon.

In case of any exepction an error is thrown and undef is returned.

=cut

sub get_services {
    my ($self, $type) = @_;
    my @services;
    $type ||= "-1";

    if ($type != TYPE_FILESYSTEM and
        $type != TYPE_DIRECTORY and
        $type != TYPE_FILE and
        $type != TYPE_PROCESS and
        $type != TYPE_HOST and
        $type != TYPE_SYSTEM and
        $type != TYPE_FIFO and
        $type != TYPE_STATUS and 
        $type != -1 ) {

            throw Error::Simple("Don't understand this service type!");
            return undef;
    }

    $self->_fetch_info;

    foreach my $s (@{$self->{xml_hash}->{monit}->{service}}) {
        if (($type != -1 and $s->{type}->{value} == $type) or ($type == -1)) {
            push @services,  $s->{name}->{value};
        }
    }
    return @services;
}

=head2 C<$res = Monit::HTTP-E<gt>_set_xml($xml)>

Private method to set raw xml data.
Called from C<Monit::HTTP->_fetch_info()>

=cut

sub _set_xml {
    my ($self, $xml) = @_;
    $self->{status_raw_content} = $xml;
}

=head2 C<$res = Monit::HTTP-E<gt>_get_xml($xml)>

Private method to get raw xml data.
Called from C<Monit::HTTP->_fetch_info()>

=cut

sub _get_xml {
    my ($self) = @_;
    return $self->{status_raw_content};
}

=head2 C<$hashref_tree =
Monit::HTTP-E<gt>service_status($servicename)>

Returns the status for a particular service in form of hash with all the info 
for that service.
Return undef is the service does not exists.
To know the structure of the hash ref use Data::Dumper :D

=cut

sub service_status {
    my ($self, $service) = @_;
    my $status_href = {};

    $self->_fetch_info;

    foreach my $s (@{$self->{xml_hash}->{monit}->{service}}) {
        if ($s->{name}->{value} eq $service) {
            $status_href->{name} = $s->{name}->{value};
            $status_href->{type} = $s->{type}->{value};
            $status_href->{status}  = $s->{status}->{value};
            $status_href->{pendingaction} = $s->{pendingaction}->{value};
            $status_href->{monitor} = $s->{monitor}->{value};
            $status_href->{group} = $s->{group}->{value};
            $status_href->{pid} = $s->{pid}->{value};
            $status_href->{ppid} = $s->{ppid}->{value};
            $status_href->{uptime} = $s->{uptime}->{value};
            $status_href->{children} = $s->{children}->{value};
            $status_href->{memory}->{kilobyte} = $s->{memory}->{kilobyte}->{value};
            $status_href->{memory}->{kilobytetotal} = $s->{memory}->{kilobytetotal}->{value};
            $status_href->{memory}->{percent} = $s->{memory}->{percent}->{value};
            $status_href->{memory}->{percenttotal} = $s->{memory}->{percenttotal}->{value};
            $status_href->{cpu}->{percent} = $s->{cpu}->{percent}->{value};
            $status_href->{cpu}->{percenttotal} = $s->{cpu}->{percenttotal}->{value};
            $status_href->{host} = $self->{hostname};
            $status_href->{load}->{avg01} = $s->{load}->{avg01}->{value};
            $status_href->{load}->{avg05} = $s->{load}->{avg05}->{value};
            $status_href->{load}->{avg15} = $s->{load}->{avg15}->{value};
        }
    }

    if (! scalar keys %$status_href) {
        throw Error::Simple("Service $service does not exist");
        return undef;
    } else { return $status_href; }
}

=head2 C<$hashref_tree = Monit::HTTP-E<gt>command_run($servicename,
$command)>

Perform an action against a service.
$command can be a constant (ACTION_STOP, ACTION_START, ACTION_RESTART, ACTION_MONITOR, ACTION_UNMONITOR)

This method throws errors in case something goes wrong. Use eval { } statement to catch the error.

=cut

sub command_run {
    my ($self, $service, $command) = @_;

    if ($command ne ACTION_STOP and
        $command ne ACTION_START and
        $command ne ACTION_RESTART and
        $command ne ACTION_MONITOR and
        $command ne ACTION_UNMONITOR ) {

            throw Error::Simple("Don't understand this action");
            return;
    }

    if(not defined $service) {
        $self->{is_success} = 0;
        throw Error::Simple "Service not specified";
        return;
    }

    # if services does not exist throw error

    my $url = "http://" . $self->{hostname} . ":" . $self->{port} . "/" . $service;

    my $req = HTTP::Request->new(POST => $url);
    push @{ $self->{ua}->requests_redirectable }, 'POST';
    $req->content_type('application/x-www-form-urlencoded');
    $req->content("action=$command");

    if (defined $self->{username} and defined $self->{password}) {
        $req->authorization_basic($self->{username},$self->{password});
    }
    try {
        my $res = $self->{ua}->request($req);
        if (! $res->is_success) {
            throw Error::Simple($res->status_line);
        }
    } 
    catch Error with {
        my $ex = shift;
        $ex->throw();
    };
}

=head1 AUTHOR

Angelo "pallotron" Failla, C<< <pallotron at freaknet.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-monit-http-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Monit-HTTP-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Monit::HTTP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Monit-HTTP-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Monit-HTTP-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Monit-HTTP-API>

=item * Search CPAN

L<http://search.cpan.org/dist/Monit-HTTP-API>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Angelo "pallotron" Failla, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Monit::HTTP

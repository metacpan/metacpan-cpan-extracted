package Net::pWhoIs;

use strict;
use Socket;
use IO::Socket::INET;
use Scalar::Util 'reftype';

our $VERSION = '0.06';
 
$| = 1;

######################################################
sub new {
######################################################
    my ($class, $args) = @_;
    my $self;

    my %defaults = (
        pwhoisserver => 'whois.pwhois.org',
        port         => 43,
    );

    # Apply defaults.
    for my $key (keys %defaults) {
        $self->{$key} = $defaults{$key};
    }

    # Apply arguments passed by human.
    # They may clobber our defaults.
    for my $key (keys %{$args}) {
        $self->{$key} = $args->{$key};
    }

    bless $self, $class;

    return $self;
}

######################################################
sub resolveReq {
######################################################
    my $self = shift;
    my $what = shift;

    if ($what !~ /\\d+\\.\\d+\\.\\d+\\.\\d+/) {
        my @host = gethostbyname($what);
        if (scalar(@host) == 0) {
            return;
        } else {
            return Socket::inet_ntoa($host[4]);
        }
    }
}

######################################################
sub pwhois {
######################################################
    my $self = shift;
    my $what = shift;

    my @req;

    # Here for legacy purposes only.
    if ($self->{req}) { 
        @req  = @{$self->{req}};
    }

    # Passed value shall trump legacy.
    if ($what) {
        if (Scalar::Util::reftype($what) eq 'ARRAY') {
            @req  = @{$what};
        }
        else {
            push @req, $what;
        }
    }

    if (! @req) {
        # Nothing to process.
        return;
    }

    my $socket = new IO::Socket::INET (
        PeerHost => $self->{pwhoisserver},
        PeerPort => $self->{port},
        Proto    => 'tcp',
    );
    die "Cannot connect to server $!\n" unless $socket;

    # Build request
    # This array is needed to handle hosts which can't be resolved to IP.
    my @req_new;
    my $request = "begin\n";
    for my $elmt (@req) {
        my $resolved = $self->resolveReq($elmt);
        if ($resolved) {
            $request .= "$resolved\n";
	    push @req_new, $elmt;
        }
    }
    $request .= "end\n";

    $socket->send($request);
    shutdown($socket, 1);

    my $responses;
    while (my $line = $socket->getline) {
        $responses .= $line;
    }
    $socket->close();

    my %results;
    my $cntr = 0;
    for my $response (split /\n\n/, $responses) {
        my $formatted = $self->formatResponse($response);
        $results{$req_new[$cntr++]} = $formatted;
    }

    return \%results;
}

######################################################
sub formatResponse {
######################################################
    my $self = shift;
    my $what = shift;

    my @lines = split /\n/, $what;

    my %formatted;
    for my $line (@lines) {
        my ($name, $value) = split /:\s/, $line;
        if ($name && $value) {
            $formatted{lc($name)} = $value;
        }
    }

    return \%formatted;
}

######################################################
sub printReport {
######################################################
    my $self = shift;
    my $what = shift;

    my $report;
    for my $req (keys %{$what}) {
        $report .= sprintf ("Request: %s\n", $req);
        for my $key (sort keys %{$what->{$req}}) {
            $report .= sprintf("%-22s : %s\n", $key, $what->{$req}{$key});
        }
    }
    return $report;
}

1;

=head1 NAME

Net::pWhoIs - Client library for Prefix WhoIs (pWhois)

=head1 SYNOPSIS

    use Net::pWhoIs;

    my $obj = Net::pWhoIs->new();
  
    # You may pass hostnames or IP addresses.
    my @array = qw(
        166.70.12.30
        207.20.243.105
        67.225.131.208
        perlmonks.org
	brokenhost.brokendomain.co
        8.8.8.8
        12.12.12.12
        ftp2.freebsd.org
    );

    # You can pass an array.
    my $output = $obj->pwhois(\@array);

    # Or you can pass a scalar.
    my $output = $obj->pwhois('8.8.8.8');

    # Generate a formatted report.
    print $obj->printReport($output);
  
    # Or manipulate the data yourself.
    for my $req (keys %{$output}) {
        # req contains queried item.
	print $req, "\n";
        for my $key (keys %{$output->{$req}}) {
	    # key contains name of pwhois query result item.  Output ref contains value of pwhois query result item.
            printf("%s : %s\n", $key, $output->{$req}{$key});
        }

	# Or grab it direct.
        print $output->{$req}{'city'}, "\n";
        print $output->{$req}{'org-name'}, "\n";
    }


=head1 DESCRIPTION

Client library for pWhois service.  Includes support for bulk queries.

=head1 CONSTRUCTOR

=over 4

=item $obj = Net::pWhoIs->new( %options )

Construct a new C<Net::pWhoIs> object and return it.
Key/value pair arguments may be provided to set up the initial state.
The 

    pwhoisserver  whois.pwhois.org
    port          43

=back

=head1 METHODS

The following methods are available:

=over 4

=item Net::pWhoIs->pwhois()

Perform queries on passed arrayref or scalar.  Thus both single query and bulk queries supported.  Returns a hash of hashrefs.  Unresolvable hostnames are skipped.

=back

=over 4

=item Net::pWhoIs->printReport()

An optional method which generates a formated report to stdout.  Accepts returned output from Net::pWhoIs->pwhois()

=back

=head1 Client

A full featured client is included: pwhoiscli.pl.  Pass it hostnames or IP seperated by space.

=head1 OUTPUT HASHREF KEYS

The following is the list hashref keys returned by pwhois.

    as-org-name
    as-path
    cache-date
    city
    country
    country-code
    ip
    latitude
    longitude
    net-name
    org-name
    origin-as
    prefix
    region
    route-originated-date
    route-originated-ts

=head1 AUTHOR

Matt Hersant <matt_hersant@yahoo.com>

=cut

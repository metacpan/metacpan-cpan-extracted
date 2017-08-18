package Net::pWhoIs;

use strict;
use Socket;
use IO::Socket::INET;
use Scalar::Util 'reftype';

our $VERSION = '0.01';
 
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

    if (!$self->{req}) {
        die "Attribute 'req' is required for this module.\n";
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
            die "Failed host to resolve to IP: $what\n";
        } else {
            return Socket::inet_ntoa($host[4]);
        }
    }
}

######################################################
sub pwhois {
######################################################
    my $self = shift;

    if (Scalar::Util::reftype($self->{req}) eq 'ARRAY') {
        return $self->pwhoisBulk();
    }

    my $socket = new IO::Socket::INET (
        PeerHost => $self->{pwhoisserver},
        PeerPort => $self->{port},
        Proto    => 'tcp',
    );
    die "Cannot connect to server $!\n" unless $socket;

    my $resolved = $self->resolveReq($self->{req});
    my $size = $socket->send($resolved);

    shutdown($socket, 1);
 
    my $response;
    $socket->recv($response, 1024);
    $socket->close();

    my $formatted;
    if ($response) {
        $formatted = $self->formatResponse($response);
    }
    return $formatted;
}

######################################################
sub pwhoisBulk {
######################################################
    my $self = shift;

    my $socket = new IO::Socket::INET (
        PeerHost => $self->{pwhoisserver},
        PeerPort => $self->{port},
        Proto    => 'tcp',
    );
    die "Cannot connect to server $!\n" unless $socket;

    $socket->send("begin\n");

    my %results;
    for my $elmt (@{$self->{req}}) {
        my $resolved = $self->resolveReq($elmt);

        $socket->send("$resolved\n");

        my $response;
        $socket->recv($response, 1024);

        if ($response) {
            my $formatted = $self->formatResponse($response);
            if ($formatted) {
                $results{$elmt} = $formatted;
            }
        }
    }

    $socket->send("end\n");

    shutdown($socket, 1);
    $socket->close();

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

1;

=head1 NAME

Net::pWhoIs - Client library for Prefix WhoIs (pWhois)

=head1 SYNOPSIS

  use Net::pWhoIs;

  my %attrs = ( req => '166.70.12.30' );
  my $obj = Net::pWhoIs->new(\%attrs);
  my $output = $obj->pwhois();
  # Output for single query is hashref.
  for my $elmt (qw{org-name country city region}) {
      print $output->{$elmt}, "\n";
  }

  # Bulk query, combination of IPs and hostnames.
  my @list = ('166.70.12.30', '207.20.243.105', '67.225.131.208', 'perlmonks.org');
  my $obj = Net::pWhoIs->new({ req => \@list });
  # Output for bulk queries is array of hashrefs.
  my $output = $obj->pwhois();

  use Data::Dumper;
  print Dumper($output);

=head1 DESCRIPTION

Client for pWhois service.  Includes support for bulk queries.

=head1 CONSTRUCTOR

The following constructor methods are available:

=over 4

=item $obj = Net::pWhoIs->new( %options )

This method constructs a new C<Net::pWhoIs> object and returns it.
Key/value pair arguments may be provided to set up the initial state.
The only require argument is: req.

    pwhoisserver  whois.pwhois.org
    port          43
    req           Rlequired argument, may be scalar or array

=back

=head1 METHODS

The following methods are available:

=over 4

=item Net::pWhoIs->pwhois()

Perform a single query.  Returns a hashref.

=back

=over 4

=item Net::pWhoIs->pwhoisBulk()

Perform bulk queries using a single socket.  Returns an array of hashrefs.  This method is called by Net::pWhoIs->pwhois() if the req argument is an array.

=back

=head1 HASHREF KEYS

The following list hashref keys returned by pwhois or pwhoisBulk.

    ip
    as-org-name
    as-path
    origin-as
    org-name
    country-code
    prefix
    net-name
    latitude
    longitude
    cache-date
    city
    region
    country

=head1 AUTHOR

Mat Hersant <matt_hersant@yahoo.com>

=cut


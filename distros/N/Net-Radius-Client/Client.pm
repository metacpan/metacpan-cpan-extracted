package Net::Radius::Client;

use 5.008;
use IO::Socket::INET;
use Net::Radius::Dictionary;
use Net::Radius::Packet;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::Radius::Client ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    load
    query
);

our $VERSION = '0.03';
our $debug = 0;

# Preloaded methods go here.

my $ident = 1;

# subroutine to make string of 16 random bytes
sub bigrand() {
    pack "n8",
    rand(65536), rand(65536), rand(65536), rand(65536),
    rand(65536), rand(65536), rand(65536), rand(65536);
}

my $dict = undef;

sub load {
    my ($d) = @_;
    # Net::Radius::Dictionary pass silently if
    # dictionary is not readable (seems like bug)
    die "Couldn't read dictionary $d\n" unless (-r $d);
    $dict = new Net::Radius::Dictionary $d
        or die "Couldn't read dictionary: $!";
}

sub query {
    my ($servers, $code, $argref) = @_;
    my $retref={};
    my ($rec, $req, $rsp);
    my $password;

    if (not defined($dict)) {
        load("dictionary");
    }

    $req = new Net::Radius::Packet $dict;
    $req->set_code($code);

    foreach my $vs (keys %$argref) {
        foreach my $a (keys %{$argref->{$vs}}) {
            if ($vs) {
                $req->set_vsattr($vs, $a, @{$argref->{$vs}->{$a}});
            } else {
                if ($a eq 'User-Password') {
                    $password = $argref->{$vs}->{$a}[0];
                } else {
                    $req->set_attr($a, $argref->{$vs}->{$a}[0]);
                }
            }
        }
    }

    my ($retries, $timeout, $rc);

    foreach my $host (keys %$servers) {
        foreach my $port (keys %{$servers->{$host}}) {
            if (defined($servers->{$host}->{$port}->{'retries'})) {
                $retries = $servers->{$host}->{$port}->{'retries'};
            } else {
                $retries = 3;
            }
            if (defined($servers->{$host}->{$port}->{'timeout'})) {
                $timeout = $servers->{$host}->{$port}->{'timeout'};
            } else {
                $timeout = 1;
            }
            
            $ident = ($ident + 1) & 255;
            $req->set_identifier($ident);
            
            if ($code eq 'Access-Request') {
                $req->set_authenticator(bigrand);
            } else {
                $req->set_authenticator("");
            }

            if ($code eq 'Access-Request') {
                $req->unset_attr('User-Password');
                $req->set_password($password, $servers->{$host}->{$port}->{'secret'});
            }

            $req->dump if ($debug);

            my $pack = $req->pack; # Can generate error 'Unknown RADIUS tuples'
                                   # if dictionary has not been loaded (bug?)
            if ($code ne 'Access-Request') {
                $pack = auth_resp($pack,$servers->{$host}->{$port}->{'secret'});
            }

            my $socket = new IO::Socket::INET->new(PeerAddr => $host,
                                                   PeerPort => $port,
                                                   Proto    => 'udp',
                                                   Timeout  => $timeout);

            while($retries) {
                $retries--;

                $rc = $socket->send($pack);
                next if ($rc != length($pack));

                # Timeout parametor has no effect to recv method;
                # so we use select to detect timeout
                my $rin = '';
                vec($rin, fileno($socket), 1) = 1;
                my $nfound = select($rin, undef, undef, $timeout);
                next if ($nfound <= 0); # either timeout or end of file

                my $rec;
                $rc = $socket->recv($rec, 4096); # RFC2866: 20<=size<=4095
                next unless ($rc);

                $rsp = new Net::Radius::Packet $dict, $rec;

                # Make sure response is authentic
                {
                    my $p = $rec;
                    substr($p, 4, 16) = $req->authenticator;
                    $p = auth_resp($p,$servers->{$host}->{$port}->{'secret'});
                    if ($rsp->authenticator ne substr($p, 4, 16)) {
                        next; # ignore non-authentic response
                    }
                }
            
                $rsp->dump if ($debug);

                next if ($rsp->identifier != $ident);

                if ($code eq 'Access-Request' and
                    $rsp->code ne 'Access-Accept' and
                    $rsp->code ne 'Access-Reject') {
                    next;
                }
                if ($code eq 'Accounting-Request' and
                    $rsp->code ne 'Accounting-Response') {
                    next;
                }

                foreach my $a ($rsp->attributes) {
                    if (not defined($retref->{0})) {
                        $retref->{0} = {};
                    }
                    $retref->{0}->{$a} = [ $rsp->attr($a) ];
                }
                foreach my $v ($rsp->vendors) {
                    foreach my $a ($rsp->vsattributes($v)) {
                        if (not defined($retref->{$v})) {
                            $retref->{$v} = {};
                        }
                        $retref->{$v}->{$a} = $rsp->vsattr($v, $a);
                    }
                }

                return ($rsp->code, \%$retref);
            }
        }
    }

    return ('', \%$retref);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::Radius::Client - Pure-Perl, VSA-empowered RADIUS client

=head1 SYNOPSIS

  use Net::Radius::Client;

  load("dictionary");

  # $Net::Radius::Client::debug = 1;

  my $servers = {
      '192.168.1.1' => { 
          1812 => { 
              'secret' => 'perl4sins', 
              'timeout' => 1, 
              'retries' => 3 
              }
      },
      '192.168.1.2' => { 
          1812 => { 
              'secret' => 'perl4sins', 
              'timeout' => 1, 
              'retries' => 3 
              }
      }
  };

  my $req = { 
      0 => {
          'User-Name' => ['anus'],
          'User-Password' => ['vulgaris'] 
          },
      9 => {
          'cisco-avpair' => ['some cisco stuff']
          } 
  };
                   
  my ($code, $respref) = query($servers, "Access-Request", $req);

  if ($code) {
      print $code . "\n";
      foreach my $vendor (keys %$respref) {
          foreach my $attr (keys %{$respref->{$vendor}}) {
              foreach my $val (@{$respref->{$vendor}->{$attr}}) {
                  print $attr . ' = ' . $val . "\n";
              }
          }
      }
  } else {
      print "Probably timed out\n";
  }
             
=head1 ABSTRACT

The Net::Radius::Client package implements a single call, high-level 
RADIUS client.

=head1 DESCRIPTION

The C<query> routine tries to deliver request to RADIUS server(s)
and returns its response whenever successful.

RADIUS servers to query are represented as a hash carrying
network-scope details. See SYNOPSIS for more information.

RADIUS attribute-value pairs for both request and response
take shape of a two-dimentional hash-ref first indexed by 
attribute vendor ID (0 for IETF) and then by attribute name
(as configured in the "dictionary"). Since RADIUS protocol allows 
for multiple attributes of the same type in packet, value(s) of 
each attribute are kept in a list. See SYNOPSIS for guidance.

The C<load> routine loads up RADIUS dictionary file, as specified
by its first parameter, and should be called once on startup.

=head2 EXPORT

=over

=item load

=item query

=back

=head1 SEE ALSO

=over

=item L<Net::Radius::Packet>

=item L<Net::Radius::Dictionary>

=item L<http://www.freeradius.org/rfc/>

=back

=head1 AUTHOR

Ilya Etingof, E<lt>ilya@glas.netE<gt>
Alexey Michurin, E<lt>alexey@michurin.com.ruE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

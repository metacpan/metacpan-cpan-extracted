package Net::Whois::ARIN;

=head1 NAME

Net::Whois::ARIN - ARIN whois client

=head1 SYNOPSIS

  use Net::Whois::ARIN;

  my $w = Net::Whois::ARIN->new(
              host    => 'whois.arin.net',
              port    => 43,
              timeout => 30,
          );

  #  fetch raw whois output as a scalar
  my $result = $w->query( '207.173.0.0' );

  #  fetch raw whois output as a list
  my @results = $w->query( 'NET-207-173-0-0-1' );

  #  search for a network record
  my @output = $w->network( '207.173.0.0' );
  foreach my $net (@output) {
      printf(
          "%s\t(%s)\t%s\n",
          $net->OrgName,
          $net->NetHandle,
          $net->NetRange,
      );

      # display the network's contact information
      foreach my $cust ($net->contacts) {
          printf "Contact: %s (%s)\n", $cust->Name, $cust->Email;
      }
  }

  # lookup an autonomous system number
  my($asn) = $w->asn( 5650 );
  printf "AS5650 was assigned to %s\n", $asn->OrgName;

  # search for a point-of-contact by handle
  my @contact = $w->contact('DM2339-ARIN');

  my @contact_records = $w->domain('eli.net');

  # search for an organization record by the OrgId
  my @org = $w->organization('FRTR');

  # search for a customer record by Handle
  my @customers = $w->customer('C00823787');

=head1 DESCRIPTION

This module provides a Perl interface to the ARIN Whois server.  The module takes care of connecting to an ARIN whois server, sending your whois requests, and parsing the whois output.  The whois records are returned as lists of Net::Whois::ARIN::* instances.

=cut

use strict;

use vars qw/ $VERSION /;
$VERSION = '0.12';

use Carp;
use IO::Socket;
use Net::Whois::ARIN::AS;
use Net::Whois::ARIN::Contact;
use Net::Whois::ARIN::Customer;
use Net::Whois::ARIN::Network;
use Net::Whois::ARIN::Organization;

my $CONTACT_REGEX = qr/(RTech|Tech|NOC|OrgAbuse|OrgTech|RAbuse|Abuse|Admin)(\w+)/;

=head1 METHODS

In the calling conventions below C<[]>'s represent optional parameters.

=over 4

=item B<new> - create a Net::Whois::ARIN object

  my $o = Net::Whois::ARIN->new(
    [-hostname=> 'whois.arin.net',]
    [-port    => 43,]
    [-timeout => 45,]
    [-retries => 3,]
  );

This is the constuctor for Net::Whois::ARIN.  The object returned can be used to query the whois database.

=cut

sub new {
    my $class = shift;
    my %param = @_;
    my %args;

    foreach (keys %param) {
        if    (/^-?host(?:name)?$/i) { $args{'host'}    = $param{$_} }
        elsif (/^-?port$/i)          { $args{'port'}    = $param{$_} }
        elsif (/^-?timeout$/i)       { $args{'timeout'} = $param{$_} }
        elsif (/^-?retries$/i)       { $args{'retries'} = $param{$_} }
        else { 
            carp("$_ is not a valid argument to ${class}->new()");
        }
    }

    my $self = bless {
        '_host'    => $args{'host'} || 'whois.arin.net',
        '_port'    => $args{'port'} || 43,
        '_timeout' => $args{'timeout'},
        '_retries' => $args{'retries'} || 3,
    }, $class;

    return $self;
}

sub _connect {
    my $self = shift;
    my $host = $self->{'_host'};
    my $port = $self->{'_port'};
    my $retries = $self->{'_retries'};
    my $sock = undef;

    do {
        $sock = IO::Socket::INET->new(
            PeerHost => $host,
            PeerPort => $port,
            Proto    => 'tcp',
            ( ( defined $self->{'_timeout'} )
                ? ('Timeout' => $self->{'_timeout'})
                : (),
            ),
        )
    } while (!$sock && --$retries);
 
    unless ($sock) {
        my $error = $@;
        if($error eq 'IO::Socket::INET: ') {
            $error = 'connection time out';
        }
        croak "can't connect to ${host}\[$port\]: $error";
    }

    $sock->autoflush();
    return $sock;
}

=item B<query> - make a raw query to the whois server

  my @output = $o->query('207.173.112.0');

=cut

#  open connection, send a whois query, close connection, return whois response
sub query {
    my($self, $query) = @_;
    my $s = $self->_connect();
    print $s '' . $query . "\x0d\x0a";
    local $/;
    my $results = <$s>;
    undef $s;
    return (wantarray) ? split(/\n/, $results) : $results;
}

=item B<network> - request a network record

  my @records = $o->network('207.173.112.0');

This method requires a single argument.  The argument indicates the network to use in the whois lookup.  The method returns a list of Net::Whois::ARIN::Network records that matched your search criteria.

=cut

sub network {
    my ($self, $query) = @_;
    my @output  = $self->query("n + $query");
    my @contacts;
    my @records;
    my %attributes;
    my $record_count = 0;
    my $found_contact_info = 0;
    foreach (@output) {
        next unless $_ =~ /^(\S+):\s+(.*)$/;
        my ($key, $value) = ($1, $2);
        $value =~ s/\s*$//;
  
        if ($key eq 'OrgName' || $key eq 'CustName') { 
            $record_count++;
            unless ($record_count > 1) {
                $attributes{$key} = $value;
                next;
            }
            my $net = Net::Whois::ARIN::Network->new( %attributes );
            $net->contacts( @contacts );
            push @records, $net;
            $found_contact_info = 0;
            @contacts = ();
            %attributes = ();
        }
  
        if ($key =~ /^$CONTACT_REGEX$/ ) {
            $found_contact_info ++;
            if ($2 eq 'Handle') {
                my @data = $self->contact( $value );;
                push @contacts, @data;
                $contacts[-1]->Type( $1 );
            }
        }
        elsif( !$found_contact_info ) {
            $attributes{$key} = $value;
        }
    }

    my $net = Net::Whois::ARIN::Network->new( %attributes );
    $net->contacts( @contacts );
    push @records, $net;

    return @records;
}

=item B<asn> - request an ASN record

  my @record = $o->asn(5650);

This method requires a single argument.  The argument indicates the autonomous system number to use in the whois lookup.  The method returns a list of Net::Whois::ARIN::AS objects.  

=cut

sub asn {
    my ($self, $query) = @_;
    my @output  = $self->query("a + $query");
    my(%attributes, @contacts);

    foreach ( @output ) {
        next unless $_ =~ /^(\S+):\s+(.*)$/;
        my ($key, $value) = ($1, $2);
        $value =~ s/\s*$//;
        if ($key eq 'Address') {
            $attributes{Address} .= "$value\n";
        }
        elsif( $key =~ /^$CONTACT_REGEX$/ ) {
            if ($2 eq 'Handle') {
                push @contacts, $self->contact( $value );
                $contacts[-1]->Type( $1 );
            }            
        }
        else {
            $attributes{$key} = $value;
        }
    }

    chomp( $attributes{Address} )
        if exists $attributes{Address};

    my $as = Net::Whois::ARIN::AS->new( %attributes );
    $as->contacts( @contacts );
    return $as;
}

=item B<organization> - request an organization record

  my @record = $w->org('ELIX');

=cut

sub organization {
    my ($self, $query) = @_;
    my @output  = $self->query("o + $query");

    my @records;
    my(%attributes, @contacts);
    my $record_count = 0;
    my $found_contact_info = 0;

    foreach ( @output ) {
        next unless $_ =~ /^(\S+):\s+(.*)$/;
        my ($key, $value) = ($1, $2);
        $value =~ s/\s*$//;

        if ($key eq 'OrgName') {
            $record_count++;
            unless ($record_count > 1) {
                $attributes{$key} = $value;
                next;
            }
            my $org = Net::Whois::ARIN::Organization->new( %attributes );
            $org->contacts( @contacts );
            push @records, $org;
            $found_contact_info = 0;
            @contacts = ();
            %attributes = ();
        }
        if ($key eq 'Address') {
            $attributes{Address} .= "$value\n";
        }
        elsif( $key =~ /^$CONTACT_REGEX$/ ) {
            $found_contact_info ++;
            if ($2 eq 'Handle') {
                push @contacts, $self->contact( $value );
                $contacts[-1]->Type( $1 );
            }
        }
        elsif( !$found_contact_info ) {
            $attributes{$key} = $value;
        }
    }

    chomp( $attributes{Address} )
        if exists $attributes{Address};

    my $org = Net::Whois::ARIN::Organization->new( %attributes );
    $org->contacts( @contacts );
    push @records, $org;
    return @records;
}

=item B<customer> - request a customer record

  my @records = $w->customer('ELIX');

=cut

sub customer {
    my ($self, $query) = @_;
    my @output  = $self->query("c + $query");

    my @records;
    my(%attributes, @contacts);
    my $record_count = 0;
    my $found_contact_info = 0;

    foreach ( @output ) {
        next unless $_ =~ /^(\S+):\s+(.*)$/;
        my ($key, $value) = ($1, $2);
        $value =~ s/\s*$//;

        if ($key eq 'CustName') {
            $record_count++;
            unless ($record_count > 1) {
                $attributes{$key} = $value;
                next;
            }
            my $cust = Net::Whois::ARIN::Customer->new( %attributes );
            $cust->contacts( @contacts );
            push @records, $cust;
            $found_contact_info = 0;
            @contacts = ();
            %attributes = ();
        }

        if ($key eq 'Address') {
            $attributes{Address} .= "$value\n";
        }
        elsif( $key =~ /^$CONTACT_REGEX$/ ) {
            $found_contact_info ++;
            if ($2 eq 'Handle') {
		#  do a whois lookup for point of contact information
		my @data = $self->contact($value);
                push @contacts, @data;
                $contacts[-1]->Type( $1 );
            }
        }
        elsif( !$found_contact_info ) {
            $attributes{$key} = $value;
        }
    }

    chomp( $attributes{Address} )
        if exists $attributes{Address};

    my $cust = Net::Whois::ARIN::Customer->new( %attributes );
    $cust->contacts( @contacts );
    push @records, $cust;
    return @records;
}

=item B<contact> - request a point-of-contact record

  my @record = $w->contact('DM2339-ARIN');

=cut

sub contact {
    my ($self, $query) = @_;
    my @output  = $self->query("p + $query");
    my @records;
    my $n = -1;
    foreach ( @output ) {
        next unless $_ =~ /^(\S+):\s+(.*)$/;
        my ($key, $value) = ($1, $2);
        $value =~ s/\s*$//;
#        $records[++$n] = {} if /^(Name):/;
        $records[++$n] = {} if $n < 0;
        if ($key eq 'Address') {
            $records[$n]->{Address} .= "$value\n";
        }
        else {
            $records[$n]->{$key} = $value;
        }
    }

    my @contacts;
    foreach ( @records ) {
        my %attributes = %$_;
        chomp($attributes{Address})
            if exists $attributes{Address};
        push @contacts, Net::Whois::ARIN::Contact->new( %attributes );
    }

    return @contacts;
}

=item B<domain> - request all records from a given domain

  @output = $w->domain('eli.net');

=back

=cut

sub domain {
    my ($self, $query) = @_;
    $query = "\@$query" if $query !~ /^\@/;
    $query = "+ $query";
    my @output = $self->query($query);
    my @contacts;
    my %attr;
    foreach (@output) {
         if(/^(\S+):\s+(.*)$/) {
             $attr{$1} = $2;
         }
         if(/^Email:\s+.*$/) {
             push @contacts, Net::Whois::ARIN::Contact->new( %attr );
             %attr = ();
         }
    }
    return @contacts;
}

=head1 SEE ALSO

L<Net::Whois::ARIN::AS>

L<Net::Whois::ARIN::Network>

L<Net::Whois::ARIN::Contact>

L<Net::Whois::ARIN::Organization>

L<Net::Whois::ARIN::Customer>

=head1 AUTHOR

Todd Caine  <todd.caine at gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2011 Todd Caine.  All rights reserved. 

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


1;
__END__

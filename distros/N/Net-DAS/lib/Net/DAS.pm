package Net::DAS;

=pod

=head1 NAME

Net::DAS - Simple Domain Availabilty Seach client.

=head1 SYNOPSIS

  # new object
  my $das = Net::DAS->new();
  # you can change query timeout, set to use registrar DAS servers (where available), select only specific modules, and override the requst function (normally for testing)
  my $das = Net::DAS->new({timeout=>2,use_registrar=>1,modules=>['eu','be'],_request=>\&my_request});
  
  # lookup() always works in batch mode, so if you are only looking up a single domain you can access that domains result directly
  my $res  =$das->lookup('test.eu')->{'test.eu'};
  if ($res->{'avail'}) {
	  # do something
  } else {
     print $res->{'reason'};
  }

  # or with multiple domains
  my $res  =$das->lookup('test.eu','test2.eu','test3.eu');
  print $res->{'test2.eu'}->{'reason'};
  
=head1 DESCRIPTION

Net::DAS is a client that aims to simplify using DAS with multiple registries by having small submodules (see L<Net::DAS::*>) to iron out the differences in the servers. It also inclused a shell script  L<Net::DAS::das> to do lookups from the command line.

=head1 PUBLIC METHODS

=cut

use 5.010;
use strict;
use warnings;
use Carp qw (croak);
use Module::Load;
use IO::Socket::INET;
use Time::HiRes qw (usleep);

our $VERSION = '0.19';
our @modules = qw (EU BE NO LT UK SI IT GENT SE NU RO);

=pod

=head2 new

Accepts a hash reference with available options being timeout (integer default 4), use_registrar (bool default 0), modules (array_ref default all), _request (sub - only used for overriding request method for testing)

  my $das = Net::DAS->new();
  my $das = Net::DAS->new({timeout=>2,use_registrar=>1,modules=>['eu','be'],_request=>\&my_request});

=cut

sub new {
    my $class = shift;
    my $self = shift || {};
    bless $self, $class;
    $self->{tlds}          = {};
    $self->{use_registrar} = undef unless exists $self->{use_registrar};
    $self->{timeout}       = 4 unless exists $self->{timeout};
    $self->{_request}      = \&_send_request unless exists $self->{_request};
    our (@modules);
    @modules = @{ $self->{modules} } if exists $self->{modules};
    my ( $m, $t );

    foreach (@modules) {
        $m = 'Net::DAS::' . uc($_);
        eval {
            load($m);
            $self->{$m} = $m->register();
            foreach my $t ( @{ $self->{$m}->{tlds} } ) {
                $self->{tlds}->{$t} = $m;
            }
        };
        if ($@) {
            warn "Warning: unable to load module $m: $@\n";
            next;
        }
    }
    return $self;
}

=pod

=head2 lookup

Lookup domain availability in batch mode. You can specify 1 or more domains, but always works in batch mode, so if you are only looking up a single domain you can access that domains result directly by using the domain name as a reference. When looking up multiple domains, just send an array and the return will be a hashref with the domain names as the keys 

  my $res  =$das->lookup('test.eu')->{'test.eu'};
  if ($res->{'avail'}) {
	  # do something
  } else {
     print $res->{'reason'};
  }

  # or with multiple domains
  my $res  =$das->lookup('test.eu','test2.eu','test3.eu');
  my $res  =$das->lookup(@domains);
  print $res->{'test2.eu'}->{'reason'};

=cut

sub lookup {
    my ( $self, @domains ) = @_;
    return { 'avail' => -1, 'reason' => 'NO DOMAIN SPECIFIED' } unless @domains;
    my ( $r, $b ) = {};
    foreach my $i (@domains) {
        chomp($i);
        $r = { 'domain' => $i };
        eval {
            ( $r->{'label'}, $r->{'tld'} ) = $self->_split_domain($i);
            croak("TLD ($r->{'tld'}) not supported") unless ( $r->{'module'} = $self->{tlds}->{ $r->{'tld'} } );
            my ($disp) = defined $self->{ $r->{module} }->{dispatch} ? $self->{ $r->{module} }->{dispatch} : [];
            chomp( $r->{'query'} = defined( $disp->[0] ) ? $disp->[0]->( $r->{'domain'} ) : $r->{'domain'} );

            local $SIG{ALRM} = sub { die "TIMEOUT\n" };
            alarm $self->{timeout};
            chomp( $r->{'response'} = $self->{_request}->( $self, $r->{'query'}, $r->{module} ) );
            alarm 0;

            $r->{'avail'}
                = defined( $disp->[1] )
                ? $disp->[1]->( $r->{'response'}, $i )
                : $self->_parse( $r->{'response'}, $i );
            $r->{'reason'} = 'AVAILABLE'                if $r->{'avail'} == 1;
            $r->{'reason'} = 'NOT AVAILABLE'            if $r->{'avail'} == 0;
            $r->{'reason'} = 'NOT VALID'                if $r->{'avail'} == -1;
            $r->{'reason'} = 'NOT AUTHORIZED'           if $r->{'avail'} == -2;
            $r->{'reason'} = 'IP BLOCKED'               if $r->{'avail'} == -3;
            $r->{'reason'} = 'UNABLE TO PARSE RESPONSE' if $r->{'avail'} == -100;
        };
        if ($@) {
            chomp( $r->{reason} = $@ );
            $r->{avail} = -1;
        }
        $b->{$i} = $r;
    }
    $self->_close_ports();
    return $b;
}

=pod

=head2 available

A quick function to lookup availability of a single domain without details. Warning, you should check if the result == 1, as there are different return codes.

  print "available" if $das->availabile('test.eu')==1;

=cut

sub available {
    my ( $self, $dom ) = @_;
    my $r = $self->lookup($dom);
    return $r->{$dom}->{'avail'};
}

=pod

=head1 PRIVATE METHODS

=item _split_domain : splits a domain into an array ($dom,$tld)

=cut

sub _split_domain {
    my ( $self, $i ) = @_;
    return ( $1, $2 ) if $i =~ m/(.*)\.(.*\..*)/ && exists $self->{tlds}->{$2};
    return ( $1, $2 ) if $i =~ m/(.*)\.(.*)/;
    croak( 'Invalid domain ' . $i );
    return;
}

=pod

=item _send_request : should not be called directly, its called by lookup()

=cut

sub _send_request {
    my ( $self, $q, $m ) = @_;
    my $svc = ( $self->{use_registrar} && exists $self->{$m}->{registrar} ) ? 'registrar' : 'public';
    my $h   = $self->{$m}->{$svc}->{host};
    my $p   = defined $self->{$m}->{$svc}->{port} ? $self->{$m}->{$svc}->{port} : 4343;
    my $pr  = defined $self->{$m}->{$svc}->{proto} ? $self->{$m}->{$svc}->{proto} : 'tcp';
    my $nl  = defined $self->{$m}->{nl} ? $self->{$m}->{nl} : "\n";
    if ( !$self->{$m}->{sock} || !$self->{$m}->{sock}->connected() ) {
        $self->{$m}->{sock} = IO::Socket::INET->new( PeerAddr => $h, PeerPort => $p, Proto => $pr, Timeout => 30 )
            || croak("Unable to connect to $h:$p $@");
    }

    #usleep($self->{$m}->{delay}) if exists $self->{$m}->{delay};
    $self->{$m}->{sock}->syswrite( $q . "$nl" );
    my ( $res, $buf );
    while ( $self->{$m}->{sock}->sysread( $buf, 1024 ) ) {
        $res .= $buf;
        last if $self->{$m}->{sock}->atmark;
    }
    unless ( exists $self->{$m}->{close_cmd} ) {
        $self->{$m}->{sock}->close();
        undef $self->{$m}->{sock};
    }
    return $res;
}

=pod

=item _parse : should not be called directly, its called by lookup(). This sub is normally overriden by the registry module's parser

=cut

sub _parse {
    my $self = shift;
    chomp( my $i = uc(shift) );
    return -3 if $i =~ m/IP ADDRESS BLOCKED/;
    return 1  if $i =~ m/.*STATUS:\sAVAILABLE/;
    return 0  if $i =~ m/.*STATUS:\sNOT AVAILABLE/;
    return -1 if $i =~ m/.*STATUS:\sNOT VALID/;
    return (-100);
}

=pod

=item _close_ports : closes any open sockets; you should'nt need to call this.

=cut

sub _close_ports {
    my $self = shift;
    return unless defined $self->{modules};
    foreach my $k ( @{ $self->{modules} } ) {
        my $m = 'NET::DAS' . $k;
        next unless exists $self->{$m} && !defined $self->{$m}->{sock} && $self->{$m}->{sock}->connected();
        $self->{$m}->{sock}->syswrite( $self->{$m}->{close_cmd} ) if exists $self->{$m}->{close_cmd};
        undef $self->{$m}->{sock};
    }
    return;
}

=pod

=item DESTROY: ensures that any open sockets are closed cleanly before closing; you dont need to call this.

=cut

sub DESTROY {
    my $self = shift;
    $self->_close_ports() if defined $self->{modules};
    undef $self->{modules};
}

1;

=pod

=head1 AUTHOR

Michael Holloway <michael@thedarkwinter.com>

=head1 LICENSE

Artistic License

=cut

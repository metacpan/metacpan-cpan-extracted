#
#  Utils for SAP Business Connector (BC)
#


package SAP::BC;

=pod

=head1 NAME

SAP::BC - Interface to SAP's Business Connector

=head1 SYNOPSIS

 use SAP::BC;

 my $bc = SAP::BC->new( server   => 'http://karma:5555',
                        user     => 'dj',
                        password => 'secret' );

 my $service_ref = $bc->services(); # list (SAP) services available

=head1 DESCRIPTION

I<SAP::BC> is an OO interface that exposes functions within
SAP's Business Connector (BC) as methods. It was primarily written
as a class for discovering services and their respective RFC
components for another module project SAP::BC::Proxy::SOAP which
is a SOAP (to RFCXML) proxy for calls to SAP via the BC.

=head1 METHODS

=over 4

=cut

use strict;

use LWP::Simple;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Cookies;

use vars qw($VERSION %BC $COOKIES);

$VERSION = '0.03';

# Not sure about the usefulness of this hash, yet, but I'll
# keep it for now. It keeps the BC implemention details visible.

%BC = (
        'listServers'     => '/invoke/sap.admin.server/list',
        'listServiceMaps' => '/invoke/sap.admin.map/list',
        'getProperties'   => '/WmRoot/server-environment.dsp',
        'disconnect'      => '/invoke/wm.server/disconnect',
      );

$COOKIES = new HTTP::Cookies(hide_cookie2 => 1);

# The constructor.
# Represents a Business Connector instance.

=pod

=item B<new() (constructor)>

Use this to create a BC instance. You can pass either a single
argument, which is the URL of the BC you want to manipulate, or
a list of values, like this:

 my $bc = SAP::BC->new('http://karma:5555'); not allowed after BC 4.x

 or

 my $bc = SAP::BC->new( 'server'   => 'http://karma',
                        'user'     => 'username',
                        'password' => 'secret' ); <= manditory after BC 4.x

where the user and password parameters are the ones for the
SAP BC itself. 

=cut

sub new {
  my $class = shift;

  my $self;

  if ($#_ == 0) {     # if there's only one thing passed
    my $arg = shift;
    if (ref($arg) eq 'HASH') {   # and it's a hash-ref
      $self = $arg;              # great - take that for $self
    }
    else {                          # otherwise..
      $self = { 'server' => $arg }; # assume it's the BC's URL
    }
  }
  else {              # otherwise, if there's more stuff passed,
    $self = { @_ };   # so make a hash out of it
  }

# $self->{'server'} =~ s/\/?$//; # remove possible trailing slash
# die "Cannot connect to $self->{'server'}: $!\n" unless get $self->{'server'};

  bless $self, $class;
  return $self;
}

=pod

=item B<authentication()>

Use this method to get or set the user and password values for
authentication with the BC.

=cut

sub authentication {
  my $self = shift;

# Set if passed
  if ($#_ > 0) {
    $self->{'user'} = shift;
    $self->{'password'} = shift;
  }

# Make sure there's no undefs
#  $self->{'user'} ||= '';
#  $self->{'password'} ||= '';

# Return both values
  return ($self->{'user'},$self->{'password'});

}

=pod

=item B<SAP_systems()>

Use this method to get a list of SAP systems known to the BC.
The data will be cached after the first call. 

=cut

sub SAP_systems {
# Return a list of SAP systems
  my $self = shift;

  unless (exists ($self->{'SAP_systems'})) {

#   Prime
    $self->{'SAP_systems'} = [];

#   Call service on BC
#    my $res = get "$self->{'server'}$BC{'listServers'}"
#      or die "Cannot retrieve server list: $!\n";
#   Call service on BC
    $self->_prime_ua();
    my $req = HTTP::Request->new('GET', "$self->{'server'}$BC{'listServers'}");
    $req->authorization_basic($self->authentication);
	$req = $self->{'ua'}->prepare_request($req);
    my $res =  $self->{'ua'}->request($req)->content()
        or die "Cannot retrieve server list: $!\n";
    $res =~ s/\n//g;
    # print STDERR "The Server List: ".$res."\n";

#   Parse results for server names
    #foreach (grep(/$BC{'listServiceMaps'}/,split("\n",$res))) {
    foreach (grep(/\>serverName/,split(/<\/TR>/,$res))) {
#     print STDERR "LINE: $_ \n";
      #my ($sapsys) = $_ =~ m/$BC{'listServiceMaps'}\?serverName=(\w{3})/;
      my ($sapsys) = $_ =~ m/(\w+)<\/TD>.*?$/;
      push(@{$self->{'SAP_systems'}},$sapsys);
    }

  }

  return $self->{'SAP_systems'};

}

=pod

=item B<services()>

To discover a list of services associated with the SAP systems
known to the BC, use this method. You can pass a list of
SAP systems for which you want to discover the services, or

if you don't pass anything, services for all the SAP systems 
known to the BC will be returned. If the SAP systems haven't
previously been discovered using the I<SAP_systems> method,
this will happen automatically.

A reference to a hash will be returned, with the keys being
the service names, and the argument being a hashref with the
details, like this:

 { 
   'SOAP:getStateName'   =>
          {
            'sapsys'  => 'LNX',
            'rfcname' => 'Z_SOAP_GET_STATE_NAME',
          },
   'SOAP:getStateStruct' =>
          {
            'sapsys'  => 'LNX',
            'rfcname' => 'Z_SOAP_GET_STATE_STRUCT',
          },
   ...
 }

=cut

sub services {
# Return a list of BC (-> SAP) services)
# Can receive an optional list of SAP systems
# to use to restrict the search
  my $self = shift;
  my $sys_list = shift || $self->SAP_systems();

  unless (exists($self->{'services'})) {
	$self->_prime_ua();

#   Prime
    $self->{'services'} = {};

#   Invoke the map list service for each of the SAP systems
    foreach my $sys (@{$sys_list}) {
      my $req = HTTP::Request->new('GET', "$self->{'server'}$BC{'listServiceMaps'}?serverName=$sys");
      $req->authorization_basic($self->authentication);
      my $res =  $self->{'ua'}->request($req)->content()
          or die "Cannot retrieve Service Map for $sys: $!\n";
      $res =~ s/\n//g;
      #print STDERR "SERVICE LIST: $res \n";
      #my $res = get "$self->{'server'}$BC{'listServiceMaps'}?serverName=$sys" 
      #  or die "Cannot retrieve Service Map for $sys: $!\n";

      #foreach my $serviceMap (grep(/editServiceMap.*svcname/,split("\n",$res))) {
      while  ( $res =~ m/serverName<\/b><\/td><td>([\w_]+).*?outboundMaps<\/b><\/td>/gi) {
      my ( $srvname, $outbm ) = ( $1, $' );
      while  ( $outbm =~ m/functionName<\/b><\/td><td>(\w+).*?folder<\/b><\/td><td>([\w.]+).*?service<\/b><\/td><td>(\w+)/gi) {
      my ( $rfcname, $srvpath, $service ) = ( $1, $2, $3 );
#        print STDERR "LINE: $srvname $rfcname $srvpath $service $package \n";
#        my ($sapsys, $rfcname, $service) = 
#	        $serviceMap =~ m/^.*?serverName\=(.*?)\&.*?rfcname\=(.*?)\&.*?svcname\=(.*?)\&.*$/;
        $self->{'services'}->{$srvpath.':'.$service} = {
                                            'sapsys'  => $srvname,
                                            'rfcname' => $rfcname,
                                          };
  
#        $self->{'services'}->{$service} = {
#                                            'sapsys'  => $sapsys,
#                                            'rfcname' => $rfcname,
#                                          };

      }
      }

    }

  }

  return $self->{'services'};
  
}

=pod

=item B<disconnect()>

Disconnects from the BC and frees the session.

=cut

sub disconnect {
  my $self = shift;
  my $ua = LWP::UserAgent->new(timeout => 5);
  $ua->agent("sap::bc/$VERSION");
  $ua->cookie_jar($COOKIES);
  my $req = HTTP::Request->new('GET', "$self->{'server'}$BC{'disconnect'}");
  $req->authorization_basic($self->authentication);
  my $res = $ua->request($req);
  return 1;
}


=pod

=item B<_clear_caches()>

This is an internal method that removes the cached information
(such as that determined by I<SAP_systems> and I<services> - so that
the information can be refreshed by another call, if e.g. services
have been added to the BC.

=cut

sub _clear_caches {
  my $self = shift;
  delete $self->{'SAP_systems'};
  delete $self->{'services'};

  return 1;
}

=pod

=item B<properties()>

An experimental method that returns a hashref of properties
pertaining to the BC instance connected to.

It relies on parsing some HTML, which is flakey at best. 

=cut

sub properties {
  my $self = shift;

  unless (exists ($self->{'properties'})) {

#   Prime
    $self->{'properties'} = {};

#   Call service on BC
    $self->_prime_ua();
    my $req = HTTP::Request->new('GET', "$self->{'server'}$BC{'getProperties'}");
    $req->authorization_basic($self->authentication);

    $self->{'scratch'} =  $self->{'ua'}->request($req);

  }

  return $self->{'scratch'};

}

=pod

=item B<_prime_ua()>

An internal method to prime a UserAgent.

=cut

sub _prime_ua {
  my $self = shift;

# Don't do anything if it's already primed
  return if exists $self->{'ua'};

  $self->{'ua'} = LWP::UserAgent->new();
  $self->{'ua'}->agent("sap::bc/$VERSION");
  $self->{'ua'}->cookie_jar($COOKIES);
}


=pod

=back

=cut

1;

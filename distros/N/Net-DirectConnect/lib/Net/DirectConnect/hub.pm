#$Id: hub.pm 998 2013-08-14 12:21:20Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/lib/Net/DirectConnect/hub.pm $
package    #hide from cpan
  Net::DirectConnect::hub;
use Net::DirectConnect;
use Net::DirectConnect::hubcli;
use strict;
no strict qw(refs);
use warnings "NONFATAL" => "all";
no warnings qw(uninitialized);
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
our $VERSION = ( split( ' ', '$Revision: 998 $' ) )[1];
use base 'Net::DirectConnect';

sub init {
  my $self = shift;
  %$self = (
    %$self,
    'incomingclass' => 'Net::DirectConnect::hubcli',
    'auto_connect'  => 0,
    'auto_listen'   => 1,
    'myport'        => 411,
    'myport_base'   => 0,
    'myport_random' => 0,
    'myport_tries'  => 1,
    'HubName'       => 'Net::DirectConnect test hub',
    , @_
  );
  #$self->baseinit();
  $self->{'parse'} ||= {};
  $self->{'cmd'}   ||= {};
}
1;

#$Id: hubhub.pm 998 2013-08-14 12:21:20Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/lib/Net/DirectConnect/hubhub.pm $
#reserved for future 8)
package    #hide from cpan
  Net::DirectConnect::hubhub;
use Net::DirectConnect;
use strict;
no strict qw(refs);
use warnings "NONFATAL" => "all";
no warnings qw(uninitialized);
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
our $VERSION = ( split( ' ', '$Revision: 998 $' ) )[1];
use base 'Net::DirectConnect';

sub init {
  my $self = shift;
  %$self = ( %$self, @_ );
  $self->{'parse'} = {};
  $self->{'cmd'}   = {};
}
1;

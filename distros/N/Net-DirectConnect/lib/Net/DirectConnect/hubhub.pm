#$Id: hubhub.pm 505 2009-11-22 03:52:21Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/lib/Net/DirectConnect/hubhub.pm $
#reserved for future 8)
package    #hide from cpan
  Net::DirectConnect::hubhub;
use Net::DirectConnect;
use strict;
no warnings qw(uninitialized);
our $VERSION = ( split( ' ', '$Revision: 505 $' ) )[1];
use base 'Net::DirectConnect';

sub init {
  my $self = shift;
  %$self = ( %$self, @_ );
  $self->{'parse'} = {};
  $self->{'cmd'}   = {};
}
1;

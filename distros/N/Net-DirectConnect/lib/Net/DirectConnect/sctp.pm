#$Id: adc.pm 858 2011-10-10 22:56:04Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/lib/Net/DirectConnect/adc.pm $
package    #hide from cpan
  Net::DirectConnect::sctp;
use strict;
no strict qw(refs);
use warnings "NONFATAL" => "all";
no warnings qw(uninitialized);
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use Socket;
use Data::Dumper;    #dev only
#$Data::Dumper::Sortkeys = $Data::Dumper::Useqq = $Data::Dumper::Indent = 1;
sub init {
  my $self = shift if ref $_[0];
  $self->{'Proto'} = 'sctp';
  $self->{'socket_options'}{Type} = Socket::SOCK_STREAM;
}
64;

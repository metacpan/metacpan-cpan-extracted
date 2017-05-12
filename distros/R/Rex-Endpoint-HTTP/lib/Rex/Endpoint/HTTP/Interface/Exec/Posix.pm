#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Endpoint::HTTP::Interface::Exec::Posix;
   
use strict;
use warnings;

use Rex::Endpoint::HTTP::Interface::Exec::Base;
use base qw(Rex::Endpoint::HTTP::Interface::Exec::Base);

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_);

   bless($self, $proto);

   return $self;
}

sub exec {
   my ($self, $cmd) = @_;

   my $out = qx{LC_ALL=C $cmd};

   return $out;
}
1;

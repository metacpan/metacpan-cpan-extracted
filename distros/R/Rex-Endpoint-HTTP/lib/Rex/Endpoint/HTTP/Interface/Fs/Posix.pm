#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Endpoint::HTTP::Interface::Fs::Posix;
   
use strict;
use warnings;

use Rex::Endpoint::HTTP::Interface::Fs::Base;
use base qw(Rex::Endpoint::HTTP::Interface::Fs::Base);

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_);

   bless($self, $proto);

   return $self;
}

sub rename {
   my ($self, $old, $new) = @_;

   system("/bin/mv $old $new >/dev/null 2>&1");

   if($? == 0) { return 1; }
}

1;

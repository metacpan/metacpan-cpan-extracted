#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Endpoint::HTTP::Interface::System;
   
use strict;
use warnings;

sub create {
   my ($class, $type) = @_;

   if(! $type) {
      if($^O =~ m/MSWin/) {
         $type = "Windows";
      }
      else {
         $type = "Base";
      }
   }

   my $klass = "Rex::Endpoint::HTTP::Interface::System::$type";
   eval "use $klass";

   if($@) {
      die("Error loading Interface class ($klass).");
   }

   return $klass->new;
}

1;

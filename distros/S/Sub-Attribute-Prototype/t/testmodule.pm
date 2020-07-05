package testmodule;

use strict;
use warnings;

use Sub::Attribute::Prototype;

sub func :prototype(&@) {
   my ( $code, @items ) = @_;
   return grep { $code->($_) } @items;
}

0x55AA;

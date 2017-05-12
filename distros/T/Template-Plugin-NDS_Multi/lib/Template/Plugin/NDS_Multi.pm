package Template::Plugin::NDS_Multi;
# Copyright (c) 2007-2009 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###############################################################################

$VERSION = "3.00";

require 5.004;

use warnings;
use strict;
use base qw( Template::Plugin );
use Template;
use Template::Plugin;

###############################################################################
###############################################################################

# sub sources {
#    shift;
#    my $obj    = shift;
#    my @ret    = $obj->sources();
#    @ret       = ()  if (! @ret);
#    return [ @ret ];
# }

###############################################################################

sub eles {
   shift;
   my $obj    = shift;
   my @ret    = $obj->eles();
   @ret       = ()  if (! @ret);
   return [ @ret ];
}

# sub eles_in_source {
#    shift;
#    my $obj    = shift;
#    my $source = shift;
#    my @ret    = $obj->eles_in_source($source);
#    @ret       = ()  if (! @ret);
#    return [ @ret ];
# }

# sub ele_in_sources {
#    shift;
#    my $obj    = shift;
#    my $ele    = shift;
#    my @ret    = $obj->ele_in_sources($ele);
#    @ret       = ()  if (! @ret);
#    return [ @ret ];
# }

# sub ele_in_source {
#    shift;
#    my $obj    = shift;
#    my $source = shift;
#    my $ele    = shift;
#    my $ret    = $obj->ele_in_source($source,$ele);
#    $ret       = "" if (! defined $ret);
#    return $ret;
# }

sub ele {
   shift;
   my $obj    = shift;
   my $ele    = shift;
   my $ret    = $obj->ele($ele);
   $ret       = "" if (! defined $ret);
   return $ret;
}

###############################################################################

sub value {
   shift;
   my $obj     = shift;
   my $ele    = shift;
   my $path   = shift;
   my $ret    = $obj->value($ele,$path);
   $ret       = "" if (! defined $ret  ||  ref($ret));
   return $ret;
}

sub values {
   shift;
   my $obj     = shift;
   my $ele    = shift;
   my $path   = shift;
   my @val    = $obj->values($ele,$path);
   @val       = ()  if (! @val);
   my @ret;
   foreach my $val (@val) {
      if (defined $val  &&  ref($val)) {
         push(@ret,ref($val));
      } elsif (defined $val  &&  $val ne "") {
         push(@ret,$val);
      }
   }
   return [ @ret ];
}

sub keys {
   shift;
   my $obj     = shift;
   my $ele    = shift;
   my $path   = shift;
   my @key    = $obj->keys($ele,$path);
   @key       = ()  if (! @key);
   my @ret;
   foreach my $key (@key) {
      push(@ret,$key)  if (defined $key  &&  $key ne "");
   }
   return [ @ret ];
}

###############################################################################

sub which {
   shift;
   my $obj     = shift;
   my @ret    = $obj->which(@_);
   @ret       = ()  if (! @ret);
   return [ @ret ];
}

###############################################################################

# sub which_sources {
#    shift;
#    my $obj     = shift;
#    my @ret    = $obj->which_sources(@_);
#    @ret       = ()  if (! @_  ||  $ret[0] == 0);
#    shift(@ret)  if (@ret);
#    return [ @ret ];
# }

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

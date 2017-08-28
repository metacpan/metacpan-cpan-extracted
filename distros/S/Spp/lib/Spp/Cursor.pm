# Copyright 2016 The Michael Song. All rights rberved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

package Spp::Cursor;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(new_cursor getchar prechar nextchar);

use 5.012;

sub new_cursor {
   my ($str, $ns) = @_;
   $str = $str . chr(0);
   return {
      str    => $str,
      ns     => $ns,
      off    => 0,
      maxoff => 0,      # record max match location
      debug  => 0,      # 1 open debug mode
      depth  => 0,      # match_rule trace depth
   };
}

sub getchar {
   my $cursor = shift;
   return substr($cursor->{str}, $cursor->{off}, 1);
}

sub prechar {
   my $cursor = shift;
   return substr($cursor->{str}, $cursor->{off} - 1, 1);
}

sub nextchar {
   my $cursor = shift;
   return substr($cursor->{str}, $cursor->{off} + 1, 1);
}

1;

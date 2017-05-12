use strict;
package Siesta::Send::Test;

our @sent;

sub new { bless {}, shift }
sub send { push @sent, $_[1] }

1;

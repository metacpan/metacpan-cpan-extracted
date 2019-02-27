#line 1
package Test::Builder::TodoDiag;
use strict;
use warnings;

our $VERSION = '1.302073';

BEGIN { require Test2::Event::Diag; our @ISA = qw(Test2::Event::Diag) }

sub diagnostics { 0 }

1;

__END__

#line 61

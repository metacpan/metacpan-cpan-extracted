package TUI::toolkit::boolean;

use strict;
use warnings;

our $VERSION = '0.04';

use Exporter 'import';

our @EXPORT = qw(
  true
  false
);

sub true  () { !!1 }
sub false () { !!0 }

# Perl v5.36 and later have a built-in boolean type, 
# so if it's available, use it.
BEGIN {
  no strict 'refs';
  for my $sub ( @EXPORT ) {
    if ( defined &{ 'builtin::' . $sub } ) {
      no warnings;
      *$sub = \&{ 'builtin::' . $sub };
    }
  }
}

1

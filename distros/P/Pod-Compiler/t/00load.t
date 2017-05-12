# Testing of Pod::Compiler
# Author: Marek Rouchal <marekr@cpan.org>

$| = 1;

use Test;

BEGIN { plan tests => 1 }

# load the module
eval "use Pod::Compiler;";
if($@) {
  ok(0);
  print "$@\n";
} else {
  ok(1);
}

__END__


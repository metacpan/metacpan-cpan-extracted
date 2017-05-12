# Emacs, this is -*- perl -*- code.

BEGIN { use Test; plan tests => 4; }

use Test;

# Test 1:
eval join '', <DATA>;
ok (not $@);

# Test 2:
eval { import X qw (-abc); };
ok (not $@);

# Test 3, 4:
eval { import Y qw (-def); };
ok (not $@);
ok ($Y::DEBUG, 1);

# Get rid of "used only once" warning:
do { 1; } if $Y::DEBUG;

__DATA__

package X;

use strict;
use vars qw(@ISA %PRAGMATA);

require Pragmatic;

@ISA = qw(Pragmatic);

%PRAGMATA = (abc => sub { 1; });

1;


package Y;

use strict;
use vars qw ($DEBUG @ISA %PRAGMATA);

$DEBUG = 0;

@ISA = qw(X);

%PRAGMATA = (def => sub { $DEBUG = 1; });

1;

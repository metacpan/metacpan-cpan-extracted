# Emacs, this is -*- perl -*- code.

BEGIN { use Test; plan tests => 11; }

use Test;

# Test 1:
eval join '', <DATA>;
ok (not $@);

# Test 2, 3:
eval { import X; };
ok (not $@);
eval { X->flintstone; }; # die
ok ($@);

# Test 4, 5:
eval { import X qw (-fred); };
ok (not $@);
ok (X->flintstone, 'fred');

# Test 6, 7:
eval { import X qw (-barney); };
ok (not $@);
ok (X->flintstone, 'barney');

# Test 8, 9:
eval { import X qw (-flintstone=wilma); };
ok (not $@);
ok (X->flintstone, 'wilma');

# Test 10, 11:
eval { import X qw (-flintstone=betty); };
ok (not $@);
eval { X->flintstone; }; # die
ok ($@);

__DATA__

package X;

use strict;
use vars qw($DEBUG @ISA %PRAGMATA);

require Pragmatic;

$DEBUG = 0;

@ISA = qw(Pragmatic);

my $fred = sub { 'fred'; };
my $barney = sub { 'barney'; };

sub wilma { 'wilma'; }
# no sub betty

# Need to suppress 'Subroutine %s redefined' warnings:
%PRAGMATA =
  (fred => sub {
     local $^W = 0;
     *flintstone = $fred;
   },

   barney => sub {
     local $^W = 0;
     *flintstone = $barney;
   },

   flintstone => sub {
     no strict qw(refs);
     local $^W = 0;
     *flintstone = *{$_[1]};
   });

1;

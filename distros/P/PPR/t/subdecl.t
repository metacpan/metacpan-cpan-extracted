use warnings;
use strict;

use B::Deparse;
use Test::More;
use PPR;

plan tests => 9;

my $subdecl = qr{ ^ (?&PerlSubroutineDeclaration) $  $PPR::GRAMMAR }x;

# Perl 5.38 addition...
ok 'sub or_equals   ($x ||= 0 ) {...}' =~ $subdecl, 'or_equals';
ok 'sub doh_equals  ($x //= 0 ) {...}' =~ $subdecl, 'doh_equals';

# 'sub' keyword is optional for these...
ok 'AUTOLOAD {}' =~ $subdecl, 'AUTOLOAD';
ok 'DESTROY {}'  =~ $subdecl, 'DESTROY';
ok '&DESTROY();' !~ $subdecl, '&DESTROY();';
ok 'DESTROY();'  =~ $subdecl, 'DESTROY();';

# Prototypes may come before or after signature, depending on the Perl version...
ok 'sub protofirst :prototype($$@) ($x, $y, @z) {...}' =~ $subdecl, 'protofirst';
ok 'sub protolast  ($x, $y, @z) :prototype($$@) {...}' =~ $subdecl, 'protolast';

# Unnamed subs can have signatures too...
ok 'sub unnamed  ($, $y) {...}' =~ $subdecl, 'unnamed';

done_testing();


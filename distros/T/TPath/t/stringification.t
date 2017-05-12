# makes sure stringification of an expression is semantically identical to the original

use strict;
use warnings;

use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More;
use Test::Exception;
use ToyXMLForester;

my $f = ToyXMLForester->new;

my @paths = grep /^\s*+\S(?<!#)/, <<'EOF' =~ /.*/mg;
a
//a
//*[@attr('b')]
descendant::*
descendant::@attr('b')
^a
/>a
/>@attr('b')
a[@attr('b') or @attr('c')]
a[@attr('b') and @attr('c')]
a[@attr('b') one @attr('c')]
a[!@attr('b') one @attr('c')]
a[@attr('b') or @attr('c') and @attr('d')]
a[(@attr('b') or @attr('c')) and @attr('d')]
/a/b
/a//b
\.a\\
:"a b"
/a/"b c"
/a//"b c"
a[1]
a[b]
a[@attr('b')]
a[@attr('b') = 1]
a[@attr('b') == 1]
a[@attr('b') =~ 'b']
^a
^@attr('b')
~a~
~a~~b~
a?
a+
a*
a{,2}
a{2,}
a{2}
a{2,3}
(a/b){2}
:root/a
:id(foo)/a
.
..
//a/:p[@te('a')]
a[@attr('b') - 1 = 0]
a[@attr('b')=1]
a[:ceil(@attr('b'))=1]
a[:ceil(@attr('b') + 1)=1]
a[b - 1 = 0]
a[b=1]
a[:ceil(b)=1]
a[:ceil(b + 1)=1]
a|b
(a|b)
(a|b)/c
(//*)[0]
//a[@attr('b')='\r\v\f\b\n\t']
EOF

plan tests => @paths * 3;

for my $path (@paths) {
    my ( $p1, $p2 );
    eval {
        lives_ok { $p1 = $f->path($path) } "could parse $path";
    };
    if ($@) {
        diag "failed initial compilation of path $path; error: $@";
    }
    eval {
        lives_ok { $p2 = $f->path("$p1") } "could parse the stringification of $path as $p1";
    };
    if ($@) {
        diag
"failed compilation of stringification of path $path into $p1; error: $@";
    }
    is_deeply $p1, $p2,
      "identical structure produced for path $path and its stringification $p1";
}
done_testing();

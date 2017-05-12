# tests out whether the |=, =|=, and =| tests work

use strict;
use warnings;
use File::Basename qw(dirname);

BEGIN {
    push @INC, dirname($0);
}

use Test::More tests => 8;
use ToyXMLForester;
use ToyXML qw(parse);

my $f     = ToyXMLForester->new;
my $p     = parse '<a><foobar/><ofoob/><ofoo/></a>';
my $index = $f->index($p);

my $path = q{//*[@tag |= 'foo']};
my @elements = $f->path($path)->select( $p, $index );
is @elements, 1, "got expected number of elements from $p with $path";
is 'foobar', $elements[0]->tag, 'got correct element';

$path = q{//*[@tag =|= 'foo']};
@elements = $f->path($path)->select( $p, $index );
is @elements, 3, "got expected number of elements from $p with $path";

$path = q{//*[@tag =| 'foo']};
@elements = $f->path($path)->select( $p, $index );
is @elements, 1, "got expected number of elements from $p with $path";
is $elements[0]->tag, 'ofoo', 'got correct element';

$path = q{//*[@tag |= @tag]};
@elements = $f->path($path)->select( $p, $index );
is @elements, 4, "got expected number of elements from $p with $path";

$path = q{//*[@tag =|= @tag]};
@elements = $f->path($path)->select( $p, $index );
is @elements, 4, "got expected number of elements from $p with $path";

$path = q{//*[@tag =| @tag]};
@elements = $f->path($path)->select( $p, $index );
is @elements, 4, "got expected number of elements from $p with $path";

done_testing();

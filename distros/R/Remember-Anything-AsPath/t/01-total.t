use strict;
use warnings;
use Test::More;
use File::Path qw(remove_tree);

if (eval{ require Digest::SHA }) {
    Digest::SHA->import('sha256_hex');
    plan tests => 5;
}
else {
    plan skip_all => "Need 'Digest::SHA' available for testing";
}

use_ok('Remember::Anything::AsPath');

(my $tmp_dir = __FILE__) =~ s/01-total.t$//;
$tmp_dir .= 'tmp';

my $some_obj = bless {
    foo  => 'bar',
    aref => [0 .. 10],
    href => {
        foo => 'bar',
    },
    obj  => (bless { foo => 'bar' }, 'AnotherClass'),
}, 'SomeClass';

{ # default attrib
    my $db_brain = Remember::Anything::AsPath->new(
        out_dir => $tmp_dir,
    );

    is $db_brain->seen($some_obj), 0, 'Unknown object is not found (1)';

    $db_brain->remember($some_obj);
    is $db_brain->seen($some_obj), 1, 'Remembered object (1)';

    remove_tree("$tmp_dir");
}

{ # custom threedepth, and digest sub
    $tmp_dir =~ s{\/$}{};
    my $digest_sub = \&sha256_hex;
    my $db_brain = Remember::Anything::AsPath->new(
        out_dir    => $tmp_dir,
        digest_sub => $digest_sub,
        tree_depth => 4,
    );

    is $db_brain->seen($some_obj), 0, 'Unknown object is not found (2)';
    $db_brain->remember($some_obj);

    is $db_brain->seen($some_obj), 1, 'Remembered object (2)';

    remove_tree("$tmp_dir");
}

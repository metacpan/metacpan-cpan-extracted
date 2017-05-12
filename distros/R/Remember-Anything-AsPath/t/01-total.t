use strict;
use warnings;
use Test::More;
use File::Path qw(remove_tree);

if (eval{ require Digest::SHA }) {
    Digest::SHA->import('sha256_hex');
    plan tests => 7;
}
else {
    plan skip_all => "Need 'Digest::SHA' available for testing";
}

use_ok('Remember::Anything::AsPath');

(my $cur_dir = __FILE__) =~ s/01-total.t$//;

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
        out_dir => $cur_dir,
    );

    is $db_brain->seen($some_obj), 0, 'Unknown object is not found (1)';

    $db_brain->remember($some_obj);
    is $db_brain->seen($some_obj), 1, 'Remembered object (1)';

    my $id_file = "${cur_dir}/d917ccecd7502f/532daa7fa39b89/70beeba37abd";
    ok -e $id_file, 'Default treedepth and file id correct';
    remove_tree("${cur_dir}/d917ccecd7502f");
}

{ # custom threedepth, and digest sub
    $cur_dir =~ s{\/$}{};
    my $digest_sub = \&sha256_hex;
    my $db_brain = Remember::Anything::AsPath->new(
        out_dir    => $cur_dir,
        digest_sub => $digest_sub,
        tree_depth => 4,
    );

    is $db_brain->seen($some_obj), 0, 'Unknown object is not found (2)';
    $db_brain->remember($some_obj);

    is $db_brain->seen($some_obj), 1, 'Remembered object (2)';

    my $id_file = "$cur_dir/7b8439e0c9f22cabf/59d9ac7ce38a97e7a/bf26c695de86115c9/7e2315701aa59";
    ok -e $id_file, 'Custom treedepth and file id correct';
    remove_tree("$cur_dir/7b8439e0c9f22cabf");
}

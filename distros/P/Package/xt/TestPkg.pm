package xt::TestPkg;
use Test::More;

use Cwd 'abs_path';
use lib abs_path 'lib';
use Capture::Tiny 'capture_merged';

$ENV{PATH} = abs_path('bin') . ":$ENV{PATH}";

sub test {
    my ($dest, $from) = @_;
    `rm -fr $dest`;

    my $home = $ENV{HOME};
    my $cmd = "pkg new --desc='Best Foo module ever' --from=$from --module=Foo::Bar --git.create=0 $dest";

    my $rc = system($cmd);

    `rm -fr $dest/.git`;

    if ($rc == 0) {
        pass 'command worked';
    }
    else {
        fail 'command failed';
        exit;
    }

    my $diff = capture_merged {
        system("diff -ru $dest-expected $dest");
    };
    if (not length $diff) {
        pass 'new Foo is correct';
        `rm -fr $dest`;
    }
    else {
        fail 'new Foo does not match expected';
        die $diff;
    }
}

1;

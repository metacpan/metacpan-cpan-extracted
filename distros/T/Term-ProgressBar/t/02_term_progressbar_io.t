# -*- mode: cperl; -*-
use Test::More;

use_ok('Term::ProgressBar::IO');

use IO::File;
use Capture::Tiny qw(capture_stderr);

my $fh = IO::File->new('t/random_file','r') or
    die "Unable to open t/random_file for reading: $!";

Term::ProgressBar->__force_term (50);

my $pb;
my $err = capture_stderr {
    $pb = Term::ProgressBar::IO->new($fh);
};

ok($pb->target() == 9*2+3,'Correct number of bytes in __DATA__');

while (<$fh>) {
    $err = capture_stderr {
        $pb->update();
    };
}

print STDERR $pb->last_update();
ok($pb->last_update() == $pb->target(),'Last position is now target');

close($fh);

done_testing();

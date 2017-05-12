use strict;
use warnings;
use Test::More;
use Capture::Tiny 'capture';
use File::Spec;

my $example = File::Spec->catfile('t', 'Target');
chdir $example;

capture {
    system $^X, 'Makefile.PL';
    system 'make', 'html5manifest_target1';
    system 'make', 'html5manifest_target2';
};

my $manifest = do {
    open my $fh, '<', 'example1.manifest' or die "Can'ot open file example1.manifest: $!";
    local $/;
    <$fh>;
};

is($manifest, <<MANIFEST);
CACHE MANIFEST

CACHE:
/site.css
/site.js
/skip.txt
MANIFEST

$manifest = do {
    open my $fh, '<', 'example2.manifest' or die "Can'ot open file example2.manifest: $!";
    local $/;
    <$fh>;
};

is($manifest, <<MANIFEST);
CACHE MANIFEST

CACHE:
/foo.js
MANIFEST

capture {
    system 'make', 'distclean';
};

done_testing;

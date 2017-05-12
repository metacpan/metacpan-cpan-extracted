use strict;
use warnings;
use Test::More;
use Capture::Tiny 'capture';
use File::Spec;

my $example = File::Spec->catfile('t', 'Example');
chdir $example;

capture {
    system $^X, 'Makefile.PL';
    system 'make', 'html5manifest';
};

my $manifest = do {
    open my $fh, '<', 'example.manifest' or die "Can'ot open file example.manifest: $!";
    local $/;
    <$fh>;
};

is($manifest, <<MANIFEST);
CACHE MANIFEST

NETWORK:
/api
/foo/bar.cgi

CACHE:
/site.css
/site.js

# digest: KC22SJMksgNahFOXL97t7w
MANIFEST

capture {
    system 'make', 'distclean';
};

done_testing;

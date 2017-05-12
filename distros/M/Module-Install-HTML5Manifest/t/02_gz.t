use strict;
use warnings;
use Test::More;
use Capture::Tiny 'capture';
use Digest::MD5;
use File::Spec;
use IO::Uncompress::Gunzip 'gunzip';

my $example = File::Spec->catfile('t', 'Zlib');
chdir $example;

capture {
    system $^X, 'Makefile.PL';
    system 'make', 'html5manifest';
};

my $md5 = Digest::MD5->new;

gunzip('example.manifest.gz' => \my $manifest);
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

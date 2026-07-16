use v5.40;
use experimental 'signatures';
use FindBin;
use PAGI::Nano;

# Ports PAGI-Tools' app-01-file to PAGI::Nano.
# Static file serving (index resolution, MIME types, ETag/304, range requests,
# path-traversal protection) all come from PAGI::App::File, which `static` mounts
# under a prefix. Mounting at the bare root '/' is supported and serves the whole
# tree, just like the original pure file-server example.
#
#     pagi-server app.pl
#     curl http://127.0.0.1:5000/

my $dir = "$FindBin::Bin/public/";

my $app = app {
    static '/' => $dir;
};

$app;

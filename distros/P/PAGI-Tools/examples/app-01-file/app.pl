use strict;
use warnings;
use File::Basename;
use File::Spec;
use PAGI::App::File;

# PAGI::App::File Example
# Run with: pagi-server ./examples/app-01-file/app.pl --port 5000
#
# Features demonstrated:
#   - Static file serving from a root directory
#   - Index file resolution (index.html)
#   - MIME type detection
#   - ETag caching (304 Not Modified)
#   - Range requests for partial content
#   - Path traversal protection
#
# Test URLs:
#   http://localhost:5000/           -> index.html
#   http://localhost:5000/test.txt   -> plain text
#   http://localhost:5000/data.json  -> JSON
#   http://localhost:5000/style.css  -> CSS
#   http://localhost:5000/subdir/nested.txt -> nested file

my $dir = dirname(__FILE__);
my $app = PAGI::App::File->new(
    root => File::Spec->catdir($dir, 'static'),
)->to_app;

$app;

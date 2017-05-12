# Test resolving MIME types with File::LibMagic

use Test::More;

if ( eval "require File::LibMagic" ) {
    plan tests => 10;
}
else {
    plan skip_all => 'File::LibMagic not installed';
}

BEGIN {
    $ENV{DEBUG_NO_FILE_MIMEINFO} = 1;
}

use RPC::ExtDirect::Server;

my $cls = 'RPC::ExtDirect::Server';
my $static_dir = 't/htdocs';

my ($type, $charset);

# foo.txt is a legitimate text file
($type, $charset) = $cls->_guess_mime_type("$static_dir/foo.txt");

is $type,    'text/plain', 'foo type';
is $charset, 'us-ascii',   'foo charset';

# bar.png is actually text
($type, $charset) = $cls->_guess_mime_type("$static_dir/bar.png");

is $type,    'text/plain', 'bar type';
is $charset, 'us-ascii',   'bar charset';

# This is an actual GIF
($type, $charset) = $cls->_guess_mime_type("$static_dir/empty.gif");

is $type,    'image/gif',  'gif type';
is $charset, 'binary',     'gif charset';

# Unicode text in UTF-8
($type, $charset) = $cls->_guess_mime_type("$static_dir/utf8.txt");

is $type,    'text/plain', 'utf8 type';
is $charset, 'utf-8',      'utf8 charset';

# Non-unicode HTML in single byte Windows codepage
($type, $charset) = $cls->_guess_mime_type("$static_dir/win.html");

is $type,    'text/html',  'win type';
is $charset, 'iso-8859-1', 'win charset';


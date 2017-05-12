# Test resolving MIME types with File::MimeInfo

use Test::More;

if ( eval "require File::MimeInfo" ) {
    plan tests => 5;
}
else {
    plan skip_all => 'File::MimeInfo not installed';
}

BEGIN {
    $ENV{DEBUG_NO_FILE_LIBMAGIC} = 1;
}

use RPC::ExtDirect::Server;

my $cls = 'RPC::ExtDirect::Server';
my $static_dir = 't/htdocs';

my $type;

# foo.txt is a legit text file
($type) = $cls->_guess_mime_type("$static_dir/foo.txt");

is $type, 'text/plain', 'foo type';

# bar.png is actually text but File::MimeInfo is dumb
($type) = $cls->_guess_mime_type("$static_dir/bar.png");

is $type, 'image/png', 'bar type';

# This is an actual GIF image
($type) = $cls->_guess_mime_type("$static_dir/empty.gif");

is $type, 'image/gif', 'gif type';

# Unicode text in UTF-8
($type) = $cls->_guess_mime_type("$static_dir/utf8.txt");

is $type, 'text/plain', 'utf8 type';

# Non-Unicode HTML in single byte Windows codepage
($type) = $cls->_guess_mime_type("$static_dir/win.html");

is $type, 'text/html', 'win type';


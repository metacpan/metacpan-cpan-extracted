use strict;
use Test::Base;

use Path::Class;
use Path::Class::URI;
plan tests => 2 * blocks;

filters 'chomp';

run {
    my $block = shift;
    my $f = file( split '/', eval '"' . $block->input . '"' );
    is $f->uri, $block->expected;

    my $f2 = file_from_uri($f->uri);
    is $f2, $f;
};

__END__

===
--- input
bob/john.txt
--- expected
file:bob/john.txt

===
--- input
/path/foo/\xe5\x97\xad.txt
--- expected
file:///path/foo/%E5%97%AD.txt

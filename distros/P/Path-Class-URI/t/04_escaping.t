use strict;
use Test::Base;

use Path::Class;
use Path::Class::URI;
plan tests => 4 * blocks;

filters 'chomp';

run {
    my $block = shift;

    {
        my $file = file($block->input);
        my $file_back = file_from_uri($file->uri);
        isa_ok $file_back, 'Path::Class::File';
        is $file_back, $file;
    }

    {
        my $dir = dir($block->input);
        my $dir_back = dir_from_uri($dir->uri);
        isa_ok $dir_back, 'Path::Class::Dir';
        is $dir_back, $dir;
    }
};

__END__

===
--- input
/path/to/test/download;jsessionid=ABC.pdf
===
--- input
/a/b;c/d;e
===
--- input
/a/b%c/d%e

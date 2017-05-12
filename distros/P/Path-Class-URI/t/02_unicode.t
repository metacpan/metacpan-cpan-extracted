use strict;
use Test::Base;

use Path::Class;
use Path::Class::Unicode;
plan tests => 5 * blocks;

filters 'chomp', 'eval_str';
sub eval_str { eval '"' . shift() . '"' }

run {
    my $block = shift;
    my $f = ufile( split '/', $block->input );
    is $f->uri, $block->expected;
    my $f2 = ufile_from_uri($f->uri);
    is $f2, $f;

    {
        local $Path::Class::Unicode::encoding = "utf-8";
        is file($f2->stringify)->basename, $block->local_utf8;

        local $Path::Class::Unicode::encoding = "cp932";
        is file($f2->stringify)->basename, $block->local_cp932;
    }

    is file($f2->stringify)->ufile, $f;
};

__END__

===
--- input
bob/john.txt
--- expected
file:bob/john.txt
--- local_utf8
john.txt
--- local_cp932
john.txt

===
--- input
/path/foo/\x{30c6}\x{30b9}\x{30c8}.txt
--- expected
file:///path/foo/%E3%83%86%E3%82%B9%E3%83%88.txt
--- local_utf8
\xE3\x83\x86\xE3\x82\xB9\xE3\x83\x88.txt
--- local_cp932
\x83\x65\x83\x58\x83\x67.txt

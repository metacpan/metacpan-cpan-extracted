#!perl -wT
use strict;
use warnings;
use Test::More;


plan tests => 11;

use_ok("RackMan::File");

my $file = eval { RackMan::File->new };
is $@, "", "RackMan::File->new";
isa_ok $file, "RackMan::File", 'check that $file';

eval { $file->name("lipsum.txt") };
is $@, "", '$file->name("lipsum.txt")';

eval { $file->path("t/files") };
is $@, "", '$file->path("t/files")';

eval { $file->add_content("Lorem ipsum dolor sit amet, ") };
is $@, "", '$file->add_content("...")';

eval { $file->add_content("consectetur adipisicing elit, sed ",
    "do eiusmod tempor incididunt ut labore et dolore magna aliqua. ") };
is $@, "", '$file->add_content("...")';

eval { $file->add_content("Ut enim ad minim veniam, quis nostrud ",
    "exercitation ullamco laboris nisi ",
    "ut aliquip ex ea commodo consequat.\n") };
is $@, "", '$file->add_content("...")';

eval { $file->write };
is $@, "", '$file->write';

my $path = "t/files/lipsum.txt";
ok -f $path, "check that $path exists";

open my $fh, "<", $path or die "can't read $path: $!";
my $content = <$fh>;
close $fh;
unlink $path;

my $lipsum = "Lorem ipsum dolor sit amet, consectetur adipisicing "
    . "elit, sed do eiusmod tempor incididunt ut labore et dolore "
    . "magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation "
    . "ullamco laboris nisi ut aliquip ex ea commodo consequat.\n";
is $content, $lipsum, "check file content";

unlink $path;


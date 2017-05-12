#! perl -T

BEGIN {
    use strict;
    use warnings;
    use Test::More tests => 8;

    use_ok('Sys::Mmap');
}

use FileHandle;

$temp_file = "mmap.tmp";

my $temp_file_contents = "ABCD1234" x 1000; 
sysopen(FOO, $temp_file, O_WRONLY|O_CREAT|O_TRUNC) or die "$temp_file: $!\n";
print FOO $temp_file_contents;
close FOO;

my $foo;
sysopen(FOO, $temp_file, O_RDONLY) or die "$temp_file: $!\n";
# Test negative offsets fail.
is(eval { mmap($foo, 0, PROT_READ, MAP_SHARED, FOO, -100); 1}, undef, "Negative seek fails.");
like($@, qr/^\Qmmap: Cannot operate on a negative offset (-100)\E/, "croaks when negative offset is passed in"); 
# Now map the file for real
mmap($foo, 0, PROT_READ, MAP_SHARED, FOO);
close FOO;

is($foo, $temp_file_contents, "RO access to the file produces valid data");
munmap($foo);

sysopen(FOO, $temp_file, O_RDWR) or die "$temp_file: $!\n";
mmap($foo, 0, PROT_READ|PROT_WRITE, MAP_SHARED, FOO);
close FOO;

substr($foo, 3, 1) = "Z";
substr($temp_file_contents, 3, 1) = "Z";
is($foo, $temp_file_contents, 'Foo can be altered in RW mode');
munmap($foo);

sysopen(FOO, $temp_file, O_RDONLY) or die "$temp_file: $!\n";
my $bar = <FOO>;
is($bar, $temp_file_contents, 'Altered foo reflects on disk');

{
    my $foo;
    my $file_size = -s $temp_file;
    open(my $fh, "<", $temp_file) or die;
    isa_ok($fh, 'GLOB');
    mmap($foo, $file_size, &Sys::Mmap::PROT_READ, &Sys::Mmap::MAP_SHARED, $fh);
    is($foo, $temp_file_contents, 'Read $foo, when it comes from a FileHandle');
    munmap($foo);
}
    

unlink($temp_file);

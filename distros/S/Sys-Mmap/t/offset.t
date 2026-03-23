#! perl

use strict;
use warnings;

use Test::More tests => 4;

use Sys::Mmap;
use Fcntl qw(O_WRONLY O_CREAT O_TRUNC O_RDONLY);

my $temp_file = "offset.tmp";
my $file_size = 8192;

# Create a file large enough to map with an offset
sysopen(FOO, $temp_file, O_WRONLY|O_CREAT|O_TRUNC) or die "$temp_file: $!\n";
print FOO "A" x $file_size;
close FOO;

# Test 1: mmap with non-zero offset and explicit munmap
{
    my $data;
    sysopen(FOO, $temp_file, O_RDONLY) or die "$temp_file: $!\n";
    mmap($data, 256, PROT_READ, MAP_SHARED, FOO, 256);
    close FOO;
    is(length($data), 256, "mmap with offset returns correct length");
    is($data, "A" x 256, "mmap with offset returns correct data");
    munmap($data);
}

# Test 2: mmap with non-zero offset, DESTROY cleanup (no explicit munmap)
# This is the crash from GitHub issue #1 - segfault on cleanup when offset != 0
{
    my $data;
    sysopen(FOO, $temp_file, O_RDONLY) or die "$temp_file: $!\n";
    mmap($data, 256, PROT_READ, MAP_SHARED, FOO, 256);
    close FOO;
    is(length($data), 256, "mmap with offset (DESTROY path) returns correct length");
    # $data goes out of scope here - DESTROY is called instead of explicit munmap
    # Before the fix, this would segfault
}

pass("Survived DESTROY with non-zero offset (no segfault)");

unlink($temp_file);

#! perl

use strict;
use warnings;

use Test::More 'no_plan';
use Sys::Mmap;
use Fcntl qw(O_WRONLY O_CREAT O_TRUNC O_RDONLY O_RDWR);

my $temp_file = "comprehensive.tmp";
my $file_size = 8192;

# Create a test file with known content
sub create_test_file {
    my ($size, $pattern) = @_;
    $pattern = "ABCD1234" unless defined $pattern;
    sysopen(my $fh, $temp_file, O_WRONLY|O_CREAT|O_TRUNC) or die "$temp_file: $!\n";
    my $content = ($pattern x int($size / length($pattern) + 1));
    $content = substr($content, 0, $size);
    print $fh $content;
    close $fh;
    return $content;
}

# ---- Tied interface tests (new / TIESCALAR) ----

{
    my $content = create_test_file(4096);

    # Collect any warnings during tied cleanup to verify no munmap failures
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    {
        my $var;
        my $obj = Sys::Mmap->new($var, 4096, $temp_file);
        ok(defined $obj, "tied file: new() returns a defined object");
        ok(tied($var), "tied file: variable is tied after new()");
        is(length($var), 4096, "tied file: tied variable has correct length");
        is($var, $content, "tied file: tied variable has correct content");

        # Test STORE: writing through tied interface
        my $new_data = "HELLO";
        $var = $new_data;
        is(substr($var, 0, length($new_data)), $new_data, "tied file: STORE writes data at beginning");
        # Rest of mapping should be unchanged
        is(substr($var, length($new_data), 4), substr($content, length($new_data), 4), "tied file: STORE preserves rest of data");
        # Let $var and $obj go out of scope together
    }
    pass("tied file: variable cleaned up without crash");

    # The DESTROY fix should prevent munmap failures on the blessed reference
    my @munmap_warns = grep { /munmap failed/ } @warnings;
    is(scalar @munmap_warns, 0, "tied file: no munmap failures during DESTROY cleanup");
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    {
        my $var;
        my $obj = Sys::Mmap->new($var, 4096);
        ok(defined $obj, "tied anon: new() with anonymous memory returns defined object");
        ok(tied($var), "tied anon: variable is tied for anonymous memory");
        is(length($var), 4096, "tied anon: anonymous tied variable has correct length");

        $var = "test data";
        is(substr($var, 0, 9), "test data", "tied anon: STORE works on anonymous memory");
    }
    pass("tied anon: anonymous memory cleaned up without crash");

    my @munmap_warns = grep { /munmap failed/ } @warnings;
    is(scalar @munmap_warns, 0, "tied anon: no munmap failures during DESTROY cleanup");
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    # Create a tiny file
    create_test_file(100);
    is(-s $temp_file, 100, "tied grow: initial file is 100 bytes");

    {
        my $var;
        Sys::Mmap->new($var, 4096, $temp_file);
        ok(tied($var), "tied grow: tied to grown file");
        is(length($var), 4096, "tied grow: tied variable reflects grown size");
    }

    # File should have been grown to 4096
    ok(-s $temp_file >= 4096, "tied grow: file was grown to requested length");

    my @munmap_warns = grep { /munmap failed/ } @warnings;
    is(scalar @munmap_warns, 0, "tied grow: no munmap failures during DESTROY cleanup");
}

# ---- MAP_ANON tests ----

{
    my $data;
    my $addr = mmap($data, 4096, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANON, *STDOUT);
    ok(defined $addr, "MAP_ANON: mmap succeeds");
    is(length($data), 4096, "MAP_ANON: mapping has correct length");

    # Anonymous memory should be zero-filled
    is($data, "\0" x 4096, "MAP_ANON: memory is zero-filled");

    # Write and read back
    substr($data, 0, 5) = "Hello";
    is(substr($data, 0, 5), "Hello", "MAP_ANON: can write to region");

    munmap($data);
}

{
    my $data;
    eval { mmap($data, 0, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANON, *STDOUT) };
    like($@, qr/MAP_ANON.*no length/i, "MAP_ANON: len=0 croaks");
}

# ---- len=0 with offset: inferred length should be file_size - offset ----

{
    my $content = create_test_file(8192);

    my $data;
    sysopen(my $fh, $temp_file, O_RDONLY) or die "$temp_file: $!\n";
    mmap($data, 0, PROT_READ, MAP_SHARED, $fh);
    close $fh;

    is(length($data), 8192, "len=0: infers full file size");
    is($data, $content, "len=0: maps entire file content");
    munmap($data);
}

{
    my $content = create_test_file(8192);
    my $offset = 4096;

    my $data;
    sysopen(my $fh, $temp_file, O_RDONLY) or die "$temp_file: $!\n";
    mmap($data, 0, PROT_READ, MAP_SHARED, $fh, $offset);
    close $fh;

    is(length($data), 8192 - $offset, "len=0 with offset: infers file_size - offset");
    is($data, substr($content, $offset), "len=0 with offset: content matches file from offset");
    munmap($data);
}

{
    my $content = create_test_file(8192);
    my $offset = 256;  # likely not page-aligned

    my $data;
    sysopen(my $fh, $temp_file, O_RDONLY) or die "$temp_file: $!\n";
    mmap($data, 0, PROT_READ, MAP_SHARED, $fh, $offset);
    close $fh;

    is(length($data), 8192 - $offset, "len=0 with non-aligned offset: infers correct remaining size");
    is($data, substr($content, $offset), "len=0 with non-aligned offset: content matches");
    munmap($data);
}

{
    create_test_file(4096);

    my $data;
    sysopen(my $fh, $temp_file, O_RDONLY) or die "$temp_file: $!\n";
    eval { mmap($data, 0, PROT_READ, MAP_SHARED, $fh, 4096) };
    close $fh;
    like($@, qr/offset.*beyond end of file/i, "len=0: offset at EOF croaks");
}

{
    create_test_file(4096);

    my $data;
    sysopen(my $fh, $temp_file, O_RDONLY) or die "$temp_file: $!\n";
    eval { mmap($data, 0, PROT_READ, MAP_SHARED, $fh, 8192) };
    close $fh;
    like($@, qr/offset.*beyond end of file/i, "len=0: offset beyond EOF croaks");
}

# ---- Explicit offset with explicit length ----

{
    my $content = create_test_file(8192);
    my $offset = 4096;
    my $len = 1024;

    my $data;
    sysopen(my $fh, $temp_file, O_RDONLY) or die "$temp_file: $!\n";
    mmap($data, $len, PROT_READ, MAP_SHARED, $fh, $offset);
    close $fh;

    is(length($data), $len, "explicit offset+length: correct length");
    is($data, substr($content, $offset, $len), "explicit offset+length: correct content");
    munmap($data);
}

# ---- DESTROY cleanup (implicit munmap via scope exit) ----

{
    my $content = create_test_file(8192);

    {
        my $data;
        sysopen(my $fh, $temp_file, O_RDONLY) or die "$temp_file: $!\n";
        mmap($data, 0, PROT_READ, MAP_SHARED, $fh);
        close $fh;
        is(length($data), 8192, "DESTROY: mmap succeeded before scope exit");
        # $data goes out of scope - DESTROY called implicitly
    }
    pass("DESTROY: survived without explicit munmap");
}

# Cleanup
unlink($temp_file);

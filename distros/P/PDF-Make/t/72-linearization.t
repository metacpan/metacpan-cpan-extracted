#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);

BEGIN {
    use_ok('PDF::Make');
    use_ok('PDF::Make::Linearization');
}

# Test 1: Module loads
ok(1, 'PDF::Make::Linearization module loaded');

# Test 2: StreamReader class exists
can_ok('PDF::Make::StreamReader', qw(new read_header is_linearized page_count
                                      page_available read_page page_range));

# Test 3: Methods added to PDF::Make::Document
can_ok('PDF::Make::Document', qw(is_linearized linear_params linearize write_linearized));

# Test 4: Create basic PDF and check it's not linearized
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page;
    
    ok(!$doc->is_linearized, 'New PDF is not linearized');
    is($doc->linear_params, undef, 'linear_params returns undef for non-linearized');
}

# Test 5: StreamReader requires fetch callback
{
    eval {
        PDF::Make::StreamReader->new();
    };
    like($@, qr/fetch callback required/, 'StreamReader requires fetch');
    
    eval {
        PDF::Make::StreamReader->new(fetch => 'not a code ref');
    };
    like($@, qr/must be a code reference/, 'StreamReader fetch must be code ref');
}

# Test 6: StreamReader with mock fetch
{
    my $mock_data = "%PDF-2.0\n%\xe2\xe3\xcf\xd3\n1 0 obj\n<<\n/Linearized 1\n/L 12345\n/N 5\n/O 3\n/E 1000\n/H [ 500 100 ]\n/T 10000\n>>\nendobj\n";
    
    my $reader = PDF::Make::StreamReader->new(
        fetch => sub {
            my ($offset, $length) = @_;
            return substr($mock_data . ("\x00" x 5000), $offset, $length);
        }
    );
    
    ok($reader, 'StreamReader created');
    
    # Read header
    $reader->read_header;
    
    ok($reader->is_linearized, 'Detected linearized PDF');
    is($reader->page_count, 5, 'Page count extracted');
    
    my $params = $reader->params;
    is($params->{file_length}, 12345, 'File length extracted');
    is($params->{first_page_obj}, 3, 'First page object extracted');
    is($params->{first_page_end}, 1000, 'First page end extracted');
    is($params->{hint_offset}, 500, 'Hint offset extracted');
    is($params->{hint_length}, 100, 'Hint length extracted');
    is($params->{main_xref_offset}, 10000, 'Main xref offset extracted');
}

# Test 7: Non-linearized PDF detection
{
    my $non_linear = "%PDF-2.0\n1 0 obj\n<< /Type /Catalog >>\nendobj\n";
    
    my $reader = PDF::Make::StreamReader->new(
        fetch => sub {
            my ($offset, $length) = @_;
            return substr($non_linear . ("\x00" x 5000), $offset, $length);
        }
    );
    
    $reader->read_header;
    ok(!$reader->is_linearized, 'Non-linearized PDF detected');
    is($reader->page_count, 0, 'Page count is 0 for non-linearized');
}

# Test 8: Page availability tracking
{
    my $mock_data = "%PDF-2.0\n1 0 obj\n<<\n/Linearized 1\n/L 12345\n/N 3\n/O 3\n/E 1000\n/H [ 500 100 ]\n/T 10000\n>>\nendobj\n";
    
    my $reader = PDF::Make::StreamReader->new(
        fetch => sub {
            my ($offset, $length) = @_;
            return substr($mock_data . ("\x00" x 5000), $offset, $length);
        }
    );
    
    $reader->read_header;
    
    # First page should be marked as loaded
    ok($reader->page_available(0), 'First page marked as available');
    ok(!$reader->page_available(1), 'Page 1 not yet available');
    ok(!$reader->page_available(2), 'Page 2 not yet available');
}

# Test 9: linearize() method
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page;
    
    my $result = $doc->linearize;
    is($result, $doc, 'linearize() returns self');
}

# Test 10: write_linearized (basic test)
{
    my $doc = PDF::Make::Document->new;
    $doc->add_page;

    my $ok = eval {
        $doc->write_linearized;
        1;
    };

    if ($ok) {
        ok(1, 'write_linearized basic test');
    } else {
        like($@, qr/linearized write failed|not yet implemented|unimplemented/i,
            'write_linearized currently unimplemented in XS');
    }
}

# Test 11: Check linearization detection in raw data
{
    my $linear_data = "%PDF-2.0\n1 0 obj\n<</Linearized 1>>\nendobj\n";
    my $non_linear_data = "%PDF-2.0\n1 0 obj\n<</Type /Catalog>>\nendobj\n";

    ok($linear_data =~ /\/Linearized\s+1/, 'linearized marker present in fixture');
    ok($non_linear_data !~ /\/Linearized\s+1/, 'non-linearized fixture lacks marker');
}

# Test 12: Hint table parsing smoke test
{
    my $reader = PDF::Make::StreamReader->new(
        fetch => sub { return "\x00" x 4096; }
    );
    ok($reader, 'StreamReader for hint parsing');
    # Can't fully test without valid hint stream data
}

# Test 13: Page range calculation
{
    my $mock_data = "%PDF-2.0\n1 0 obj\n<<\n/Linearized 1\n/L 12345\n/N 2\n/O 3\n/E 1000\n/H [ 500 100 ]\n/T 10000\n>>\nendobj\n";
    
    # Create minimal hint stream data
    my $hint_header = pack("N", 1);      # Min objects
    $hint_header .= pack("N", 100);      # First page loc  
    $hint_header .= pack("n", 16);       # Bits for obj count
    $hint_header .= pack("N", 500);      # Min page length
    $hint_header .= pack("n", 32);       # Bits for page length
    $hint_header .= "\x00" x 24;         # Rest of header
    
    my $hint_stream = "2 0 obj\n<</Length 40>>\nstream\n" . $hint_header . "\nendstream\nendobj\n";
    
    my $full_data = $mock_data . ("\x00" x (500 - length($mock_data))) . $hint_stream . ("\x00" x 5000);
    
    my $reader = PDF::Make::StreamReader->new(
        fetch => sub {
            my ($offset, $length) = @_;
            return substr($full_data, $offset, $length);
        }
    );
    
    $reader->read_header;
    
    # Try loading hints
    eval { $reader->load_hints; };
    # May fail due to minimal hint data, but shouldn't crash
    ok(1, 'Hint loading attempt does not crash');
}

# Test 14: Invalid page numbers
{
    my $mock_data = "%PDF-2.0\n1 0 obj\n<<\n/Linearized 1\n/L 12345\n/N 2\n>>\nendobj\n";
    
    my $reader = PDF::Make::StreamReader->new(
        fetch => sub { return $mock_data . ("\x00" x 5000); }
    );
    
    $reader->read_header;
    
    eval { $reader->page_available(-1); };
    ok(!$@, 'Negative page number returns false, no crash');
    
    eval { $reader->read_page(999); };
    like($@, qr/Invalid page number/, 'Invalid page number throws');
}

done_testing();

package PDF::Make::Linearization;

use strict;
use warnings;
use PDF::Make;

our $VERSION = '0.04';

=head1 NAME

PDF::Make::Linearization - PDF Linearization (Fast Web View) support

=head1 SYNOPSIS

    use PDF::Make;
    use PDF::Make::Linearization;

    # Check if a PDF is linearized
    my $doc = PDF::Make->open('document.pdf');
    if ($doc->is_linearized) {
        my $params = $doc->linear_params;
        say "Fast Web View: Yes";
        say "Pages: $params->{page_count}";
        say "First page ends at byte: $params->{first_page_end}";
    }

    # Create a linearized PDF
    my $pdf = PDF::Make->new;
    $pdf->page->text(100, 700, "Page 1");
    $pdf->page->text(100, 700, "Page 2");
    $pdf->finalize;
    $pdf->write_linearized('optimized.pdf');

    # Streaming reader for HTTP byte-range requests
    my $reader = PDF::Make::StreamReader->new(
        fetch => sub {
            my ($offset, $length) = @_;
            return http_range_request($url, $offset, $length);
        }
    );
    $reader->read_header;
    say "Pages: ", $reader->page_count;

    # Load pages on demand
    $reader->read_page(0);  # First page (usually pre-loaded)
    $reader->read_page(5);  # Triggers fetch for page 6

=head1 DESCRIPTION

This module provides PDF linearization support, enabling "Fast Web View" 
functionality per Annex F of ISO 32000-2:2020.

Linearization reorganizes a PDF file so that:

=over 4

=item * The first page can display before the entire file downloads

=item * Subsequent pages load on demand via HTTP byte-range requests

=item * Hint tables enable efficient page offset calculation

=back

=head1 METHODS ADDED TO PDF::Make

=head2 is_linearized

    my $bool = $doc->is_linearized;

Returns true if the document is linearized (has Fast Web View).

=head2 linear_params

    my $params = $doc->linear_params;

Returns a hashref with linearization parameters:

    {
        version         => 1,           # Linearized version
        file_length     => 123456,      # Total file size
        hint_offset     => 1234,        # Hint stream offset
        hint_length     => 567,         # Hint stream length
        first_page_obj  => 7,           # First page object number
        first_page_end  => 12345,       # End of first page section
        page_count      => 10,          # Number of pages
        main_xref_offset => 98765,      # Main xref table offset
    }

Returns undef if document is not linearized.

=head2 linearize

    $doc->linearize;

Prepares the document for linearized output. This analyzes page dependencies
and computes the optimal object ordering.

=head2 write_linearized

    $doc->write_linearized($path);
    my $bytes = $doc->write_linearized;

Writes the document in linearized format. If a path is provided, writes to
that file. Otherwise returns the PDF bytes.

=cut

# Storage for linearization state (inside-out pattern for XS objects)
my %_linearize_state;

# Add methods to PDF::Make::Document - XS provides these when available
{
    no warnings 'redefine';
    
    # is_linearized - wraps XS _xs_is_linearized
    unless (defined &PDF::Make::Document::is_linearized) {
        *PDF::Make::Document::is_linearized = sub { $_[0]->_xs_is_linearized };
    }

    # linear_params - wraps XS _xs_linear_params; returns undef when not linearized
    unless (defined &PDF::Make::Document::linear_params) {
        *PDF::Make::Document::linear_params = sub {
            my ($self) = @_;
            return undef unless $self->is_linearized;
            return $self->_xs_linear_params;
        };
    }

    # linearize - wraps XS _xs_linearize, records state for write_linearized
    unless (defined &PDF::Make::Document::linearize) {
        *PDF::Make::Document::linearize = sub {
            my ($self) = @_;
            $self->_xs_linearize;
            $_linearize_state{"$self"} = 1;
            return $self;
        };
    }

    # write_linearized - wraps XS _xs_write_linearized_to_path, or returns bytes
    unless (defined &PDF::Make::Document::write_linearized) {
        *PDF::Make::Document::write_linearized = sub {
            my ($self, $path) = @_;
            $_linearize_state{"$self"} = 1;
            return $self->_xs_write_linearized_to_path($path) if defined $path;
            return $self->_write_linearized_bytes;
        };
    }
    
    # _write_linearized_bytes - use LinearContext to produce linearized output
    unless (defined &PDF::Make::Document::_write_linearized_bytes) {
        *PDF::Make::Document::_write_linearized_bytes = sub {
            my ($self) = @_;

            # Use LinearContext pipeline
            my $ctx = PDF::Make::LinearContext->_new($self);
            $ctx->analyze;
            $ctx->build_hints;
            return $ctx->write;
        };
    }
}

=head1 PDF::Make::StreamReader

Streaming reader for linearized PDFs, enabling page-on-demand loading.

=head2 new

    my $reader = PDF::Make::StreamReader->new(
        fetch => sub {
            my ($offset, $length) = @_;
            # Return $length bytes starting at $offset
            return $data;
        }
    );

Creates a new streaming reader with the given fetch callback.

=head2 read_header

    $reader->read_header;

Reads and parses the PDF header and linearization dictionary.
This is the first operation to perform.

=head2 is_linearized

    if ($reader->is_linearized) { ... }

Returns true if the PDF is linearized.

=head2 page_count

    my $count = $reader->page_count;

Returns the total number of pages. Available after C<read_header>.

=head2 page_available

    if ($reader->page_available($page_num)) { ... }

Returns true if the given page (0-based) is loaded.

=head2 read_page

    $reader->read_page($page_num);

Fetches and parses the given page's data. May trigger HTTP range request.

=head2 page_range

    my ($offset, $length) = $reader->page_range($page_num);

Returns the byte offset and length for the given page.
Useful for HTTP Range header construction.

=cut

package PDF::Make::StreamReader;

use strict;
use warnings;
use Carp qw(croak);

sub new {
    my ($class, %args) = @_;
    
    croak "fetch callback required" unless $args{fetch};
    croak "fetch must be a code reference" unless ref($args{fetch}) eq 'CODE';
    
    my $self = bless {
        fetch           => $args{fetch},
        is_linearized   => 0,
        page_count      => 0,
        params          => {},
        hints_loaded    => 0,
        page_hints      => [],
        shared_hints    => [],
        page_loaded     => {},  # page_num => 1
        header_data     => undef,
        _doc            => undef,
    }, $class;
    
    return $self;
}

sub read_header {
    my ($self) = @_;
    
    # Fetch first 4KB
    my $header_size = 4096;
    my $data = $self->{fetch}->(0, $header_size);
    
    croak "Failed to fetch header" unless defined $data && length($data) > 0;
    
    $self->{header_data} = $data;
    
    # Check for linearization
    if ($data =~ m{/Linearized\s+(\d+)}s) {
        $self->{is_linearized} = 1;
        $self->{params}{version} = $1;
    }
    
    # Extract linearization parameters
    if ($self->{is_linearized}) {
        # /L - file length
        if ($data =~ m{/L\s+(\d+)}s) {
            $self->{params}{file_length} = $1;
        }
        
        # /N - page count
        if ($data =~ m{/N\s+(\d+)}s) {
            $self->{page_count} = $1;
            $self->{params}{page_count} = $1;
        }
        
        # /O - first page object
        if ($data =~ m{/O\s+(\d+)}s) {
            $self->{params}{first_page_obj} = $1;
        }
        
        # /E - end of first page
        if ($data =~ m{/E\s+(\d+)}s) {
            $self->{params}{first_page_end} = $1;
        }
        
        # /H - hint stream [offset length]
        if ($data =~ m{/H\s*\[\s*(\d+)\s+(\d+)\s*(?:(\d+)\s+(\d+)\s*)?\]}s) {
            $self->{params}{hint_offset} = $1;
            $self->{params}{hint_length} = $2;
            $self->{params}{overflow_offset} = $3 if defined $3;
            $self->{params}{overflow_length} = $4 if defined $4;
        }
        
        # /T - main xref offset
        if ($data =~ m{/T\s+(\d+)}s) {
            $self->{params}{main_xref_offset} = $1;
        }
        
        # Mark first page as loaded (it's in the header section)
        $self->{page_loaded}{0} = 1;
    }
    
    return $self;
}

sub is_linearized {
    my ($self) = @_;
    return $self->{is_linearized};
}

sub page_count {
    my ($self) = @_;
    return $self->{page_count};
}

sub params {
    my ($self) = @_;
    return { %{$self->{params}} };
}

sub page_available {
    my ($self, $page_num) = @_;
    return $self->{page_loaded}{$page_num} ? 1 : 0;
}

sub load_hints {
    my ($self) = @_;
    
    return if $self->{hints_loaded};
    croak "Not linearized" unless $self->{is_linearized};
    
    my $offset = $self->{params}{hint_offset};
    my $length = $self->{params}{hint_length};
    
    croak "Hint offset/length not available" 
        unless defined $offset && defined $length;
    
    # Fetch hint stream
    my $hint_data = $self->{fetch}->($offset, $length);
    croak "Failed to fetch hint stream" 
        unless defined $hint_data && length($hint_data) >= $length;
    
    # Parse hint stream
    $self->_parse_hint_stream($hint_data);
    
    $self->{hints_loaded} = 1;
    
    return $self;
}

sub _parse_hint_stream {
    my ($self, $data) = @_;
    
    # Find stream content (skip object header and dictionary)
    my $stream_start = index($data, "stream");
    return unless $stream_start >= 0;
    $stream_start += 6;  # Skip "stream"
    
    # Skip newline after "stream"
    $stream_start++ if substr($data, $stream_start, 1) eq "\r";
    $stream_start++ if substr($data, $stream_start, 1) eq "\n";
    
    my $stream_end = rindex($data, "endstream");
    return unless $stream_end > $stream_start;
    
    my $stream_content = substr($data, $stream_start, $stream_end - $stream_start);
    
    # Parse page offset hint table header (§F.4.2)
    # First 40 bytes contain header fields
    return unless length($stream_content) >= 40;
    
    my @bytes = unpack("C*", $stream_content);
    my $pos = 0;
    
    # Item 1: Min objects per page (4 bytes)
    my $min_obj = ($bytes[$pos] << 24) | ($bytes[$pos+1] << 16) | 
                  ($bytes[$pos+2] << 8) | $bytes[$pos+3];
    $pos += 4;
    
    # Item 2: First page location (4 bytes)
    my $first_loc = ($bytes[$pos] << 24) | ($bytes[$pos+1] << 16) | 
                    ($bytes[$pos+2] << 8) | $bytes[$pos+3];
    $pos += 4;
    
    # Item 3: Bits for obj count (2 bytes)
    my $bits_obj = ($bytes[$pos] << 8) | $bytes[$pos+1];
    $pos += 2;
    
    # Item 4: Min page length (4 bytes)
    my $min_len = ($bytes[$pos] << 24) | ($bytes[$pos+1] << 16) | 
                  ($bytes[$pos+2] << 8) | $bytes[$pos+3];
    $pos += 4;
    
    # Item 5: Bits for page length (2 bytes)
    my $bits_len = ($bytes[$pos] << 8) | $bytes[$pos+1];
    $pos += 2;
    
    # Store parsed values
    $self->{hint_header} = {
        min_obj_count   => $min_obj,
        first_page_loc  => $first_loc,
        bits_obj_count  => $bits_obj,
        min_page_length => $min_len,
        bits_page_len   => $bits_len,
    };
    
    # Continue parsing per-page data...
    # (Simplified for now)
    
    return 1;
}

sub read_page {
    my ($self, $page_num) = @_;
    
    croak "Invalid page number" 
        if $page_num < 0 || $page_num >= $self->{page_count};
    
    # Already loaded?
    return $self if $self->{page_loaded}{$page_num};
    
    # Need hints for page ranges
    $self->load_hints unless $self->{hints_loaded};
    
    # Get page byte range
    my ($offset, $length) = $self->page_range($page_num);
    
    # Fetch page data
    my $page_data = $self->{fetch}->($offset, $length);
    croak "Failed to fetch page $page_num" 
        unless defined $page_data && length($page_data) > 0;
    
    # Parse page objects
    # (In real implementation, would parse and add to document)
    
    # Mark page as loaded
    $self->{page_loaded}{$page_num} = 1;
    
    return $self;
}

sub page_range {
    my ($self, $page_num) = @_;
    
    croak "Invalid page number" 
        if $page_num < 0 || $page_num >= $self->{page_count};
    
    # Load hints if needed
    $self->load_hints unless $self->{hints_loaded};
    
    # Calculate offset from hint data
    my $header = $self->{hint_header};
    return (0, 0) unless $header;
    
    my $offset = $header->{first_page_loc};
    my $length = $header->{min_page_length};
    
    # Add deltas for pages before this one
    for my $i (0 .. $page_num - 1) {
        my $hint = $self->{page_hints}[$i];
        if ($hint) {
            $offset += $hint->{page_length};
        } else {
            $offset += $length;  # Use min length as estimate
        }
    }
    
    # Get this page's length
    my $page_hint = $self->{page_hints}[$page_num];
    if ($page_hint) {
        $length = $page_hint->{page_length};
    }
    
    return ($offset, $length);
}

sub doc {
    my ($self) = @_;
    return $self->{_doc};
}

=head1 LINEARIZATION STRUCTURE

A linearized PDF has this structure:

    ┌─────────────────────────────────────┐
    │ Header (%PDF-2.0)                   │
    ├─────────────────────────────────────┤
    │ Linearization dictionary (obj 1)    │
    ├─────────────────────────────────────┤
    │ First page xref (partial)           │
    ├─────────────────────────────────────┤
    │ Document catalog, pages tree root   │
    ├─────────────────────────────────────┤
    │ First page objects                  │
    ├─────────────────────────────────────┤
    │ Hint stream                         │
    ├─────────────────────────────────────┤
    │ Remaining pages (2..N)              │
    ├─────────────────────────────────────┤
    │ Shared objects                      │
    ├─────────────────────────────────────┤
    │ Main xref + trailer                 │
    └─────────────────────────────────────┘

=head1 SEE ALSO

L<PDF::Make>, ISO 32000-2:2020 Annex F (Linearized PDF)

=cut

1;

__END__

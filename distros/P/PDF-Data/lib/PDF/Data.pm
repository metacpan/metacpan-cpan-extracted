package PDF::Data;

# Require Perl v5.16; enable warnings and UTF-8.
use v5.16;
use warnings;
use utf8;

# Declare module version.  (Also in pod documentation below.)
use version; our $VERSION = version->declare('v1.2.0');

# Initialize modules.
use mro;
use namespace::autoclean;
use Carp                qw[carp croak confess];;
use Clone;
use Compress::Raw::Zlib qw[:status :flush];
use Data::Dump          qw[dd dump];
use List::MoreUtils     qw[minmax];
use List::Util          qw[max];
use Math::Trig          qw[pi];
use POSIX               qw[mktime strftime];
use Scalar::Util        qw[blessed reftype];

# Use byte strings instead of Unicode character strings.
use bytes;

# Basic parsing regular expressions.
our $n  = qr/(?:\n|\r\n?)/;                       # Match a newline. (LF, CRLF or CR)
our $ss = '\x00\x09\x0a\x0c\x0d\x20';             # List of PDF whitespace characters.
our $s  = "[$ss]";                                # Match a single PDF whitespace character.
our $ws = qr/(?:(?:(?>%[^\r\n]*)?$s+)+)/;         # Match whitespace, including PDF comments.

# Declare prototypes.
sub is_hash ($);
sub is_array ($);
sub is_stream ($);

# Utility functions.
sub is_hash   ($) { ref $_[0] && reftype($_[0]) eq "HASH"; }
sub is_array  ($) { ref $_[0] && reftype($_[0]) eq "ARRAY"; }
sub is_stream ($) { &is_hash  && exists $_[0]{-data}; }

# Create a new PDF::Data object, representing a minimal PDF file.
sub new {
  my ($self, %args) = @_;

  # Get the class name.
  my $class = blessed $self || $self;

  # Create a new instance using the constructor arguments.
  my $pdf = bless \%args, $class;

  # Set creation timestamp.
  $pdf->{Info}{CreationDate} = $pdf->timestamp;

  # Create an empty document catalog and page tree.
  $pdf->{Root}{Pages} = { Kids => [], Count => 0 };

  # Validate the PDF structure and return the new instance.
  return $pdf->validate;
}

# Deep copy entire PDF::Data object.
sub clone {
  my ($self) = @_;
  return Clone::clone($self);
}

# Create a new page with the specified size.
sub new_page {
  my ($self, $x, $y) = @_;

  # Paper sizes.
  my %sizes = (
    LETTER => [  8.5,    11      ],
    LEGAL  => [  8.5,    14      ],
    A0     => [ 33.125,  46.8125 ],
    A1     => [ 23.375,  33.125  ],
    A2     => [ 16.5,    23.375  ],
    A3     => [ 11.75,   16.5    ],
    A4     => [  8.25,   11.75   ],
    A5     => [  5.875,  8.25    ],
    A6     => [  4.125,  5.875   ],
    A7     => [  2.9375, 4.125   ],
    A8     => [  2.0625, 2.9375  ],
  );

  # Default page size to US Letter (8.5" x 11").
  unless ($x and $y and $x > 0 and $y > 0) {
    $x ||= "LETTER";
    croak "Error: Unknown paper size \"$x\"!\n" unless $sizes{$x};
    ($x, $y) = @{$sizes{$x}};
  }

  # Make sure page size was specified.
  croak join(": ", $self->{-file} || (), "Error: Paper size not specified!\n") unless $x and $y and $x > 0 and $y > 0;

  # Scale inches to default user space units (72 DPI).
  $x *= 72 if $x < 72;
  $y *= 72 if $y < 72;

  # Create and return a new page object.
  return {
    Type      => "/Page",
    MediaBox  => [0, 0, $x, $y],
    Contents  => { -data => "" },
    Resources => {
      ProcSet => ["/PDF", "/Text"],
    },
  };
}

# Deep copy the specified page object.
sub copy_page {
  my ($self, $page) = @_;

  # Temporarily hide parent reference.
  delete local $page->{Parent};

  # Clone the page object.
  my $copied_page = Clone::clone($page);

  # return cloned page object.
  return $copied_page;
}

# Append the specified page to the PDF.
sub append_page {
  my ($self, $page) = @_;

  # Increment page count for page tree root node.
  $self->{Root}{Pages}{Count}++;

  # Add page object to page tree root node for simplicity.
  push @{$self->{Root}{Pages}{Kids}}, $page;
  $page->{Parent} = $self->{Root}{Pages};

  # Return the page object.
  return $page;
}

# Read and parse PDF file.
sub read_pdf {
  my ($self, $file, %args) = @_;

  # Read entire file at once.
  local $/;

  # Contents of entire PDF file.
  my $data;

  # Check for standard input.
  if (($file // "-") eq "-") {
    # Read all data from standard input.
    $file = "<standard input>";
    binmode STDIN or croak "$file: $!\n";
    $data = <STDIN>;
    close STDIN or croak "$file: $!\n";
  } else {
    # Read the entire file.
    open my $IN, '<', $file or croak "$file: $!\n";
    binmode $IN or croak "$file: $!\n";
    $data = <$IN>;
    close $IN or croak "$file: $!\n";
  }

  # Parse PDF file data and return new instance.
  return $self->parse_pdf($data, -file => $file, %args);
}

# Parse PDF file data.
sub parse_pdf {
  my ($self, $data, %args) = @_;

  # Get the class name.
  my $class = blessed $self || $self;

  # Create a new instance using the provided arguments.
  $self = bless \%args, $class;

  # Validate minimal PDF file structure starting with %PDF and ending with %%EOF.
  my ($pdf_version, $pdf_data) = $data =~ /%PDF-(\d+\.\d+)$s*?$n(.*)%%EOF/s
    or croak join(": ", $self->{-file} || (), "File does not contain a valid PDF document!\n");

  # Discard startxref value which should be present in any valid PDF, but don't require it.
  $pdf_data =~ s/\bstartxref$ws?(\d+)$ws\z//s;

  # Check PDF version.
  warn join(": ", $self->{-file} || (), "Warning: PDF version $pdf_version not supported!\n")
    unless $pdf_version =~ /^1\.[0-7]$/;

  # Parsed indirect objects.
  my $objects = {};

  # Parse PDF objects.
  my @objects = $self->parse_objects($objects, $pdf_data, 0);

  # PDF trailer dictionary.
  my $trailer;

  # Find trailer dictionary.
  for (my $i = 0; $i < @objects; $i++) {
    if ($objects[$i][0] eq "trailer") {
      $i < $#objects and $objects[$i + 1][1]{type} eq "dict"
        or croak join(": ", $self->{-file} || (), "Byte offset $objects[$i][1]{offset}: Invalid trailer dictionary!\n");
      $trailer = $objects[$i + 1][0];
      last;
    }
  }

  # Make sure trailer dictionary was found.
  croak join(": ", $self->{-file} || (), "PDF trailer dictionary not found!\n") unless defined $trailer;

  # Resolve indirect object references.
  $self->resolve_references($objects, $trailer);

  # Create a new instance from the parsed data.
  my $pdf = bless $trailer, $class;

  # Add any provided arguments.
  foreach my $key (sort keys %args) {
    $pdf->{$key} = $args{$key};
  }

  # Validate the PDF structure (unless the -novalidate flag is set) and return the new instance.
  return $self->{-novalidate} ? $pdf : $pdf->validate;
}

# Generate and write a new PDF file.
sub write_pdf {
  my ($self, $file, $time) = @_;

  # Default missing timestamp to current time, but keep a zero time as a flag.
  $time //= time;

  # Generate PDF file data.
  my $pdf_data = $self->pdf_file_data($time);

  # Check if standard output is wanted.
  if (($file // "-") eq "-") {
    # Write PDF file data to standard output.
    $file = "<standard output>";
    binmode STDOUT           or croak "$file: $!\n";
    print   STDOUT $pdf_data or croak "$file: $!\n";
  } else {
    # Write PDF file data to specified output file.
    open my $OUT, ">", $file or croak "$file: $!\n";
    binmode $OUT             or croak "$file: $!\n";
    print   $OUT $pdf_data   or croak "$file: $!\n";
    close   $OUT             or croak "$file: $!\n";

    # Set modification time to the specified or current timestamp, unless zero.
    utime $time, $time, $file if $time;

    # Print success message.
    print STDERR "Wrote new PDF file \"$file\".\n\n";
  }
}

# Generate PDF file data suitable for writing to an output PDF file.
sub pdf_file_data {
  my ($self, $time) = @_;

  # Default missing timestamp to current time, but keep a zero time as a flag.
  $time //= time;

  # Set PDF modification timestamp, unless zero.
  $self->{Info}{ModDate} = $self->timestamp($time) if $time;

  # Set PDF producer.
  $self->{Info}{Producer} = sprintf "(%s)", join " ", __PACKAGE__, $VERSION;

  # Validate the PDF structure.
  $self->validate;

  # Array of indirect objects, with lookup hash as first element.
  my $objects = [{}];

  # Objects seen while generating the PDF file data.
  my $seen = {};

  # Start with PDF header.
  my $pdf_file_data = "%PDF-1.4\n%\xBF\xF7\xA2\xFE\n\n";

  # Write all indirect objects.
  my $xrefs = $self->write_indirect_objects(\$pdf_file_data, $objects, $seen);

  # Add cross-reference table.
  my $startxref   = length($pdf_file_data);
  $pdf_file_data .= sprintf "xref\n0 %d\n", scalar @{$xrefs};
  $pdf_file_data .= join("", @{$xrefs});

  # Save correct size in trailer dictionary.
  $self->{Size} = scalar @{$xrefs};

  # Write trailer dictionary.
  $pdf_file_data .= "trailer ";
  $self->write_object(\$pdf_file_data, $objects, $seen, $self, 0);

  # Write startxref value.
  $pdf_file_data =~ s/\n?\z/\n/;
  $pdf_file_data .= "startxref\n$startxref\n";

  # End of PDF file data.
  $pdf_file_data .= "%%EOF\n";

  # Return PDF file data.
  return $pdf_file_data;
}

# Dump internal structure of PDF file.
sub dump_pdf {
  my ($self, $file, $mode) = @_;

  # Default to standard output.
  $file = "-" if not defined $file or $file eq "";

  # Default to dumping full PDF internal structure.
  $mode //= "";

  # Use "<standard output>" instead of "-" to describe standard output.
  my $filename = ($file // "") =~ s/^-?$/<standard output>/r;

  # Open output file.
  open my $OUT, ">$file" or croak "$filename: $!\n";

  # Data structures already seen.
  my $seen = {};

  # Dump PDF structures.
  printf $OUT "\$pdf = %s;\n", $self->dump_object($self, '$pdf', $seen, 0, $mode) or croak "$filename: $!\n";

  # Close output file.
  close $OUT or croak "$filename: $!\n";

  # Print success message.
  if ($mode eq "outline") {
    print STDERR "Dumped outline of PDF internal structure to file \"$file\".\n\n" unless $file eq "-";
  } else {
    print STDERR "Dumped PDF internal structure to file \"$file\".\n\n" unless $file eq "-";
  }
}

# Dump outline of internal structure of PDF file.
sub dump_outline {
  my ($self, $file) = @_;

  # Call dump_pdf() with outline parameter.
  return $self->dump_pdf($file // "-", "outline");
}

# Merge content streams.
sub merge_content_streams {
  my ($self, $streams) = @_;

  # Make sure content is an array.
  return $streams unless is_array $streams;

  # Remove extra trailing space from streams.
  foreach my $stream (@{$streams}) {
    die unless is_stream $stream;
    $stream->{-data} //= "";
    $stream->{-data} =~ s/(?<=$s) \z//;
  }

  # Concatenate stream data and calculate new length.
  my $merged = { -data => join("", map { $_->{-data}; } @{$streams}) };
  $merged->{Length} = length($merged->{-data});

  # Return merged content stream.
  return $merged;
}

# Find bounding box for a content stream.
sub find_bbox {
  my ($self, $content_stream, $new) = @_;

  # Get data from stream, if necessary.
  $content_stream = $content_stream->{-data} // "" if is_stream $content_stream;

  # Split content stream into lines.
  my @lines = grep { $_ ne ""; } split /\n/, $content_stream;

  # Bounding box.
  my ($left, $bottom, $right, $top);

  # Regex to match a number.
  my $n = qr/-?\d+(?:\.\d+)?/;

  # Determine bounding box from content stream.
  foreach (@lines) {
    # Skip neutral lines.
    next if m{^(?:/Figure <</MCID \d >>BDC|/PlacedGraphic /MC\d BDC|EMC|/GS\d gs|BX /Sh\d sh EX Q|[Qqh]|W n|$n $n $n $n $n $n cm)$s*$};

    # Capture coordinates from drawing operations to calculate bounding box.
    if (my ($x1, $y1, $x2, $y2, $x3, $y3) = /^($n) ($n) (?:[ml]|($n) ($n) (?:[vy]|($n) ($n) c))$/) {
      ($left, $right) = minmax grep { defined $_; } $left, $right, $x1, $x2, $x3;
      ($bottom, $top) = minmax grep { defined $_; } $bottom, $top, $y1, $y2, $y3;
    } elsif (my ($x, $y, $width, $height) = /^($n) ($n) ($n) ($n) re$/) {
      ($left, $right) = minmax grep { defined $_; } $left, $right, $x, $x + $width;
      ($bottom, $top) = minmax grep { defined $_; } $bottom, $top, $y, $y + $height;
    } else {
      croak "Parse error: Content line \"$_\" not recognized!\n";
    }
  }

  # Print bounding box and rectangle.
  my $width  = $right - $left;
  my $height = $top   - $bottom;
  print STDERR "Bounding Box: $left $bottom $right $top\nRectangle: $left $bottom $width $height\n\n";

  # Return unless generating a new bounding box.
  return unless $new;

  # Update content stream.
  for ($content_stream) {
    # Update coordinates in drawing operations.
    s/^($n) ($n) ([ml])$/join " ", $self->round($1 - $left, $2 - $bottom), $3/egm;
    s/^($n) ($n) ($n) ($n) ([vy])$/join " ", $self->round($1 - $left, $2 - $bottom, $3 - $left, $4 - $bottom), $5/egm;
    s/^($n) ($n) ($n) ($n) ($n) ($n) (c)$/join " ", $self->round($1 - $left, $2 - $bottom, $3 - $left, $4 - $bottom, $5 - $left, $6 - $bottom), $7/egm;
    s/^($n $n $n $n) ($n) ($n) (cm)$/join " ", $1, $self->round($2 - $left, $3 - $bottom), $4/egm;
  }

  # Return content stream.
  return $content_stream;
}

# Make a new bounding box for a content stream.
sub new_bbox {
  my ($self, $content_stream) = @_;

  # Call find_bbox() with "new" parameter.
  $self->find_bbox($content_stream, 1);
}

# Generate timestamp in PDF internal format.
sub timestamp {
  my ($self, $time) = @_;

  $time //= time;
  my @time = localtime $time;
  my $tz = $time[8] * 60 - mktime(gmtime 0) / 60;
  return sprintf "(D:%s%+03d'%02d')", strftime("%Y%m%d%H%M%S", @time), $tz / 60, abs($tz) % 60;
}

# Round numeric values to 12 significant digits to avoid floating-point rounding error and remove trailing zeroes.
sub round {
  my ($self, @numbers) = @_;

  @numbers = map { sprintf("%.12f", sprintf("%.12g", $_ || 0)) =~ s/\.?0+$//r; } @numbers;
  return wantarray ? @numbers : $numbers[0];
}

# Concatenate a transformation matrix with an original matrix, returning a new matrix.
sub concat_matrix {
  my ($self, $transform, $orig) = @_;

  return [$self->round(
    $transform->[0] * $orig->[0] + $transform->[1] * $orig->[2],
    $transform->[0] * $orig->[1] + $transform->[1] * $orig->[3],
    $transform->[2] * $orig->[0] + $transform->[3] * $orig->[2],
    $transform->[2] * $orig->[1] + $transform->[3] * $orig->[3],
    $transform->[4] * $orig->[0] + $transform->[5] * $orig->[2] + $orig->[4],
    $transform->[4] * $orig->[1] + $transform->[5] * $orig->[3] + $orig->[5],
  )];
}

# Calculate the inverse of a matrix, if possible.
sub invert_matrix {
  my ($self, $matrix) = @_;

  # Calculate the determinant of the matrix.
  my $det = $self->round($matrix->[0] * $matrix->[3] - $matrix->[1] * $matrix->[2]);

  # If the determinant is zero, then the matrix is not invertible.
  return if $det == 0;

  # Return the inverse matrix.
  return [$self->round(
     $matrix->[3] / $det,
    -$matrix->[1] / $det,
    -$matrix->[2] / $det,
     $matrix->[0] / $det,
    ($matrix->[2] * $matrix->[5] - $matrix->[3] * $matrix->[4]) / $det,
    ($matrix->[1] * $matrix->[4] - $matrix->[0] * $matrix->[5]) / $det,
  )];
}

# Create a transformation matrix to translate the origin of the coordinate system to the specified coordinates.
sub translate {
  my ($self, $x, $y) = @_;

  # Return a translate matrix.
  return [$self->round(1, 0, 0, 1, $x, $y)];
}

# Create a transformation matrix to scale the coordinate space by the specified horizontal and vertical scaling factors.
sub scale {
  my ($self, $x, $y) = @_;

  # Return a scale matrix.
  return [$self->round($x, 0, 0, $y, 0, 0)];
}

# Create a transformation matrix to rotate the coordinate space counterclockwise by the specified angle (in degrees).
sub rotate {
  my ($self, $angle) = @_;

  # Calculate the sine and cosine of the angle.
  my $sin = sin($angle * pi / 180);
  my $cos = cos($angle * pi / 180);

  # Return a rotate matrix.
  return [$self->round($cos, $sin, -$sin, $cos, 0, 0)];
}

# Validate PDF structure.
sub validate {
  my ($self) = @_;

  # Catch validation errors.
  eval {
    # Make sure document catalog exists and has the correct type.
    $self->validate_key("Root", "Type", "/Catalog", "document catalog");

    # Make sure page tree root node exists, has the correct type, and has no parent.
    $self->validate_key("Root/Pages", "Type", "/Pages", "page tree root");
    $self->validate_key("Root/Pages", "Parent", undef,  "page tree root");

    # Validate page tree.
    $self->validate_page_tree("Root/Pages", $self->{Root}{Pages});
  };

  # Check for validation errors.
  if ($@) {
    # Make validation errors fatal if -validate flag is set.
    if ($self->{-validate}) {
      croak $@;
    } else {
      carp $@;
    }
  }

  # Return this instance.
  return $self;
}

# Validate page tree.
sub validate_page_tree {
  my ($self, $path, $page_tree_node) = @_;

  # Count of leaf nodes (page objects) under this page tree node.
  my $count = 0;

  # Validate children.
  is_array(my $kids = $page_tree_node->{Kids}) or croak join(": ", $self->{-file} || (), "Error: $path\->{Kids} must be an array!\n");
  for (my $i = 0; $i < @{$kids}; $i++) {
    is_hash(my $kid = $kids->[$i]) or croak join(": ", $self->{-file} || (), "Error: $path\[$i] must be be a hash!\n");
    $kid->{Type} or croak join(": ", $self->{-file} || (), "Error: $path\[$i]->{Type} is a required field!\n");
    if ($kid->{Type} eq "/Pages") {
      $count += $self->validate_page_tree("$path\[$i]", $kid);
    } elsif ($kid->{Type} eq "/Page") {
      $self->validate_page("$path\[$i]", $kid);
      $count++;
    } else {
      croak join(": ", $self->{-file} || (), "Error: $path\[$i]->{Type} must be /Pages or /Page!\n");
    }
  }

  # Validate resources, if any.
  $self->validate_resources("$path\->{Resources}", $page_tree_node->{Resources}) if is_hash($page_tree_node->{Resources});

  # Fix leaf node count if wrong.
  if (($page_tree_node->{Count} || 0) != $count) {
    warn join(": ", $self->{-file} || (), "Warning: Fixing: $path\->{Count} = $count\n");
    $page_tree_node->{Count} = $count;
  }

  # Return leaf node count.
  return $count;
}

# Validate page object.
sub validate_page {
  my ($self, $path, $page) = @_;

  if (my $contents = $page->{Contents}) {
    $contents = $self->merge_content_streams($contents) if is_array($contents);
    is_stream($contents) or croak join(": ", $self->{-file} || (), "Error: $path\->{Contents} must be an array or stream!\n");
    $contents->{-data} //= "";
    $self->validate_content_stream("$path\->{Contents}", $contents);
  }

  # Validate resources, if any.
  $self->validate_resources("$path\->{Resources}", $page->{Resources}) if is_hash($page->{Resources});
}

# Validate resources.
sub validate_resources {
  my ($self, $path, $resources) = @_;

  # Validate XObjects, if any.
  $self->validate_xobjects("$path\{XObject}", $resources->{XObject}) if is_hash($resources->{XObject});
}

# Validate form XObjects.
sub validate_xobjects {
  my ($self, $path, $xobjects) = @_;

  # Validate each form XObject.
  foreach my $name (sort keys %{$xobjects}) {
    $self->validate_xobject("$path\{$name}", $xobjects->{$name});
  }
}

# Validate a single XObject.
sub validate_xobject {
  my ($self, $path, $xobject) = @_;

  # Make sure the XObject is a stream.
  is_stream($xobject) or croak join(": ", $self->{-file} || (), "Error: $path must be a content stream!\n");
  $xobject->{-data} //= "";

  # Validate the content stream, if this is a form XObject.
  $self->validate_content_stream($path, $xobject) if $xobject->{Subtype} eq "/Form";

  # Validate resources, if any.
  $self->validate_resources("$path\{Resources}", $xobject->{Resources}) if is_hash($xobject->{Resources});
}

# Validate content stream.
sub validate_content_stream {
  my ($self, $path, $stream) = @_;

  # Make sure the content stream can be parsed.
  my @objects = eval { $self->parse_objects({}, $stream->{-data} // "", 0); };
  croak join(": ", $self->{-file} || (), "Error: $path: $@") if $@;

  # Minify content stream if requested.
  $self->minify_content_stream($stream, \@objects) if $self->{-minify};
}

# Minify content stream.
sub minify_content_stream {
  my ($self, $stream, $objects) = @_;

  # Parse object stream if necessary.
  $objects ||= [ $self->parse_objects({}, $stream->{-data} // "", 0) ];

  # Generate new content stream from objects.
  $stream->{-data} = $self->generate_content_stream($objects);

  # Recalculate stream length.
  $stream->{Length} = length $stream->{-data};

  # Sanity check.
  die "Content stream serialization failed"
    if dump([map {$_->[0]} @{$objects}]) ne
       dump([map {$_->[0]} $self->parse_objects({}, $stream->{-data}, 0)]);
}

# Generate new content stream from objects.
sub generate_content_stream {
  my ($self, $objects) = @_;

  # Generated content stream.
  my $stream = "";

  # Loop across parsed objects.
  foreach my $object (@{$objects}) {
    # Check parsed object type.
    if ($object->[1]{type} eq "dict") {
      # Serialize dictionary.
      $self->serialize_dictionary(\$stream, $object->[0]);
    } elsif ($object->[1]{type} eq "array") {
      # Serialize array.
      $self->serialize_array(\$stream, $object->[0]);
    } elsif ($object->[1]{type} eq "image") {
      # Serialize inline image data.
      $self->serialize_image(\$stream, $object->[0]);
    } else {
      # Serialize string or other token.
      $self->serialize_object(\$stream, $object->[0]);
    }
  }

  # Return generated content stream.
  return $stream;
}

# Serialize a hash as a dictionary object.
sub serialize_dictionary {
  my ($self, $stream, $hash) = @_;

  # Serialize the hash key-value pairs.
  my @pairs = %{$hash};
  ${$stream} .= "<<";
  for (my $i = 0; $i < @pairs; $i++) {
    if ($i % 2) {
      if (is_hash($pairs[$i])) {
        $self->serialize_dictionary($stream, $pairs[$i]);
      } elsif (is_array($pairs[$i])) {
        $self->serialize_array($stream, $pairs[$i]);
      } else {
        $self->serialize_object($stream, $pairs[$i]);
      }
    } else {
      ${$stream} .= "/$pairs[$i]";
    }
  }
  ${$stream} .= ">>";
}

# Serialize an array.
sub serialize_array {
  my ($self, $stream, $array) = @_;

  # Serialize the array values.
  ${$stream} .= "[";
  foreach my $obj (@{$array}) {
    if (is_hash($obj)) {
      $self->serialize_dictionary($stream, $obj);
    } elsif (is_array($obj)) {
      $self->serialize_array($stream, $obj);
    } else {
      $self->serialize_object($stream, $obj);
    }
  }
  ${$stream} .= "]";
}

# Append the serialization of inline image data to the generated content stream.
sub serialize_image {
  my ($self, $stream, $image) = @_;

  # Append inline image data between ID (Image Data) and EI (End Image) operators.
  ${$stream} .= "\nID\n$image\nEI\n";
}

# Append the serialization of an object to the generated content stream.
sub serialize_object {
  my ($self, $stream, $object) = @_;

  # Strip leading/trailing whitespace from object if minifying.
  if ($self->{-minify}) {
    $object =~ s/^$s+//;
    $object =~ s/$s+$//;
  }

  # Wrap the line if line length would exceed 255 characters.
  ${$stream} .= "\n" if length(${$stream}) - (rindex(${$stream}, "\n") + 1) + length($object) >= 255;

  # Add a space if necessary.
  ${$stream} .= " " unless ${$stream} =~ /(^|[$ss)>\[\]{}])$/ or $object =~ /^[$ss()<>\[\]{}\/%]/;

  # Add the serialized object.
  ${$stream} .= $object;
}

# Validate the specified hash key value.
sub validate_key {
  my ($self, $hash, $key, $value, $label) = @_;

  # Create the hash if necessary.
  $hash = $_[1] = {} unless $hash;

  # Get the hash node from the PDF structure by path, if necessary.
  $hash = $self->get_hash_node($hash) unless is_hash $hash;

  # Make sure the hash key has the correct value.
  if (defined $value and (not defined $hash->{$key} or $hash->{$key} ne $value)) {
    warn join(": ", $self->{-file} || (), "Warning: Fixing $label: {$key} $hash->{$key} -> $value\n") if $hash->{$key};
    $hash->{$key} = $value;
  } elsif (not defined $value and exists $hash->{$key}) {
    warn join(": ", $self->{-file} || (), "Warning: Deleting $label: {$key} $hash->{$key}\n") if $hash->{$key};
    delete $hash->{$key};
  }

  # Return this instance.
  return $self;
}

# Get a hash node from the PDF structure by path.
sub get_hash_node {
  my ($self, $path) = @_;

  # Split the path.
  my @path = split /\//, $path;

  # Find the hash node with the specified path, creating nodes if necessary.
  my $hash = $self;
  foreach my $key (@path) {
    $hash->{$key} ||= {};
    $hash = $hash->{$key};
  }

  # Return the hash node.
  return $hash;
}

# Parse PDF objects into Perl representations.
sub parse_objects {
  my ($self, $objects, $data, $offset) = @_;

  # Parsed PDF objects.
  my @objects;

  # Calculate EOF offset.
  my $eof = $offset + length $data;

  # Copy data for parsing.
  local $_ = $data;

  # Parse PDF objects in input string.
  while ($_ ne "") {
    # Update the file offset.
    $offset = $eof - length $_;

    # Parse the next PDF object.
    if (s/\A$ws//) {                                                            # Strip leading whitespace/comments.
      next;
    } elsif (s/\A(<<((?:[^<>]+|<[^<>]+>|(?1))*)$ws?>>)//) {                     # Dictionary: <<...>> (including nested dictionaries)
      my @pairs = $self->parse_objects($objects, $2, $offset);
      for (my $i = 0; $i < @pairs; $i++) {
        $pairs[$i] = $i % 2 ? $pairs[$i][0] : $pairs[$i][1]{name}
          // croak join(": ", $self->{-file} || (), "Byte offset $offset: Dictionary key is not a name!\n");
      }
      push @objects, [ { @pairs }, { type => "dict" } ];
    } elsif (s/\A(\[((?:(?>[^\[\]]+)|(?1))*)\])//) {                            # Array: [...] (including nested arrays)
      my $array = [ map $_->[0], $self->parse_objects($objects, $2, $offset) ];
      push @objects, [ $array, { type => "array" }];
    } elsif (s/\A(\((?:(?>[^\\()]+)|\\.|(?1))*\))//) {                          # String literal: (...) (including nested parens)
      push @objects, [ $1, { type => "string" } ];
    } elsif (s/\A(<[0-9A-Fa-f$ss]*>)//) {                                       # Hexadecimal string literal: <...>
      push @objects, [ lc($1) =~ s/$s+//gr, { type => "hex" } ];
    } elsif (s/\A(\/?[^$ss()<>\[\]{}\/%]+)//) {                                 # /Name, number or other token
      # Check for tokens of special interest.
      my $token = $1;
      if ($token eq "obj" or $token eq "R") {                                   # Indirect object/reference: 999 0 obj or 999 0 R
        my ($id, $gen) = splice @objects, -2;
        my $type = $token eq "R" ? "reference" : "definition";
        "$id->[1]{type} $gen->[1]{type}" eq "int int"
          or croak join(": ", $self->{-file} || (), "Byte offset $offset: $id->[0] $gen->[0] $token: Invalid indirect object $type!\n");
        my $new_id = join("-", $id->[0], $gen->[0] || ());
        push @objects, [
          ($token eq "R" ? \$new_id : $new_id),
          { type => $token, offset => $id->[1]{offset} }
        ];
      } elsif ($token eq "ID") {                                                # Inline image data: ID ... EI
        s/\A$s(.*?)(?:\r\n|$s)?EI$s//s or croak join(": ", $self->{-file} || (), "Byte offset $offset: Invalid inline image data!\n");
        my $image = $1;

        # TODO: Apply encoding filters?

        push @objects, [ $image, { type => "image" } ];
      } elsif ($token eq "stream") {                                            # Stream content: stream ... endstream
        my ($id, $stream) = @objects[-2,-1];
        $stream->[1]{type} eq "dict" or croak join(": ", $self->{-file} || (), "Byte offset $offset: Stream dictionary missing!\n");
        $id->[1]{type} eq "obj" or croak join(": ", $self->{-file} || (), "Byte offset $offset: Invalid indirect object definition!\n");
        $_ = $_->[0] for $id, $stream;
        defined(my $length = $stream->{Length})
          or warn join(": ", $self->{-file} || (), "Byte offset $offset: Object #$id: Stream length not found in metadata!\n");
        s/\A\r?\n//;

        # Check for unsupported stream types.
        my $type = $stream->{Type} // "";
        if ($type eq "/ObjStm") {
          croak join(": ", $self->{-file} || (), "Byte offset $offset: PDF 1.5 object streams are not supported!\n");
        } elsif ($type eq "/XRef") {
          croak join(": ", $self->{-file} || (), "Byte offset $offset: PDF 1.5 cross-reference streams are not supported!\n");
	} elsif ($type !~ /^(?:\/(?:CMap|Metadata|XObject))?$/) {
          carp join(": ", $self->{-file} || (), "Byte offset $offset: Unrecognized stream type \"$type\"!\n");
        }

        # If the declared stream length is missing or invalid, determine the shortest possible length to make the stream valid.
        unless (defined($length) && !ref($length) && substr($_, $length) =~ /\A($s*endstream$ws)/) {
          if (/\A((?>(?:[^e]+|(?!endstream$s)e)*))endstream$s/) {
            $length = length($1);
          } else {
            croak join(": ", $self->{-file} || (), "Byte offset $offset: Invalid stream definition!\n");
          }
        }

        $stream->{-data}  = substr($_, 0, $length);
        $stream->{-id}    = $id;
        $stream->{Length} = $length;

        $_ = substr($_, $length);
        s/\A$s*endstream$ws//;

        $self->filter_stream($stream) if $stream->{Filter};
      } elsif ($token eq "endobj") {                                            # Indirect object definition: 999 0 obj ... endobj
        my ($id, $object) = splice @objects, -2;
        $id->[1]{type} eq "obj" or croak join(": ", $self->{-file} || (), "Byte offset $offset: Invalid indirect object definition!\n");
        $object->[1]{id} = $id->[0];
        $objects->{$id->[0]} = $object;
        $objects->{offset}{$object->[1]{offset} // $offset} = $object;
        push @objects, $object;
      } elsif ($token eq "xref") {                                              # Cross-reference table
        s/\A$ws\d+$ws\d+$n(?>\d{10}\ \d{5}\ [fn](?:\ [\r\n]|\r\n))+//
          or croak join(": ", $self->{-file} || (), "Byte offset $offset: Invalid cross-reference table!\n");
      } elsif ($token =~ /^[+-]?\d+$/) {                                        # Integer: [+-]999
        push @objects, [ $token, { type => "int" } ];
      } elsif ($token =~ /^[+-]?(?:\d+\.\d*|\.\d+)$/) {                         # Real number: [+-]999.999
        push @objects, [ $token, { type => "real" } ];
      } elsif ($token =~ /^\/(.*)$/) {                                          # Name: /Name
        push @objects, [ $token, { type => "name", name => $1 } ];
      } elsif ($token =~ /^(?:true|false)$/) {                                  # Boolean: true or false
        push @objects, [ $token, { type => "bool", bool => $token eq "true" } ];
      } else {                                                                  # Other token
        push @objects, [ $token, { type => "token" } ];
      }
    } else {
      s/\A([^\r\n]*).*\z/$1/s;
      croak join(": ", $self->{-file} || (), "Byte offset $offset: Parse error on input: \"$_\"\n");
    }

    # Update offset/length of last object.
    $objects[-1][1]{offset} //= $offset;
    $objects[-1][1]{length}   = $eof - length($_) - $objects[-1][1]{offset};
  }

  # Return parsed PDF objects.
  return @objects;
}

# Parse PDF objects from standalone PDF data.
sub parse_data {
  my ($self, $data) = @_;

  # Parse PDF objects from data.
  my @objects = $self->parse_objects({}, $data // "", 0);

  # Discard parser metadata.
  @objects = map { $_->[0]; } @objects;

  # Return parsed objects.
  return wantarray ? @objects : $objects[0];
}

# Filter stream data.
sub filter_stream {
  my ($self, $stream) = @_;

  # Get stream filters, if any.
  my @filters = $stream->{Filter} ? is_array $stream->{Filter} ? @{$stream->{Filter}} : ($stream->{Filter}) : ();

  # Decompress stream data if necessary.
  if ($filters[0] eq "/FlateDecode") {
    # Remember that this stream was compressed.
    $stream->{-compress} = 1;

    # Decompress the stream.
    my $zlib = new Compress::Raw::Zlib::Inflate;
    my $output;
    my $status = $zlib->inflate($stream->{-data}, $output);
    if ($status == Z_OK or $status == Z_STREAM_END) {
      $stream->{-data}  = $output;
      $stream->{Length} = length $output;
    } else {
      croak join(": ", $self->{-file} || (), "Object #$stream->{-id}: Stream inflation failed! ($zlib->msg)\n");
    }

    # Stream is no longer compressed; remove /FlateDecode filter.
    shift @filters;

    # Preserve remaining filters, if any.
    if (@filters > 1) {
      $stream->{Filter} = \@filters;
    } elsif (@filters) {
      $stream->{Filter} = shift @filters;
    } else {
      delete $stream->{Filter};
    }
  }
}

# Compress stream data.
sub compress_stream {
  my ($self, $stream) = @_;

  # Get stream filters, if any.
  my @filters = $stream->{Filter} ? is_array $stream->{Filter} ? @{$stream->{Filter}} : ($stream->{Filter}) : ();

  # Return a new stream so the in-memory copy remains uncompressed to work with.
  my $new_stream = { %{$stream} };
  $new_stream->{-data} = "";
  my ($zlib, $status) = Compress::Raw::Zlib::Deflate->new(-Level => 9, -Bufsize => 65536, AppendOutput => 1);
  $zlib->deflate($stream->{-data}, $new_stream->{-data}) == Z_OK or croak join(": ", $self->{-file} || (), "Object #$stream->{-id}: Stream deflation failed! ($zlib->msg)\n");
  $zlib->flush($new_stream->{-data}, Z_FINISH)           == Z_OK or croak join(": ", $self->{-file} || (), "Object #$stream->{-id}: Stream deflation failed! ($zlib->msg)\n");
  $new_stream->{Length} = length $new_stream->{-data};
  $new_stream->{Filter} = @filters ? ["/FlateDecode", @filters] : "/FlateDecode";
  return $new_stream;
}

# Resolve indirect object references.
sub resolve_references {
  my ($self, $objects, $object) = @_;

  # Replace indirect object references with a reference to the actual object.
  if (ref $object and reftype($object) eq "SCALAR") {
    my $id = ${$object};
    if ($objects->{$id}) {
      ($object, my $metadata) = @{$objects->{$id}};
      return $object if $metadata->{resolved}++;
    } else {
      ($id, my $gen) = split /-/, $id;
      $gen ||= "0";
      warn join(": ", $self->{-file} || (), "Warning: $id $gen R: Referenced indirect object not found!\n");
    }
  }

  # Check object type.
  if (is_hash $object) {
    # Resolve references in hash values.
    foreach my $key (sort { fc($a) cmp fc($b) || $a cmp $b; } keys %{$object}) {
      $object->{$key} = $self->resolve_references($objects, $object->{$key}) if ref $object->{$key};
    }

    # For streams, validate the length metadata.
    if (is_stream $object) {
      $object->{-data} //= "";
      substr($object->{-data}, $object->{Length}) =~ s/\A$s+\z// if $object->{Length} and length($object->{-data}) > $object->{Length};
      my $len = length $object->{-data};
      $object->{Length} ||= $len;
      $len == $object->{Length}
        or warn join(": ", $self->{-file} || (), "Warning: Object #$object->{-id}: Stream length does not match metadata! ($len != $object->{Length})\n");
    }
  } elsif (is_array $object) {
    # Resolve references in array values.
    foreach my $i (0 .. $#{$object}) {
      $object->[$i] = $self->resolve_references($objects, $object->[$i]) if ref $object->[$i];
    }
  }

  # Return object with resolved references.
  return $object;
}

# Write all indirect objects to PDF file data.
sub write_indirect_objects {
  my ($self, $pdf_file_data, $objects, $seen) = @_;

  # Enumerate all indirect objects.
  $self->enumerate_indirect_objects($objects);

  # Cross-reference file offsets.
  my $xrefs = ["0000000000 65535 f \n"];

  # Loop across indirect objects.
  for (my $i = 1; $i <= $#{$objects}; $i++) {
    # Save file offset for cross-reference table.
    push @{$xrefs}, sprintf "%010d 00000 n \n", length(${$pdf_file_data});

    # Write the indirect object header.
    ${$pdf_file_data} .= "$i 0 obj\n";

    # Write the object itself.
    $self->write_object($pdf_file_data, $objects, $seen, $objects->[$i], 0);

    # Write the indirect object trailer.
    ${$pdf_file_data} =~ s/\n?\z/\n/;
    ${$pdf_file_data} .= "endobj\n\n";
  }

  # Return cross-reference file offsets.
  return $xrefs;
}

# Enumerate all indirect objects.
sub enumerate_indirect_objects {
  my ($self, $objects) = @_;

  # Add top-level PDF indirect objects.
  $self->add_indirect_objects($objects,
    $self->{Root}                 ? $self->{Root}                 : (), # Document catalog
    $self->{Info}                 ? $self->{Info}                 : (), # Document information dictionary (if any)
    $self->{Root}{Dests}          ? $self->{Root}{Dests}          : (), # Named destinations (if any)
    $self->{Root}{Metadata}       ? $self->{Root}{Metadata}       : (), # Document metadata (if any)
    $self->{Root}{Outlines}       ? $self->{Root}{Outlines}       : (), # Document outline hierarchy (if any)
    $self->{Root}{Pages}          ? $self->{Root}{Pages}          : (), # Document page tree
    $self->{Root}{Threads}        ? $self->{Root}{Threads}        : (), # Articles (if any)
    $self->{Root}{StructTreeRoot} ? $self->{Root}{StructTreeRoot} : (), # Document structure tree (if any)
  );

  # Add optional content groups, if any.
  $self->add_indirect_objects($objects, @{$self->{Root}{OCProperties}{OCGs}}) if $self->{Root}{OCProperties};

  # Enumerate shared objects.
  $self->enumerate_shared_objects($objects, {}, {}, $self->{Root});

  # Add referenced indirect objects.
  for (my $i = 1; $i <= $#{$objects}; $i++) {
    # Get object.
    my $object = $objects->[$i];

    # Check object type.
    if (is_hash $object) {
      # Objects to add.
      my @objects;

      # Hashes to scan.
      my @hashes = $object;

      # Iteratively recurse through hash tree.
      while (@hashes) {
        # Get the next hash.
        $object = shift @hashes;

        # Check each hash key.
        foreach my $key (sort { fc($a) cmp fc($b) || $a cmp $b; } keys %{$object}) {
          if (($object->{Type} // "") eq "/ExtGState" and $key eq "Font" and is_array $object->{Font} and is_hash $object->{Font}[0]) {
            push @objects, $object->{Font}[0];
          } elsif ($key =~ /^(?:Data|First|ID|Last|Next|Obj|Parent|ParentTree|Popup|Prev|Root|StmOwn|Threads|Widths)$/
              or $key =~ /^(?:AN|Annotation|B|C|CI|DocMDP|F|FontDescriptor|I|IX|K|Lock|N|P|Pg|RI|SE|SV|V)$/ and ref $object->{$key} and is_hash $object->{$key}
              or is_hash $object->{$key} and ($object->{$key}{-data} or $object->{$key}{Kids} or ($object->{$key}{Type} // "") =~ /^\/(?:Filespec|Font)$/)
              or ($object->{S} // "") eq "/Thread" and $key eq "D"
              or ($object->{S} // "") eq "/Hide"   and $key eq "T"
          ) {
            push @objects, $object->{$key};
          } elsif ($key =~ /^(?:Annots|B|C|CO|Fields|K|Kids|O|Pages|TrapRegions)$/ and is_array $object->{$key}) {
            push @objects, grep { is_hash $_; } @{$object->{$key}};
          } elsif (is_hash $object->{$key}) {
            push @hashes, $object->{$key};
          }
        }
      }

      # Add the objects found, if any.
      $self->add_indirect_objects($objects, @objects) if @objects;
    }
  }
}

# Enumerate shared objects.
sub enumerate_shared_objects {
  my ($self, $objects, $seen, $ancestors, $object) = @_;

  # Add shared indirect objects.
  if ($seen->{$object}++) {
    $self->add_indirect_objects($objects, $object) unless $objects->[0]{$object};
    return;
  }

  # Return if this object is an ancestor of itself.
  return if $ancestors->{$object};

  # Add this object to the lookup hash of ancestors.
  $ancestors->{$object}++;

  # Recurse to check entire object tree.
  if (is_hash $object) {
    foreach my $key (sort { fc($a) cmp fc($b) || $a cmp $b; } keys %{$object}) {
      $self->enumerate_shared_objects($objects, $seen, $ancestors, $object->{$key}) if ref $object->{$key};
    }
  } elsif (is_array $object) {
    foreach my $obj (@{$object}) {
      $self->enumerate_shared_objects($objects, $seen, $ancestors, $obj) if ref $obj;
    }
  }

  # Remove this object from the lookup hash of ancestors.
  delete $ancestors->{$object};
}

# Add indirect objects.
sub add_indirect_objects {
  my ($self, $objects, @objects) = @_;

  # Loop across specified objects.
  foreach my $object (@objects) {
    # Make sure content streams are defined.
    $object->{-data} //= "" if is_stream $object;

    # Check if object exists and is not in the lookup hash yet.
    if (defined $object and not $objects->[0]{$object}) {
      # Add the new indirect object to the array.
      push @{$objects}, $object;

      # Save the object ID in the lookup hash, keyed by the object.
      $objects->[0]{$object} = $#{$objects};
    }
  }
}

# Write a direct object to the string of PDF file data.
sub write_object {
  my ($self, $pdf_file_data, $objects, $seen, $object, $indent) = @_;

  # Make sure the same object isn't written twice.
  if (ref $object and $seen->{$object}++) {
    croak join(": ", $self->{-file} || (), "Object $object written more than once!\n");
  }

  # Check object type.
  if (is_hash $object) {
    # For streams, compress the stream or update the length metadata.
    if (is_stream $object) {
      $object->{-data} //= "";
      if (($self->{-compress} or $object->{-compress}) and not ($self->{-decompress} or $object->{-decompress})) {
        $object = $self->compress_stream($object);
      } else {
        $object->{Length} = length $object->{-data};
      }
    }

    # Dictionary object.
    $self->serialize_object($pdf_file_data, "<<\n");
    foreach my $key (sort { fc($a) cmp fc($b) || $a cmp $b; } keys %{$object}) {
      next if $key =~ /^-/;
      my $obj = $object->{$key};
      $self->add_indirect_objects($objects, $obj) if is_stream $obj;
      $self->serialize_object($pdf_file_data, join("", " " x ($indent + 2), "/$key "));
      if (not ref $obj) {
        $self->serialize_object($pdf_file_data, "$obj\n");
      } elsif ($objects->[0]{$obj}) {
        $self->serialize_object($pdf_file_data, "$objects->[0]{$obj} 0 R\n");
      } else {
        $self->write_object($pdf_file_data, $objects, $seen, $object->{$key}, ref $object ? $indent + 2 : 0);
      }
    }
    $self->serialize_object($pdf_file_data, join("", " " x $indent, ">>\n"));

    # For streams, write the stream data.
    if (is_stream $object) {
      $object->{-data} //= "";
      croak join(": ", $self->{-file} || (), "Stream written as direct object!\n") if $indent;
      my $newline = substr($object->{-data}, -1) eq "\n" ? "" : "\n";
      ${$pdf_file_data} =~ s/\n?\z/\n/;
      ${$pdf_file_data} .= "stream\n$object->{-data}${newline}endstream\n";
    }
  } elsif (is_array $object and not grep { ref $_; } @{$object}) {
    # Array of simple objects.
    if ($self->{-minify}) {
      $self->serialize_array($pdf_file_data, $object);
    } else {
      ${$pdf_file_data} .= "[ @{$object} ]\n";
    }
  } elsif (is_array $object) {
    # Array object.
    $self->serialize_object($pdf_file_data, "[\n");
    my $spaces = " " x ($indent + 2);
    foreach my $obj (@{$object}) {
      $self->add_indirect_objects($objects, $obj) if is_stream $obj;
      ${$pdf_file_data} .= $spaces unless $self->{-minify};
      if (not ref $obj) {
        $self->serialize_object($pdf_file_data, $obj);
        $spaces = " ";
      } elsif ($objects->[0]{$obj}) {
        $self->serialize_object($pdf_file_data, "$objects->[0]{$obj} 0 R\n");
        $spaces = " " x ($indent + 2);
      } else {
        $self->write_object($pdf_file_data, $objects, $seen, $obj, $indent + 2);
        $spaces = " " x ($indent + 2);
      }
    }
    ${$pdf_file_data} .= "\n" if $spaces eq " " and not $self->{-minify};
    $self->serialize_object($pdf_file_data, join("", " " x $indent, "]\n"));
  } elsif (reftype($object) eq "SCALAR") {
    # Unresolved indirect reference.
    my ($id, $gen) = split /-/, ${$object};
    $gen ||= "0";
    $self->serialize_object($pdf_file_data, join("", " " x $indent, "($id $gen R)\n"));
  } else {
    # Simple object.
    $self->serialize_object($pdf_file_data, join("", " " x $indent, "$object\n"));
  }
}

# Dump PDF object.
sub dump_object {
  my ($self, $object, $label, $seen, $indent, $mode) = @_;

  # Dump output.
  my $output = "";

  # Hash key sort priority.
  my %priority = (
    Type           => -2,
    Version        => -1,
    Root           => 1,
    Pages          => 2,
    PageLabels     => 3,
    Names          => 4,
    Dests          => 5,
    Outlines       => 6,
    Threads        => 7,
    StructTreeRoot => 8,
  );

  # Check mode and object type.
  if ($mode eq "outline") {
    if (ref $object and $seen->{$object}) {
      # Previously-seen object; dump the label.
      $output = "$seen->{$object}";
    } elsif (is_hash $object) {
      # Hash object.
      $seen->{$object} = $label;
      if (is_stream $object) {
        $output = "(STREAM)";
      } else {
        $label =~ s/(?<=\w)$/->/;
        my @keys = sort { ($priority{$a} // 0) <=> ($priority{$b} // 0) || fc($a) cmp fc($b) || $a cmp $b; } keys %{$object};
        my $key_len = max map length $_, @keys;
        foreach my $key (@keys) {
          my $obj = $object->{$key};
          next unless ref $obj;
          $output .= sprintf "%s%-${key_len}s => ", " " x ($indent + 2), $key;
          $output .= $self->dump_object($object->{$key}, "$label\{$key\}", $seen, ref $object ? $indent + 2 : 0, $mode) . ",\n";
        }
        if ($output) {
          $output = join("", "{ # $label\n", $output, (" " x $indent), "}");
        } else {
          $output = "{...}";
        }
        $output =~ s/\{ \# \$pdf->\n/\{\n/;
      }
    } elsif (is_array $object and not grep { ref $_; } @{$object}) {
      # Array of simple objects.
      $output = "[...]";
    } elsif (is_array $object) {
      # Array object.
      for (my $i = 0; $i < @{$object}; $i++) {
        $output .= sprintf "%s%s,\n", " " x ($indent + 2), $self->dump_object($object->[$i], "$label\[$i\]", $seen, $indent + 2, $mode) if ref $object->[$i];
      }
      if ($output =~ /\A$s+(.*?),\n\z/) {
        $output = "[... $1]";
      } elsif ($output =~ /\n/) {
        $output = join("", "[ # $label\n", $output, (" " x $indent), "]");
      } else {
        $output = "[$output]";
      }
    } elsif (reftype($object) eq "SCALAR") {
      # Unresolved indirect reference.
      my ($id, $gen) = split /-/, ${$object};
      $gen ||= "0";
      $output .= "\"$id $gen R\"";
    }
  } elsif (ref $object and $seen->{$object}) {
    # Previously-seen object; dump the label.
    $output = $seen->{$object};
  } elsif (is_hash $object) {
    # Hash object.
    $seen->{$object} = $label;
    $output = "{ # $label\n";
    $label =~ s/(?<=\w)$/->/;
    my @keys = sort { ($priority{$a} // 0) <=> ($priority{$b} // 0) || fc($a) cmp fc($b) || $a cmp $b; } keys %{$object};
    my $key_len = max map length $_, @keys;
    foreach my $key (@keys) {
      my $obj = $object->{$key};
      $output .= sprintf "%s%-${key_len}s => ", " " x ($indent + 2), $key;
      if ($key eq -data) {
        chomp $obj;
        $output .= $obj =~ /\A(?:<\?xpacket|[\n\t -~]*\z)/ ? "<<'EOF',\n$obj\nEOF\n" : dump($obj) . "\n";
      } elsif (not ref $obj) {
        $output .= dump($obj) . ",\n";
      } else {
        $output .= $self->dump_object($object->{$key}, "$label\{$key\}", $seen, ref $object ? $indent + 2 : 0, $mode) . ",\n";
      }
    }
    $output .= (" " x $indent) . "}";
    $output =~ s/\{ \# \$pdf\n/\{\n/;
  } elsif (is_array $object and not grep { ref $_; } @{$object}) {
    # Array of simple objects.
    $output = sprintf "[%s]", join(", ", map { /^\d+\.\d+$/ ? $_ : dump($_); } @{$object});
  } elsif (is_array $object) {
    # Array object.
    $output .= "[ # $label\n";
    my $spaces = " " x ($indent + 2);
    for (my $i = 0; $i < @{$object}; $i++) {
      my $obj = $object->[$i];
      if (ref $obj) {
        $output .= sprintf "%s%s,\n", $spaces, $self->dump_object($obj, "$label\[$i\]", $seen, $indent + 2, $mode);
        $spaces = " " x ($indent + 2);
      } else {
        $output .= $spaces . dump($obj) . ",";
        $spaces = " ";
      }
    }
    $output .= ",\n" if $spaces eq " ";
    $output .= (" " x $indent) . "]";
  } elsif (reftype($object) eq "SCALAR") {
    # Unresolved indirect reference.
    my ($id, $gen) = split /-/, ${$object};
    $gen ||= "0";
    $output .= "\"$id $gen R\"";
  } else {
    # Simple object.
    $output = sprintf "%s%s\n", " " x $indent, dump($object);
  }

  # Return generated output.
  return $output;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PDF::Data - Manipulate PDF files and objects as data structures

=head1 VERSION

version v1.2.0

=head1 SYNOPSIS

  use PDF::Data;

=head1 DESCRIPTION

This module can read and write PDF files, and represents PDF objects as data
structures that can be readily manipulated.

=head1 METHODS

=head2 new

  my $pdf = PDF::Data->new(-compress => 1, -minify => 1);

Constructor to create an empty PDF::Data object instance.  Any arguments passed
to the constructor are treated as key/value pairs, and included in the C<$pdf>
hash object returned from the constructor.  When the PDF file data is generated,
this hash is written to the PDF file as the trailer dictionary.  However, hash
keys starting with "-" are ignored when writing the PDF file, as they are
considered to be flags or metadata.

For example, C<$pdf-E<gt>{-compress}> is a flag which controls whether or not
streams will be compressed when generating PDF file data.  This flag can be set
in the constructor (as shown above), or set directly on the object.

The C<$pdf-E<gt>{-minify}> flag controls whether or not to save space in the
generated PDF file data by removing comments and extra whitespace from content
streams.  This flag can be used along with C<$pdf-E<gt>{-compress}> to make the
generated PDF file data even smaller, but this transformation is not reversible.

=head2 clone

  my $pdf_clone = $pdf->clone;

Deep copy the entire PDF::Data object itself.

=head2 new_page

  my $page = $pdf->new_page;
  my $page = $pdf->new_page('LETTER');
  my $page = $pdf->new_page(8.5, 11);

Create a new page object with the specified size (in inches).  Alternatively,
certain page sizes may be specified using one of the known keywords: "LETTER"
for U.S. Letter size (8.5" x 11"), "LEGAL" for U.S. Legal size (8.5" x 14"), or
"A0" through "A8" for ISO A-series paper sizes.  The default page size is U.S.
Letter size (8.5" x 11").

=head2 copy_page

  my $copied_page = $pdf->copy_page($page);

Deep copy a single page object.

=head2 append_page

  $page = $pdf->append_page($page);

Append the specified page object to the end of the PDF page tree.

=head2 read_pdf

  my $pdf = PDF::Data->read_pdf($file, %args);

Read a PDF file and parse it with C<$pdf-E<gt>parse_pdf()>, returning a new
object instance.  Any streams compressed with the /FlateDecode filter will be
automatically decompressed.  Unless the C<$pdf-E<gt>{-decompress}> flag is set,
the same streams will also be automatically recompressed again when generating
PDF file data.

=head2 parse_pdf

  my $pdf = PDF::Data->parse_pdf($data, %args);

Used by C<$pdf-E<gt>read_pdf()> to parse the raw PDF file data and create a new
object instance.  This method can also be called directly instead of calling
C<$pdf-E<gt>read_pdf()> if the PDF file data comes another source instead of a
regular file.

=head2 write_pdf

  $pdf->write_pdf($file, $time);

Generate and write a new PDF file from the current state of the PDF::Data
object.

The C<$time> parameter is optional; if not defined, it defaults to the current
time.  If C<$time> is defined but false (zero or empty string), no timestamp
will be set.

The optional C<$time> parameter may be used to specify the modification
timestamp to save in the PDF metadata and to set the file modification timestamp
of the output file.  If not specified, it defaults to the current time.  If a
false value is specified, this method will skip setting the modification time in
the PDF metadata, and skip setting the timestamp on the output file.

=head2 pdf_file_data

  my $pdf_file_data = $document->pdf_file_data($time);

Generate PDF file data from the current state of the PDF data structure,
suitable for writing to an output PDF file.  This method is used by the
C<$pdf-E<gt>write_pdf()> method to generate the raw string of bytes to be
written to the output PDF file.  This data can be directly used (e.g. as a MIME
attachment) without the need to actually write a PDF file to disk.

The optional C<$time> parameter may be used to specify the modification
timestamp to save in the PDF metadata.  If not specified, it defaults to the
current time.  If a false value is specified, this method will skip setting the
modification time in the PDF metadata.

=head2 dump_pdf

  $pdf->dump_pdf($file, $mode);

Dump the PDF internal structure and data for debugging.  If the C<$mode>
parameter is "outline", dump only the PDF internal structure without the data.

=head2 dump_outline

  $pdf->dump_outline($file);

Dump an outline of the PDF internal structure for debugging.  (This method
simply calls the C<$pdf-E<gt>dump_pdf()> method with the C<$mode> parameter
specified as "outline".)

=head2 merge_content_streams

  my $stream = $pdf->merge_content_streams($array_of_streams);

Merge multiple content streams into a single content stream.

=head2 find_bbox

  $pdf->find_bbox($content_stream, $new);

Analyze a content stream to determine the correct bounding box for the content
stream.  The current implementation was purpose-built for a specific use case
and should not be expected to work correctly for most content streams.

The C<$content_stream> parameter may be a stream object or a string containing
the raw content stream data.

The current algorithm breaks the content stream into lines, skips over various
"neutral" lines and examines the coordinates specified for certain PDF drawing
operators: "m" (moveto), "l" (lineto), "v" (curveto, initial point replicated),
"y" (curveto, final point replicated), and "c" (curveto, all points specified).

The minimum and maximum X and Y coordinates seen for these drawing operators are
used to determine the bounding box (left, bottom, right, top) for the content
stream.  The bounding box and equivalent rectangle (left, bottom, width, height)
are printed.

If the C<$new> boolean parameter is set, an updated content stream is generated
with the coordinates adjusted to move the lower left corner of the bounding box
to (0, 0).  This would be better done by translating the transformation matrix.

=head2 new_bbox

  $new_content = $pdf->new_bbox($content_stream);

This method simply calls the C<$pdf-E<gt>find_bbox()> method above with C<$new>
set to 1.

=head2 timestamp

  my $timestamp = $pdf->timestamp($time);
  my $now       = $pdf->timestamp;

Generate timestamp in PDF internal format.

=head1 UTILITY METHODS

=head2 round

  my @numbers = $pdf->round(@numbers);

Round numeric values to 12 significant digits to avoid floating-point rounding
error and remove trailing zeroes.

=head2 concat_matrix

  my $matrix = $pdf->concat_matrix($transformation_matrix, $original_matrix);

Concatenate a transformation matrix with an original matrix, returning a new
matrix.  This is for arrays of 6 elements representing standard 3x3
transformation matrices as used by PostScript and PDF.

=head2 invert_matrix

  my $inverse = $pdf->invert_matrix($matrix);

Calculate the inverse of a matrix, if possible.  Returns C<undef> if the matrix
is not invertible.

=head2 translate

  my $matrix = $pdf->translate($x, $y);

Returns a 6-element transformation matrix representing translation of the origin
to the specified coordinates.

=head2 scale

  my $matrix = $pdf->scale($x, $y);

Returns a 6-element transformation matrix representing scaling of the coordinate
space by the specified horizontal and vertical scaling factors.

=head2 rotate

  my $matrix = $pdf->rotate($angle);

Returns a 6-element transformation matrix representing counterclockwise rotation
of the coordinate system by the specified angle (in degrees).

=head1 INTERNAL METHODS

=head2 validate

  $pdf->validate;

Used by C<$pdf-E<gt>new()>, C<$pdf-E<gt>parse_pdf()> and
C<$pdf-E<gt>write_pdf()> to validate some parts of the PDF structure.
Currently, C<$pdf-E<gt>validate()> uses C<$pdf-E<gt>validate_key()> to verify
that the document catalog and page tree root node exist and have the correct
type, and that the page tree root node has no parent node.  Then it calls
C<$pdf-E<gt>validate_page_tree()> to validate the entire page tree.

By default, if a validation error occurs, it will be output as warnings, but
the C<$pdf-E<gt>{-validate}> flag can be set to make the errors fatal.

=head2 validate_page_tree

  my $count = $pdf->validate_page_tree($path, $page_tree_node);

Used by C<$pdf-E<gt>validate()>, and called by itself recursively, to validate
the PDF page tree and its subtrees.  The C<$path> parameter specifies the
logical path from the root of the PDF::Data object to the page subtree, and the
C<$page_tree_node> parameter specifies the actual page tree node data structure
represented by that logical path.  C<$pdf-E<gt>validate()> initially calls
C<$pdf-E<gt>validate_page_tree()> with "Root/Pages" for C<$path> and
C<$pdf-E<gt>{Root}{Pages}> for C<$page_tree_node>.

Each child of the page tree node (in C<$page_tree_node-E<gt>{Kids}>) should be
another page tree node for a subtree or a single page node.  In either case, the
parameters used for the next method call will be C<"$path\[$i]"> for C<$path>
(e.g. "Root/Pages[0][1]") and C<$page_tree_node-E<gt>{Kids}[$i]> for
C<$page_tree_node> (e.g.  C<$pdf-E<gt>{Root}{Pages}{Kids}[0]{Kids}[1]>).  These
parameters are passed to either C<$pdf-E<gt>validate_page_tree()> recursively
(if the child is a page tree node) or to C<$pdf-E<gt>validate_page()> (if the
child is a page node).

After validating the page tree, C<$pdf-E<gt>validate_resources()> will be called
to validate the page tree's resources, if any.

If the count of pages in the page tree is incorrect, it will be fixed.  This
method returns the total number of pages in the specified page tree.

=head2 validate_page

  $pdf->validate_page($path, $page);

Used by C<$pdf-E<gt>validate_page_tree()> to validate a single page of the PDF.
The C<$path> parameter specifies the logical path from the root of the PDF::Data
object to the page, and the C<$page> parameter specifies the actual page data
structure represented by that logical path.

This method will call C<$pdf-E<gt>merge_content_streams()> to merge the content
streams into a single content stream (if C<$page-E<gt>{Contents}> is an array),
then it will call C<$pdf-E<gt>validate_content_stream()> to validate the page's
content stream.

After validating the page, C<$pdf-E<gt>validate_resources()> will be called to
validate the page's resources, if any.

=head2 validate_resources

  $pdf->validate_resources($path, $resources);

Used by C<$pdf-E<gt>validate_page_tree()>, C<$pdf-E<gt>validate_page()> and
C<$pdf-E<gt>validate_xobject()> to validate associated resources.  The C<$path>
parameter specifies the logical path from the root of the PDF::Data object to
the resources, and the C<$resources> parameter specifies the actual resources
data structure represented by that logical path.

This method will call C<validate_xobjects> for C<$resources-E<gt>{XObject}>, if
set.

=head2 validate_xobjects

  $pdf->validate_xobjects($path, $xobjects);

Used by C<$pdf-E<gt>validate_resources()> to validate form XObjects in the
resources.  The C<$path> parameter specifies the logical path from the root of
the PDF::Data object to the hash of form XObjects, and the C<$xobjects>
parameter specifies the actual hash of form XObjects represented by that logical
path.

This method simply loops across all the form XObjects in C<$xobjects> and calls
C<$pdf-E<gt>validate_xobject()> for each of them.

=head2 validate_xobject

  $pdf->validate_xobject($path, $xobject);

Used by C<$pdf-E<gt>validate_xobjects()> to validate a form XObject.  The
C<$path> parameter specifies the logical path from the root of the PDF::Data
object to the form XObject, and the C<$xobject> parameter specifies the actual
form XObject represented by that logical path.

This method verifies that C<$xobject> is a stream and C<$xobject-E<gt>{Subtype}>
is "/Form", then calls C<$pdf-E<gt>validate_content_stream()> with C<$xobject>
to validate the form XObject content stream, then calls
C<$pdf-E<gt>validate_resources()> to validate the form XObject's resources, if
any.

=head2 validate_content_stream

  $pdf->validate_content_stream($path, $stream);

Used by C<$pdf-E<gt>validate_page()> and C<$pdf-E<gt>validate_xobject()> to
validate a content stream.  The C<$path> parameter specifies the logical path
from the root of the PDF::Data object to the content stream, and the C<$stream>
parameter specifies the actual content stream represented by that logical path.

This method calls C<$pdf-E<gt>parse_objects()> to make sure that the content
stream can be parsed.  If the C<$pdf-E<gt>{-minify}> flag is set,
C<$pdf-E<gt>minify_content_stream()> will be called with the array of parsed
objects to minify the content stream.

=head2 minify_content_stream

  $pdf->minify_content_stream($stream, $objects);

Used by C<$pdf-E<gt>validate_content_stream()> to minify a content stream.  The
C<$stream> parameter specifies the content stream to be modified, and the
optional C<$objects> parameter specifies a reference to an array of parsed
objects as returned by C<$pdf-E<gt>parse_objects()>.

This method calls C<$pdf-E<gt>parse_objects()> to populate the C<$objects>
parameter if unspecified, then it calls C<$pdf-E<gt>generate_content_stream()>
to generate a minimal content stream for the array of objects, with no comments
and only the minimum amount of whitespace necessary to parse the content stream
correctly.  (Obviously, this means that this transformation is not reversible.)

Currently, this method also performs a sanity check by running the replacement
content stream through C<$pdf-E<gt>parse_objects()> and comparing the entire
list of objects returned against the original list of objects to ensure that the
replacement content stream is equivalent to the original content stream.

=head2 generate_content_stream

  my $data = $pdf->generate_content_stream($objects);

Used by C<$pdf-E<gt>minify_content_stream()> to generate a minimal content
stream to replace the original content stream.  The C<$objects> parameter
specifies a reference to an array of parsed objects as returned by
C<$pdf-E<gt>parse_objects()>.  These objects will be used to generate the new
content stream.

For each object in the array, this method will call an appropriate serialization
method: C<$pdf-E<gt>serialize_dictionary()> for dictionary objects,
C<$pdf-E<gt>serialize_array()> for array objects, or
C<$pdf-E<gt>serialize_object()> for other objects.  After serializing all the
objects, the newly-generated content stream data is returned.

=head2 serialize_dictionary

  $pdf->serialize_dictionary($stream, $hash);

Used by C<$pdf-E<gt>generate_content_stream()>,
C<$pdf-E<gt>serialize_dictionary()> (recursively) and
C<$pdf-E<gt>serialize_array()> to serialize a hash as a dictionary object.  The
C<$stream> parameter specifies a reference to a string containing the data for
the new content stream being generated, and the C<$hash> parameter specifies the
hash reference to be serialized.

This method will serialize all the key-value pairs of C<$hash>, prefixing each
key in the hash with "/" to serialize the key as a name object, and calling an
appropriate serialization routine for each value in the hash:
C<$pdf-E<gt>serialize_dictionary()> for dictionary objects (recursive call),
C<$pdf-E<gt>serialize_array()> for array objects, or
C<$pdf-E<gt>serialize_object()> for other objects.

=head2 serialize_array

  $pdf->serialize_array($stream, $array);

Used by C<$pdf-E<gt>generate_content_stream()>,
C<$pdf-E<gt>serialize_dictionary()> and C<$pdf-E<gt>serialize_array()>
(recursively) to serialize an array.  The C<$stream> parameter specifies a
reference to a string containing the data for the new content stream being
generated, and the C<$array> parameter specifies the array reference to be
serialized.

This method will serialize all the array elements of C<$array>, calling an
appropriate serialization routine for each element of the array:
C<$pdf-E<gt>serialize_dictionary()> for dictionary objects,
C<$pdf-E<gt>serialize_array()> for array objects (recursive call), or
C<$pdf-E<gt>serialize_object()> for other objects.

=head2 serialize_object

  $pdf->serialize_object($stream, $object);

Used by C<$pdf-E<gt>generate_content_stream()>,
C<$pdf-E<gt>serialize_dictionary()> and C<$pdf-E<gt>serialize_array()>
to serialize a simple object.  The C<$stream> parameter specifies a reference to
a string containing the data for the new content stream being generated, and the
C<$object> parameter specifies the pre-serialized object to be serialized to the
specified content stream data.

This method will strip leading and trailing whitespace from the pre-serialized
object if the C<$pdf-E<gt>{-minify}> flag is set, then append a newline
to C<${$stream}> if appending the pre-serialized object would exceed 255
characters for the last line, then append a space to C<${$stream}> if necessary
to parse the object correctly, then append the pre-serialized object to
C<${$stream}>.

=head2 validate_key

  $pdf->validate_key($hash, $key, $value, $label);

Used by C<$pdf-E<gt>validate()> to validate specific hash key values.

=head2 get_hash_node

  my $hash = $pdf->get_hash_node($path);

Used by C<$pdf-E<gt>validate_key()> to get a hash node from the PDF structure by
path.

=head2 parse_objects

  my @objects = $pdf->parse_objects($objects, $data, $offset);

Used by C<$pdf-E<gt>parse_pdf()> to parse PDF objects into Perl representations.

=head2 parse_data

  my @objects = $pdf->parse_data($data);

Uses C<$pdf-E<gt>parse_objects()> to parse PDF objects from standalone PDF data.

=head2 filter_stream

  $pdf->filter_stream($stream);

Used by C<$pdf-E<gt>parse_objects()> to inflate compressed streams.

=head2 compress_stream

  $new_stream = $pdf->compress_stream($stream);

Used by C<$pdf-E<gt>write_object()> to compress streams if enabled.  This is
controlled by the C<$pdf-E<gt>{-compress}> flag, which is set automatically when
reading a PDF file with compressed streams, but must be set manually for PDF
files created from scratch, either in the constructor arguments or after the
fact.

=head2 resolve_references

  $object = $pdf->resolve_references($objects, $object);

Used by C<$pdf-E<gt>parse_pdf()> to replace parsed indirect object references
with direct references to the objects in question.

=head2 write_indirect_objects

  my $xrefs = $pdf->write_indirect_objects($pdf_file_data, $objects, $seen);

Used by C<$pdf-E<gt>write_pdf()> to write all indirect objects to a string of
new PDF file data.

=head2 enumerate_indirect_objects

  $pdf->enumerate_indirect_objects($objects);

Used by C<$pdf-E<gt>write_indirect_objects()> to identify which objects in the
PDF data structure need to be indirect objects.

=head2 enumerate_shared_objects

  $pdf->enumerate_shared_objects($objects, $seen, $ancestors, $object);

Used by C<$pdf-E<gt>enumerate_indirect_objects()> to find objects which are
already shared (referenced from multiple objects in the PDF data structure).

=head2 add_indirect_objects

  $pdf->add_indirect_objects($objects, @objects);

Used by C<$pdf-E<gt>enumerate_indirect_objects()> and
C<$pdf-E<gt>enumerate_shared_objects()> to add objects to the list of indirect
objects to be written out.

=head2 write_object

  $pdf->write_object($pdf_file_data, $objects, $seen, $object, $indent);

Used by C<$pdf-E<gt>write_indirect_objects()>, and called by itself recursively,
to write direct objects out to the string of new PDF file data.

=head2 dump_object

  my $output = $pdf->dump_object($object, $label, $seen, $indent, $mode);

Used by C<$pdf-E<gt>dump_pdf()>, and called by itself recursively, to dump (or
outline) the specified PDF object.

=cut

package RF::Antenna::Planet::MSI::Format;
use strict;
use warnings;
use Scalar::Util qw();
use Tie::IxHash qw{};
use Path::Class qw{};

our $VERSION = '0.08';

=head1 NAME

RF::Antenna::Planet::MSI::Format - RF Antenna Pattern File Reader and Writer in Planet MSI Format

=head1 SYNOPSIS

Read from MSI file

  use RF::Antenna::Planet::MSI::Format;
  my $antenna = RF::Antenna::Planet::MSI::Format->new;
  $antenna->read($filename);

Create a blank object, load data from other sources, then write antenna pattern file.

  my $antenna = RF::Antenna::Planet::MSI::Format->new;
  $antenna->name("My Name");
  $antenna->make("My Make");
  my $file    = $antenna->write($filename);

=head1 DESCRIPTION

This package reads and writes antenna radiation patterns in Planet MSI antenna format.

Planet is a RF propagation simulation tool initially developed by MSI. Planet was a 2G radio planning tool which has set a standard in the early days of computer aided radio network design. The antenna pattern file and the format which is currently known as ".msi" format or .msi-file has become a standard.

=head1 CONSTRUCTORS

=head2 new

Creates a new blank object for creating files or loading data from other sources

  my $antenna = RF::Antenna::Planet::MSI::Format->new;

Creates a new object and loads data from other sources

  my $antenna = RF::Antenna::Planet::MSI::Format->new(
                                                      NAME          => "My Antenna Name",
                                                      MAKE          => "My Manufacturer Name",
                                                      FREQUENCY     => "2437" || "2437 MHz" || "2.437 GHz",
                                                      GAIN          => "10.0" || "10.0 dBd" || "12.14 dBi",
                                                      COMMENT       => "My Comment",
                                                      horizontal    => [[0.00, 0.96], [1.00, 0.04], ..., [180.00, 31.10], ..., [359.00, 0.04]],
                                                      vertical      => [[0.00, 1.08], [1.00, 0.18], ..., [180.00, 31.23], ..., [359.00, 0.18]],
                                                     );

=cut

sub new {
  my $this  = shift;
  die("Error: new constructor requires key/value pairs") if @_ % 2;
  my $class = ref($this) ? ref($this) : $this;
  my $self  = {};
  bless $self, $class;

  my @later = ();
  while (@_) { #preserve order
    my $key   = shift;
    my $value = shift;
    if ($key eq 'header') {
      if (ref($value) eq 'HASH') {
        my @order = qw{NAME MAKE FREQUENCY GAIN TILT POLARIZATION COMMENT};
        my %copy  = %$value;
        foreach my $key (@order) {
          $self->header($key => delete($copy{$key})) if exists $copy{$key};
        }
        $self->header(%copy); #appends the rest in hash order
      } elsif (ref($value) eq 'ARRAY') {
        $self->header(@$value); #preserves order
      } else {
        die("Error: header value expected to be either array reference or hash reference");
      }
    } elsif ($key eq 'horizontal') {
      die("Error: horizontal value expected to be array reference") unless ref($value) eq 'ARRAY';
      $self->horizontal($value);
    } elsif ($key eq 'vertical') {
      die("Error: vertical value expected to be array reference") unless ref($value) eq 'ARRAY';
      $self->vertical($value);
    } else {
      die("Error: header key/value pairs must be strings") if ref($value);
      push @later, $key, $value; #store for later so that we process header before header keys
    }
  }
  $self->header(@later) if @later;

  return $self;
}

=head2 read

Reads an antenna pattern file and parses the data into the object data structure. Returns the object so that the call can be chained.

  $antenna->read($filename);
  $antenna->read(\$scalar);

Assumptions:
  The first line in the MSI file contains the name of the antenna.  It appears that some vendors suppress the "NAME" token but we always write the NAME token.
  The keys can be mixed case but convention appears to be all upper case keys for common keys and lower case keys for vendor extensions.

=cut

sub read {
  my $self        = shift;
  my $file        = shift;
  my $blob        = ref($file) eq 'SCALAR' ? ${$file} : Path::Class::file($file)->slurp;
  $self->{'blob'} = $blob; #store for blob method
  my @lines       = split(/[\n\r]+/, $blob);
  my $loop        = 0;
  while (1) {
    my $line = shift @lines;
    $line =~ s/\A\s*//; #ltrim
    $line =~ s/\s*\Z//; #rtrim
    if ($line) {
      $loop++;
      my ($key, $value) = split /\s+/, $line, 2; #split with limit returns undef value if empty string
      $value = '' unless defined $value;
  
      if ($loop == 1 and $key ne 'NAME') { #First line of file is NAME even if NAME token is surpessed
        $self->header(NAME => $line);
      } else {
        #printf "Key: $key, Value: $value\n";
        if (uc($key) eq 'HORIZONTAL') {
          $self->_parse_polarization(\@lines, horizontal => $value);
        } elsif (uc($key) eq 'VERTICAL') {
          $self->_parse_polarization(\@lines, vertical => $value);
        } else {
          $self->header($key => $value);
        }
      }
    }
    last unless @lines;
  }
  return $self;

  sub _parse_polarization {
    my $self   = shift;
    my $lines  = shift;
    my $method = shift;
    my $value  = shift; #string
    if ($value =~ m/([0-9]+)/) { #support bad data like missing 360 or "360 0"
      $value = $1 + 0; #convert string to number
    } else {
      $value = 360;    #default
    }
    my @data = map {s/\s+\Z//; s/\A\s+//; [split /\s+/, $_, 2]} splice @$lines, 0, $value;
    die(sprintf('Error: %s records with %s records returned %s records', uc($method), $value, scalar(@data))) unless scalar(@data) == $value;
    $self->$method(\@data);
  }
}

=head2 read_fromZipMember

Reads an antenna pattern file from a zipped archive and parses the data into the object data structure.

  $antenna->read_fromZipMember($zip_filename, $member_filename);

=cut

sub read_fromZipMember {
  my $self            = shift;
  my $zip_filename    = shift or die("Error: zip filename required");
  my $member_filename = shift or die("Error: zip member name requried");

  require Archive::Zip;
  require Archive::Zip::MemberRead;

  my $zip_archive = Archive::Zip->new;
  unless ( $zip_archive->read("$zip_filename") == Archive::Zip::AZ_OK() ) {die "Error: $zip_filename read error"};

  my $blob  = '';
  my $fh    = Archive::Zip::MemberRead->new($zip_archive, "$member_filename");
  while (defined(my $line = $fh->getline)) {$blob .= "$line$/"}; #getline chomps but preserve_line_ending does not work for foreign line endings
  $fh->close;

  return $self->read(\$blob);
}

=head2 blob

Returns the data blob that was read by the read($file), read($scalar_ref), or read_fromZipMember($,$) methods.

=cut

sub blob {
  my $self = shift;
  return $self->{'blob'};
}

=head2 write

Writes the object's data to an antenna pattern file and returns a Path::Class file object of the written file.

  my $file     = $antenna->write($filename); #isa Path::Class::file
  my $tempfile = $antenna->write;            #isa Path::Class::file in temp directory
  $antenna->write(\$scalar);                 #returns undef with data writen to the variable

=cut

sub write {
  my $self     = shift;
  my $filename = shift;

  #Open file handle
  my $fh;
  my $file;
  if (ref($filename) eq 'SCALAR') {
    $file            = undef;
    open $fh, '>', $filename;
  } elsif (length $filename) {
    $file            = Path::Class::file($filename);
    $fh              = $file->open('w') or die(qq{Error: Cannot open "$filename" for writing});
  } else {
    require File::Temp;
    ($fh, $filename) = File::Temp::tempfile('antenna_pattern_XXXXXXXX', TMPDIR => 1, SUFFIX => '.msi');
    $file            = Path::Class::file($filename);
  }

  #Print to file handle

  sub _print_fh_key_value {
    my $fh    = shift;
    my $key   = shift;
    my $value = shift;
    print $fh "$key $value\n";
  }

  my $header = $self->header; #isa Tie::IxHash ordered hash

  ##Print NAME as first line
  _print_fh_key_value($fh, 'NAME', $header->{'NAME'});

  ##Print rest of the headers
  foreach my $key (keys %$header) {
    next if $key eq 'NAME'; #written above
    my $value = $header->{$key};
    _print_fh_key_value($fh, $key, $value) if defined $value;
  }

  sub _print_fh_key_array {
    my $fh    = shift;
    my $key   = shift;
    my $array = shift;
    if (@$array) {
      _print_fh_key_value($fh, $key, scalar(@$array));
      foreach my $row (@$array) {
        my $key   = $row->[0];
        my $value = $row->[1];
        _print_fh_key_value($fh, $key, $value);
      }
    }
  }

  ##Print antenna pattern angle and loss values
  foreach my $method (qw{horizontal vertical}) {
    my $array = $self->$method;
    next unless $array;
    my $key   = uc($method);
    _print_fh_key_array($fh, $key, $array);
  }

  #Close file handle and Return file object
  close $fh;
  return $file;
}

=head1 DATA STRUCTURE METHODS

=head2 header

Set header values and returns the header data structure which is a hash reference tied to L<Tie::IxHash> to preserve header sort order.

Set a key/value pair

  $antenna->header(COMMENT => "My comment");          #upper case keys are common/reserved whereas mixed/lower case keys are vendor extensions

Set multiple keys/values with one call

  $antenna->header(NAME => $myname, MAKE => $mymake);

Read arbitrary values

  my $value = $antenna->header->{$key};

Returns ordered list of header keys

  my @keys = keys %{$antenna->header};

Common Header Keys: NAME MAKE FREQUENCY GAIN TILT POLARIZATION COMMENT

=cut

sub header {
  my $self = shift;
  die('Error: header method requires key/value pairs') if @_ % 2;
  unless (defined $self->{'header'}) {
    my %data = ();
    tie(%data, 'Tie::IxHash');
    $self->{'header'} = \%data;
  }
  while (@_) {
    my $key   = shift;
    my $value = shift;
    $self->{'header'}->{$key} = $value;
  }
  return $self->{'header'};
}

=head2 horizontal, vertical

Horizontal or vertical data structure for the angle and relative loss values from the specified gain in the header.

Each methods sets and returns an array reference of array references [[$angle1, $value1], [$angle2, $value2], ...]

Please note that the format uses equal spacing of data points by angle.  Most files that I have seen use 360 one degree measurements from 0 (i.e. boresight) to 359 degrees with values in dB down from the maximum lobe even if that lobe is not the boresight.

=cut

sub horizontal {
  my $self              = shift;
  $self->{'horizontal'} = shift if @_;
  return $self->{'horizontal'};
}

sub vertical {
  my $self            = shift;
  $self->{'vertical'} = shift if @_;
  return $self->{'vertical'};
}

=head1 HELPER METHODS

Helper methods are wrappers around the header data structure to aid in usability.

=head2 name

Sets and returns the name of the antenna in the header structure

  my $name = $antenna->name;
  $antenna->name("My Antenna Name");

Assumed: Less than about 40 ASCII characters

=cut

sub name {
  my $self = shift;
  $self->header(NAME => shift) if @_;
  return $self->header->{'NAME'};
}

=head2 make

Sets and returns the name of the manufacturer in the header structure

  my $make = $antenna->make;
  $antenna->make("My Antenna Manufacturer");

Assumed: Less than about 40 ASCII characters

=cut

sub make {
  my $self = shift;
  $self->header(MAKE => shift) if @_;
  return $self->header->{'MAKE'};
}

=head2 frequency

Sets and returns the frequency string as displayed in header structure

  my $frequency = $antenna->frequency;
  $antenna->frequency("2450");          #correct format in MHz
  $antenna->frequency("2450 MHz");      #acceptable format
  $antenna->frequency("2.45 GHz");      #common format but technically not to spec
  $antenna->frequency("2450-2550");     #common range format but technically not to spec
  $antenna->frequency("2.45-2.55 GHz"); #common range format but technically not to spec

=cut

sub frequency {
  my $self = shift;
  $self->header(FREQUENCY => shift) if @_;
  return $self->header->{'FREQUENCY'};
}

=head2 frequency_mhz, frequency_ghz, frequency_mhz_lower, frequency_mhz_upper, frequency_ghz_lower, frequency_ghz_upper

Attempts to read and parse the string header value and return the frequency as a number in the requested unit of measure.

=cut

#supported formats
#123.1 => assumed MHz
#123.1 MHz
#123.1 GHz
#123.1 kHz
#123.1-124.1 => assumed MHz
#123.1-124.1 MHz
#123.1-124.1 GHz
#123.1-124.1 kHz
#123x124
#123x124 MHz
#123x124 GHz
#123x124 kHz

sub frequency_mhz {
  my $self   = shift;
  my $string = $self->frequency;
  my $number = undef; #return undef if cannot parse

  if (defined($string)) {

    my $upper  = undef;
    my $lower  = undef;

    my $scale  = 1; #Default: MHz
    if ($string =~ m/GHz/i) {
      $scale = 1e3;
    } elsif ($string =~ m/kHz/i) {
      $scale = 1e-3;
    } elsif ($string =~ m/MHz/i) {
      $scale = 1;
    }

    if (Scalar::Util::looks_like_number($string)) { #entire string looks like a number
      $number = $scale * $string;
      $lower  = $number;
      $upper  = $number;
    } elsif ($string =~  m/([0-9]*\.?[0-9]+)[^0-9.]+([0-9]*\.?[0-9]+)/) { #two non-negative numbers with any separator
      $lower  = $scale * $1;
      $upper  = $scale * $2;
      $number = ($lower + $upper) / 2;
    } elsif ($string =~ m/([0-9]*\.?[0-9]+)/) { #one non-negative number
      $number = $scale * $1;
      $lower  = $number;
      $upper  = $number;
    }
    $self->{'frequency_mhz'}       = $number;
    $self->{'frequency_mhz_lower'} = $lower;
    $self->{'frequency_mhz_upper'} = $upper;

  }
  return $number;
}

sub frequency_ghz {
  my $self = shift;
  my $mhz  = $self->frequency_mhz;
  return $mhz ? $mhz/1000 : undef;
}

sub frequency_mhz_lower {
  my $self = shift;
  $self->frequency_mhz; #initialize
  return $self->{'frequency_mhz_lower'};
}

sub frequency_mhz_upper {
  my $self = shift;
  $self->frequency_mhz; #initialize
  return $self->{'frequency_mhz_upper'};
}

sub frequency_ghz_lower {
  my $self = shift;
  my $mhz  = $self->frequency_mhz_lower;
  return $mhz ? $mhz/1000 : undef;
}

sub frequency_ghz_upper {
  my $self = shift;
  my $mhz  = $self->frequency_mhz_upper;
  return $mhz ? $mhz/1000 : undef;
}

=head2 gain

Sets and returns the antenna gain string as displayed in file (dBd is the default unit of measure)

  my $gain = $antenna->gain;
  $antenna->gain("9.1");          #correct format in dBd
  $antenna->gain("9.1 dBd");      #correct format in dBd
  $antenna->gain("9.1 dBi");      #correct format in dBi
  $antenna->gain("(dBi) 9.1");    #supported format

=cut

sub gain {
  my $self = shift;
  $self->header(GAIN => shift) if @_;
  return $self->header->{'GAIN'};
}

=head2 gain_dbd, gain_dbi

Attempts to read and parse the string header value and return the gain as a number in the requested unit of measure.

=cut

sub gain_dbd {
  my $self   = shift;
  my $string = $self->gain;
  my $number = undef;
  if (defined($string)) {

    my $scale  = 0; #default dBd
    if ($string =~ m/dBi/i) {
      $scale = -2.14;
    } elsif ($string =~ m/dBd/i) {
      $scale = 0;
    }

    if (Scalar::Util::looks_like_number($string)) { #entire string looks like a number
      $number = $string + $scale; #default: dBd
    } elsif ($string =~ m/([+-]?[0-9]*\.?[0-9]+)/) { #one real number
      $number = $1 + $scale;
    }

  }
  return $number;
}

sub gain_dbi {
  my $self = shift;
  my $dbd  = $self->gain_dbd;
  return defined($dbd) ? $dbd + 2.14 : undef;
}

=head2 electrical_tilt

Antenna electrical_tilt string as displayed in file.

  my $electrical_tilt = $antenna->electrical_tilt;
  $antenna->electrical_tilt("MECHINICAL");

=cut

sub electrical_tilt {
  my $self = shift;
  $self->header(ELECTRICAL_TILT => shift) if @_;
  return $self->header->{'ELECTRICAL_TILT'};
}

=head2 comment

Antenna comment string as displayed in file.

  my $comment = $antenna->comment;
  $antenna->comment("My Comment");

=cut

sub comment {
  my $self = shift;
  $self->header(COMMENT => shift) if @_;
  return $self->header->{'COMMENT'};
}

=head1 SEE ALSO

Format Definition: L<http://radiomobile.pe1mew.nl/?The_program:Definitions:MSI>

Antenna Pattern File Library L<https://www.wireless-planning.com/msi-antenna-pattern-file-library>

Format Definition from RCC: L<https://web.archive.org/web/20080821041142/http://www.rcc.com/msiplanetformat.html>

=head1 AUTHOR

Michael R. Davis, MRDVT

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis

=cut

1;

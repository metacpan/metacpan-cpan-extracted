package RF::Antenna::Planet::MSI::Format;
use strict;
use warnings;
use Scalar::Util qw();
use Tie::IxHash qw{};
use Path::Class qw{};

our $VERSION = '0.02';

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
                                                      name          => "My Antenna Name",
                                                      make          => "My Manufacturer Name",
                                                      frequency     => "2437" || "2437 MHz" || "2.437 GHz",
                                                      gain          => "10.0" || "10.0 dBd" || "12.14 dBi",
                                                      comment       => "My Comment",
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
        my @order = qw{NAME MAKE FREQUENCY H_WIDTH V_WIDTH FRONT_TO_BACK GAIN TILT POLARIZATION COMMENT};
        my %uc    = map {uc($_) => $value->{$_}} keys %$value;
        foreach my $key (@order) {
          next unless exists $uc{$key};
          $self->header($key => delete($uc{$key}));
        }
        $self->header(%uc); #appends unknown keys to header
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

=cut

sub read {
  my $self  = shift;
  my $file  = shift;
  my $blob  = ref($file) eq 'SCALAR' ? ${$file} : Path::Class::file($file)->slurp;
  my @lines = split(/[\n\r]+/, $blob);
  while (1) {
    my $line = shift @lines;
    $line =~ s/\A\s*//; #ltrim
    $line =~ s/\s*\Z//; #rtrim
    next unless $line;
    my ($key, $value) = split /\s+/, $line, 2; #split with limit returns undef value if empty string
    $value = '' unless defined $value; 
    #printf "Key: $key, Value: $value\n";
    if ($key =~ m/\AHORIZONTAL\Z/i) {
      my @data = map {s/\s+\Z//; s/\A\s+//; [split /\s+/, $_, 2]} splice @lines, 0, $value;
      die(sprintf('Error: HORIZONTAL records with %s records returned %s records', $value, scalar(@data))) unless scalar(@data) == $value;
      $self->horizontal(\@data);
    } elsif ($key =~ m/\AVERTICAL\Z/i) {
      my @data = map {s/\s+\Z//; s/\A\s+//; [split /\s+/, $_, 2]} splice @lines, 0, $value;
      die unless @data == $value;
      die(sprintf('Error: VERTICAL records with %s records returned %s records', $value, scalar(@data))) unless scalar(@data) == $value;
      $self->vertical(\@data);
    } else {
      $self->header($key => $value);
    }
    last unless @lines;
  }
  return $self;
}

=head2 write

Writes the object's data to an antenna pattern file and returns a Path::Class file object of the written file.

  my $file     = $antenna->write($filename); #isa Path::Class::file
  my $tempfile = $antenna->write;            #isa Path::Class::file in temp directory
  $antenna->write(\my $scalar_ref);          #returns undef with data writen to the variable

=cut

sub write {
  my $self     = shift;
  my $filename = shift;
  my $fh;
  my $file;
  if (ref($filename) eq 'SCALAR') {
    $file = undef;
    open $fh, '>', $filename;
  } elsif (length $filename) {
    $file            = Path::Class::file($filename);
    $fh              = $file->open('w') or die(qq{Error: Cannot open "$filename" for writing});
  } else {
    require File::Temp;
    ($fh, $filename) = File::Temp::tempfile('antenna_pattern_XXXXXXXX', TMPDIR => 1, SUFFIX => '.msi');
    $file            = Path::Class::file($filename);
  }

  sub _print_fh_key_value {
    my $fh    = shift;
    my $key   = shift;
    my $value = shift;
    print $fh "$key $value\n";
  }

  my $header = $self->header; #isa Tie::IxHash ordered hash
  foreach my $key (keys %$header) {
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

  foreach my $method (qw{horizontal vertical}) {
    my $array = $self->$method;
    next unless $array;
    my $key   = uc($method);
    _print_fh_key_array($fh, $key, $array);
  }

  close $fh;
  return $file;
}

=head1 DATA STRUCTURE METHODS

=head2 header

Set header values and returns the header data structure which is a hash reference tied to L<Tie::IxHash> to preserve header sort order.

Set a key/value pair

  $antenna->header(Comment => "My comment");          #will upper case all keys

Set multiple keys/values with one call

  $antenna->header(NAME => $myname, MAKE => $mymake);

Read arbitrary values

  my $value = $antenna->header->{uc($key)};

Returns ordered list of header keys

  my @keys = keys %{$antenna->header};

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
    $self->{'header'}->{uc($key)} = $value;
  }
  return $self->{'header'};
}

=head2 horizontal, vertical

Horizontal or vertical data structure for the angle and relative loss values from the specified gain in the header.

Each methods sets and returns an array reference of array references [[$angle1, $value1], $angle2, $value2], ...]

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
  $antenna->frequency("2450");     #correct format in MHz
  $antenna->frequency("2450 MHz"); #acceptable format
  $antenna->frequency("2.45 GHz"); #common format but technically not to spec

=cut

sub frequency {
  my $self = shift;
  $self->header(FREQUENCY => shift) if @_;
  return $self->header->{'FREQUENCY'};
}

=head2 frequency_mhz, frequency_ghz

Attempts to read and parse the string header value and return the frequency as a number in the requested unit of measure.

=cut

sub frequency_mhz {
  my $self   = shift;
  my $string = $self->frequency;
  if (Scalar::Util::looks_like_number($string)) {
    return $string + 0; #convert from string to number
  } elsif ($string =~ m/([0-9\.]+)\s*MHz/i) {
    return $1 + 0; #pulls the number out before the string for you ... try it perl -e 'print "2314.23 MHz" + 0'
  } elsif ($string =~ m/([0-9\.]+)\s*GHz/i) {
    return ($1 + 0) * 1000;
  } elsif ($string =~ m/([0-9\.]+)\s*kHz/i) {
    return eval{($1 + 0) / 1000}; #eval will return undef on divide by zero
  } else {
    return undef;
  }
}

sub frequency_ghz {
  my $self = shift;
  my $mhz  = $self->frequency_mhz;
  return $mhz ? $mhz/1000 : undef;
}

=head2 gain

Antenna gain string as displayed in file (dBd is the default unit of measure)

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
  if (Scalar::Util::looks_like_number($string)) {
    return $string + 0; #dBd is the default UOM
  } elsif ($string =~ m/dBd/i) {
    if ($string =~ m/([0-9]*\.?[0-9]+)/) { #0.123 | .123 | 123
      return $1 + 0;
    }
  } elsif ($string =~ m/dBi/i) {
    if ($string =~ m/([0-9]*\.?[0-9]+)/) {
      return ($1 + 0) - 2.14;
    }
  } else {
    return undef;
  }
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

=head1 AUTHOR

Michael R. Davis, MRDVT

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis

=cut

1;

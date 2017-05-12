package Parse::Flash::Cookie;

use 5.008;    # minimum Perl is V5.8.0
use strict;
use warnings;

our $VERSION = '0.09';

use Log::Log4perl;
use XML::Writer;   # to create XML output
use URI::Escape;   # to safely display buffer in debug mode
use DateTime;
use Config;        # to determine endianness

use constant LENGTH_OF_SHORT   => 2;
use constant LENGTH_OF_INTEGER => 2;
use constant LENGTH_OF_LONG    => 4;
use constant LENGTH_OF_FLOAT   => 8;
use constant END_OF_OBJECT     => "\x00\x00\x09";

# The below constants are little-endian.  Adobe flash cookies are
# little-endian even on big-endian platforms.
use constant POSITIVE_INFINITY => "\x7F\xF0\x00\x00\x00\x00\x00\x00";
use constant NEGATIVE_INFINITY => "\xFF\xF0\x00\x00\x00\x00\x00\x00";
use constant NOT_A_NUMBER      => "\x7F\xF8\x00\x00\x00\x00\x00\x00";

my $conf = q(
  log4perl.category.sol.parser             = WARN, ScreenAppender
  log4perl.appender.ScreenAppender         = Log::Log4perl::Appender::Screen
  log4perl.appender.ScreenAppender.stderr  = 0
  log4perl.appender.ScreenAppender.layout  = PatternLayout
  log4perl.appender.ScreenAppender.layout.ConversionPattern=[%p] %m%n
);
Log::Log4perl::init( \$conf );
my $log  = Log::Log4perl::->get_logger(q(sol.parser));

my $file   = undef;
my $FH     = undef;
my $writer = undef;

my %datatype = (
                0x0 => 'number',
                0x1 => 'boolean',
                0x2 => 'string',
                0x3 => 'object',
                0x5 => 'null',
                0x6 => 'undefined',
                0x7 => 'pointer',
                0x8 => 'array',
                0xa => 'raw-array',
                0xb => 'date',
                0xd => 'object-string-number-boolean-textformat',
                0xf => 'object-xml',
                0x10 => 'object-customclass',
               );

# Return true if architecture is little-endian, otherwise false
sub _is_little_endian {
	return ( $Config{byteorder} =~ qr/^1234/ ) ? 1 : 0;
}


# Add an XML element to current document.  Do nothing if $writer is
# undef. Return true.
sub _addXMLElem {

  # Skip if not XML mode
  return unless $writer;

  my ($type, $name, $value) = @_;
  $writer->startTag(
                    'data',
                    'type' => $type,
                    'name' => $name,
                   );

  $writer->characters($value) if (defined($value));
  $writer->endTag();

  return 1;
}

#  Parse and return type and value as list.  Expects to be called in
# list context.  Argument name is passed in order to have the
# individual subs create XML elements themselves.
sub _getTypeAndValue {
  my $name = shift;

  $log->logdie("expected to be called in LIST context") if !wantarray();

  # Read data type
  my $value       = undef;
  my $type        = _readBytes(1);
  my $type_as_txt = $datatype{$type};
  if (!exists($datatype{$type})) {
    $log->warn(qq{Missing datatype for '$type'!}) if $log->is_warn();
  }

  # Read element depending on type
  if($type == 0) {
    $log->debug(q{float}) if $log->is_debug();
    $value =  _getFloat($name);
  } elsif($type == 1){
    $log->debug(q{bool}) if $log->is_debug();
    $value =  _getBool($name);
  } elsif ($type == 2) {
    $log->debug(q{string}) if $log->is_debug();
    $value =  _getString($name);
  } elsif($type == 3){
    $log->debug(q{object}) if $log->is_debug();
    $value =  _getObject($name);
  } elsif($type == 5) {   # null
    $log->debug(q{null}) if $log->is_debug();
    $value = undef;
    _addXMLElem('null', $name);
  } elsif($type == 6) {   # undef
    $log->debug(q{undef}) if $log->is_debug();
    $value = undef;
    _addXMLElem('undef', $name);
  } elsif($type == 7){    # pointer
    $log->debug(q{pointer}) if $log->is_debug();
    $value = _getPointer($name);
  } elsif($type == 8){    # array
    $log->debug(q{array}) if $log->is_debug();
    $value = _getArray($name);
  } elsif($type == 0xb){  # date
    $value = _getDate($name);
  } elsif($type == 0xf){  # doublestring
    $log->logdie("Not implemented yet: doublestring");
  } elsif($type == 0x10){ # customclass
    $log->debug(q{customclass}) if $log->is_debug();
    $value = _getObject($name, 1);
  } else {
    $log->logdie("Unknown type:$type" );
  }

  return ($type_as_txt, $value);
}

# Parse object and return contents as comma separated string.
sub _getObject {
  my $name = shift;
  my $customClass = shift;
  my @retvals = ();
  $writer->startTag(
    'data',
    'type'   => 'object',
    'name'   => $name,
  ) if $writer;

 LOOP:
  while (eof($FH) != 1) {
    # Read until end flag is detected : 00 00 09
    if (_readRaw(3) eq END_OF_OBJECT) {
      #return join(q{,}, @retvals);
      last LOOP;
    }

    # "un-read" the 3 bytes
    seek($FH, -3, 1) or $log->logdie("seek failed");

    # Read name
    $name = _readString();
    $log->debug(qq{name:$name}) if $log->is_debug();

    # Read 2nd name if customClass is set
    if ($customClass) {
      push @retvals, q{class_name=} . $name . q{;};
      $name = _readString();
      $log->debug(qq{name:$name (2nd name - customClass)}) if $log->is_debug();
      $customClass = 0;
    }

    # Get data type and value
    my ($type, $value) = _getTypeAndValue($name);

		{
			no warnings q{uninitialized};  # allow undefined values
			$log->debug(qq{type:$type value:$value}) if $log->is_debug();
			push @retvals, $name . q{;} . $value;
		}
  }

  $writer->endTag() if $writer;

  return join(q{,}, @retvals);
}


# Parse array and return contents as comma separated string.
sub _getArray {
  my $name = shift;

  my @retvals = ();
  my $length = _readLong();
  if($length == 0) {
    return _getObject();
  }

  $writer->startTag(
    'data',
    'type'   => 'array',
    'length' => $length,
    'name'   => $name,
  ) if $writer;

 ELEMENT:
  while ($length-- > 0) {
    $name = _readString();

    if (!defined($name)) {
      last ELEMENT;
    }

    my $retval = undef;
    my ($type, $value) = _getTypeAndValue($name);
    {
      no warnings q{uninitialized}; # allow undef values
      $log->debug(qq{$name;$type;$value}) if $log->is_debug();
      $retval = qq{$name;$type;$value};
    }
    push @retvals, $retval;
  }

  $writer->endTag() if $writer;

  # Now expect END_OF_OBJECT tag to be next
  if (_readRaw(3) eq END_OF_OBJECT) {
    return join(q{,}, @retvals);
  }

  $log->error(q{Did not find expected END_OF_OBJECT! at end of array!}) if $log->is_error();
  return;
}

#################################

# Utility functions - does not generate XML output

# Parse and return a given number of bytes (unformatted)
sub _readRaw {
  my $len    = shift;
  $log->logdie("missing length argument") unless $len;
  my $buffer = undef;
  my $num    = read($FH, $buffer, $len);
  return $buffer;
}

# Parse and return a string: The first 2 bytes contains the string
# length, succeeded by the string itself. Read length first unless
# length is given, otherwise read the given number of bytes.
sub _readString {
  my $len    = shift;
  my $buffer = undef;
  my $num    = undef;

  $log->debug(qq{len not given as arg}) if $log->is_debug() && !$len;

  # read length from filehandle unless set
  $len = join(q{}, _readShort(2)) unless ($len);

  # return undef if length is zero
  return unless $len;

  $log->debug(qq{len:$len}) if $log->is_debug();
  $num = read($FH, $buffer, $len);
  if ($log->is_debug()) {
    $log->debug(qq{buffer:} . uri_escape($buffer));
  }
  return $buffer;
}

# Parse and return a given number of bytes
sub _readBytes {
  my $len    = shift || 1;
  my $buffer = undef;
  my $num    = read($FH, $buffer, $len);
  return unpack 'C*', $buffer;         # An unsigned char (octet) value.
}

# Parse and return signed short (integer) number, default 2 bytes
sub _readSignedShort {
  my $len    = shift || LENGTH_OF_SHORT;
  my $buffer = undef;
  my $num    = read($FH, $buffer, $len);
  (_is_little_endian())
    ? return unpack 's*', reverse $buffer
    : return unpack 's*', $buffer;
}

# Parse and return short (integer) number, default 2 bytes
sub _readShort {
  my $len    = shift || LENGTH_OF_SHORT;
  my $buffer = undef;
  my $num    = read($FH, $buffer, $len);
  (_is_little_endian())
    ? return unpack 'S*', reverse $buffer
    : return unpack 'S*', $buffer;
}

# Parse and return integer number, default 2 bytes
sub _readInt {
  my $len    = shift || LENGTH_OF_INTEGER;
  my $buffer = undef;
  my $num    = read($FH, $buffer, $len);
  return unpack 'C*', reverse $buffer;
}

# Parse and return long integer number, default 4 bytes
sub _readLong {
  my $len    = shift || LENGTH_OF_LONG;
  my $buffer = undef;
  my $num    = read($FH, $buffer, $len);
  return unpack 'C*', reverse $buffer;
}

# Parse and return floating point number: default 8 bytes
sub _readFloat {
  my $len    = shift || LENGTH_OF_FLOAT;
  my $buffer = undef;
  my $num    = read($FH, $buffer, $len);

	# Check special numbers - do not rely on OS/compiler to tell the
	# truth.  
	if ($buffer eq POSITIVE_INFINITY) {
		return q{inf};
	} elsif ($buffer eq NEGATIVE_INFINITY) {
		return q{-inf};
	} elsif ($buffer eq NOT_A_NUMBER) {
		return q{nan};
	}
	
  (_is_little_endian())
    ? return unpack 'd*', reverse $buffer
    : return unpack 'd*', $buffer;
}

#################################

### Functions that gets data and creates XML output

# Get next boolean element. Return 1 if the element's value is
# non-zero, otherwise 0. Add XML node if in XML mode.
sub _getBool {
  my $name = shift;
  my $value = _readBytes(1);

  if ($value !~ qr/^[01]$/) {
    my $orgval = $value;
    $value = ($value) ? 1 : 0;
    $log->warn(qq{Unexpected boolean value '$orgval' was converted to $value}) if $log->is_warn();
  }

  _addXMLElem('boolean', $name, $value);
  return $value;
}

# Get next string element. Return the element's value. Add XML node
# if in XML mode
sub _getString {
  my $name = shift;
  my $value = _readString();
  _addXMLElem('string', $name, $value);
  return $value;
}

# Return floating point number - create XML
sub _getFloat {
  my $name = shift;
  my $value = _readFloat();
  _addXMLElem('number', $name, $value); # Yes it's called number, not float
  return $value;
}

# Return a date object - create XML
sub _getDate {
  my $name = shift;

  # Date consists of a float (8 bytes) value followed by a signed short (2
  # bytes) UTC offset
  my $msec      = _readFloat();
	my $utcoffset = - _readSignedShort(2) / 60;
  $log->debug(qq{msec:$msec utcoffset:$utcoffset}) if $log->is_debug();

  # Create datetime object starting on Jan 1st 1970 and add msec to
  # get the given date
  my $dt = DateTime->from_epoch( epoch => 0 )->add( seconds => $msec / 1000 );

  $writer->comment("DateObject:Milliseconds Count From Jan. 1, 1970; Timezone UTC + Offset.")
    if $writer;
  $writer->startTag(
    'data',
    'type'      => 'date',
    'name'      => $name,
    'msec'      => $msec,
    'date'      => $dt->ymd() . q{ } . $dt->hms(),
    'utcoffset' => $utcoffset,
  ) if $writer;
  $writer->endTag() if $writer;

  my $retval = undef;
  {
    no warnings q{uninitialized}; # allow undef values
    $log->debug(qq{date;$msec;$utcoffset}) if $log->is_debug();
    $retval = qq{date;$msec;$utcoffset};
  }
  return $retval;
}

# Return a pointer.  The value read indicates the element index of the
# element pointed to.
sub _getPointer {
  my $name = shift;

  my $value =_readShort();
  $log->debug(qq{name:$name value:$value}) if $log->is_debug();
  _addXMLElem('pointer', $name, $value); # Yes it's called number, not float
  return $value;
}


##################################################################


# Parse and return file header - 16 bytes in total. Return name if
# file starts with sol header, otherwise undef.  Failure means the
# 'TCSO' tag is missing.
sub _getHeader {

  # skip first 6 bytes
  $log->debug(q{header: skip first 6 bytes}) if $log->is_debug();
  _readString(6);

  # next 4 bytes should contain 'TSCO' tag
  if (_readString(4) ne q{TCSO}) {
    $log->error("missing TCSO - not a sol file") if $log->is_error();
    return; # failure
  }

  # Skip next 7 bytes
  $log->debug(q{header: skip next 7 bytes}) if $log->is_debug();
  _readString(7);

  # Read next byte (length of name) + the name
  my $name = _readString(_readInt(1));
  $log->debug("name:$name") if $log->is_debug();

  # Read version number
  my $version =_readLong();
  $log->debug(qq{header: version:'$version'}) if $log->is_debug();

  # TODO: Add support for version 3 sol files
  if ($version != 0) {
      $log->logdie(qq{SOL version '$version' is unsupported!}) if $log->is_debug();
  }

  return $name; # ok
}

# Parse and return an element. In scalar context, return element
# content as semi colon separated string, in list context return
# element's name, type and value as a list.
sub _getElem {
  my $retval = undef;

  # Read element length and name
  my $name = _readString(_readInt(2));
  #$log->debug(qq{element name:$name}) if $log->is_debug();

  # Read data type and value
  my ($type, $value) = _getTypeAndValue($name);

  # Read trailer (single byte)
  my $trailer = _readBytes(1);
  if ($trailer != 0) {
    $log->warn(qq{Expected 00 trailer, got '$trailer'}) if $log->is_warn();
  }

  {
    no warnings q{uninitialized}; # allow undef values
    $log->info(qq{$name;$type;$value}) if $log->is_info();

    # Context sensitive return
    if (wantarray()) {
      return ($name, $type, $value);
    } else {
      return qq{$name;$type;$value};
    }
  }
}

# parse file and return contents as a textual list
sub to_text {
  my $file = shift;

  $log->logdie( q{Missing argument file.}) if (!$file);
  $log->logdie(qq{No such file '$file'})  if (! -f $file);

  $log->debug("start") if $log->is_debug();

  open($FH,"< $file") || $log->logdie("Error opening file $file");
  $log->debug(qq{file:$file}) if $log->is_debug();
  binmode($FH);

  my @retvals = ();

  # Read header
  my $name = _getHeader() or $log->logdie("Invalid sol header");
  push @retvals, $name;

  # Read data elements
  while (eof($FH) != 1) {
    $log->debug(q{read element}) if $log->is_debug();
    my $string = _getElem();
    push @retvals, $string;
  }

  close($FH) or $log->logdie(q{failed to close filehandle!});

  return @retvals;
}

# Parse file and return contents as a scalar containing XML
# representing the file's content
sub to_xml {
  my $file = shift;

  $log->logdie( q{Missing argument file.}) if (!$file);
  $log->logdie(qq{No such file '$file'})  if (! -f $file);

  $log->debug("start") if $log->is_debug();

  open($FH,"< $file") || $log->logdie("Error opening file $file");
  $log->debug(qq{file:$file}) if $log->is_debug();
  binmode($FH);

  my $output = undef;
  $writer = new XML::Writer(OUTPUT => \$output, DATA_MODE => 1, DATA_INDENT => 4 );

  # Read header
  my $headername = _getHeader() or $log->logdie("Invalid sol header");

  $writer->startTag(
                    'sol',
                    'name'       => $headername,
                    'created_by' => __PACKAGE__,
                    'version'    => $VERSION
                   );

  # Read data elements
  while (eof($FH) != 1) {
    $log->debug(q{read element}) if $log->is_debug();
    my ($name, $type, $value) = _getElem();
  }

  close($FH) or $log->logdie(q{failed to close filehandle!});
  $writer->endTag('sol');
  $writer->end();

  return $output;
}

1;

__END__

=pod

=head1 NAME

Parse::Flash::Cookie - A flash cookie parser.

=head1 SYNOPSIS

  use Parse::Flash::Cookie;
  my @content = Parse::Flash::Cookie::to_text("settings.sol");
  print join("\n", @content);

  my $xml = Parse::Flash::Cookie::to_xml("settings.sol");
  print $xml;

=head1 DESCRIPTION

Local Shared Object (LSO), sometimes known as flash cookies, is a
cookie-like data entity used by Adobe Flash Player.  LSOs are stored
as files on the local file system with the I<.sol> extension.  This
module reads a Local Shared Object file and return content as a list.

=head1 FUNCTIONS

=over

=item to_text

Parses file and return contents as a textual list.

=back

=over

=item to_xml

Parses file and return contents as a scalar containing XML
representing the file's content.

=back


=head1 SOL DATA FORMAT

The SOL files use a binary encoding that is I<little-endian>
regardless of platform architecture. This means the SOL files are
platform independent, but they have to be interpreted differently on
I<little-endian> and I<big-endian> platforms.  See L<perlport> for
more.

It consists of a header and any number of elements.  Both header and
the elements have variable lengths.

=head2 Header

The header has the following structure:

=over

=item * 6 bytes (discarded)

=item * 4 bytes that should contain the string 'TSCO'

=item * 7 bytes (discarded)

=item * 1 byte that signifies the length of name (X bytes)

=item * X bytes name

=item * 4 bytes (discarded)

=back

=head2 Element

Each element has the following structure:

=over

=item * 2 bytes length of element name (Y bytes)

=item * Y bytes element name

=item * 1 byte data type

=item * Z bytes data (depending on the data type)

=item * 1 byte trailer

=back

=head1 TODO

=head2 Pointer

Resolve the value of object being pointed at for datatype
I<pointer> (instead of index).

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-flash-cookie at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-Flash-Cookie>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Parse::Flash::Cookie

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Flash-Cookie>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-Flash-Cookie>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parse-Flash-Cookie>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-Flash-Cookie>

=back

=head1 SEE ALSO

=head2 L<perlport>

=head2 Local Shared Object

http://en.wikipedia.org/wiki/Local_Shared_Object

=head2 Flash coders Wiki doc on .Sol File Format

http://sourceforge.net/docman/?group_id=131628

=head1 ALTERNATIVE IMPLEMENTATIONS

http://objection.mozdev.org/ (Firefox extension, Javascript, by Trevor
Hobson)

http://www.sephiroth.it/python/solreader.php (PHP, by Alessandro
Crugnola)

http://osflash.org/s2x (Python, by Aral Balkan)

=head1 COPYRIGHT & LICENSE

Copyright 2007 Andreas Faafeng, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



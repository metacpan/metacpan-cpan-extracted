# NAME

RF::Antenna::Planet::MSI::Format - RF Antenna Pattern File Reader and Writer in Planet MSI Format

# SYNOPSIS

Read from MSI file

    use RF::Antenna::Planet::MSI::Format;
    my $antenna = RF::Antenna::Planet::MSI::Format->new;
    $antenna->read($filename);

Create a blank object, load data from other sources, then write antenna pattern file.

    my $antenna = RF::Antenna::Planet::MSI::Format->new;
    $antenna->name("My Name");
    $antenna->make("My Make");
    my $file    = $antenna->write($filename);

# DESCRIPTION

This package reads and writes antenna radiation patterns in Planet MSI antenna format.

Planet is a RF propagation simulation tool initially developed by MSI. Planet was a 2G radio planning tool which has set a standard in the early days of computer aided radio network design. The antenna pattern file and the format which is currently known as the ".msi" format or an msi file has become a standard.

# CONSTRUCTORS

## new

Creates a new blank object for creating files or loading data from other sources

    my $antenna = RF::Antenna::Planet::MSI::Format->new;

Creates a new object and loads data from other sources

    my $antenna = RF::Antenna::Planet::MSI::Format->new(
                                                        NAME          => "My Antenna Name",
                                                        MAKE          => "My Manufacturer Name",
                                                        FREQUENCY     => "2437" || "2437 MHz" || "2.437 GHz",
                                                        GAIN          => "10.0" || "10.0 dBd" || "12.15 dBi",
                                                        COMMENT       => "My Comment",
                                                        horizontal    => [[0.00, 0.96], [1.00, 0.04], ..., [180.00, 31.10], ..., [359.00, 0.04]],
                                                        vertical      => [[0.00, 1.08], [1.00, 0.18], ..., [180.00, 31.23], ..., [359.00, 0.18]],
                                                       );

## read

Reads an antenna pattern file and parses the data into the object data structure. Returns the object so that the call can be chained.

    $antenna->read($filename);
    $antenna->read(\$scalar);

Assumptions:
  The first line in the MSI file contains the name of the antenna.  It appears that some vendors suppress the "NAME" token but we always write the NAME token.
  The keys can be mixed case but convention appears to be all upper case keys for common keys and lower case keys for vendor extensions.

## read\_fromZipMember

Reads an antenna pattern file from a zipped archive and parses the data into the object data structure.

    $antenna->read_fromZipMember($zip_filename, $member_filename);

## blob

Returns the data blob that was read by the read($file), read($scalar\_ref), or read\_fromZipMember($,$) methods.

## write

Writes the object's data to an antenna pattern file and returns a Path::Class file object of the written file.

    my $file     = $antenna->write($filename); #isa Path::Class::file
    my $tempfile = $antenna->write;            #isa Path::Class::file in temp directory
    $antenna->write(\$scalar);                 #returns undef with data writen to the variable

## file\_extension

Sets and returns the file extension to use for write method when called without any parameters.

    my $suffix = $antenna->file_extension('.ant');

Default: .msi

Alternatives: .pla, .pln, .ptn, .txt, .ant

## media\_type

Returns the Media Type (formerly known as MIME Type) for use in Internet applications.

Default: application/vnd.planet-antenna-pattern

# DATA STRUCTURE METHODS

## header

Set header values and returns the header data structure which is a hash reference tied to [Tie::IxHash](https://metacpan.org/pod/Tie::IxHash) to preserve header sort order.

Set a key/value pair

    $antenna->header(COMMENT => "My comment");          #upper case keys are common/reserved whereas mixed/lower case keys are vendor extensions

Set multiple keys/values with one call

    $antenna->header(NAME => $myname, MAKE => $mymake);

Read arbitrary values

    my $value = $antenna->header->{$key};

Returns ordered list of header keys

    my @keys = keys %{$antenna->header};

Common Header Keys: NAME MAKE FREQUENCY GAIN TILT POLARIZATION COMMENT

## horizontal

Sets and returns the horizontal data structure for angles with relative loss values from the specified gain in the header.  The data structure is an array reference of array references \[\[$angle1, $value1\], \[$angle2, $value2\], ...\]

Conventions: The industry has standardized on using 360 points from 0 to 359 degrees with non-negative loss values.  The angle 0 is the boresight with increasing values continuing clockwise (e.g., top-down view). Typically, plots show horizontal patterns with 0 degrees pointing up (i.e., North).  This is standard compass convention.

## vertical

Sets and returns the vertical data structure for angles with relative loss values from the specified gain in the header.  The data structure is an array reference of array references \[\[$angle1, $value1\], \[$angle2, $value2\], ...\]

Conventions: The industry has standardized on using 360 points from 0 to 359 degrees with non-negative loss values. The angle 0 is the boresight with increasing values continuing clockwise (e.g., left-side view).  The angle 0 is the boresight pointing towards the horizon with increasing values continuing clockwise where 90 degrees is pointing to the ground and 270 is pointing into the sky.  Typically, plots show vertical patterns with 0 degrees pointing right (i.e., East).

# HELPER METHODS

Helper methods are wrappers around the header data structure to aid in usability.

## name

Sets and returns the name of the antenna in the header structure

    my $name = $antenna->name;
    $antenna->name("My Antenna Name");

Assumed: Less than about 40 ASCII characters

## make

Sets and returns the name of the manufacturer in the header structure

    my $make = $antenna->make;
    $antenna->make("My Antenna Manufacturer");

Assumed: Less than about 40 ASCII characters

## frequency

Sets and returns the frequency string as displayed in header structure

    my $frequency = $antenna->frequency;
    $antenna->frequency("2450");          #correct format in MHz
    $antenna->frequency("2450 MHz");      #acceptable format
    $antenna->frequency("2.45 GHz");      #common format but technically not to spec
    $antenna->frequency("2450-2550");     #common range format but technically not to spec
    $antenna->frequency("2.45-2.55 GHz"); #common range format but technically not to spec

## frequency\_mhz, frequency\_ghz, frequency\_mhz\_lower, frequency\_mhz\_upper, frequency\_ghz\_lower, frequency\_ghz\_upper

Attempts to read and parse the string header value and return the frequency as a number in the requested unit of measure.

## gain

Sets and returns the antenna gain string as displayed in file (dBd is the default unit of measure)

    my $gain = $antenna->gain;
    $antenna->gain("9.1");          #correct format in dBd
    $antenna->gain("9.1 dBd");      #correct format in dBd
    $antenna->gain("9.1 dBi");      #correct format in dBi
    $antenna->gain("(dBi) 9.1");    #supported format

## gain\_dbd, gain\_dbi

Attempts to read and parse the string header value and return the gain as a number in the requested unit of measure.

## tilt

Antenna tilt string as displayed in file.

    my $tilt = $antenna->tilt;
    $antenna->tilt("MECHANICAL");
    $antenna->tilt("ELECTRICAL");

## electrical\_tilt

Antenna electrical\_tilt string as displayed in file.

    my $electrical_tilt = $antenna->electrical_tilt;
    $antenna->electrical_tilt("4"); #4-degree downtilt

## electrical\_tilt\_degrees

Attempts to read and parse the header and return the electrical down tilt in degrees.

    my $degrees = $antenna->electrical_tilt_degrees; #isa number

Note: I recommend storing electrical downtilt in the TILT and ELECTRICAL\_TILT headers like this:

    TILT ELECTRICAL
    ELECTRICAL_TILT 4

However, this method attempts to read as many different formats as found in the source files.

## comment

Antenna comment string as displayed in file.

    my $comment = $antenna->comment;
    $antenna->comment("My Comment");

# SEE ALSO

Format Definition: [http://radiomobile.pe1mew.nl/?The\_program:Definitions:MSI](http://radiomobile.pe1mew.nl/?The_program:Definitions:MSI)

Antenna Pattern File Library [https://www.wireless-planning.com/msi-antenna-pattern-file-library](https://www.wireless-planning.com/msi-antenna-pattern-file-library)

Format Definition from RCC: [https://web.archive.org/web/20080821041142/http://www.rcc.com/msiplanetformat.html](https://web.archive.org/web/20080821041142/http://www.rcc.com/msiplanetformat.html)

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis

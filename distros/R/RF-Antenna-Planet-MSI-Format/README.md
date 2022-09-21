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

Planet is a RF propagation simulation tool initially developed by MSI. Planet was a 2G radio planning tool which has set a standard in the early days of computer aided radio network design. The antenna pattern file and the format which is currently known as ".msi" format or .msi-file has become a standard.

# CONSTRUCTORS

## new

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

## read

Reads an antenna pattern file and parses the data into the object data structure. Returns the object so that the call can be chained.

    $antenna->read($filename);

## write

Writes the object's data to an antenna pattern file and returns a Path::Class file object of the written file.

    my $file     = $antenna->write($filename); #isa Path::Class::file
    my $tempfile = $antenna->write;            #isa Path::Class::file in temp directory
    $antenna->write(\my $scalar_ref);          #returns undef with data writen to the variable

# DATA STRUCTURE METHODS

## header

Set header values and returns the header data structure which is a hash reference tied to [Tie::IxHash](https://metacpan.org/pod/Tie::IxHash) to preserve header sort order.

Set a key/value pair

    $antenna->header(Comment => "My comment");          #will upper case all keys

Set multiple keys/values with one call

    $antenna->header(NAME => $myname, MAKE => $mymake);

Read arbitrary values

    my $value = $antenna->header->{uc($key)};

Returns ordered list of header keys

    my @keys = keys %{$antenna->header};

## horizontal, vertical

Horizontal or vertical data structure for the angle and relative loss values from the specified gain in the header.

Each methods sets and returns an array reference of array references \[\[$angle1, $value1\], $angle2, $value2\], ...\]

Please note that the format uses equal spacing of data points by angle.  Most files that I have seen use 360 one degree measurements from 0 (i.e. boresight) to 359 degrees with values in dB down from the maximum lobe even if that lobe is not the boresight.

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
    $antenna->frequency("2450");     #correct format in MHz
    $antenna->frequency("2450 MHz"); #acceptable format
    $antenna->frequency("2.45 GHz"); #common format but technically not to spec

## frequency\_mhz, frequency\_ghz

Attempts to read and parse the string header value and return the frequency as a number in the requested unit of measure.

## gain

Antenna gain string as displayed in file (dBd is the default unit of measure)

## gain\_dbd, gain\_dbi

Attempts to read and parse the string header value and return the gain as a number in the requested unit of measure.

## electrical\_tilt

Antenna electrical\_tilt string as displayed in file.

    my $electrical_tilt = $antenna->electrical_tilt;
    $antenna->electrical_tilt("MECHINICAL");

## comment

Antenna comment string as displayed in file.

    my $comment = $antenna->comment;
    $antenna->comment("My Comment");

# SEE ALSO

Format Definition: [http://radiomobile.pe1mew.nl/?The\_program:Definitions:MSI](http://radiomobile.pe1mew.nl/?The_program:Definitions:MSI)

Antenna Pattern File Library [https://www.wireless-planning.com/msi-antenna-pattern-file-library](https://www.wireless-planning.com/msi-antenna-pattern-file-library)

# AUTHOR

Michael R. Davis, MRDVT

# COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis

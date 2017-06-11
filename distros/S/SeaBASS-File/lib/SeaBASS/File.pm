package SeaBASS::File;

use strict;
use warnings;

=head1 NAME

SeaBASS::File - Object-oriented interface for reading/writing SeaBASS files

=head1 VERSION

version 0.171600

=cut

our $VERSION = '0.171600'; # VERSION

=head1 SYNOPSIS

To read SeaBASS files:

    use SeaBASS::File qw(STRICT_READ STRICT_WRITE INSERT_BEGINNING INSERT_END);

    my $sb_file = SeaBASS::File->new("input.txt");

    # Calculate the average chlorophyll value using next
    my $chl_total = 0;
    my $measurements = 0;
    
    while (my $row = $sb_file->next()){
        if (defined($row->{'chl'})){
            $chl_total += $row->{'chl'};
            $measurements++;
        }
    }
    if ($measurements){
        print $chl_total/$measurements;
    } else {
        print "No chl values.";
    }
    
    #alternatively:
    $sb_file->rewind();
    while (my %row = $sb_file->next()){
        if (defined($row{'chl'})){
            $chl_total += $row{'chl'};
            $measurements++;
        }
    }

    # Calculate the average chlorophyll value using where
    my $chl_total2 = 0;
    my $measurements2 = 0;
    $sb_file->where(sub {
        if (defined($_->{'chl'})){
            $chl_total2 += $_->{'chl'};
            $measurements2++;
        }
    });
    if ($measurements2){
        print $chl_total2/$measurements2;
    } else {
        print "No chl values.";
    }
    
Or to modify SeaBASS files:

    use SeaBASS::File qw(STRICT_READ STRICT_WRITE INSERT_BEGINNING INSERT_END);

    my $sb_file = SeaBASS::File->new("input.txt");

    # Add a one degree bias to water temperature
    while (my $row = $sb_file->next()){
        $row->{'wt'} += 1;
        $sb_file->update($row);
    }
    
    $sb_file->write(); # to STDOUT

    # Remove the one degree bias to water temperature
    $sb_file->where(sub {
        $_->{'wt'} -= 1;
    });
    
    $sb_file->write("output_file.txt");
    
Or to start a SeaBASS file from scratch:

    use SeaBASS::File qw(STRICT_READ STRICT_WRITE INSERT_BEGINNING INSERT_END);

    my $sb_file = SeaBASS::File->new({strict => 0, add_empty_headers => 1});
    $sb_file->add_field('lat','degrees');
    $sb_file->add_field('lon','degrees');
    $sb_file->append({'lat' => 1, 'lon' => 2});
    $sb_file->append("3,4"); # or if you're reading from a CSV file
    $sb_file->write();

=head1 DESCRIPTION

C<SeaBASS::File> provides an easy to use, object-oriented interface for
reading, writing, and modifying SeaBASS data files.

=head2 What is SeaBASS?

L<SeaWiFS|http://oceancolor.gsfc.nasa.gov> Bio-optical Archive and Storage
System housed at Goddard Space Flight  Center. 
L<SeaBASS|http://seabass.gsfc.nasa.gov/> provides the permanent public
repository for data collected under the auspices of the NASA Ocean Biology and
Biogeochemistry Program. It also houses data collected by participants in the
NASA Sensor Intercomparision and Merger for Biological and Oceanic 
Interdisciplinary Studies (SIMBIOS) Program.  SeaBASS includes marine
bio-optical, biogeochemical, and (some) atmospheric data.

=head2 SeaBASS File Format

SeaBASS files are plain ASCII files with a special header and a matrix of
values.

=head3 Header

The SeaBASS header block consists of many lines of header-keyword pairs.  Some
headers are optional  but most, although technically not required for reading,
are required to be ingested into the system.  More detailed information is
available in the  SeaBASS L<wiki
article|http://seabass.gsfc.nasa.gov/wiki/article.cgi?article=metadataheaders>.
The only absolutely required header for this module to work is the /fields
line.  This module turns fields and units lowercase at all times.

    /begin_header
    /delimiter=space
    /missing=-999
    /fields=date,time,lat,lon,depth,wt,sal
    /end_header
    
=head3 Body

The SeaBASS body is a matrix of data values, organized much like a spreadsheet.
 Each column is separated by the value presented in the  /delimiter header. 
Likewise, missing values are indicated by the value presented in the /missing
header.  The /fields header identifies the geophysical parameter presented in
each column.

    /begin_header
    /delimiter=space
    /missing=-999
    /fields=date,time,lat,lon,depth,wt,sal
    /end_header
    19920109 16:30:00 31.389 -64.702 3.4 20.7320 -999
    19920109 16:30:00 31.389 -64.702 19.1 20.7350 -999
    19920109 16:30:00 31.389 -64.702 38.3 20.7400 -999
    19920109 16:30:00 31.389 -64.702 59.6 20.7450 -999

=head3 Strictly Speaking

SeaBASS files are run through a program called 
L<FCHECK|http://seabass.gsfc.nasa.gov/wiki/article.cgi?article=FCHECK> before
they are submitted and before they are ingested into a NASA relational database
management system. Some of the things it checks for are required
L<headers|http://seabass.gsfc.nasa.gov/wiki/article.cgi?article=metadataheaders>
and proper  L<field
names|http://seabass.gsfc.nasa.gov/wiki/article.cgi?article=stdfields>. All
data must always have an associated depth, time, and location, though these
fields may be placed in the header and are not always required in the data.
Just because this module writes the files does not mean they will pass FCHECK.

Files are case-INsensitive.  Headers are not allowed to have any whitespace.

=cut

use Carp qw(:DEFAULT);
use Fcntl qw(SEEK_SET);
use List::MoreUtils qw(firstidx each_arrayref);
use Date::Calc qw(Add_Delta_Days);
use Scalar::Util qw(looks_like_number);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(STRICT_READ STRICT_WRITE STRICT_ALL INSERT_BEGINNING INSERT_END);
our @EXPORT    = qw();

our $AUTOLOAD;

=head1 EXPORT

This module does not export anything by default.

=head2 STRICT_READ

C<STRICT_READ> is used with the C<strict> option, enabling error messages when
reading header lines and inserting header data.

=head2 STRICT_WRITE

C<STRICT_WRITE> is used with the C<strict> option, enabling error messages when
writing the data to a file/stream.

=head2 STRICT_ALL

C<STRICT_ALL> is used with the C<strict> option, enabling C<STRICT_READ> and
C<STRICT_WRITE>.

=head2 INSERT_BEGINNING 

C<INSERT_BEGINNING> is used with L<insert|/"insert($index, \%data_row |
\@data_row | $data_row | %data_row)"> or L<add_field|/"add_field($field_name [,
$unit [, $position]])"> to insert a data row or field at the beginning of their
respective lists.

=head2 INSERT_END 

C<INSERT_END> is used with L<insert|/"insert($index, \%data_row | \@data_row |
$data_row | %data_row)"> or L<add_field|/"add_field($field_name [, $unit [,
$position]])"> to insert a data row or field at the end of their respective
lists.

=cut

sub STRICT_READ      {1}
sub STRICT_WRITE     {2}
sub STRICT_ALL       {3}
sub INSERT_BEGINNING {0}
sub INSERT_END       {-1}

my %DEFAULT_OPTIONS = (
	default_headers        => {},
	headers                => {},
	preserve_case          => 1,
	keep_slashes           => 0,
	cache                  => 1,
	delete_missing_headers => 0,
	missing_data_to_undef  => 1,
	preserve_comments      => 1,
	add_empty_headers      => 0,
	strict                 => STRICT_WRITE,
	fill_ancillary_data    => 0,
	preserve_header        => 0,
	preserve_detection_limits => 0,
);

#return values for ref()
my %OPTION_TYPES = (
	default_headers        => [ 'ARRAY', 'HASH' ],
	headers                => [ 'ARRAY', 'HASH' ],
	preserve_case          => [''],
	keep_slashes           => [''],
	cache                  => [''],
	delete_missing_headers => [''],
	missing_data_to_undef  => [''],
	preserve_comments      => [''],
	add_empty_headers      => [''],
	strict                 => [''],
	fill_ancillary_data    => [''],
	preserve_header        => [''],
	preserve_detection_limits => [''],
);

# All headers required by STRICT_READ and STRICT_WRITE
my @REQUIRED_HEADERS = qw(
	begin_header
	investigators
	affiliations
	contact
	experiment
	cruise
	data_file_name
	documents
	calibration_files
	data_type
	start_date
	end_date
	start_time
	end_time
	north_latitude
	south_latitude
	east_longitude
	west_longitude
	missing
	delimiter
	units
	end_header
);

# Headers that must be specified, regardless of strictness.
my @ABSOLUTELY_REQUIRED_HEADERS = qw(
	fields
);

# Valid headers used for STRICT_READ and STRICT_WRITE
our @ALL_HEADERS = qw(
	begin_header
	investigators
	affiliations
	contact
	experiment
	cruise
	station
	data_file_name
	documents
	calibration_files
	data_type
	data_status
	start_date
	end_date
	start_time
	end_time
	north_latitude
	south_latitude
	east_longitude
	west_longitude
	cloud_percent
	measurement_depth
	secchi_depth
	water_depth
	wave_height
	wind_speed
	missing
	below_detection_limit
	above_detection_limit
	delimiter
	fields
	units
	end_header
);

# headers that are allowed but are not to be added during add_empty_headers
my @HIDDEN_HEADERS = qw(
	received
);

# what to set the missing value to if it's not defined
our $DEFAULT_MISSING = -999;
our $DEFAULT_BDL = -888;
our $DEFAULT_ADL = -777;

# overly complex data structure only understandable by idiots
# your IQ is the percentage chance that it won't make sense
# IE: my IQ = 40, I have a 60% chance of it making sense to me
my %ANCILLARY = (
	'lat'       => [ { 'north_latitude'    => qr/^(.*?)$/ }, { 'south_latitude' => qr/^(.*?)$/ } ],
	'lon'       => [ { 'east_longitude'    => qr/^(.*?)$/ }, { 'west_longitude' => qr/^(.*?)$/ } ],
	'depth'     => [ { 'measurement_depth' => qr/^(.*?)$/ }, ],
	'date_time' => [ '$date $time', ],
	'date' => [ [ \&julian_to_greg, '$year$julian' ], [ \&julian_to_greg, '$year$jd' ], [ \&julian_to_greg, '$year$sdy' ], '$year$month$day', ],
	'year' => [ { '$date' => qr/^(\d{4})/ }, { 'start_date' => qr/^(\d{4})/ }, ],
	'month' => [ { '$date' => qr/^\d{4}(\d{2})/ }, [ \&julian_to_greg, qr/^\d{4}(\d{2})\d{2}$/, '$year$julian' ], [ \&julian_to_greg, qr/^\d{4}(\d{2})\d{2}$/, '$year$jd' ], [ \&julian_to_greg, qr/^\d{4}(\d{2})\d{2}$/, '$year$sdy' ], { 'start_date' => qr/^\d{4}(\d{2})/ }, ],
	'day'   => [ { '$date' => qr/^\d{6}(\d{2})/ }, [ \&julian_to_greg, qr/^\d{4}\d{2}(\d{2})$/, '$year$julian' ], [ \&julian_to_greg, qr/^\d{4}\d{2}(\d{2})$/, '$year$jd' ], [ \&julian_to_greg, qr/^\d{4}\d{2}(\d{2})$/, '$year$sdy' ], { 'start_date' => qr/^\d{6}(\d{2})/ }, ],
	'time'  => [ '$hour:$minute:$second', ],
	'hour'    => [ { '$time'   => qr/^(\d+):/ },            { 'start_time' => qr/^(\d+):/ }, ],
	'minute'  => [ { '$time'   => qr/:(\d+):/ },            { 'start_time' => qr/:(\d+):/ }, ],
	'second'  => [ { '$time'   => qr/:(\d+)(?:[^:\d]|$)/ }, { 'start_time' => qr/:(\d+)(?:[^:\d]|$)/ }, ],
	'station' => [ { 'station' => qr/^(.*?)$/ }, ],
);

# what fill_ancillary_data adds to each row
#my @FILL_ANCILLARY_DATA = qw(date time date_time lat lon depth);
my @FILL_ANCILLARY_DATA = keys(%ANCILLARY);

my %FIELD_FORMATTING = (
	'year'   => '%04d',
	'month'  => '%02d',
	'day'    => '%02d',
	'julian' => '%03d',
	'sdy'    => '%03d',
	'hour'   => '%02d',
	'minute' => '%02d',
	'second' => '%02d',
);

=head1 CONSTRUCTOR

=head2 new([$filename,] [\%options])

    my $sb_file = SeaBASS::File->new("input_file.txt");
    my $sb_file = SeaBASS::File->new("input_file.txt", { delete_missing_headers => 1 });
    my $sb_file = SeaBASS::File->new("output_file.txt", { add_empty_headers => 1 });
    my $sb_file = SeaBASS::File->new({ add_empty_headers => 1 });

Creates a C<SeaBASS::File> object.  If the file specified exists, the object
can be used to read the file.  If the file specified does not exist, an empty
object is created and will be written to the specified file by default when
invoking C<write()>.

Options should be given in a hash reference to ensure proper argument parsing.
If a file is specified, options can be given as a hash list.

=over 4

=item * default_headers

=item * headers

These two options accept either an array reference or a hash reference.  They
are used to set or override header information.  First, headers are read from
C<default_headers>, then from the data file itself, then are overridden by
whatever is in C<headers>.

Arguments are an array reference of header lines, or a hash reference of
header/value pairs.

    my $sb_file = SeaBASS::File->new({
        default_headers => [
            '/cruise=fake_cruise',
            '/experiment=default_experiment',
        ],
        headers => {
            'experiment' => 'real_experiment',
        },
    });
    
B<Warning:> Modifying the delimiter or missing value will likely break the
object.  Modifying these will change the expected format for all rows.  Do so
with caution.

=item * preserve_case

C<1> or C<0>, default C<1>. Setting this to C<0> will change all values in the
header to lowercase.  Header descriptors (the /header part) are always turned 
to lowercase, as well as all fields and units.

=item * keep_slashes

C<1> or C<0>, default C<0>. Forces the object to keep the / in the beginning of
headers when accessed.  If set to C<1>, when using the L<headers|/"headers([
\%new_headers | \@get_headers | @get_headers ])"> function, they will be
returned with leading slash.

=item * cache

C<1> or C<0>, default C<1>.  Enables caching data rows as they are read.  This
speeds up re-reads and allows the data to be modified.  This is required for
writing files.

=item * delete_missing_headers

C<1> or C<0>, default C<0>.  Any headers that are equal to the /missing header,
NA, or are not defined (when using the C<headers/default_headers> options) are
deleted.  They cannot be retrieved using C<headers> and will not be written.

=item * missing_data_to_undef

C<1> or C<0>, default C<1>.  If any values in the data block are equal to the
/missing, /above_detection_limit, /below_detection_limit headers, they are set
to undef when they are retrieved.

=item * preserve_comments

C<1> or C<0>, default C<1>.  Setting this option to zero will discard any
comments found in the header.

=item * add_empty_headers

C<0>, C<1>, or a string.  If set to a string, this will populate any missing
headers, including optional ones, and will set their value to the string given.
If set to 1, the string 'NA' is used.  This option disables C<STRICT_WRITE>.

=item * strict

    my $sb_file = SeaBASS::File->new("input_file.txt", {strict => STRICT_ALL});
    my $sb_file = SeaBASS::File->new("input_file.txt", {strict => (STRICT_READ | STRICT_WRITE)});
    my $sb_file = SeaBASS::File->new("input_file.txt", {strict => 0});
    my $sb_file = SeaBASS::File->new("input_file.txt", {strict => STRICT_WRITE}); #default

=over 4

=item * C<STRICT_READ>

C<STRICT_READ> will throw errors when reading invalid headers, missing required
ones, or an invalid delimiter.  This may change in future revisions.

=item * C<STRICT_WRITE>

C<STRICT_WRITE> will throw the same errors when writing the data to a file or
stream.  C<STRICT_WRITE> only checks for required headers and invalid headers,
but does not check their values to see if they are actually filled. This may
change in future revisions.

=back

=item * fill_ancillary_data

C<0> or C<1>, default C<0>.  Insert date, time, measurement depth, station, and
location values to the data rows from the headers.  Values are not overridden
if they are already present.  This option is only useful when reading files.

B<Note:> It is bad practice to include these fields in the data if they don't
change throughout the file.  This option is used to remove the burden of
checking whether they are in the data or header.

B<Another odd behavior:> This option will also combine individual date/time
parts in the data (year/month/day/etc) to create more uniform date/time fields.

B<Another odd behavior:> If any part of a date/time is missing, the fields
dependent on it will not be added to the row.

=item * preserve_header

C<0> or C<1>, default C<0>.  Preserves header and comment order.  This option
disables modifying the header, as well, but will not error if you try -- it will
simply not be reflected in the output.

=item * preserve_detection_limits

C<0> or C<1>, default C<0>.  Disables setting values equal to below_detection_limit
or above_detection_limit to null while reading files.  This should only be used
during read-only operation, as there is no telling missing data from data
outside limits.

=back

=cut

sub new {
	my ( $class, $file ) = ( shift, shift );

	my $self = bless( {}, $class );

	my %myoptions;

	if ( ref($file) eq 'HASH' ) {
		%myoptions = ( %DEFAULT_OPTIONS, %$file );
		$file = '';
	} elsif ( ref( $_[0] ) eq 'HASH' ) {
		%myoptions = ( %DEFAULT_OPTIONS, %{ $_[0] } );
	} elsif ( !ref( $_[0] ) ) {
		if ( $#_ % 2 == 1 ) {
			%myoptions = ( %DEFAULT_OPTIONS, @_ );
		} else {
			croak('Even sized list expected');
		}
	} else {
		croak("Arguments not understood.");
	}

	$self->{'options'} = \%myoptions;
	$self->check_options();

	if ( ref($file) eq 'GLOB' ) {
		$self->{'handle'} = $file;
	} elsif ( ref($file) eq 'SCALAR' ) {
		open( my $fh, "<", $file );
		$self->{'handle'} = $fh;
	} elsif ($file) {
		if ( !ref($file) ) {
			if ( -r $file ) {
				open( my $fh, "<", $file );
				$self->{'handle'} = $fh;
			} elsif ( $self->{'options'}{'strict'} & STRICT_READ ) {
				croak("Strict read set, but input file not found or unreadable.");
			} else {
				$self->{'default_write_to'} = $file;
				$file = '';
			}
		} else {
			croak("Invalid parameter, expected file path or file handle.");
		}
	} ## end elsif ($file)
	if ($file) {
		unless ( $self->read_headers() ) {
			unless ( $self->{'options'}{'strict'} & STRICT_READ ) {
				return;
			}
		}
	} else {
		$self->create_blank_file();
	}
	return $self;
} ## end sub new

=head1 OBJECT METHODS

=head2 add_headers(\%headers | \@header_lines | @header_lines)

    $sb_file->add_headers({'investigators' => 'jason_lefler'});
    $sb_file->add_headers(['/investigators=jason_lefler']);
    $sb_file->add_headers('/investigators=jason_lefler');
    
C<add_headers> is used to add or override metadata for a C<SeaBASS::File>, as
well as add comments.

This function can not be used to change fields/units, see 
L<add_field|/"add_field($field_name [, $unit [, $position]])"> and
L<remove_field|/"remove_field($field_name [, ... ])"> for that.

B<Warning:> Modifying the delimiter or missing value halfway through
reading/writing will likely break the object.  Modifying these will change the
expected format for any new or non-cached rows.  Do so with caution.

=cut

sub add_headers {
	my $self    = shift;
	my $success = 1;
	my $strict  = $self->{'options'}{'strict'} & STRICT_WRITE;
	if ( ref( $_[0] ) eq 'HASH' ) {
		while ( my ( $k, $v ) = each( %{ $_[0] } ) ) {
			$success &= $self->validate_header( $k, $v, $strict );
			$self->{'headers'}{$k} = $v;
		}
	} elsif ( ref( $_[0] ) eq 'ARRAY' ) {
		foreach ( @{ $_[0] } ) {
			if ( $_ =~ /^\s*!/ ) {
				push( @{ $self->{'comments'} }, $_ );
			} elsif ( $strict && $_ !~ m"^/" ) {
				carp("Invalid header line: $_");
				$success = 0;
			} else {
				my ( $k, $v ) = split( /=/, $_, 2 );
				$success &= $self->validate_header( $k, $v, $strict );
				$self->{'headers'}{$k} = $v;
			}
		} ## end foreach (@{$_[0]})
	} elsif ( !ref( $_[0] ) ) {
		foreach (@_) {
			if ( $_ =~ /^\s*!/ ) {
				push( @{ $self->{'comments'} }, $_ );
			} elsif ( $strict && $_ !~ m"^/" ) {
				carp("Invalid header line: $_");
				$success = 0;
			} else {
				my ( $k, $v ) = split( /=/, $_, 2 );
				$success &= $self->validate_header( $k, $v, $strict );
				$self->{'headers'}{$k} = $v;
			}
		} ## end foreach (@_)
	} else {
		$success = 0;
	}
	return $success;
} ## end sub add_headers

=head2 headers([ \%new_headers | \@get_headers | @get_headers ])

=head2 head

=head2 h

    my %headers = $sb_file->headers(['investigators']);
    print Dumper(\%headers); # { investigators => 'jason_lefler' }
    
    my ($inv) = $sb_file->headers('investigators');
    print $inv; # jason_lefler
    
    $sb_file->headers({investigators => 'jason_lefler'});
    
    $sb_file->headers()->{'investigators'} = 'jason_lefler';
    
C<headers> is used to read or modify header values.  Given an array reference
of header names, it will return a hash/hash reference with header/value pairs. 
Given a plain list of header names, it will return an array/array reference of
the given header values.  Given a hash reference, this function is a proxy for
L<add_headers|/"add_headers(\%headers | \@header_lines | @header_lines)">.

If C<keep_slashes> is set, then headers will be returned as such, IE: C<<
{'/investigators' => 'jason_lefler'} >>.

This function can also be used to set header values without going through the
normal validation.

C<head> and C<h> are aliases to C<headers>.

=cut

sub head { shift->headers(@_); }
sub h    { shift->headers(@_); }

sub headers {
	my $self = shift;
	if ( !@_ ) {
		return $self->{'headers'};
	} elsif ( ref( $_[0] ) eq 'HASH' ) {
		return $self->add_headers(@_);
	} elsif ( ref( $_[0] ) eq 'ARRAY' ) {
		my %ret;
		for my $header ( @{ $_[0] } ) {
			$ret{$header} = $self->{'headers'}{ lc($header) };
		}
		if (wantarray) {
			return %ret;
		} else {
			return \%ret;
		}
	} else {
		my @ret;
		foreach (@_) {
			if ( !ref ) {
				my $value = $self->{'headers'}{ lc($_) };
				push( @ret, defined($value) ? $value : undef );
			} else {
				croak("Argument not understood: $_");
			}
		} ## end foreach (@_)
		if (wantarray) {
			return @ret;
		} elsif ( $#ret == 0 ) {
			return $ret[0];
		} else {
			return \@ret;
		}
	} ## end else [ if (!@_) ]

} ## end sub headers

=head2 data([$index])

=head2 d

=head2 body

=head2 b

=head2 all

    my $row = $sb_file->data(1);
    my @rows = $sb_file->all();

C<data> is responsible for returning either a data line via an index or all of
the data lines at once.

Data is returned as C<< field => value >> pairs.

If given an index: in list context, returns the hash of the row; in scalar
context, returns a reference to the row.

If not given an index: in list context, returns an array of the rows; in scalar
context, returns a reference to an array of the rows.

If given an index out of range, returns undef.  If given a negative index,
C<rewind>s the file, then returns undef.

If C<cache> is enabled and the row has already been read, it is retrieved from
the cache.  If it has not already be read, all rows leading up to the desired
row will be read and cached, and the desired row returned.

If C<cache> is disabled and either all rows are retrieved or a  previously
retrieved row is called again, the file will C<rewind>, then seek to the
desired row.

C<d>, C<body>, C<b>, and C<all> are all aliases to C<data>.  (Yes, that means
C<all> can be used with arguments, it would just look silly.)

=cut

sub body { shift->data(@_); }
sub b    { shift->data(@_); }
sub d    { shift->data(@_); }
sub all  { shift->data(@_); }

sub data {
	my ( $self, $index ) = @_;
	if ( defined($index) ) {
		if ( $index < 0 ) {
			$self->rewind();
			return;
		}
		if ( $self->{'options'}{'cache'} ) {
			if ( $index > $self->{'max_dataidx'} ) {
				my $startidx = $self->{'dataidx'};
				for ( my $i = 0; $i < ( $index - $startidx ); $i++ ) {
					if ( !$self->next() ) {
						return;
					}
				}
			} ## end if ($index > $self->{'max_dataidx'...})

			$self->{'dataidx'} = $index;

			if (wantarray) {
				return %{ $self->{'data'}[$index] };
			} else {
				return $self->{'data'}[$index];
			}
		} else {
			if ( $index <= $self->{'dataidx'} ) {
				$self->rewind();
			}
			my $startidx = $self->{'dataidx'};
			for ( my $i = 0; $i < ( $index - $startidx - 1 ); $i++ ) {
				if ( !$self->next() ) {
					return;
				}
			}
			return $self->next();
		} ## end else [ if ($self->{'options'}...)]
	} else {
		if ( $self->{'options'}{'cache'} ) {
			while ( $self->next() ) {
				# noop
			}
			if (wantarray) {
				return @{ $self->{'data'} };
			} else {
				return $self->{'data'};
			}
		} else {
			$self->rewind();
			my @data_rows;
			while ( my $data = $self->next() ) {
				push( @data_rows, $data );
			}
			if (wantarray) {
				return @data_rows;
			} else {
				return \@data_rows;
			}
		} ## end else [ if ($self->{'options'}...)]
	} ## end else [ if (defined($index)) ]
} ## end sub data

=head2 next()

    while (my $row = $sb_file->next()){
        print $row->{'lat'};
        ... 
    }
    while (my %row = $sb_file->next()){
        print $row{'lat'};
        ... 
    }
    
Returns the next data row in the file, returning C<undef> when it runs out of
rows.

Data is returned as C<< field => value >> pairs.

In list context, returns a hash of the row.  In scalar context, returns a
reference to the hash of a row.

After a C<rewind>, C<next> will return the very first data hash, then each row
in turn.  If the row has been cached, it's retrieved from the cache instead of
rereading from the file.

=cut

sub next {
	my $self = shift;
	if (@_) {
		croak("invalid number of arguments on next(), expected 0.");
	}

	if ( $self->{'options'}{'cache'} && $self->{'dataidx'} < $self->{'max_dataidx'} ) {
		$self->{'dataidx'}++;

		if (wantarray) {
			return %{ $self->{'data'}[ $self->{'dataidx'} ] };
		} else {
			return $self->{'data'}[ $self->{'dataidx'} ];
		}
	} elsif ( $self->{'handle'} ) {
		my $handle      = $self->{'handle'};
		my $line_number = $self->{'line_number'};

		while ( my $line = <$handle> ) {
			$line_number++;
			strip($line);
			if ($line) {
				my $data_row = $self->make_data_hash($line);
				$self->{'line_number'} = $line_number;
				if ( $self->{'options'}{'cache'} ) {
					push( @{ $self->{'data'} }, $data_row );
				}
				$self->{'dataidx'}++;
				if ( $self->{'dataidx'} > $self->{'max_dataidx'} ) {
					$self->{'max_dataidx'} = $self->{'dataidx'};
				}
				if (wantarray) {
					return %{$data_row};
				} else {
					return $data_row;
				}
			} ## end if ($line)
		} ## end while (my $line = <$handle>)
	} ## end elsif ($self->{'handle'})
	return;
} ## end sub next

=head2 rewind()

C<rewind> seeks to the start of the data.  The next C<next> will return the 
very first row (or C<data(0)>).  If caching is enabled, it will not actually
perform a seek, it will merely reset the index interator.  If caching is
disabled, a seek is performed on the file handle to return to the start of the
data.

=cut

sub rewind {
	my ($self) = @_;
	if ( $self->{'dataidx'} != -1 ) {
		if ( !$self->{'options'}{'cache'} ) {
			seek( $self->{'handle'}, $self->{'data_start_position'}, SEEK_SET );
		}
		$self->{'line_number'} = $self->{'data_start_line'};
		$self->{'dataidx'}     = -1;
	} ## end if ($self->{'dataidx'}...)
} ## end sub rewind

=head2 update(\%data_row | \@data_row | $data_row | %data_row)

    while (my %row = $sb_file->next()){
        if ($row{'depth'} == -999){
            $row{'depth'} = 0;
        }
        $sb_file->update(\%row);
    }
    
    # Less useful for update():
    print join(',',@{$sb_file->actual_fields()}); #lat,lon,depth,chl
    
    while (my %row = $sb_file->next()){
        if ($row{'depth'} == -999){
            $row{'depth'} = 0;
        }
        $sb_file->update(@row{'lat','lon','depth','chl'});
        # or
        $sb_file->update([@row{'lat','lon','depth','chl'}]);
    }

C<update> replaces the last row read (using C<next()>) with the input.

Caching must be enabled to use C<update>, C<set>, or C<insert>.

=cut

sub update {
	my $self = shift;
	if ( !$self->{'options'}{'cache'} ) {
		croak("Caching must be enabled to write.");
	} elsif ( $self->{'dataidx'} == -1 ) {
		croak("No rows read yet.");
	}
	my $new_row = $self->ingest_row(@_);
	unless ( defined($new_row) ) {
		croak("Error parsing inputs");
	}
	$self->{'data'}[ $self->{'dataidx'} ] = $new_row;
} ## end sub update

=head2 set($index, \%data_row | \@data_row | $data_row | %data_row)

    my %row = (lat => 1, lon => 2, chl => 1);
    $sb_file->set(0, \%row);
    
    print join(',',@{$sb_file->actual_fields()}); #lat,lon,chl
    $sb_file->set(0, [1, 2, 1]);
    

C<set> replaces the row  at the given index with the input.  Seeks to the 
given index if it has not been read to yet.  C<croak>s if the file does not go
up to the index specified.

Caching must be enabled to use C<update>, C<set>, or C<insert>.

=cut

sub set {
	my $self  = shift;
	my $index = shift;
	if ( !$self->{'options'}{'cache'} ) {
		croak("Caching must be enabled to write");
	}
	if ( $index < 0 ) {
		croak("Index must be positive integer");
	}
	my $new_row = $self->ingest_row(@_);
	unless ( defined($new_row) ) {
		croak("Error parsing inputs");
	}

	if ( $index > $self->{'max_dataidx'} ) {
		my $current_idx = $self->{'dataidx'};
		$self->data($index);
		$self->{'dataidx'} = $current_idx;

		if ( $index > $self->{'max_dataidx'} ) {
			croak("Index out of bounds.");
		}
	} ## end if ($index > $self->{'max_dataidx'...})

	$self->{'data'}[$index] = $new_row;
} ## end sub set

=head2 insert($index, \%data_row | \@data_row | $data_row | %data_row)

    use SeaBASS::File qw(INSERT_BEGINNING INSERT_END);
    ...
    
    my %row = (lat => 1, lon => 2, chl => 1);
    $sb_file->insert(INSERT_BEGINNING, \%row);
    
    print join(',',@{$sb_file->actual_fields()}); #lat,lon,chl
    
    $sb_file->insert(1, [1, 2, 1]);
    $sb_file->insert(INSERT_END, [1, 2, 1]);
    
Inserts the row into the given position.  C<INSERT_BEGINNING> inserts a new row
at the start of the data, C<INSERT_END> inserts one at the end of the data
block.

The index must be a positive integer, C<INSERT_BEGINNING>, or C<INSERT_END>.

If a row is inserted at the end, the entire data block is read from the file to
cache every row, the row is appended to the end, and the current position is
reset to the original position, so C<next()> will still return the real next
row from the data.

If a row is inserted before the current position, the current position is 
shifted accordingly and will still return the C<next()> real row.

Caching must be enabled to use C<update>, C<set>, or C<insert>.

=cut

sub insert {
	my $self  = shift;
	my $index = shift;
	if ( !$self->{'options'}{'cache'} ) {
		croak("Caching must be enabled to write.");
	}
	if ( $index < INSERT_END ) {
		croak("Index must be positive integer, or INSERT_BEGINNING (beginning), or INSERT_END (end)");
	}
	my $new_row = $self->ingest_row(@_);
	unless ( defined($new_row) ) {
		croak("Error parsing inputs");
	}

	if ( $index == INSERT_END ) {
		my $current_idx = $self->{'dataidx'};
		$self->data();
		$self->{'dataidx'} = $current_idx;
	} elsif ( $index > $self->{'max_dataidx'} ) {
		my $current_idx = $self->{'dataidx'};
		$self->data($index);
		$self->{'dataidx'} = $current_idx;

		if ( $index == $self->{'max_dataidx'} + 1 ) {
			$index = INSERT_END;
		} elsif ( $index > $self->{'max_dataidx'} ) {
			croak("Index out of bounds.");
		}
	} ## end elsif ($index > $self->{'max_dataidx'...})

	if ( $index <= $self->{'dataidx'} && $index != INSERT_END ) {
		$self->{'dataidx'}++;
	}

	$self->{'max_dataidx'}++;

	if ( $index == INSERT_BEGINNING ) {
		unshift( @{ $self->{'data'} }, $new_row );
	} elsif ( $index == INSERT_END ) {
		push( @{ $self->{'data'} }, $new_row );
	} else {
		splice( @{ $self->{'data'} }, $index, 0, $new_row );
	}
} ## end sub insert

=head2 prepend(\%data_row | \@data_row | $data_row | %data_row)

C<prepend> is short for C<insert(INSERT_BEGINNING, ...)>.

=cut

sub prepend {
	my $self = shift;
	$self->insert( INSERT_BEGINNING, @_ );
}

=head2 append(\%data_row | \@data_row | $data_row | %data_row)

C<append> is short for C<insert(INSERT_END, ...)>.

=cut

sub append {
	my $self = shift;
	$self->insert( INSERT_END, @_ );
}

=head2 remove([$index])

If index is specified, it deletes the desired index.  If it is omitted, the
last row read is deleted.  The current position is modified accordingly.

=cut

sub remove {
	my ( $self, $index ) = @_;

	if ( !$self->{'options'}{'cache'} ) {
		croak("Caching must be enabled to write.");
	} elsif ( !defined($index) && $self->{'dataidx'} < 0 ) {
		croak("No rows read yet.");
	}

	if ( !defined($index) ) {
		$index = $self->{'dataidx'};
	}

	if ( $index < 0 ) {
		croak("Index must be positive integer");
	} elsif ( $index > $self->{'max_dataidx'} ) {
		my $current_idx = $self->{'dataidx'};
		$self->data($index);
		$self->{'dataidx'} = $current_idx;

		if ( $index > $self->{'max_dataidx'} ) {
			croak("Index out of bounds.");
		}
	} ## end elsif ($index > $self->{'max_dataidx'...})

	if ( $index <= $self->{'dataidx'} ) {
		$self->{'dataidx'}--;
	}
	$self->{'max_dataidx'}--;

	splice( @{ $self->{'data'} }, $index, 1 );
} ## end sub remove

=head2 where(\&function)

    # Find all rows with depth greater than 10 meters
    my @ret = $sb_file->where(sub {
        if ($_->{'depth'} > 10){
            return $_;
        } else {
            return undef;
        }
    });

    # Delete all measurements with depth less than 10 meters
    $sb_file->where(sub {
        if ($_->{'depth'} < 10){
            $_ = undef;
        }
    });
    
    # Calculate the average chlorophyll value
    my $chl_total = 0;
    my $measurements = 0;
    $sb_file->where(sub {
        if (defined($_->{'chl'})){
            $chl_total += $_->{'chl'};
            $measurements++;
        }
    });
    if ($measurements){
        print $chl_total/$measurements;
    } else {
        print "No chl values.";
    }


Traverses through each data line, running the given function on each row. 
C<$_> is set to the current row.  If C<$_> is set to undefined, C<remove()> is 
called.  Any changes in C<$_> will be reflected in the data.

Any defined value returned is added to the return array.  If nothing is
returned, a 0 is added.

=cut

sub where {
	my ( $self, $function ) = ( shift, shift );
	if ( ref($function) ne 'CODE' ) {
		croak("Invalid arguments.");
	}
	my $currentidx = $self->{'dataidx'};
	$self->rewind();

	my @new_rows;

	while ( my $row = $self->next() ) {
		local *_ = \$row;
		my $ret = $function->();
		if ( defined($ret) && defined(wantarray) ) {
			push( @new_rows, $ret );
		}
		if ( !defined($row) ) {
			if ( $self->{'dataidx'} <= $currentidx ) {
				$currentidx--;
			}
			$self->remove();
		} ## end if (!defined($row))
	} ## end while (my $row = $self->next...)

	$self->data($currentidx);

	return @new_rows;
} ## end sub where

=head2 get_all($field_name [, ... ] [, \%options])

Returns an array/arrayref of all the values matching each given field name. 
This function errors out if no field names are passed in or a non-existent
field is requested.

Available options are:

=over 4

=item * delete_missing

If any of the fields are missing, the row will not be added to any of the
return arrays.  (Useful for plotting or statistics that don't work well with
bad values.)

=back

=cut

sub get_all {
	my $self = shift;
	my %options = ( 'delete_missing' => 0 );
	if ( ref( $_[$#_] ) eq 'HASH' ) {
		%options = %{ pop(@_) };
	}
	if ( !@_ ) {
		croak("get_all must be called with at least one field name");
	}

	my $missing = ( $self->{'options'}{'missing_data_to_undef'} ? undef : $self->{'missing'} );

	my $currentidx = $self->{'dataidx'};
	$self->rewind();

	my @fields = map {lc} @_;    # turn all inputs lowercase

	foreach my $field (@fields) {
		if ( ( firstidx { $_ eq $field } @{ $self->{'actual_fields'} } ) < 0 ) {
			if ( !$self->{'options'}{'fill_ancillary_data'} || ( firstidx { $_ eq $field } keys( %{ $self->{'ancillary'} } ) ) < 0 ) {
				croak("Field $field does not exist");
			}
		}
	} ## end foreach my $field (@fields)

	my @ret = map { [] } @fields;    # make return array of arrays

	while ( my $row = $self->next() ) {
		if ( $options{'delete_missing'} ) {
			my $has_all = 1;
			foreach my $field (@fields) {
				unless ( defined( $row->{$field} ) && ( !defined($missing) || $row->{$field} != $missing ) ) {
					$has_all = 0;
					last;
				}
			} ## end foreach my $field (@fields)
			unless ($has_all) {
				next;
			}
		} ## end if ($options{'delete_missing'...})

		for ( my $i = 0; $i <= $#fields; $i++ ) {
			push( @{ $ret[$i] }, $row->{ $fields[$i] } );
		}
	} ## end while (my $row = $self->next...)

	$self->data($currentidx);

	if ( $#_ == 0 ) {
		if (wantarray) {
			return @{ $ret[0] };
		} else {
			return $ret[0];
		}
	} elsif (wantarray) {
		return @ret;
	} else {
		return \@ret;
	}
} ## end sub get_all

=head2 remove_field($field_name [, ... ])

Removes a field from the file.  C<update_fields> is called to remove the field
from cached rows.  Any new rows grabbed will have the removed fields omitted,
as well.  A warning is issued if the field does not exist.

=cut

sub remove_field {
	my $self = shift;
	if ( !@_ ) {
		croak("Field(s) must be specified.");
	}
	foreach my $field_orig (@_) {
		my $field = lc($field_orig);

		my $field_idx = firstidx { $_ eq $field } @{ $self->{'actual_fields'} };

		if ( $field_idx < 0 ) {
			carp("Field $field does not exist.");
		} else {
			splice( @{ $self->{'actual_fields'} }, $field_idx, 1 );
			splice( @{ $self->{'actual_units'} },  $field_idx, 1 );
		}
	} ## end foreach my $field_orig (@_)
	$self->update_fields();
} ## end sub remove_field

=head2 add_field($field_name [, $unit [, $position]])

Adds a field to the file.  C<update_fields> is called to populate all cached
rows.  Any rows retrieved will have the new field set to undefined or /missing,
depending on if the option C<missing_data_to_undef> is set.

If the unit is not specified, it is set to unitless.

If the position is not specified, the field is added to the end.

=cut

sub add_field {
	my ( $self, $field, $unit, $position ) = @_;
	if ( !$self->{'options'}{'cache'} ) {
		croak("Caching must be enabled to write.");
	} elsif ( !$field ) {
		croak("Field must be specified.");
	}
	$field = lc($field);

	my $field_idx = firstidx { $_ eq $field } @{ $self->{'actual_fields'} };
	if ( $field_idx >= 0 ) {
		croak("Field already exists.");
	}
	if ( !defined($position) ) {
		$position = INSERT_END;
	}
	$unit ||= 'unitless';
	$unit = lc($unit);

	if ( $position == INSERT_END ) {
		push( @{ $self->{'actual_fields'} }, $field );
		push( @{ $self->{'actual_units'} },  $unit );
	} elsif ( $position == INSERT_BEGINNING ) {
		unshift( @{ $self->{'actual_fields'} }, $field );
		unshift( @{ $self->{'actual_units'} },  $unit );
	} else {
		splice( @{ $self->{'actual_fields'} }, $position, 0, $field );
		splice( @{ $self->{'actual_units'} },  $position, 0, $unit );
	}
	$self->update_fields();
} ## end sub add_field

=head2 find_fields($string | qr/match/ [, ... ])

Finds fields matching the string or regex given.   If given a string, it must
match a field exactly and entirely to be found.  To find a substring, use
C<qr/chl/>.  Fields are returned in the order that they will be output.  This
function takes into account fields that are added or removed.  All fields are
always lowercase, so all matches are case insensitive.

Given one argument, returns an array of the fields found.  An empty array is
returned if no fields match.

Given multiple arguments, returns an array/arrayref of arrays of fields found.
IE: C<find_fields('lw','es')> would return something like
C<[['lw510','lw550'],['es510','es550']]>.  If no field is matched, the inner
array will be empty. IE: C<[[],[]]>.

=cut

sub find_fields {
	my $self = shift;
	if ( $#_ < 0 ) {
		croak("Input must be a string or regex object.");
	}

	my @ret;

	foreach my $find (@_) {
		my ( $regex, @matching );
		if ( defined($find) ) {
			if ( !ref($find) ) {
				$regex = lc(qr/^$find$/i);
			} elsif ( ref($find) eq 'Regexp' ) {
				$regex = lc(qr/$find/i);
			} else {
				croak("Input must be a string or regex object.");
			}

			foreach my $field ( @{ $self->{'actual_fields'} } ) {
				if ( $field =~ $regex ) {
					push( @matching, $field );
				}
			}
		}
		push( @ret, \@matching );
	} ## end foreach my $find (@_)

	if ( $#_ == 0 ) {
		return @{ $ret[0] };
	} else {
		if (wantarray) {
			return @ret;
		} else {
			return \@ret;
		}
	} ## end else [ if ($#_ == 0) ]
} ## end sub find_fields

=head2 add_comment(@comments)

Adds comments to the output file, which are printed, in bulk, after C</missing>.
Comments are trimmed before entry and !s are added, if required.

=cut

sub add_comment {
	my $self = shift;
	push(@{$self->{'comments'}}, map {
		my $c = $_;
		$c =~ s/^\s+|\s+$//g;
		if ($c =~ /^!/){
			$c
		} else {
			"! $c"
		}
	} @_);
}

=head2 get_comments([@indices])

Returns a list of the comments at the given indices.  If no indices are passed
in, return them all.

=cut

sub get_comments {
	my $self = shift;
	my @ret;
	if (@_){
		@ret = map {$self->{'comments'}[$_]} @_;
	} else {
		@ret = @{$self->{'comments'}};
	}
	if (wantarray){
		return @ret;
	} else {
		return \@ret;
	}
}

=head2 set_comments(@comments)

Overwrites all of the comments in the file.  For now, this is the proper way
to remove comments.  Comments are trimmed before entry and !s are added, if 
required.

=cut

sub set_comments {
	my $self = shift;
	$self->{'comments'} = [map {
		my $c = $_;
		$c =~ s/^\s+|\s+$//g;
		if ($c =~ /^!/){
			$c
		} else {
			"! $c"
		}
	} @_];
}

=head2 write([$filename | $file_handle | \*GLOB])

Outputs the current header and data to the given handle or glob.  If no
arguments are given, and a non-existent filename was given to C<new>, the
contents are output into that.  If an output file was not given, C<write>
outputs to STDOUT.

If C<STRICT_WRITE> is enabled, the headers are checked for invalid headers and
missing required headers and errors/warnings can be thrown accordingly.

The headers are output in a somewhat-arbitrary but consistent order.  If
C<add_empty_headers> is enabled, placeholders are added for every header that
does not exist.  A comment section is also added if one is not present.

=cut

sub write {
	my ( $self, $write_to_h ) = @_;

	my $strict_write = $self->{'options'}{'strict'} & STRICT_WRITE;
	my $slash        = ( $self->{'options'}{'keep_slashes'} ? '/' : '' );
	my $error        = 0;

	if ($strict_write) {
		foreach my $header ( keys( %{ $self->{'headers'} } ) ) {
			( my $header_no_slash = $header ) =~ s"^/"";
			if ( ( firstidx { $_ eq $header_no_slash } @ALL_HEADERS ) < 0 && ( firstidx { $_ eq $header_no_slash } @HIDDEN_HEADERS ) < 0 ) {
				carp("Invalid header: $header");
				$error = 1;
			}
		} ## end foreach my $header (keys(%{...}))

		foreach my $header (@REQUIRED_HEADERS) {
			if ( !exists( $self->{'headers'}{$header} ) ) {
				carp("Missing required header: $header");
				$error = 1;
			}
		} ## end foreach my $header (@REQUIRED_HEADERS)
	} ## end if ($strict_write)

	if ( !$error ) {
		my $close_write_to = 0;
		my $old_fh         = select();

		if ( !$write_to_h && exists( $self->{'default_write_to'} ) ) {
			$write_to_h ||= $self->{'default_write_to'};
		}

		if ( defined($write_to_h) ) {
			if ( ref($write_to_h) eq 'GLOB' ) {
				select($write_to_h);
			} elsif ( !ref($write_to_h) ) {
				my $write_to = $write_to_h;
				$write_to_h = undef;
				open( $write_to_h, ">", $write_to ) || croak("Invalid argument for write().");
				$close_write_to = 1;
				select($write_to_h);
			} else {
				croak("Invalid argument for write().");
			}
		} ## end if (defined($write_to_h...))

		$self->{'headers'}{"${slash}delimiter"} ||= 'comma';
		my $actual_delim = lc( $self->{'headers'}{"${slash}delimiter"} );
		if ( $actual_delim eq 'comma' ) {
			$actual_delim = ',';
		} elsif ( $actual_delim eq 'space' ) {
			$actual_delim = ' ';
		} elsif ( $actual_delim eq 'tab' ) {
			$actual_delim = "\t";
		} elsif ( $actual_delim eq 'semicolon' ) {
			$actual_delim = ';';
		} else {
			$actual_delim = ',';
			$self->{'headers'}{"${slash}delimiter"} = 'comma';
		}

		my $missing = ( exists( $self->{'missing'} ) ? $self->{'missing'} : $DEFAULT_MISSING );
		my $bdl     = ( exists( $self->{'below_detection_limit'} ) ? $self->{'below_detection_limit'} : $DEFAULT_BDL );
		my $adl     = ( exists( $self->{'above_detection_limit'} ) ? $self->{'above_detection_limit'} : $DEFAULT_ADL );

		if ( $self->{'options'}{'preserve_header'} ) {
			print join("\n", @{ $self->{'preserved_header'} }, '');
		} else {
			if ( !exists( $self->{'headers'}{"${slash}begin_header"} ) ) {
				print "/begin_header\n";
			}

			my $add_missing_headers = $self->{'options'}{'add_empty_headers'};
			if ( $add_missing_headers && $add_missing_headers eq '1' ) {
				$add_missing_headers = 'NA';
			}
			if ( !$self->{'options'}{'preserve_case'} ) {
				$add_missing_headers = lc( $add_missing_headers || '' );
			}
			
			my @headers_to_print;
			
			@headers_to_print = @ALL_HEADERS;
			if ($missing eq $adl || ($self->{'options'}{'missing_data_to_undef'} && !$self->{'options'}{'preserve_detection_limits'})){
				@headers_to_print = grep(!/above_detection_limit/i, @headers_to_print);
			}
			if ($missing eq $bdl || ($self->{'options'}{'missing_data_to_undef'} && !$self->{'options'}{'preserve_detection_limits'})){
				@headers_to_print = grep(!/below_detection_limit/i, @headers_to_print);
			}
			
			unless (grep($_ ne 'unitless', @{ $self->{'actual_units'} })){
				@headers_to_print = grep(!/units/i, @headers_to_print);
			}

			foreach my $header (@headers_to_print) {
				if ( $header eq 'missing' ) {
					while ( my ( $h, $k ) = each( %{ $self->{'headers'} } ) ) {
						( my $header_no_slash = $h ) =~ s"^/"";
						if ( ( firstidx { $_ eq $header_no_slash } @ALL_HEADERS ) < 0 ) {
							print "/$h=$k\n";
						}
					} ## end while (my ($h, $k) = each...)

					foreach my $comment ( @{ $self->{'comments'} } ) {
						print "$comment\n";
					}
					if ( !@{ $self->{'comments'} } && $add_missing_headers ) {
						print "! Comments: \n!\n";
					}
					if ( !exists( $self->{'headers'}{"$slash$header"} ) ) {
						print "/missing=$missing\n";
					} else {
						print '/', $header, '=', $self->{'headers'}{"$slash$header"}, "\n";
					}
				} elsif ( $header eq 'fields' ) {
					print "/$header=", join( ',', @{ $self->{'actual_fields'} } ), "\n";
				} elsif ( $header eq 'units' ) {
					print "/$header=", join( ',', @{ $self->{'actual_units'} } ), "\n";
				} elsif ( exists( $self->{'headers'}{"$slash$header"} ) ) {
					if ( $header =~ /_header/ ) {
						print "/$header\n";
					} elsif (length($self->{'headers'}{"$slash$header"})) {
						my $v = $self->{'headers'}{"$slash$header"};
						if ( $header =~ /_latitude|_longitude/ ) {
							print "/$header=$v\[deg]\n";
						} elsif ( $header =~ /_time/ ) {
							print "/$header=$v\[gmt]\n";
						} else {
							print "/$header=$v\n";
						}
#						print '/', $header, '=', $self->{'headers'}{"$slash$header"}, "\n";
					} elsif ($add_missing_headers) {
						if ( $header =~ /_latitude|_longitude/ ) {
							print "/$header=$add_missing_headers\[deg]\n";
						} elsif ( $header =~ /_time/ ) {
							print "/$header=$add_missing_headers\[gmt]\n";
						} else {
							print "/$header=$add_missing_headers\n";
						}
					}
				} elsif ($add_missing_headers) {
					if ( $header =~ /_latitude|_longitude/ ) {
						print "/$header=$add_missing_headers\[deg]\n";
					} elsif ( $header =~ /_time/ ) {
						print "/$header=$add_missing_headers\[gmt]\n";
					} else {
						print "/$header=$add_missing_headers\n";
					}
				} ## end elsif ($add_missing_headers)
			} ## end foreach my $header (@ALL_HEADERS)

			if ( !exists( $self->{'headers'}{"${slash}end_header"} ) ) {
				print "/end_header\n";
			}
		} ## end else [ if ($self->{'options'}...)]

		$self->rewind();

		while ( my $row = $self->next() ) {
			my @values;
			foreach my $field ( @{ $self->{'actual_fields'} } ) {
				push( @values, ( defined( $row->{$field} ) ? $row->{$field} : $missing ) );
			}
			print join( $actual_delim, @values ), "\n";
		} ## end while (my $row = $self->next...)

		select($old_fh);
		if ($close_write_to) {
			close($write_to_h);
		}
	} else {
		croak("Error(s) writing file");
	}
	return;
} ## end sub write

=head2 close()

If a file handle is opened for reading, this function closes it.  This is
automatically called when the object is destroyed.  This is useful to replace
the file being read with the current changes.

=cut

sub close {
	my ($self) = @_;
	if ( $self->{'handle'} ) {
		my $ret = close( $self->{'handle'} );
		delete( $self->{'handle'} );
		return $ret;
	} else {
		return;
	}
} ## end sub close

=head2 make_data_hash($line [,\@field_list])

    my %row = $sb_file->make_data_hash("1.5,2,2.5");
    my %row = $sb_file->make_data_hash("1.5,2,2.5", [qw(lat lon sal)]);
    my %row = $sb_file->make_data_hash("1.5,2,2.5", [$sb_file->fields()]);
    my %row = $sb_file->make_data_hash("1.5,2,2.5", [$sb_file->actual_fields()]);

For mostly internal use.  This function parses a data line.  It first splits
the data via the delimiter, assigns a field to each value, and returns a hash
or hash reference.

If C<@field_list> is not set, C<< $sb_file->fields() >> is used.

If a delimiter is not set (a blank file was created, a file without a 
/delimiter header is read, etc), the delimiter is guessed and set using
L<guess_delim|/"guess_delim($line)">.

C<croak>s if the delimiter could not be guessed or the number of fields the
line is split into does not match up with the field list.

=cut

sub make_data_hash {
	my ( $self, $line, $field_list ) = @_;
	if ( !$self->{'delim'} && !$self->guess_delim($line) ) {
		croak("Need a delimiter");
	}
	my @values = split( $self->{'delim'}, $line );
	$field_list ||= $self->{'fields'};

	my ( $num_expected, $num_got ) = ( scalar( @{ $self->{'fields'} } ), scalar(@values) );
	if ( $num_expected != $num_got ) {
		croak("Incorrect number of fields or elements: got $num_got, expected $num_expected");
	}

	my %ret;

	my $iterator = each_arrayref( $field_list, \@values );
	while ( my ( $k, $v ) = $iterator->() ) {
		if ( $self->{'options'}{'missing_data_to_undef'} ) {
			if ( $self->{'missing_is_number'} && looks_like_number($v) && $v == $self->{'missing'} ) {
				$ret{$k} = undef;
			} elsif ( !$self->{'options'}{'preserve_detection_limits'} && $self->{'adl_is_number'} && looks_like_number($v) && $v == $self->{'above_detection_limit'} ){
				$ret{$k} = undef;
			} elsif ( !$self->{'options'}{'preserve_detection_limits'} && $self->{'bdl_is_number'} && looks_like_number($v) && $v == $self->{'below_detection_limit'} ){
				$ret{$k} = undef;
            } elsif ($v eq $self->{'missing'} || (!$self->{'options'}{'preserve_detection_limits'} && ($v eq $self->{'below_detection_limit'} || $v eq $self->{'above_detection_limit'}))) {
				$ret{$k} = undef;
            } else {
				$ret{$k} = $v;
            }
		} else {
			$ret{$k} = $v;
		}
	} ## end while (my ($k, $v) = $iterator...)
	$self->add_and_remove_fields( \%ret );
	if (wantarray) {
		return %ret;
	} else {
		return \%ret;
	}
} ## end sub make_data_hash

=head2 AUTOLOAD

    print $sb_file->missing();
    print $sb_file->dataidx();
    print $sb_file->actual_fields();
    ...

Returns a few internal variables.  The accessor is read only, but some
variables can be returned as a reference, and can be modified afterwards. 
Though, do it knowing this is a terrible idea.

If the variable retrieved is an array or hash reference and this is called in a
list context, the variable is dereferenced first.

Here are a few "useful" variables:

=over 4

=item * dataidx

The current row index.

=item * max_dataidx

The highest row index read so far.

=item * fields

An array of the original fields.

=item * actual_fields

An array of the current fields, as modified by C<add_field> or C<remove_field>.

=item * delim

The regex used to split data lines.

=item * missing

The null/fill/missing value of the SeaBASS file.

=item * delim

The current line delimiter regex.

=back

=cut

sub AUTOLOAD {
	my $self = shift;
	if ( !ref($self) ) {
		croak("$self is not an object");
	}

	my $name = $AUTOLOAD;
	if ($name) {
		$name =~ s/.*://;
		my $value = $self->{$name};
		if ( !defined($value) ) {
			return;
		}
		if ( ref($value) eq 'ARRAY' && wantarray ) {
			return @{$value};
		} elsif ( ref($value) eq 'HASH' && wantarray ) {
			return %{$value};
		}
		return $value;
	} ## end if ($name)
} ## end sub AUTOLOAD

sub DESTROY {
	my $self = shift;
	$self->close();
}

=head1 INTERNAL METHODS

=head2 check_options()

For internal use only.  This function is in charge of checking the options to
make sure they are of the right type (array/hash reference where appropriate).

If add_empty_headers is set, this function turns off C<STRICT_WRITE>.

Called by the object, accepts no arguments.

=cut

#<<< perltidy destroys this function
sub check_options {
    my $self = shift;
    while (my ($k, $v) = each(%{$self->{'options'}})) {
        if (!exists($DEFAULT_OPTIONS{$k})) {
            croak("Option not understood: $k");
        } elsif ((firstidx { $_ eq ref($v) } @{$OPTION_TYPES{$k}}) < 0) {
            my $expected_ref = join('/', @{$OPTION_TYPES{$k}});
            croak("Option $k not of the right type, expected: " . ($expected_ref ? "$expected_ref reference" : 'scalar'));
        } ## end elsif ((firstidx { $_ eq ...}))
    } ## end while (my ($k, $v) = each...)
    if ($self->{'options'}{'add_empty_headers'}) {
        $self->{'options'}{'strict'} &= STRICT_READ;
    }
} ## end sub check_options
#>>>

=head2 create_blank_file()

For internal use only.  C<create_blank_file> populates the object with proper
internal variables, as well as adding blank headers if C<add_empty_headers> is
set.

By default, the missing value is set to C<$DEFAULT_MISSING> (C<-999>).

This function turns on the C<cache> option, as C<cache> must be enabled to
write.

The delimiter is left undefined and will be guessed upon reading the first data
line using the L<guess_delim|/"guess_delim($line)"> function.

Called by the object, accepts no arguments.

=cut

sub create_blank_file {
	my ($self) = @_;
	$self->{'actual_fields'} = [];
	$self->{'actual_units'}  = [];
	$self->{'fields'}        = [];
	$self->{'units'}         = [];
	$self->{'headers'}       = {};
	$self->{'comments'}      = [];
	$self->{'data'}          = [];
	$self->{'dataidx'}       = -1;
	$self->{'max_dataidx'}   = -1;
	$self->{'delim'}         = undef;
	$self->{'missing'}       = $DEFAULT_MISSING;
	$self->{'below_detection_limit'} = $DEFAULT_BDL;
	$self->{'above_detection_limit'} = $DEFAULT_ADL;

	$self->{'options'}{'cache'}               = 1;
	$self->{'options'}{'fill_ancillary_data'} = 0;

	my $slash = ( $self->{'options'}{'keep_slashes'} ? '/' : '' );
	if ($self->{'options'}{'add_empty_headers'}) {
		foreach (@ALL_HEADERS) {
			if ( !exists( $self->{'headers'}{"${slash}$_"} ) ) {
				$self->{'headers'}{"${slash}$_"} = '';
				if ( $_ eq 'missing' ) {
					$self->{'headers'}{"${slash}missing"} = $DEFAULT_MISSING;
				}
			} ## end if (!exists($self->{'headers'...}))
		} ## end foreach (@ALL_HEADERS)
	} ## end if ($add_missing_headers)

	my $success = 1;
	if ( $self->{'options'}{'default_headers'} ) {
		$success &= $self->add_headers( $self->{'options'}{'default_headers'} );
	}
	if ( $self->{'options'}{'headers'} ) {
		$success &= $self->add_headers( $self->{'options'}{'headers'} );
	}
	unless ($success) {
		croak("Error creating blank file.");
	}
} ## end sub create_blank_file

=head2 read_headers()

For internal use only.  C<read_headers> reads the metadata at the beginning of
a SeaBASS file.

Called by the object, accepts no arguments.

=cut

sub read_headers {
	my $self = shift;

	if ( $self->{'headers'} ) {
		return;
	}

	my $slash = ( $self->{'options'}{'keep_slashes'} ? '/' : '' );
	my $success = 1;
	my @comments;

	$self->{'headers'}  = {};
	$self->{'comments'} = [];

	if ( $self->{'options'}{'default_headers'} ) {
		$success &= $self->add_headers( $self->{'options'}{'default_headers'} );
	}

	my $handle = $self->{'handle'};
	my $position = my $line_number = 0;
	my @header_lines;

	my $strict = $self->{'options'}{'strict'};

	while ( my $line = <$handle> ) {
		$line_number++;
		strip($line);
		if ($line) {
			if ( $line =~ m'^(/end_header)\@?$'i ) {
				push( @header_lines, $1 );
				$position = tell($handle);
				last;
			} elsif ( $line =~ m"^/" ) {
				push( @header_lines, $line );
			} elsif ( $line =~ m"^!" ) {
				push( @comments, $line );
				if ( $self->{'options'}{'preserve_header'} ) {
					push( @header_lines, $line );
				}
			} else { #TODO: search ahead for more headers or comments (in case of merely comment missing !) and fail if READ_STRICT
				seek( $handle, $position, SEEK_SET );
				if ( $strict & STRICT_READ ) {
					carp("File missing /end_header or comment missing !, assuming data start: line #$line_number ($line)");
				}
				last;
			}
		} ## end if ($line)
		$position = tell($handle);
	} ## end while (my $line = <$handle>)

# add_headers looks at STRICT_WRITE, not STRICT_READ
	if ( $strict & STRICT_READ ) {
		$self->{'options'}{'strict'} |= STRICT_WRITE;
	} else {
		$self->{'options'}{'strict'} = 0;
	}

	if ( $self->{'options'}{'preserve_header'} ) {
		$self->{'preserved_header'} = [@header_lines];
	}

	$success &= $self->add_headers( \@header_lines );

# restore strictness
	$self->{'options'}{'strict'} = $strict;

	if ( $self->{'options'}{'headers'} ) {
		$success &= $self->add_headers( $self->{'options'}{'headers'} );
	}

	my %headers = %{ $self->{'headers'} };

	if ( $self->{'options'}{'preserve_comments'} ) {
		push( @{ $self->{'comments'} }, @comments );
	}

	my $missing = $headers{"${slash}missing"} || $DEFAULT_MISSING;
	if ( $self->{'options'}{'delete_missing_headers'} ) {
		while ( my ( $k, $v ) = each(%headers) ) {
			if ( $k =~ m"/?(?:end|begin)_header$|^/?missing$" ) {
				next;
			}
			if ( !defined($v) || $v =~ m"^n/?a(?:\[.*?\])?$"i || lc($v) eq lc($missing) ) {
				delete( $headers{$k} );
			}
		} ## end while (my ($k, $v) = each...)
	} ## end if ($self->{'options'}...)

	if ( $strict & STRICT_READ ) {
		foreach (@REQUIRED_HEADERS) {
			if ( !exists( $headers{"${slash}$_"} ) ) {
				$success = 0;
				carp("Missing required header: $_");
			}
		} ## end foreach (@REQUIRED_HEADERS)
		while ( my ( $header, $value ) = each(%headers) ) {
			if ($slash) {
				$header =~ s"^/"";
			}
			if ( ( firstidx { $_ eq $header } @ALL_HEADERS ) < 0 && ( firstidx { $_ eq $header } @HIDDEN_HEADERS ) < 0 ) {
				$success = 0;
				carp("$header not a standard header.");
			}
		} ## end while (my ($header, $value...))
		if ( $headers{"${slash}begin_header"} || $headers{"${slash}end_header"} ) {
			$success = 0;
			carp("begin_ or end_header incorrect");
		}
	} ## end if ($strict & STRICT_READ)
	foreach (@ABSOLUTELY_REQUIRED_HEADERS) {
		if ( !exists( $headers{"${slash}$_"} ) ) {
			$success = 0;
			if ( $strict & STRICT_READ ) {
				carp("Missing absolutely required header: $_");
			}
		}
	} ## end foreach (@ABSOLUTELY_REQUIRED_HEADERS)

	$self->{'fields'}        = [ split( /\s*,\s*/, $headers{"${slash}fields"} || '' ) ];
	$self->{'actual_fields'} = [ split( /\s*,\s*/, $headers{"${slash}fields"} || '' ) ];

	if ( $headers{"${slash}units"} ) {
		$self->{'units'}        = [ split( /\s*,\s*/, $headers{"${slash}units"} ) ];
		$self->{'actual_units'} = [ split( /\s*,\s*/, $headers{"${slash}units"} ) ];
	} else {
		my (@new_units1);
		foreach ( @{ $self->{'fields'} } ) {
			push( @new_units1, 'unitless' );
		}
		my @new_units2 = @new_units1;
		$self->{'units'}        = \@new_units1;
		$self->{'actual_units'} = \@new_units2;
		$headers{"${slash}units"} = join( ',', @new_units1 );
	} ## end else [ if ($headers{"${slash}units"...})]

	if ( @{$self->{'fields'}} != @{$self->{'units'}} ) {
		if ( $strict & STRICT_READ ) {
			carp("/fields and /units don't match up");
			$success = 0;
		} else {
			while (@{$self->{'fields'}} > @{$self->{'units'}}){
				push(@{$self->{'units'}}, 'unitless');
			}
			while (@{$self->{'fields'}} < @{$self->{'units'}}){
				pop(@{$self->{'units'}});
			}
		}
	}

	unless ($success) {
		if ( $strict & STRICT_READ ) {
			croak("Error(s) reading SeaBASS file");
		} else {
			return;
		}
	}

	$self->{'missing'}               = $missing;
	$self->{'below_detection_limit'} = $headers{"${slash}below_detection_limit"} || $missing;
	$self->{'above_detection_limit'} = $headers{"${slash}above_detection_limit"} || $missing;
	$self->{'line_number'}           = $line_number;
	$self->{'data_start_line'}       = $line_number;
	$self->{'data_start_position'}   = $position;

	if ( $self->{'options'}{'cache'} ) {
		$self->{'data'} = [];
	}
	$self->{'dataidx'}     = -1;
	$self->{'max_dataidx'} = -1;

	$self->{'headers'} = \%headers;

	if ( $self->{'options'}{'fill_ancillary_data'} ) {
		my @fields_lc = map {lc} @{ $self->{'fields'} };
		$self->{'fields_lc'} = \@fields_lc;
		$self->{'ancillary'} = {};

		foreach my $field (@FILL_ANCILLARY_DATA) {
			$self->find_ancillaries($field);
		}

		$self->{'case_conversion'} = {};

		while ( my ( $field, $value ) = each( %{ $self->{'ancillary'} } ) ) {
			my $idx = firstidx { $_ eq $field } @{ $self->{'fields_lc'} };
			my $new_field = $field;
			if ( $idx >= 0 ) {
				$new_field = $self->{'fields'}[$idx];
			}

			if ( ref($value) ) {
				for ( my $i = 1; $i < @$value; $i++ ) {
					my $new_arg = $value->[$i];
					for ( $value->[$i] =~ /\$(\{\w+\}|\w+)/g ) {
						( my $variable = $_ ) =~ s/^\{|\}$//g;

						my $idx = firstidx { $_ eq $variable } @{ $self->{'fields_lc'} };
						my $new_variable = $self->{'fields'}[$idx];

						$new_arg =~ s/\$$variable(\W|\b|$)/\$$new_variable$1/g;
						$new_arg =~ s/\$\{$variable\}/\$$new_variable/g;
					} ## end for ($value->[$i] =~ /\$(\{\w+\}|\w+)/g)
					$value->[$i] = $new_arg;
				} ## end for (my $i = 1; $i <= length...)
			} else {
				my $new_value = $value;
				for ( $value =~ /\$(\{\w+\}|\w+)/g ) {
					( my $variable = $_ ) =~ s/^\{|\}$//g;

					my $idx = firstidx { $_ eq $variable } @{ $self->{'fields_lc'} };
					if ( $idx >= 0 ) {
						my $new_variable = $self->{'fields'}[$idx];

						$new_value =~ s/\$$variable(\W|\b|$)/\$$new_variable$1/g;
						$new_value =~ s/\$\{$variable\}/\$$new_variable/g;
					} ## end if ($idx >= 0)
				} ## end for ($value =~ /\$(\{\w+\}|\w+)/g)
				$value = $new_value;
			} ## end else [ if (ref($value)) ]
			if ( $field ne $new_field ) {
				delete( $self->{'ancillary'}{$field} );
				$self->{'case_conversion'}{$field} = $new_field;
			}
			$self->{'ancillary'}{$new_field} = $value;
		} ## end while (my ($field, $value...))

		delete( $self->{'fields_lc'} );
	} ## end if ($self->{'options'}...)

	return 1;
} ## end sub read_headers

=head2 validate_header($header, $value, $strict)

    my ($k, $v, $string) = ('investigators','jason_lefler',0)
    $sb_file->validate_header($k, $v, $strict);

For internal use only.  C<validate_header> is in charge of properly formatting
key/value pairs to add to the object.  This function will modify the input
variables in place to prepare them for use.

Returns false if there was a problem with the inputs, such as C<strict> is set
and an invalid header was passed in.

C<validate_header> will set C</missing> to C<$DEFAULT_MISSING> (C<-999>) if it
is blank or undefined.

This function will also change the expected delimiter for rows that have not
yet been cached.

=cut

sub validate_header {
	my ( $self, $k, $v, $strict ) = @_;

	my $success = 1;

	if ( !defined($v) ) {
		$v = '';
	} else {
		strip($v);
	}

	strip($k);

	$k = lc($k);

	if ( length($v) == 0 && $k !~ /_header/ ) {
		if ($strict) {
			carp("$k missing value");
			$success = 0;
		} else {
			$v = "";
		}
	} ## end if (length($v) == 0 &&...)

	if ( !$self->{'options'}{'preserve_case'} || $k =~ /fields|units/ ) {
		$v = lc($v);
	}

	if ( $self->{'options'}{'keep_slashes'} ) {
		if ( $k =~ m"^[^/]" ) {
			$k = "/$k";
		}

		if ( $strict && ( firstidx { "/$_" eq $k } @ALL_HEADERS ) < 0 && ( firstidx { "/$_" eq $k } @HIDDEN_HEADERS ) < 0 ) {
			carp("Invalid header, $k");
			$success = 0;
		}
	} else {
		if ( $k =~ m"^/" ) {
			$k =~ s"^/"";
		}

		if ( $strict && ( firstidx { $_ eq $k } @ALL_HEADERS ) < 0 && ( firstidx { $_ eq $k } @HIDDEN_HEADERS ) < 0 ) {
			carp("Invalid header, $k");
			$success = 0;
		}
	} ## end else [ if ($self->{'options'}...)]

	if ( $k =~ /_latitude|_longitude/){
		$v =~ s/\[deg\]$//i;
	} elsif ( $k =~ /_time/){
		$v =~ s/\[gmt\]$//i;
	} elsif ( $k =~ m"^/?delimiter$" ) {
		unless ( $self->set_delim( $strict, $v ) ) {
			if ($strict) {
				$success = 0;
			}
		}
	} elsif ( $k =~ m"^/?missing$" ) {
		$self->{'missing'} = ( length($v) ? $v : $DEFAULT_MISSING );
		$self->{'missing_is_number'} = looks_like_number( $self->{'missing'} );
	} elsif ( $k =~ m"^/?above_detection_limit" ) {
		$self->{'above_detection_limit'} = ( length($v) ? $v : $self->{'missing'} );
		$self->{'adl_is_number'} = looks_like_number( $self->{'above_detection_limit'} );
	} elsif ( $k =~ m"^/?below_detection_limit" ) {
		$self->{'below_detection_limit'} = ( length($v) ? $v : $self->{'missing'} );
		$self->{'bdl_is_number'} = looks_like_number( $self->{'below_detection_limit'} );
	}

	$_[1] = $k;
	$_[2] = $v;

	return $success;
} ## end sub validate_header

=head2 set_delim($strict, $delim)

Takes a string declaring the delim (IE: 'comma', 'space', etc) and updates the
object's internal delimiter regex.

=cut

sub set_delim {
	my $self   = shift;
	my $strict = shift;
	my $delim  = shift || '';
	if ( $delim eq 'comma' ) {
		$delim = qr/\s*,\s*/;
	} elsif ( $delim eq 'semicolon' ) {
		$delim = qr/\s*;\s*/;
	} elsif ( $delim eq 'space' ) {
		$delim = qr/\s+/;
	} elsif ( $delim eq 'tab' ) {
		$delim = qr/\t/;
	} elsif ($strict) {
		carp("delimiter not understood");
	} else {
		my $slash = ( $self->{'options'}{'keep_slashes'} ? '/' : '' );
		$self->{'headers'}{"${slash}delimiter"} = 'comma';
		$delim = undef;
	}
	$self->{'delim'} = $delim;
	return ( $delim ? 1 : 0 );
} ## end sub set_delim

=head2 update_fields()

C<update_fields> runs through the currently cached rows and calls 
C<add_and_remove_fields> on each row.  It then updates the /fields and /units
headers in the header hash.

=cut

sub update_fields {
	my ($self) = @_;
	if ( $self->{'options'}{'cache'} && $self->{'max_dataidx'} >= 0 ) {
		foreach my $hash ( @{ $self->{'data'} } ) {
			$self->add_and_remove_fields($hash);
		}
	}

	my $slash = ( $self->{'options'}{'keep_slashes'} ? '/' : '' );
	$self->{'headers'}{"${slash}fields"} = join( ',', @{ $self->{'actual_fields'} } );
	$self->{'headers'}{"${slash}units"}  = join( ',', @{ $self->{'actual_units'} } );
} ## end sub update_fields

=head2 add_and_remove_fields(\%row)

Given a reference to a row, this function deletes any fields removed with
C<remove_field> and adds an undefined or /missing value for each field added
via C<add_field>.  If C<missing_data_to_undef> is set, an undefined value is
given, otherwise, it is filled with the /missing value.

If C<fill_ancillary_data> is set, this function adds missing date, time,
date_time, lat, lon, and depth fields to the retrieved row from the header.

Needlessly returns the hash reference passed in.

=cut

sub add_and_remove_fields {
	my ( $self, $hash ) = @_;
	foreach my $field ( keys(%$hash) ) {
		if ( ( firstidx { $_ eq $field } @{ $self->{'actual_fields'} } ) < 0 ) {
			unless ( $self->{'options'}{'fill_ancillary_data'} && ( firstidx { $_ eq $field } keys( %{ $self->{'ancillary'} } ) ) >= 0 ) {
				delete( $hash->{$field} );
			}
		}
	} ## end foreach my $field (keys(%$hash...))

	my $missing = ( $self->{'options'}{'missing_data_to_undef'} ? undef : $self->{'missing'} );
	while ( my ( $variable, $pad ) = each(%FIELD_FORMATTING) ) {
		my $case_var = $self->{'case_conversion'}{$variable} || $variable;
		if ( defined( $hash->{$case_var} ) && ( !defined($missing) || $hash->{$case_var} != $missing ) ) {
			$hash->{$case_var} = sprintf( $pad, $hash->{$case_var} );
		}
	} ## end while (my ($variable, $pad...))

	if ( defined($self->{'ancillary'}) ) {
		$self->{'ancillary_tmp'} = {};
		for my $variable (@FILL_ANCILLARY_DATA) {
			if ( defined($self->{'ancillary'}{$variable}) ) {
				my $value = $self->extrapolate_variables( $missing, $self->{'ancillary'}{$variable}, $hash );
				if ( defined($value) ) {
					$hash->{$variable} = $value;
				}
			} ## end if ($self->{'ancillary'...})
		} ## end for my $variable (@FILL_ANCILLARY_DATA)
	} ## end if ($self->{'ancillary'...})

	foreach my $field ( @{ $self->{'actual_fields'} } ) {
		if ( !exists( $hash->{$field} ) ) {
			$hash->{$field} = $missing;
		}
	}

	return $hash;
} ## end sub add_and_remove_fields

=head2 guess_delim($line)

C<guess_delim> is is used to guess the delimiter of a line.  It is not very
intelligent.  If it sees any commas, it will assume the delimiter is a comma.
Then, it checks for tabs, spaces, then semi-colons.  Returns 1 on success.  If
it  doesn't find any, it will throw a warning and return undef.

=cut

sub guess_delim {
	my ( $self, $line ) = @_;
	my $delim_string = '';
	if ( $line =~ /,/ ) {
		my $delim = qr/\s*,\s*/;
		$self->{'delim'} = $delim;
		$delim_string = 'comma';
	} elsif ( $line =~ /\t/ ) {
		my $delim = qr/\t/;
		$self->{'delim'} = $delim;
		$delim_string = 'tab';
	} elsif ( $line =~ /\s+/ ) {
		my $delim = qr/\s+/;
		$self->{'delim'} = $delim;
		$delim_string = 'space';
	} elsif ( $line =~ /;/ ) {
		my $delim = qr/\s*;\s*/;
		$self->{'delim'} = $delim;
		$delim_string = 'semicolon';
	} else {
		carp("No delimiter defined or can be guessed");
		return;
	}
	$self->{'headers'}{ ( $self->{'options'}{'keep_slashes'} ? '/' : '' ) . 'delimiter' } = $delim_string;
	return 1;
} ## end sub guess_delim

=head2 ingest_row(\%data_row | \@data_row | $data_row | %data_row)

For mostly internal use, parses arguments for C<set>, C<update>, and C<insert>
and returns a hash or hash reference of the data row.  Given a hash reference,
it will merely return it.

Given an array or array reference, it will assume each element is a field as
listed in either C<actual_fields> or C<fields>.   If the number of elements
matches C<actual_fields>, it uses assumes it's that. If it doesn't match, it is
tried to match against C<fields>.  If it doesn't  match either, a warning is
issued and the return is undefined.

Given a non-reference scalar, it will split the scalar based on the current
delimiter.  If one is not defined, it is guessed.  If it cannot be guessed, the
return is undefined.

If the inputs are successfully parsed, all keys are turned lowercase.

=cut

sub ingest_row {
	my $self = shift;
	my %new_row;
	if ( $#_ < 0 ) {
		carp("Incorrect number of arguments to ingest_row()");
		return;
	}
	my $arrayref;
	if ( ref( $_[0] ) eq 'HASH' ) {
		%new_row = %{ shift(@_) };
	} elsif ( ref( $_[0] ) eq 'ARRAY' ) {
		$arrayref = $_[0];
	} elsif ( !ref( $_[0] ) ) {
		if ( $#_ == 0 ) {
			if ( !$self->{'delim'} && !$self->guess_delim( $_[0] ) ) {
				return;
			}
			$arrayref = [ split( $self->{'delim'}, $_[0] ) ];
		} elsif ( $#_ % 2 == 1 ) {
			%new_row = @_;
		} else {
			carp('Even sized list, scalar, or hash/array reference expected');
			return;
		}
	} else {
		carp("Arguments to ingest_row() not understood.");
		return;
	}

	if ($arrayref) {
		my $iterator;
		if ( scalar( @{ $self->{'actual_fields'} } ) == scalar( @{$arrayref} ) ) {
			$iterator = each_arrayref( $self->{'actual_fields'}, $arrayref );
		} elsif ( scalar( @{ $self->{'fields'} } ) == scalar( @{$arrayref} ) ) {
			$iterator = each_arrayref( $self->{'fields'}, $arrayref );
			$self->add_and_remove_fields( \%new_row );
		} else {
			my $actual_fields = scalar( @{ $self->{'actual_fields'} } );
			my $fields        = scalar( @{ $self->{'fields'} } );
			if ( $actual_fields == $fields ) {
				carp("Invalid number of elements, expected $fields");
			} else {
				carp("Invalid number of elements, expected $actual_fields or $fields");
			}
			return;
		} ## end else [ if (scalar(@{$self->{'actual_fields'...}}))]
		while ( my ( $k, $v ) = $iterator->() ) {
			$new_row{$k} = $v;
		}
	} ## end if ($arrayref)

	%new_row = map { lc($_) => $new_row{$_} } keys %new_row;

	if (wantarray) {
		return %new_row;
	} else {
		return \%new_row;
	}
} ## end sub ingest_row

=head2 find_ancillaries($field_name)

Used by C<fill_ancillary_data> to traverse through a field's possible
substitutes in C<%ANCILLARY> and try to find the most suitable replacement. 
Values of fields in C<%ANCILLARY> are array references, where each element is
either:

=over 4

=item * a string of existing field names used to create the value

=item * an array reference of the form [converter function, parsing regex 
(optional), arguments to converter, ... ]

=item * a hash reference of the form { header => qr/parsing_regex/ }

=back

If the element is an array reference and an argument requires a field from the
file, all arguments are parsed and the variables within them extrapolated, then
the array is put into C<< $self->{'ancillary'} >>.

If no value can be ascertained, it will not be added to the data rows.

The value found is stored in C<< $self->{'ancillary'} >>.  Returns 1 on
success, 0 if the field cannot be filled in.

=cut

sub find_ancillaries {
	my ( $self, $field ) = @_;
	if ( $self->{'ancillary'}{$field} ) {
		return 1;
	}
	my $idx = firstidx { $_ eq $field } @{ $self->{'fields_lc'} };
	if ( $idx >= 0 ) {
		$self->{'ancillary'}{$field} = "\$\{$field\}";
		return 1;
	}

	my $slash = ( $self->{'options'}{'keep_slashes'} ? '/' : '' );
	foreach my $attempt ( @{ $ANCILLARY{$field} || [] } ) {
		if ( ref($attempt) eq 'HASH' ) {
			keys( %{$attempt} );    #reset each() iterator between calls
			while ( my ( $where, $regex ) = each( %{$attempt} ) ) {
				if ( $where =~ /^\$/ ) {
					if ( ( firstidx { "\$$_" eq $where } $self->fields() ) >= 0 ) {
						$self->{'ancillary'}{$field} = [ sub { return shift; }, $regex, $where ];
						return 1;
					}
				} elsif ( defined( $self->{'headers'}{"$slash$where"} ) && $self->{'headers'}{"$slash$where"} =~ $regex && lc($1) ne 'na' ) {
					$self->{'ancillary'}{$field} = $1;
					return 1;
				}
			} ## end while (my ($where, $regex...))
		} elsif ( ref($attempt) eq 'ARRAY' ) {
			my @attempt  = @$attempt;
			my $function = shift(@attempt);
			my $regex;
			if ( ref( $attempt[0] ) eq 'Regexp' ) {
				$regex = shift(@attempt);
			}
			my $success = 1;
			my @args;
			foreach my $argument (@attempt) {
				my $tmparg = $argument;
				for ( $argument =~ /\$(\{\w+\}|\w+)/g ) {
					( my $variable = $_ ) =~ s/^\{|\}$//g;
					$success &= $self->find_ancillaries($variable);
					if ($success) {
						if ( ref( $self->{'ancillary'}{$variable} ) ) {
							$tmparg =~ s/\$$variable(\W|\b|$)/\$\{$variable\}$1/g;
						} else {
							my $value = $self->{'ancillary'}{$variable};
							$tmparg =~ s/\$$variable(\W|\b|$)/$value$1/g;
							$tmparg =~ s/\$\{$variable\}/$value/g;
						}
					} else {
						last;
					}
				} ## end for ($argument =~ /\$(\{\w+\}|\w+)/g)
				push( @args, $tmparg );
			} ## end foreach my $argument (@attempt)
			if ($success) {
				if ($regex) {
					unshift( @args, $regex );
				}
				$self->{'ancillary'}{$field} = [ $function, @args ];
				return 1;
			} ## end if ($success)
		} elsif ( !ref($attempt) ) {
			my $success = 1;
			my $tmparg  = $attempt;
			for ( $attempt =~ /\$(\{\w+\}|\w+)/g ) {
				( my $variable = $_ ) =~ s/^\{|\}$//g;
				$success &= $self->find_ancillaries($variable);
				if ($success) {
					if ( ref( $self->{'ancillary'}{$variable} ) ) {
						$tmparg =~ s/\$$variable(\W|\b|$)/\$\{$variable\}$1/g;
					} else {
						my $value = $self->{'ancillary'}{$variable};
						$tmparg =~ s/\$$variable(\W|\b|$)/$value$1/g;
						$tmparg =~ s/\$\{$variable\}/$value/g;
					}
				} else {
					last;
				}
			} ## end for ($attempt =~ /\$(\{\w+\}|\w+)/g)
			if ($success) {
				$self->{'ancillary'}{$field} = $tmparg;
				return 1;
			}
		} ## end elsif (!ref($attempt))
	} ## end foreach my $attempt (@{$ANCILLARY...})

	return 0;
} ## end sub find_ancillaries

=head2 extrapolate_variables($missing, $expression, \%row)

Used by C<add_and_remove_fields> to convert a parsed ancillary string, such as
C<'$year$month$day'>, into a real value using the fields from the C<\%row>.
C<$expression>s are strings figured out by C<find_ancillaries> and stored in
C<< $self->{'ancillary'} >>.

The return is undefined if a value cannot be created (IE: a required field is
missing).

=cut

sub extrapolate_variables {
	my ( $self, $missing, $expression, $row ) = @_;

	if ( ref($expression) ) {
		return $self->extrapolate_function( $missing, $expression, $row );
	} else {
		my $tmpexpr = $expression;
		for ( $expression =~ /\$(\{\w+\}|\w+)/g ) {
			( my $variable = $_ ) =~ s/^\{|\}$//g;
			my $value;
			if ( $self->{'ancillary_tmp'}{$variable} ) {
				$value = $self->{'ancillary_tmp'}{$variable};
			} elsif ( defined( $row->{$variable} ) && ( !defined($missing) || $row->{$variable} != $missing ) ) {
				$value = $row->{$variable};
				$self->{'ancillary_tmp'}{$variable} = $value;
			} elsif ( ref( $self->{'ancillary'}{$variable} ) ) {
				$value = $self->extrapolate_function( $missing, $self->{'ancillary'}{$variable}, $row );
				if ( !defined($value) ) {
					return;
				}
			} else {
				return;
			}

			$tmpexpr =~ s/\$$variable(\W|\b|$)/$value$1/g;
			$tmpexpr =~ s/\$\{$variable\}/$value/g;
		} ## end for ($expression =~ /\$(\{\w+\}|\w+)/g)
		return $tmpexpr;
	} ## end else [ if (ref($expression)) ]
} ## end sub extrapolate_variables

=head2 extrapolate_function($missing, $expression, \%row)

If the value stored in C<< $self->{'ancillary'} >> is an array reference, this
function uses the array to create an actual value.  See
L<find_ancillaries|/"find_ancillaries($field_name)"> for an explanation of the
array.

=cut

sub extrapolate_function {
	my ( $self, $missing, $expression, $row ) = @_;
	my $value;
	my ( $function, @args ) = @$expression;
	my $regex;

	if ( ref( $args[0] ) eq 'Regexp' ) {
		$regex = shift(@args);
	}
	for (@args) {
		$_ = $self->extrapolate_variables( $missing, $_, $row );
		if ( !defined($_) ) {
			return;
		}
	} ## end for (@args)
	$value = &$function(@args);
	if ($regex) {
		if ( $value =~ $regex ) {
			$value = $1;
		}
	}

	return $value;
} ## end sub extrapolate_function

=head1 STATIC METHODS

=head2 strip(@list)

    my @space_filled_lines = (' line1 ', ' line2', 'line3 ', 'line4');
    strip(@space_filled_lines);
    print @space_filled_lines; #line1line2line3line4

Runs through the list and removes leading and trailing whitespace.  All changes
are made in place.

It is literally this:

    sub strip {
        s/^\s+|\s+$//g for @_;
    }

=cut

# Not an object method!
sub strip {
	s/^\s+|\s+$//g for @_;
}

=head2 julian_to_greg($yyyyjjj)

Converts a date in the day of year format YYYYJJJ into YYYYMMDD.  Returns the
newly formatted string or undefined if the input does not match the required
format.

This uses the C<Add_Delta_Days> function from C<Date::Calc> to do the heavy
lifting.

=cut

# Not an object method!
sub julian_to_greg {
	my ($yyyyjjj) = @_;
	if ( $yyyyjjj =~ /^(\d{4})(\d{3})$/ ) {
		my ( $y, $m, $d ) = Add_Delta_Days( $1, 1, 1, $2 - 1 );
		return sprintf( '%04d%02d%02d', $y, $m, $d );
	}
	return;
} ## end sub julian_to_greg

=head1 CAVEATS/ODDITIES

=head2 Duplicate Fields

This class will not allow a field to be added to the object if a field of the
same name already exists.  If a file being read has duplicate field names, only
the B<last> one is used.  No warning is issued. If C<remove_field> is used to
remove it, only the first instance will be deleted.  To delete all instances,
use C<< $sb_file->remove_field($sb_file->find_fields('chl')) >>.  This may
change in future releases.

=head2 Changing Delimiter or Missing Value

Modifying the delimiter header on a file that is being read will cause any
non-cached rows to be split by the new delimiter, which should break most/all
files.  If the delimiter must be changed, call C<all()> to cache all the rows,
then change it.  This will obviously not work if caching is turned off.  The
same is true for setting the missing value, but only really applies when the
C<missing_data_to_undef> option is used (same goes to below detection limit).

=head2 Below Detection Limit

Below detection limit is only partially supported.  If C<missing_data_to_undef> is
used, fields equal to C</below_detection_limit> will be set to C<undef>, as
well.  Files modified while using C<missing_data_to_undef> will have all data
equal to C</below_detection_limit> written out set to the missing value instead
of the below detection limit value.  If the below detection limit value is equal
to the missing value or C<missing_data_to_undef> is used, the 
C</below_detection_limit> header will not be written. 

=head1 AUTHOR

Jason Lefler, C<< <jason.lefler at nasa.gov> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-seabass-file at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SeaBASS-File>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SeaBASS::File

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SeaBASS-File>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SeaBASS-File>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SeaBASS-File>

=item * Search CPAN

L<http://search.cpan.org/dist/SeaBASS-File/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jason Lefler.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of SeaBASS::File

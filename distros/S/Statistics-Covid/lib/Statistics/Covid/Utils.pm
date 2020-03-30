package Statistics::Covid::Utils;

# various stand-alone utils (static subs so-to-speak)

use 5.006;
use strict;
use warnings;

our $VERSION = '0.23';

use DateTime;
use DateTime::Format::Strptime;
use File::Path;
#use JSON qw/decode_json/;
use JSON::Parse qw/parse_json/;
use Try::Tiny;
use Data::Dump qw/dump pp/;
use File::Find;

# DBIx::Class specific sub to check if a table exists
# just tries to create a resultset based on this table
# which will fail if table does not exist (within the eval).
# the 1st param is a schema-obj (what you get when you do MyApp::Schema->connect($dsn))
# the 2nd is the table name (which accepts % wildcards)
# returns 1 if table exists in db,
#         0 if table does not exist in db
sub	table_exists_dbix_class {
	my ($schema, $tablename) = @_;
	return Statistics::Covid::Utils::table_exists_dbi($schema->storage->dbh, $tablename)
}
# DBI specific sub to check if a table exists
# just tries to create a resultset based on this table
# which will fail if table does not exist (within the eval).
# the 1st param is a DB handle (like the one you get from DBI->connect($dsn)
# the 2nd is the table name (which accepts % wildcards)
# returns 1 if table exists in db,
#         0 if table does not exist in db
# from https://www.perlmonks.org/bare/?node=DBI%20Recipes
sub	table_exists_dbi {
	my ($dbh, $tablename) = @_;
	my @tables = $dbh->tables('','','','TABLE');
	if (@tables) {
		for (@tables) {
			next unless $_;
			return 1 if $_ eq $tablename
		}
	} else {
		eval {
			local $dbh->{PrintError} = 0;
			local $dbh->{RaiseError} = 1;
			$dbh->do(qq{SELECT * FROM $tablename WHERE 1 = 0 });
		};
		return 1 unless $@;
	}
	return 0
}
# returns an arrayref of the files inside the input dir(s) specified
# by $indirs (which can be a scalar for a signle dir or an arrayref for one or more dirs)
# and further, matching the $pattern regex (if specified,
# else no check is made and all files are returned)
# $pattern can be left undefined or it can be a string containing a
# regex pattern, e.g. '\.json$' or can be a precompiled regex
# which apart from the added speed (possibly) offers the flexibility
# of using regex switches, e.g. qr/\.json$/i
sub	find_files {
	# an input dir to search in as a string
	# or one or more input dirs as a hashref
	# is the 1st input parameter:
	my @indirs = (ref($_[0]) eq 'ARRAY') ? @{$_[0]} : ($_[0]);

	# an optional regex pattern as the 2nd param:
	my $pattern = $_[1];

	my $qpattern = undef;
	if( defined $pattern ){
		if( ref($pattern) eq 'Regexp' ){ $qpattern = $pattern }
		else {
			$qpattern = qr/${pattern}/;
			if( ! defined $qpattern ){ warn "error, failed to compile regex '$pattern'."; return undef }
		}
	}

	my @filesfound;
	File::Find::find(defined $pattern ?
	# now this chdir, so -f $File::Find::name does not work!
	sub {
		push @filesfound, $File::Find::name
			if( (-f $_)
			 && ($File::Find::name =~ ${qpattern})
			)
	}
	: 
	sub {
		push @filesfound, $File::Find::name
			if (-f $_)
	}
	, @indirs
	); # and of File::Find::find
	return \@filesfound
}
sub	make_path {
	my $adir = $_[0];
	if( ! -d $adir ){
		if( ! File::Path::make_path($adir) ){
			warn "error, failed to create dir '$adir', $!";
			return 0
		}
	}
	return 1 # success
}
sub	configfile2perl {
	my $infile = $_[0];
	my $fh;
	if( ! open $fh, '<:encoding(UTF-8)', $infile ){ warn "error, failed to open file '$infile' for reading, $!"; return undef }
	my $json_contents = undef;
	{local $/ = undef; $json_contents = <$fh> } close($fh);
	my $inhash = Statistics::Covid::Utils::configstring2perl($json_contents);
	if( ! defined $inhash ){ warn "error, call to ".'Statistics::Covid::Utils::configstring2perl()'." has failed for file '$infile'."; return undef }
	return $inhash
}
sub	configstring2perl {
	my $json_contents = $_[0];
	# now remove comments
	$json_contents =~ s/#.*$//mg;
	my $inhash = Statistics::Covid::Utils::json2perl($json_contents);
	if( ! defined $inhash ){ warn $json_contents."\n\nerror, call to ".'Statistics::Covid::Utils::json2perl()'." has failed for above json string."; return undef }
	return $inhash
}
#sub json2perl { return JSON::decode_json($_[0]) }
sub json2perl { return JSON::Parse::parse_json($_[0]) }
sub	save_perl_var_to_localfile {
	my ($avar, $outfile) = @_;
	my $outfh;
	if( ! open $outfh, '>:encoding(UTF-8)', $outfile ){
		warn "error, failed to open file '$outfile' for writing json content, $!";
		return 0;
	}
	print $outfh Data::Dump::dump $avar;
	close $outfh;
	return 1;
}
sub	save_text_to_localfile {
	my ($text, $outfile) = @_;
	my $outfh;
	if( ! open $outfh, '>:encoding(UTF-8)', $outfile ){
		warn "error, failed to open file '$outfile' for writing text content, $!";
		return 0;
	}
	print $outfh $text;
	close $outfh;
	return 1;
}
# converts an ISO8601 date string to DateTime object
# which is something like:
#	 2020-03-21T22:47:56
# or 2020-03-21T22:47:56Z <<< timezone is UTC
sub iso8601_to_DateTime {
	my $datespec = $_[0];
	my $ret = undef;
	# check if we have timezone, else we add a UTC ('UTC' or 'Z')
	if( $datespec !~ m/(Z|[+-](?:2[0-3]|[01][0-9])(?::?(?:[0-5][0-9]))?)$/ ){ $datespec .= 'UTC' }
	try {
		my $parser = DateTime::Format::Strptime->new(
			# %Z covers both string timezone (e.g. 'UTC') and '+08:00'
			pattern => '%FT%T%Z',
			locale => 'en_GB',
			time_zone => 'UTC',
			on_error => sub { warn "error, failed to parse date: ".$_[1] }
		);
		if( ! defined $parser ){ warn "error, call to ".'DateTime::Format::Strptime->new()'." has failed."; return undef }
		$ret = $parser->parse_datetime($datespec);
	} catch {
		warn "error, failed to parse date '$datespec': $_";
		return undef
	};
	warn "error, call to ".'epoch_seconds_to_DateTime()'." has failed for spec '$datespec'." unless defined $ret;
	return $ret
}
# converts a time that data from the BBC contains (not their fault as they probably get it from the government)
# which is something like:
#   09:00 GMT, 25 March 
# ooops it can have BST as timezone
sub epoch_stupid_date_format_from_the_BBC_to_DateTime {
	my $datespec = $_[0];
	my $ret = undef;
	try {
		if( $datespec !~ /\:/ ){ 
			warn "date has no time, setting time to morning, 09:00 GMT";
			$datespec = '09:00 GMT, '.$datespec;
		} else { $datespec =~ s/BST/GMT/g }
		my $parser = DateTime::Format::Strptime->new(
			pattern => '%H:%M %Z, %d %b %Y', # hour:minute tz, day weekday (our addition: the year!)
			locale => 'en_GB',
			on_error => sub { warn "error, failed to parse date: ".$_[1] }
		);
		if( ! defined $parser ){ warn "error, call to ".'DateTime::Format::Strptime->new()'." has failed."; return undef }
		$ret = $parser->parse_datetime($datespec.' 2020'); # assuming it's the 2020! surely an optimist :(
		if( ! defined $ret ){ warn "error, call to ".'DateTime::Format::Strptime->parse_datetime()'." has failed for date spec: '$datespec'."; return undef }
	} catch {
		warn "error, failed to parse date '$datespec'";
		return undef
	};
	warn "error, call to ".'epoch_seconds_to_DateTime()'." has failed for spec '$datespec'." unless defined $ret;
	return $ret
}
# converts a time in MILLISECONDS since the Unix Epoch to a DateTime obj
sub epoch_milliseconds_to_DateTime {
	my $datespec = $_[0];
	$datespec = substr($datespec, 0,-3); # convert millis to seconds, remove last 3 chars
	my $ret = Statistics::Covid::Utils::epoch_seconds_to_DateTime($datespec);
	warn "error, call to ".'epoch_seconds_to_DateTime()'." has failed for spec '$datespec'." unless defined $ret;
	return $ret
}
# converts a time epoch in SECONDS since the Unix Epoch to a DateTime obj
sub epoch_seconds_to_DateTime {
	my $datespec = $_[0];

	my $ret = undef;
	try {
		$ret = DateTime->from_epoch(
			epoch => $datespec,
			locale => 'en_GB',
			time_zone => 'Europe/London'
		);
	} catch {
		warn "error, call to ".'DateTime->from_epoch()'." has failed for input epoch '$datespec': $_";
		return undef
	};
	return $ret
}
sub	objects_equal { return Statistics::Covid::IO::DualBase::objects_equal(@_) }
sub	dbixrow2string {
	my %rowhash = @_; # get_columns() returns this hash
	my $ret = "";
	$ret .= $_ . '=>' . $rowhash{$_} . "\n" for sort { $a cmp $b } keys %rowhash;
	return $ret;
}
# create a string timestamp of current (now)
# date and time as a string, to be used in creating filenames for example.
# it takes an optional timezone parameter ($tz) which L<DateTime> must understand
# or do not specify one for using the default, at your local system
sub	make_timestamped_string {
	my $tz = $_[0];
	my %dtparams = ();
	$dtparams{time_zone} = $tz if defined $tz;
	my $dt = DateTime->now(%dtparams);
	if( ! defined $dt ){ warn pp(\%dtparams)."\nerror, call to DateTime->now() has failed for the above params."; return undef }
	return $dt->ymd('-') . '_' . $dt->hms('.')
}
# given an increasing sequence of seconds, e.g. 1,3,56,89,...
# which also includes a sequence of increasing Unix-epoch seconds (i.e. sorted asc.)
# convert it to hours or 6-hour units or 24-hour units etc.
# the conversion happens IN-PLACE!
sub	discretise_increasing_sequence_of_seconds {
	my $inarr = $_[0];
	my $unit = $_[1]; # 3600 will convert the seconds to hours and 3600*24 to days
	my $offset = defined($_[2]) ? $_[2] : 0;
	my $t0 = $inarr->[0];
	$_ = ($offset+($_-$t0)/$unit) for @$inarr;
}
# this will take an array of Datum objects and a set of one or more
# (table) column names (attributes of each object), e.g. 'confirmed'
# and will create a hash, where keys are column names
# and values are arrays of the values for that column name for each object
# in the order they appear in the input array.
# A datum object has column names and each one has values (e.g. 'confirmed', 'name' etc)
# for clarity let's say that our datum objects have column names sex,age,A
# here they are (unquoted): (m,30,1), (m,31,2), (f,40,3), (f,41,4)
# a DF (dataframe) with no params will be created and returned as:
#     { '*' => {sex=>[m,m,f,f], age=>[30,30,40,40], A=>[1,2,3,4]} }
# which is equivalent to @groupby=() and @content_columns=(sex,age,A) (i.e. all columns)
# a DF groupped by column 'sex' will be
#     {
#       'm' => {sex=>[m,m], age=>[30,30], A=>[1,2]]},
#       'f' => {sex=>[f,f], age=>[40,40], A=>[3,4]]},
#     }
# and a DF groupped by 'sex' and 'age':
#     {
#       'm|30' => {sex=>[m,m], age=>[30,30], A=>[1,2]]},
#       'f|40' => {sex=>[f,f], age=>[40,40], A=>[3,4]]},
#     }
# notice that m|40 does not exist as it is not an existing combination in the data
# notice also that by specifying @content_columns, you make your DF leaner.
# e.g. why have sex in the hash when is also a key?
sub	datums2dataframe {
	my $params = $_[0];
	# this is required parameter
	my $objs = exists($params->{'datum-objs'}) ? $params->{'datum-objs'} : undef;
	if( ! defined($objs) || scalar(@$objs)==0 ){ warn "error, no objects specified with first parameter."; return undef }

	# these are optional parameters
	# the default for this is to groupby nothing
	my @groupby = exists($params->{'groupby'})&&defined($params->{'groupby'}) ? @{$params->{'groupby'}} : ();
	my $NGB = scalar @groupby;

	# the default for this is to include all columns
	# be as specific as possible so as not to return huge dataframes and on the other hand
	# not to create a dataframe for each column (inmo), as a compromise create a dataframe
	# only for the markers (confirmed, unconfirmed, etc.) and not for belongsto etc. (which can be for grouping by)
	my @content_columns = defined($params->{'content'}) ? @{$params->{'content'}} : @{$objs->[0]->column_names()};
	my $NCC = scalar @content_columns;

	# make sure that all column names exist in the first object (for the rest...)
	my $anobj = $objs->[0];
	my ($acn, $agn, $agv, $m);
	foreach $acn (@content_columns){ if( ! $anobj->column_name_is_valid($acn) ){ warn "error, column name '$acn' does not exist."; return undef } }
	foreach $agn (@groupby){ if( ! $anobj->column_name_is_valid($agn) ){ warn "error, group-by columns name '$agn' does not exist."; return undef } }

	# and start the grouping
	my %ret;
	for $anobj (@$objs){
		# create a key for the 'groupby' columns, its values will be an arrayref of data from the @content_columns
		# key is formed by values of the columns, e.g. if groupby column is sex, then keys will be 'm' and 'f'
		# and the values for key 'm' will be only for those datums with sex=m
		# and for key 'f' values will be only for datums with sex=f
		# if groupby is empty, then key is '*'
		if( $NGB == 0 ){ $agv = '*' } else {
			$agv = join('|', map { $anobj->column_value($_) } @groupby);
		}
		if( ! exists $ret{$agv} ){
			$ret{$agv} = $m = {};
			for $acn (@content_columns){ $m->{$acn} = [] }
		} else { $m = $ret{$agv} }
		for $acn (@content_columns){
			push @{$m->{$acn}}, $anobj->column_value($acn)
		}
	}
	return \%ret
}
1;
__END__
# end program, below is the POD
=pod

=encoding UTF-8

=head1 NAME

Statistics::Covid::Utils - assorted, convenient, stand-alone, public and semi-private subroutines

=head1 VERSION

Version 0.23

=head1 DESCRIPTION

This package contains assorted convenience subroutines.
Most of which are private or semi-private but some are
required by module users.

=head1 SYNOPSIS

	use Statistics::Covid;
	use Statistics::Covid::Datum;
	use Statistics::Covid::Utils;

	# read data from db
	$covid = Statistics::Covid->new({   
		'config-file' => 't/config-for-t.json',
		'debug' => 2,
	}) or die "Statistics::Covid->new() failed";
	# retrieve data from DB for selected locations (in the UK)
	# data will come out as an array of Datum objects sorted wrt time
	# (the 'datetimeUnixEpoch' field)
	my $objs = $covid->select_datums_from_db_for_specific_location_time_ascending(
		#{'like' => 'Ha%'}, # the location (wildcard)
		['Halton', 'Havering'],
		#{'like' => 'Halton'}, # the location (wildcard)
		#{'like' => 'Havering'}, # the location (wildcard)
		'UK', # the belongsto (could have been wildcarded)
	);
	# create a dataframe
	my $df = Statistics::Covid::Utils::datums2dataframe({
		'datum-objs' => $objs,
		'groupby' => ['name'],
		'content' => ['confirmed', 'datetimeUnixEpoch'],
	});
	# convert all 'datetimeUnixEpoch' data to hours, the oldest will be hour 0
	for(sort keys %$df){
		Statistics::Covid::Utils::discretise_increasing_sequence_of_seconds(
			$df->{$_}->{'datetimeUnixEpoch'}, # in-place modification
			3600 # seconds->hours
		)
	}

	# This is what the dataframe looks like:
	#  {
	#  Halton   => {
	#		confirmed => [0, 0, 3, 4, 4, 5, 7, 7, 7, 8, 8, 8],
	#		datetimeUnixEpoch => [
	#		  1584262800,
	#		  1584349200,
	#		  1584435600,
	#		  1584522000,
	#		  1584637200,
	#		  1584694800,
	#		  1584781200,
	#		  1584867600,
	#		  1584954000,
	#		  1585040400,
	#		  1585126800,
	#		  1585213200,
	#		],
	#	      },
	#  Havering => {
	#		confirmed => [5, 5, 7, 7, 14, 19, 30, 35, 39, 44, 47, 70],
	#		datetimeUnixEpoch => [
	#		  1584262800,
	#		  1584349200,
	#		  1584435600,
	#		  1584522000,
	#		  1584637200,
	#		  1584694800,
	#		  1584781200,
	#		  1584867600,
	#		  1584954000,
	#		  1585040400,
	#		  1585126800,
	#		  1585213200,
	#		],
	#	      },
	#  }

	# and after converting the datetimeUnixEpoch values to hours and setting the oldest to t=0
	#  {
	#  Halton   => {
	#                confirmed => [0, 0, 3, 4, 4, 5, 7, 7, 7, 8, 8, 8],
	#                datetimeUnixEpoch => [0, 24, 48, 72, 104, 120, 144, 168, 192, 216, 240, 264],
	#              },
	#  Havering => {
	#                confirmed => [5, 5, 7, 7, 14, 19, 30, 35, 39, 44, 47, 70],
	#                datetimeUnixEpoch => [0, 24, 48, 72, 104, 120, 144, 168, 192, 216, 240, 264],
	#              },
	#  }


=head2 datums2dataframe

It will take an array of Datum objects and a set of one or more
(table) column names (attributes of each object), e.g. 'confirmed'
and will create a hash, where keys are column names
and values are arrays of the values for that column name for each object
in the order they appear in the input array.
A datum object has column names and each one has values (e.g. C<'confirmed'>, C<'name'> etc.)
for clarity let's say that our datum objects have column names sex,age,A
here they are (unquoted): C<(m,30,1), (m,31,2), (f,40,3), (f,41,4)>
a DF (dataframe) with no params will be created and returned as:

    { '*' => {sex=>[m,m,f,f], age=>[30,30,40,40], A=>[1,2,3,4]} }

which is equivalent to C<@groupby=()> and C<@content_columns=(sex,age,A)>
(i.e. all columns) a DF groupped by column C<'sex'> will be

    {
      'm' => {sex=>[m,m], age=>[30,30], A=>[1,2]]},
      'f' => {sex=>[f,f], age=>[40,40], A=>[3,4]]},
    }

and a DF groupped by C<'sex'> and C<'age'>:

    {
      'm|30' => {sex=>[m,m], age=>[30,30], A=>[1,2]]},
      'f|40' => {sex=>[f,f], age=>[40,40], A=>[3,4]]},
    }

notice that C<m|40> does not exist as it is not an existing combination in the data
notice also that by specifying C<@content_columns>, you make your DF leaner.
e.g. why have sex in the hash when is also a key?

The reason why use a dataframe instead of an array of
L<Statistics::Covid::Datum> objects is economy.
One Datum object represents data in a single time point.
Plotting or fitting data requies a lot of data objects.
whose data from specific columns/fields/attributes must
be collected together in an array, possibly transformed,
and plotted or fitted. If you want to plot and fit the
same data you have to repeat this process twice. Whereas
by inserting this data into a dataframe you can pass it
around. The dataframe is a more high-level collection of data.

A good question is why a new dataframe structure when there is already
existing L<Data::Frame>. It's because the existing is based on L<PDL>
and I considered it too heavy a dependency when the plotter
(L<Statistics::Covid::Analysis::Plot::Simple>) or the
model fitter (L<Statistics::Covid::Analysis::Model::Simple>)
do not use (yet) L<PDL>.

The reason that this dataframe has not been turned into a
Class is because I do not want to do one before
I exhaust my search on finding an existing solution.

See L<Statistics::Covid::Analysis::Plot::Simple> how to plot
dataframes and L<Statistics::Covid::Analysis::Model::Simple>
how to fit models on data. They both take dataframes as
input.

=head1 EXPORT

None by default. But C<Statistics::Covid::Utils::datums2dataframe()>
is the sub to call with full qualified name.

=head1 AUTHOR
	
Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>, C<< <andreashad2 at gmail.com> >>

=head1 BUGS

This module has been put together very quickly and under pressure.
There are must exist quite a few bugs.

Please report any bugs or feature requests to C<bug-statistics-Covid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Covid>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Covid::Utils


You can also look for information at:

=over 4

=item * github L<repository|https://github.com/hadjiprocopis/statistics-covid>  which will host data and alpha releases

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Covid>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Covid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Covid>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Covid/>

=item * Information about the basis module DBIx::Class

L<http://search.cpan.org/dist/DBIx-Class/>

=back


=head1 DEDICATIONS

Almaz

=head1 ACKNOWLEDGEMENTS

=over 2

=item L<Perlmonks|https://www.perlmonks.org> for supporting the world with answers and programming enlightment

=item L<DBIx::Class>

=item the data providers:

=over 2

=item L<John Hopkins University|https://www.arcgis.com/apps/opsdashboard/index.html#/bda7594740fd40299423467b48e9ecf6>,

=item L<UK government|https://www.gov.uk/government/publications/covid-19-track-coronavirus-cases>,

=item L<https://www.bbc.co.uk> (for disseminating official results)

=back

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=cut


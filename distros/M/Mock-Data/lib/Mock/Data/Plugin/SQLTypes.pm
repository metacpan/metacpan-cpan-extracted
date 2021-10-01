package Mock::Data::Plugin::SQLTypes;
use Mock::Data::Plugin -exporter_setup => 1;
use Mock::Data::Plugin::Net qw( cidr macaddr ), 'ipv4', { -as => 'inet' };
use Mock::Data::Plugin::Number qw( integer decimal float sequence uuid byte );
use Mock::Data::Plugin::Text 'join' => { -as => 'text_join' }, 'words';
our %type_generators= map +($_ => 1), qw(
	integer tinyint smallint bigint
	sequence serial smallserial bigserial
	numeric decimal
	float float4 real float8 double double_precision
	bit bool boolean
	varchar char nvarchar
	text tinytext mediumtext longtext ntext
	blob tinyblob mediumblob longblob bytea
	varbinary binary
	date datetime datetime2 datetimeoffset timestamp
	datetime_with_time_zone datetime_without_time_zone
	json jsonb
	uuid inet cidr macaddr
);
export(keys %type_generators);

# ABSTRACT: Collection of generators that produce data matching a SQL column type
our $VERSION = '0.03'; # VERSION


sub apply_mockdata_plugin {
	my ($class, $mock)= @_;
	$mock->load_plugin('Text')->add_generators(
		map +("SQL::$_" => $class->can($_)), keys %type_generators
	);
}


sub generator_for_type {
	my ($mock, $type)= @_;
	$type =~ s/\s+/_/g;
	my $gen= $mock->generators->{$type} // $mock->generators->{"SQL::$type"}
		// $type_generators{$type} && Mock::Data::GeneratorSub->new(__PACKAGE__->can($type));
	# TODO: check for complex things like postgres arrays
	return $gen;
}


sub tinyint {
	my $mock= shift;
	my $params= ref $_[0] eq 'HASH'? shift : undef;
	integer($mock, { $params? %$params : (), bits => 8 }, @_);
}

sub smallint {
	my $mock= shift;
	my $params= ref $_[0] eq 'HASH'? shift : undef;
	integer($mock, { $params? %$params : (), bits => 16 }, @_);
}

sub bigint {
	my $mock= shift;
	my $params= ref $_[0] eq 'HASH'? shift : undef;
	integer($mock, { $params? %$params : (), bits => 64 }, @_);
}


BEGIN { *bigserial= *smallserial= *serial= *sequence; }


BEGIN { *numeric= *decimal; }


BEGIN { *real= *float4= *float; }

sub double {
	my $mock= shift;
	my $params= ref $_[0] eq 'HASH'? shift : undef;
	float($mock, { bits => 53, $params? %$params : () }, @_);
}

BEGIN { *float8= *double_precision= *double; }


sub bit {
	int rand 2;
}
BEGIN { *bool= *boolean= *bit; }


sub varchar {
	my $mock= shift;
	my $params= ref $_[0] eq 'HASH'? shift : undef;
	my $size= shift // ($params? $params->{size} : undef) // 16;
	my $size_weight= ($params? $params->{size_weight} : undef) // \&_default_size_weight;
	my $source= ($params? $params->{source} : undef);
	if (defined $source && !ref $source) {
		Carp::croak("No generator '$source' available")
			unless $mock->generators->{$source};
	} else {
		$source= $mock->generators->{word}? 'word' : \&word;
	}
	return text_join($mock, {
		source => $source,
		max_len => $size,
		len => $size_weight->($size),
	});
}
sub _default_size_weight {
	my $size= shift;
	$size <= 32? int rand($size+1)
		: int rand(100)? int rand(33)
		: 33+int rand($size-31)
}



BEGIN { *nvarchar= *varchar; }

sub text {
	my $mock= shift;
	my $params= ref $_[0] eq 'HASH'? shift : undef;
	varchar($mock, { size => 256, ($params? %$params : ()) }, @_);
}

BEGIN { *ntext= *tinytext= *mediumtext= *longtext= *text; }


sub char {
	my $mock= shift;
	my $params= ref $_[0] eq 'HASH'? shift : undef;
	my $size= @_? shift : ($params? $params->{size} : undef) // 1;
	my $str= varchar($mock, ($params? $params : ()), $size);
	$str .= ' 'x($size - length $str) if length $str < $size;
	return $str;
}


sub _epoch_to_iso8601 {
	my @t= localtime(shift);
	return sprintf "%04d-%02d-%02d %02d:%02d:%02d", $t[5]+1900, $t[4]+1, @t[3,2,1,0];
}
sub _iso8601_to_epoch {
	my $str= shift;
	$str =~ /^
		(\d{4}) - (\d{2}) - (\d{2})
		(?: [T ] (\d{2}) : (\d{2})  # maybe time
			(?: :(\d{2})            # maybe seconds
				(?: \. \d+ )?       # ignore milliseconds
			)?
			(?: Z | [-+ ][:\d]+ )?  # ignore timezone or Z
		)?
	/x or Carp::croak("Invalid date '$str'.  Expecting format YYYY-MM-DD[ HH:MM:SS[.SSS][TZ]]");
	require POSIX;
	return POSIX::mktime($6||0, $5||0, $4||0, $3, $2-1, $1-1900);
}

sub datetime {
	my $mock= shift;
	my $params= ref $_[0] eq 'HASH'? shift : undef;
	my $before= $params && $params->{before}? _iso8601_to_epoch($params->{before}) : (time - 86400);
	my $after=  $params && $params->{after}?  _iso8601_to_epoch($params->{after})  : (time - int(10*365.25*86400));
	_epoch_to_iso8601($after + int rand($before-$after)); 
}

sub date {
	substr(datetime(@_), 0, 10)
}

BEGIN {
	*timestamp= *datetime2= *datetime_without_time_zone= *datetime;
	*datetimeoffset= *datetime_with_time_zone= *datetime;
}


sub blob {
	my $mock= shift;
	my $params= ref $_[0] eq 'HASH'? shift : undef;
	my $size= shift // ($params? $params->{size} : undef) // 256;
	byte($mock, $size);
}

BEGIN { *tinyblob= *mediumblob= *longblob= *bytea= *binary= *varbinary= *blob; }


our $json;
sub _json_encoder {
	$json //= do {
		local $@;
		my $mod= eval { require JSON::MaybeXS; 'JSON::MaybeXS' }
			  || eval { require JSON; 'JSON' }
			  || eval { require JSON::PP; 'JSON::PP' }
			or Carp::croak("No JSON module found.  This must be installed for the SQL::json generator.");
		$mod->new->canonical->ascii
	};
}

sub json {
	my $mock= shift;
	my $params= ref $_[0] eq 'HASH'? shift : undef;
	my $data= shift // ($params? $params->{data} : undef);
	return defined $data? _json_encoder->encode($data) : '{}';
}

BEGIN { *jsonb= *json; }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Data::Plugin::SQLTypes - Collection of generators that produce data matching a SQL column type

=head1 SYNOPSIS

  my $mock= Mock::Data->new(['SQL']);
  $mock->integer(11);
  $mock->sequence($seq_name);
  $mock->numeric([9,2]);
  $mock->float({ bits => 32 });
  $mock->bit;
  $mock->boolean;
  $mock->varchar(16);
  $mock->char(16);
  $mock->text(256);
  $mock->blob(1000);
  $mock->varbinary(32);
  $mock->datetime({ after => '1900-01-01', before => '1990-01-01' });
  $mock->date;
  $mock->uuid;
  $mock->json({ data => $data || {} });
  $mock->inet;
  $mock->cidr;
  $mock->macaddr;

This module defines generators that match the data type names used by various relational
databases.

The output patterns are likely to change in future versions, but will always be valid for
inserting into a column of that type.

=head1 EXPORTABLE FUNCTIONS

=head2 generator_for_type

  my $generatpr= generator_for_type($sqltype);

Return a generator which can generate valid strings for a given SQL type.

=head1 GENERATORS

(all generators are also exportable)

=head2 Numeric Generators

=head3 integer

See L<Mock::Data::Plugin::Number/integer>

=head3 tinyint

Alias for C<< integer({ bits => 8 }) >>.

=head3 smallint

Alias for C<< integer({ bits => 16 }) >>.

=head3 bigint

Alias for C<< integer({ bits => 63 }) >>.

=head3 sequence

See L<Mock::Data::Plugin::Number/sequence>

=head3 serial

Alias for sequence

=head3 smallserial

Alias for sequence

=head3 bigserial

Alias for sequence

=head3 decimal

See L<Mock::Data::Plugin::Numeric/decimal>

=head3 numeric

Alias for C<decimal>.

=head3 float

See L<Mock::Data::Plugin::Numeric/float>

=head3 real, float4

Aliases for C<< float({ size => 7 }) >>

=head3 float8, double, double_precision

Aliases for C<< float({ size => 15 }) >>

=head3 bit

Return a 0 or a 1

=head3 bool, boolean

Alias for C<bit>.  While postgres prefers C<'true'> and C<'false'>, it allows 0/1 and they are
more convenient to use in Perl.

=head2 Text Generators

=head3 varchar

  $str= $mock->varchar($size);
  $str= $mock->varchar(\%options, $size);
  # %options:
  {
    size        => $max_chars,
	size_weight => sub($size) { ... }
    source      => $generator_or_name,
  }

Generate a string of random length, from 1 to C<$size> characters.  If C<$size> is not given, it
defaults to 16.  C<size_weight> is a function used to control the distribution of random lengths.
The default applies a reduced chance of generating long strings when C<$size> is greater than 32.

C<source> is the name of a generator (or a generator reference) to use for generating words that
get concatenated up to the random length.  The default is the generator named C<'word'> in the
current C<Mock::Data>, and if that doesn't exist it uses L<Mock::Data::Plugin::Text/word>.

=head3 nvarchar

Alias for C<varchar>

=head3 text

Same as varchar, but the default size is 256.

=head3 tinytext, mediumtext, longtext, ntext

Aliases for C<text>, and don't generate larger data because that would just slow things down.

=head3 char

  $str= $mock->char($size);
  $str= $mock->char(\%options, $size);

Same as varchar, but the default size is 1, and the string will be padded with whitespace
up to C<$size>.

=head2 Date Generators

=head3 datetime

  $datestr= $mock->datetime();
  $datestr= $mock->datetime({ before => $date, after => $date });

Returns a random date from a date range, defaulting to the past 10 years.
The input and output date strings must all be in ISO-8601 format, or an object that stringifies
to that format.  The output does not have the 'T' in the middle or 'Z' at the end, for widest
compatibility with being able to insert into databases.

=head3 date

Like C<datetime>, but only the C<'YYYY-MM-DD'> portion.

=head3 timestamp

=head3 datetime2

=head3 datetime_without_time_zone

=head3 datetimeoffset

=head3 datetime_with_time_zone

Alias for C<datetime>.

=head2 Binary Data Generators

=head3 blob

=head3 tinyblob, mediumblob, longblob, bytea, binary, varbinary

Aliases for C<blob>.  None of these change the default string length, because longer strings
of data would just slow things down.

=head2 Structured Data Generators

=head3 uuid

See L<Mock::Data::Plugin::Numeric/uuid>

=head3 json, jsonb

Return '{}'.  This is just the minimal valid value that makes it most likely that you can
perform operations on the column without type errors.

=head3 inet

See L<Mock::Data::Plugin::Net/ipv4>

=head3 cidr

See L<Mock::Data::Plugin::Net/cidr>

=head3 macaddr

See L<Mock::Data::Plugin::Net/macaddr>

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.03

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

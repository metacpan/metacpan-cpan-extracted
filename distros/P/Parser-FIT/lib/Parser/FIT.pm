package Parser::FIT;

use strict;
use warnings;
use Carp qw/croak carp/;
use feature 'state';
use Math::BigInt;
use Parser::FIT::Profile;

#require "Profile.pm";

our $VERSION = 0.03;

sub new {
	my $class = shift;
	my %options = @_;

	my $ref = {
		_DEBUG => 0,
		header => {},
		body => {},
		globalMessages => [],
		localMessages => [],
		records => 0,
		fh => undef,
		buffer => "",
		headerLength => 0,
		totalBytesRead => 0,
		messageHandlers => {},
	};

	if(exists $options{on}) {
		$ref->{messageHandlers} = $options{on};
	}

	if(exists $options{debug} && $options{debug}) {
		$ref->{_DEBUG} = 1;
	}

	bless($ref, $class);

	return $ref;
}

sub parse {
	my $self = shift;
	my $file = shift;

	croak "No file given to parse()!" unless($file);

	$self->_debug("Parsing '$file'");

	croak "File '$file' doesn't exist!" if(!-f $file);

	$self->_debug("Opening file");
	open(my $input, "<", $file) or croak "Error opening '$file': $!";
	binmode($input);

	$self->parse_fh($input);
}

sub parse_fh {
	my $self = shift;
	my $input = shift;

	unless(ref $input eq "GLOB") {
		die "parse_fh requires an opened filehandle as param!";
	}


	$self->{fh} = $input;
	my $header = $self->_read_header();
	$self->{header} = $self->_parse_header($header);
	#my $dataBody = $self->_readBytes($self->{header}->{dataLength});
	$self->_parse_data_records();
	#$self->_parse_crc();

	close($input);
}

sub parse_data {
	my $self = shift;
	my $data = shift;

	open(my $fh, "<", \$data) or die "Error opening scalar as file: $!";
	binmode($fh);

	return $self->parse_fh($fh);
}

sub _read_header {
	my $self = shift;

	my $headerLengthByte = $self->_readBytes(1);
	my $headerLength = unpack("c", $headerLengthByte);
	$self->{headerLength} = $headerLength;

	# The 1-Byte headerLength field is included in the total header length
	my $headerWithoutLengthByte = $headerLength - 1;

	my $header = $self->_readBytes($headerWithoutLengthByte);

	return $header;
}

sub _parse_header {
	my $self = shift;
	my $header = shift;

	my ($protocolVersion, $profile, $dataLength, $fileMagic, $crc);

	my $headerLength = length $header;

	if($headerLength == 13) {
		($protocolVersion, $profile, $dataLength, $fileMagic, $crc) = unpack("c s I! a4 s", $header);
	}
	elsif($headerLength == 11) {
		($protocolVersion, $profile, $dataLength, $fileMagic) = unpack("c s I! a4", $header);

		# Short header has no CRC value
		$crc = undef;
	}
	else {
		croak "Invalid headerLength=${headerLength}! Don't know how to handle this.";
	}

	croak "File either corrupted or not a real FIT file! (Missing magic '.FIT' string in header)" unless($fileMagic eq ".FIT");

	$self->_debug("ProtocolVersion: $protocolVersion");
	$self->_debug("Profile: $profile");
	$self->_debug("DataLength: $dataLength Bytes");
	$self->_debug("FileMagic: $fileMagic");
	$self->_debug("CRC: " . (defined($crc) ? $crc : "N/A"));

	my $headerInfo = {
		protocolVersion => $protocolVersion,
		profile => $profile,
		dataLength => $dataLength,
		crc => $crc,
		eof => $self->{headerLength} + $dataLength,
	};

	return $headerInfo;
}

sub _parse_record_header {
	my $self = shift;
	my $recordHeader = shift;

	return {
		# Bit 7 inidcates a normal header (=0) or "something else"
		isNormalHeader => (($recordHeader & (1<<7)) == 0),
		# Bit 6 indicates a definition msg
		isDefinitionMessage => (($recordHeader & (1<<6)) > 0),
		# Bit 5 indicates "developer data flag"
		isDeveloperData => (($recordHeader & (1<<5)) > 0),
		# Bit 4 is reserved
		# Bits 3-0 define the localMessageType
		localMessageType => $recordHeader & 0xF,
	};
}

sub _parse_data_records {
	my $self = shift;

	$self->_debug("Parsing Data Records");
	while($self->{totalBytesRead} < $self->{header}->{eof}) {
		
		my ($recordHeaderByte) = unpack("c", $self->_readBytes(1));
		$self->_debug("HeaderBytes in Binary: " . sprintf("%08b", $recordHeaderByte));
		my $header = $self->_parse_record_header($recordHeaderByte);

		if($header->{isNormalHeader}) {
			if($header->{isDeveloperData}) {
				die "Header indicates message with developer data. Not yet supported!";
			}

			if($header->{isDefinitionMessage}) {
				$self->_debug("Record definition header for LocalMessageType=" . $header->{localMessageType});
				$self->_parse_definition_message($header);
			}
			else {
				my $parseResult = $self->_parse_local_message_record($header);

				if(!defined $parseResult) {
					$self->_debug("Skipping record for unknown LocalMessageType=" . $header->{localMessageType});
					next;
				}
				
				$self->_debug("Processed record for LocalMessageType=" . $header->{localMessageType});

				$self->emitRecord($parseResult->{messageType}, $parseResult->{fields});

				$self->{records}++;
			}
		}
	}
	$self->_debug("DataRecords finished! Found a total of " . $self->{records} . " Records");
}

sub on {
	my $self = shift;
	my $msgType = shift;
	my $handler = shift;

	my $msgHandlers = $self->{messageHandlers};

	if($handler) {
		$msgHandlers->{$msgType} = $handler;
	}
	else {
		delete $msgHandlers->{$msgType};
	}
}

sub emitRecord {
	my $self = shift;
	my ($msgType, $msgData) = @_;

	if(my $handler = $self->getHandler($msgType)) {
		$handler->($msgData);
	}

	if(my $allHandler = $self->getHandler("_any")) {
		$allHandler->($msgType, $msgData);
	}
}

sub getHandler {
	my $self = shift;
	my $msgType = shift;

	if(!$msgType) {
		die "cannot get a handler for an unknown msgType!";
	}

	if(exists $self->{messageHandlers}->{$msgType}) {
		return $self->{messageHandlers}->{$msgType};
	}

	return undef;
}

sub _parse_definition_message {
	my $self = shift;
	my $header = shift;
	my $localMessageType = $header->{localMessageType};

	my $data = $self->_readBytes(5);
	my ($reserved, $arch, $globalMessageId, $fields) = unpack("ccsc", $data);

	my $globalMessageType = $self->_get_global_message_type($globalMessageId);

	$self->_debug("DefinitionMessageHeader:");
	$self->_debug("Arch: $arch - GlobalMessage: " . (defined $globalMessageType ? $globalMessageType->{name} : "<UNKNOWN_GLOBAL_MESSAGE>") . " ($globalMessageId) - #Fields: $fields");
	carp "BigEndian isn't supported so far!" if($arch == 1);

	my ($messageFields, $recordLength) = ([], 0);

	if(defined $globalMessageType) {
		($messageFields, $recordLength) = $self->_parse_defintion_message_fields($globalMessageType, $fields);
	}

	my $localMessage = {
		size => $recordLength,
		dataFields => $messageFields,
		globalMessage => $globalMessageType,,
		unpackTemplate => join("", map { $_->{baseType}->{packTemplate} } @$messageFields),
		isDeveloperMessage => $header->{isDeveloperData},
		isUnknownMessage => !defined $globalMessageType,
	};

	$self->{localMessages}->[$localMessageType] = $localMessage;

	$self->_debug("Following Record length: " . $localMessage->{size} . " bytes");
}

sub _parse_defintion_message_fields {
	my $self = shift;
	my $globalMessageType = shift;
	my $numberOfFields = shift;

	my $recordLength = 0;

	my @dataFields;

	foreach(1..$numberOfFields) {
		my $fieldDefinitionData = $self->_readBytes(3); # Every Field has 3 Bytes
		my ($fieldDefinition, $size, $baseTypeData)  = unpack("Ccc", $fieldDefinitionData);
		my ($baseTypeEndian, $baseTypeNumber) = ($baseTypeData & 128, $baseTypeData & 15);
		my $baseType = $self->_get_base_type($baseTypeNumber);
		my $fieldDescriptor = $globalMessageType->{fields}->{$fieldDefinition};

		if(!defined $fieldDescriptor) {
			$fieldDescriptor = {
				isUnkownField => 1,
				name => "<UNKNOWN_FIELD_NAME>"
			};
		}

		my $fieldName = $fieldDescriptor->{name};
		$self->_debug("FieldDefinition: Nr: $fieldDefinition (" . $fieldName . "), Size: $size, BaseType: " . $baseType->{name} . " ($baseTypeNumber), BaseTypeEndian: $baseTypeEndian");
		$recordLength += $size;

		push(@dataFields, { baseType => $baseType, fieldDescriptor => $fieldDescriptor });
	}

	return (\@dataFields, $recordLength);
}

sub _global_message_id_to_name {
	my $self = shift;
	my $globalMessageId = shift;

	# Manufacterer specific message types
	if($globalMessageId >= 0xFF00) {
			return "mfg_range_min";
	}

	state $globalMessageNames = {
		0 => "file_id",
		1 => "capabilities",
		2 => "device_settings",
		3 => "user_profile",
		4 => "hrm_profile",
		5 => "sdm_profile",
		6 => "bike_profile",
		7 => "zones_target",
		8 => "hr_zone",
		9 => "power_zone",
		10 => "met_zone",
		12 => "sport",
		15 => "goal",
		18 => "session",
		19 => "lap",
		20 => "record",
		21 => "event",
		23 => "device_info",
		26 => "workout",
		27 => "workout_step",
		28 => "schedule",
		30 => "weight_scale",
		31 => "course",
		32 => "course_point",
		33 => "totals",
		34 => "activity",
		35 => "software",
		37 => "file_capabilities",
		38 => "mesg_capabilities",
		39 => "field_capabilities",
		49 => "file_creator",
		51 => "blood_pressure",
		53 => "speed_zone",
		55 => "monitoring",
		72 => "training_file",
		78 => "hrv",
		80 => "ant_rx",
		81 => "ant_tx",
		82 => "ant_channel_id",
		101 => "length",
		103 => "monitoring_info",
		105 => "pad",
		106 => "slave_device",
		127 => "connectivity",
		128 => "weather_conditions",
		129 => "weather_alert",
		131 => "cadence_zone",
		132 => "hr",
		142 => "segment_lap",
		145 => "memo_glob",
		148 => "segment_id",
		149 => "segment_leaderboard_entry",
		150 => "segment_point",
		151 => "segment_file",
		158 => "workout_session",
		159 => "watchface_settings",
		160 => "gps_metadata",
		161 => "camera_event",
		162 => "timestamp_correlation",
		164 => "gyroscope_data",
		165 => "accelerometer_data",
		167 => "three_d_sensor_calibration",
		169 => "video_frame",
		174 => "obdii_data",
		177 => "nmea_sentence",
		178 => "aviation_attitude",
		184 => "video",
		185 => "video_title",
		186 => "video_description",
		187 => "video_clip",
		188 => "ohr_settings",
		200 => "exd_screen_configuration",
		201 => "exd_data_field_configuration",
		202 => "exd_data_concept_configuration",
		206 => "field_description",
		207 => "developer_data_id",
		208 => "magnetometer_data",
		209 => "barometer_data",
		210 => "one_d_sensor_calibration",
		225 => "set",
		227 => "stress_level",
		258 => "dive_settings",
		259 => "dive_gas",
		262 => "dive_alarm",
		264 => "exercise_title",
		268 => "dive_summary",
		285 => "jump",
		317 => "climb_pro",
	};

	if(exists $globalMessageNames->{$globalMessageId}) {
		return $globalMessageNames->{$globalMessageId};
	}
	else {
		return undef;
	}
}

sub getLocalMessageById {
	my $self = shift;
	my $localMessageId = shift;

	my $localMessage = $self->{localMessages}->[$localMessageId];

	if(!defined $localMessage) {
		die "Encountered a record  localMessageId=$localMessageId which was not introduced by a definition message!";
	}

	return $localMessage;
}

sub _get_global_message_type {
	my $self = shift;

	my $globalMessageName = $self->_global_message_id_to_name(shift);

	if(!defined $globalMessageName) {
		return undef;
	}
	
	if(exists $Parser::FIT::Profile::PROFILE->{$globalMessageName}) {
		return $Parser::FIT::Profile::PROFILE->{$globalMessageName};
	}
	else {
		return undef;
	}
}

sub _parse_local_message_record {
	my $self = shift;
	my $header = shift;

	my $localMessageId = $header->{localMessageType};
	my $localMessage = $self->getLocalMessageById($localMessageId);

	my $recordLength = $localMessage->{size};
	my $record = $self->_readBytes($recordLength);

	# skip unknown messages (the _readBytes above is correct, since we need to "remove" the bytes from the stream)
	if($localMessage->{isUnknownMessage}) {
		return undef;
	}

	my $unpackTemplate = $localMessage->{unpackTemplate};
	my @rawFields = unpack($unpackTemplate, $record);

	my $globalMessageType = $localMessage->{globalMessage};

	my %result;

	my $fieldCount = scalar @{$localMessage->{dataFields}};
	for(my $i = 0; $i < $fieldCount; $i++) {
		my $localMessageField = $localMessage->{dataFields}->[$i];
		my $rawValue = $rawFields[$i];

		my $fieldDescriptor = $localMessageField->{fieldDescriptor};
		my $fieldName = $fieldDescriptor->{name};

		if($fieldDescriptor->{isUnkownField}) {
			next;
		}

		my $postProcessedValue = $self->postProcessRawValue($rawValue, $fieldDescriptor);

		$result{$fieldName} = {
			value => $postProcessedValue,
			rawValue => $rawValue,
			fieldDescriptor => $fieldDescriptor,
		};
	}

	return {
		messageType => $localMessage->{globalMessage}->{name},
		fields => \%result
	};
}

sub postProcessRawValue {
	my $self = shift;
	my $rawValue = shift;
	my $fieldDescriptor = shift;

	if(defined $fieldDescriptor->{scale}) {
		$rawValue /= $fieldDescriptor->{scale};
	}

	if(defined $fieldDescriptor->{offset}) {
		$rawValue -= $fieldDescriptor->{offset};
	}

	if(defined $fieldDescriptor->{unit} && $fieldDescriptor->{unit} eq "semicircles") {
		state $semicirclesToDegreesConversionRate = 180 / 2**31;
		$rawValue *= $semicirclesToDegreesConversionRate;
	}

	if(defined $fieldDescriptor->{type} && $fieldDescriptor->{type} eq "date_time") {
		state $fitEpocheOffset = 631065600;
		$rawValue += $fitEpocheOffset;
	}

	return $rawValue;
}

sub _get_base_type {
	my $self = shift;
	my $index = shift;

	# See "Table 7. FIT Base Types and Invalid Values" at https://developer.garmin.com/fit/protocol/
	my $types = [
		{
			name => "enum",
			size => 1,
			invalid => 0xff,
			packTemplate => "c",
		},
		{
			name => "sint8",
			size => 1,
			invalid => 0x7f,
			packTemplate => "c"
		},
		{
			name => "uint8",
			size => 1,
			invalid => 0xff,
			packTemplate => "C",

		},
		{
			name => "sint16",
			size => 2,
			invalid => 0x7fff,
			packTemplate => "s",
		},
		{
			name => "uint16",
			size => 2,
			invalid => 0xffff,
			packTemplate => "S"
		},
		{
			name => "sint32",
			size => 4,
			invalid => 0x7fffffff,
			packTemplate => "l"
		},
		{
			name => "uint32",
			size => 4,
			invalid => 0xffffffff,
			packTemplate => "L",
		},
		{
			name => "string",
			size => 1,
			invalid => 0x00,
			packTemplate => "a"
		},
		{
			name => "float32",
			size => 4,
			invalid => 0xffffffff,
			packTemplate => "f"
		},
		{
			name => "float64",
			size => 8,
			invalid => Math::BigInt->new("0xffffffffffffffff"),
			packTemplate => "d",
		},
		{
			name => "uint8z",
			size => 1,
			invalid => 0x00,
			packTemplate => "c"
		},
		{
			name => "uint16z",
			size => 2,
			invalid => 0x0000,
			packTemplate => "S",
		},
		{
			name => "uint32z",
			size => 4,
			invalid => 0x00000000,
			packTemplate => "L"
		},
		{
			name => "byte",
			size => 1,
			invalid => 0xFF,
			packTemplate => "C",
		},
		{
			name => "sint64",
			size => 8,
			invalid => Math::BigInt->new("0x7fffffffffffffff"),
			packTemplate => "q",
		},
		{
			name => "uint64",
			size => 8,
			invalid => Math::BigInt->new("0xffffffffffffffff"),
			packTemplate => "Q",
		},
		{
			name => "uint64z",
			size => 8,
			invalid => 0x0000000000000000,
			packTemplate => "Q",
		}
	];

	if($index >= @{$types}) {
		die "Invalid index=$index for BaseTypeLookup!";
	}

	return $types->[$index];
}

sub _parse_crc {
	# TODO implement this one...some time :D
}

sub _debug {
	my $self = shift;
	if($self->{_DEBUG}) {
		print "[FIT.pm DEBUG] ", @_;
		print "\n";
	}
}

sub _readBytes {
	my $self = shift;
	my $num = shift;

	$self->{totalBytesRead} += $num;
	my $buffer;
	my $bytesRead = read($self->{fh}, $buffer, $num);
	# TODO error handling based on bytesRead
	return $buffer;
}





1;


__END__
=head1 NAME

Parser::FIT - A parser for garmin FIT (Flexible and Interoperable Data Transfer) files

=head1 SYNOPSIS

  use Parser::FIT;

  my $recordCount = 0;
  my $parser = Parser::FIT->new(on => {
    record => sub { $recordMsg = shift; $recordCount++; }
  });

  $parser->parse("some/file.fit");

  print "The file contained $recordCount records.";

=head1 ALPHA STATUS

The module is in an early alpha status. APIs may change. Parse results may be wrong.

Additionally i will probably not implement the full set of FIT messages.
I started the module for my personal needs to be able to parse FIT files from my garmin bike computer.
So results for e.g. a triathlon multisport watch may varry greatly!

But this module is free and open source: Feel free to contribute code, example data, etc!

=head1 METHODS

=head2 new

Create a new L<Parser::FIT> object.

  Parser::FIT->new(
	  debug => 1|0 # enable/disable debug output. Disabled by default
	  on => { # Provide a hashref of message handlers
	  	sessiont => sub { },
		lap => sub { },
	  }
  )

=head2 on

Register and deregister handlers for a parser.

  $parser->on(record => sub { my $message = shift; });

Concrete message handlers receive on paramter which represents the parsed message. See L</MESSAGES> for more details.

Registering an already existing handler overwrites the old one.

  $parser->on(session => sub { say "foo" });
  $parser->on(session => sub { say "bar" }); # Overwrites the previous handler

Registering a falsy value for a message type will deregister the handler:

  $parser->on(session => undef);

There is currently no check, if the provided message name actually represents an existing one from the FIT specs.

Additionally there is a special message name: C<_any>. Which can be used to receive just every message encountered by the parser.
The C<_any> handler receives two parameters. The first one is the C<messageType> which is just a string with the name of the message. The second one is a L<message|/MESSAGES> hash-ref.

  $parser->on(_any => sub {
	  my $messageType = shift;
	  my $message = shift;

	  print "Saw a message of type $msgType";
  });


The C<on> method can also be called from inside a handler callback in order to de-/register handlers based on the stream of events

  # Count the number of records per lap
  my $lapCount = 0;
  my $lapResults = [];
  $parser->on("lap" => sub {
	  my $lapMsg = shift;
	  my $lapCount++;
	  $parser->on("record" => {
		  $lapResults[$lapCount]++;
	  });
  });

=head2 parse

Parse a file and call registered message handlers.

  $parser->parse('/some/file.fit');

=head2 parse_data

Parse FIT data contained in a scalar and call registered message handlers.

  $parser->parse_data($inMemoryFitData);

=head1 DATA STRUCTURES

This section explains the used data structures you may or may not encounter when using this module.

=head2 MESSAGES

A message is a hash-ref where the keys map to fieldnames defined by the FIT Profile (aka C<Profile.xls>) for the given message.

The FIT protocol defines so called C<local messages> which allow to only store a subset of the so called C<global message>.
For example the C<session> global message defines 134 fields, but an actually recorded session message in a FIT file may only contain 20 of these.

This way it is possible to create FIT files which only contain the data the device is currently "seeing". But this also means, that this data may change "in-flight".
For example if a session is started without an heartrate sensor, the include FIT data will not have heartrate related data. When later in the session the user straps on a heartrate sensor
and pairs it with his device, all upcoming data inside the FIT file will have heartrate data. The same is true for sensors/data that goes away while recording.

Therefore you always have to check if the desired data is actually in the message.

For a list of field names you may expect to see, you can check the Garmin FIT SDK. It includes a C<Profile.xls> file which defines all the valid fields for every global message.

The fields of a message are represented as L<message fields|/MESSAGE-FIELDS>.

An example C<record> message:

  {
    'speed' => {
      'fieldDescriptor' => {
                              'name' => 'speed',
                              'id' => '6',
                              'scale' => 1000,
                              'unit' => 'm/s',
                              'type' => 'uint16',
                              'offset' => undef
                          },
      'rawValue' => 2100
      'value' => '2.1',
    },
    'position_lat' => {
        'fieldDescriptor' => { }, # skipped for readability
        'rawValue' => 574866379,
        'value' => '48.184743'
    },
    'distance' => {
        'fieldDescriptor' => { }, # skipped for readability
        'rawValue' => 238,
        'value' => '2.38',
    },
    'heart_rate' => {
      'fieldDescriptor' => { }, # skipped for readability
      'value' => 70,
      'rawValue' => 70
      },
    'timestamp' => {
      'rawValue' => 983200317,
      'fieldDescriptor' => { }, # skipped for readability
      'value' => 1614265917
      },
    'altitude' => {
        'value' => '790.8',
        'fieldDescriptor' => { }, # skipped for readability
        'rawValue' => 6454
    },
    'position_long' => {
        'fieldDescriptor' => { }, # skipped for readability
        'value' => '9.102652',
        'rawValue' => 108598869
      }
  }
=head2 MESSAGE FIELDS

A message field represents actuall data inside a message. It consists of a hash-ref containg:

=over

=item value

The value after L<post processing|/POST-PROCESSING>.

=item rawValue

The original value as it is stored in the FIT file.

=item fieldDescriptor

A hash-ref containing a L<field descriptor|/FIELD-DESCRIPTOR> which describes this field.

=back

=head2 FIELD DESCRIPTOR

A C<field descriptor> is just a hash-ref with some key-value pairs describing the underlying field.

The keys are:

=over

=item id

The id of the field in relation to the message type.

=item name

The name of the field this descriptor represents.

=item unit

The unit of measurement (e.G. C<kcal>, C<m>, C<bpm>).

=item scale

The scale by which the rawValue needs to be scaled.

=item type

The original FIT data type (e.G. C<uint8>, C<date_time>).

=back

The values for these keys are directly taken from the FIT C<Profile.xls>.


=head1 POST PROCESSING

=head2 SCALE

The FIT protocol defines for various data fields a scale (e.G. distances define a scale of 100) in order to optimize the low-level storage type.

L<Parser::FIT> divides the C<rawValue> by the scale and stores the result in C<value>. The C<rawValue> stays untouched.

=head2 OFFSET

The FIT protocol defines for various data fields an offset (e.G. altitude values are offset by 500m) in order to optimize the low-level storage type.

L<Parser::FIT> subtracts the offsets from the C<rawValue> and stores the result in C<value>. The C<rawValue> stays untouched.

=head2 CONVERSIONS

The FIT protocol defines various special data types. L<Parser::FIT> converts the following types to "more usefull" ones:

=head3 SEMICRICLES

Fields with the data type C<semicricles> get converted to degrees via this formula: C<degrees = semicircles * (180/2^31)>.

So the C<value> of a field with data type C<semicricles> is in degrees. The C<rawValue> stays in semicircles.

=head3 DATE_TIME

Fields with the data type C<date_time> get converted to unix epoche timestamps via this formula: C<unixTimestamp = fitTimestamp + 631065600>.

Internally FIT is using it's own epoche starting at December 31, 1989 UTC.

=head1 AUTHOR

This module was created by Sven Eppler <ghandi@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018-2022 by Sven Eppler

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Parser::FIT::Simple>, L<Garmin FIT SDK|https://developer.garmin.com/fit/protocol/>

=cut

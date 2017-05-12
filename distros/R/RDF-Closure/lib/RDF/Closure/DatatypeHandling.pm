package RDF::Closure::DatatypeHandling;

use 5.008;
use bignum;
use strict;
use utf8;

use DateTime;
use DateTime::Format::Strptime;
use DateTime::Format::XSD;
use DateTime::TimeZone;
use Error qw[:try];
use Math::BigInt;
use MIME::Base64 qw[encode_base64 decode_base64];
use RDF::Trine qw[statement iri];
use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
use RDF::Closure::DatatypeTuple;
use Scalar::Util qw[blessed];
use URI qw[];
use XML::LibXML;

use base qw[Exporter];

our $VERSION = '0.001';

our @EXPORT = qw[];
our @EXPORT_OK = qw[
	literal_tuple
	literal_valid
	literal_canonical
	literal_to_perl
	literal_canonical_safe
	literals_identical
	$RDF $RDFS $OWL $XSD
	];

use constant {
	TRUE    => 1,
	FALSE   => 0,
	};
use namespace::clean;

sub _strToBool
{
	my ($v) = @_;

	return RDF::Closure::DatatypeTuple::Boolean->new('true', 1)
		if lc $v eq 'true'  || $v eq '1';
	return RDF::Closure::DatatypeTuple::Boolean->new('false', 0)
		if lc $v eq 'false' || $v eq '0';
	
	throw Error::Simple(sprintf('Invalid boolean literal value "%s"', $v));
}

sub _strToDecimal
{
	my ($v) = @_;
	
	if ($v =~ /^(?:(?i)(?:[+-]?)(?:(?=[0123456789]|[.])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?))$/)
	{
		$v =~ s/^\+//;                     # remove explicit positive
		$v =~ s/0+$//    if $v =~ /\./;    # remove trailing zeros
		$v =~ s/^(\-)?0+/$1/;              # remove leading zeros
		$v =~ s/\.$//;                     # remove trailing point
		$v =~ s/^(\-)?\./${1}0./;          # restore leading zero if abs($v) < 1.0
		$v = '0'         unless length $v; # empty string is '0'
		
		return RDF::Closure::DatatypeTuple::Decimal->new($v);
	}

	throw Error::Simple(sprintf('Invalid decimal literal value "%s"', $v));
}

sub _strToAnyURI
{
	my ($v) = @_;
	
	# percent-encoded with non-hexadecimal characters
	my @bits = split /\%/, $v;
	shift @bits;
	throw Error::Simple(sprintf('Invalid IRI "%s"', $v))
		if grep { !/^[0-9A-F]{2}/i } @bits;
	
	my $u = URI->new($v);
	return RDF::Closure::DatatypeTuple::URI->new($u->canonical->as_string, $u);
}

sub _strToBase64Binary
{
	my ($v) = @_;
	
	return RDF::Closure::DatatypeTuple::Base64Binary->new(encode_base64(decode_base64($v), ''))
		if $v =~ /^[A-Za-z0-9\=\+\/\r\n\s]*$/;
	
	throw Error::Simple(sprintf('Invalid Base64Binary "%s"', $v));
}

#: limits for unsigned bytes
my $_limits_unsignedByte       = [-1, 256];

#: limits for bytes
my $_limits_byte               = [-129, 128];

#: limits for unsigned int
my $_limits_unsignedInt        = [-1, 4294967296];

#: limits for int
my $_limits_int                = [-2147483649, 2147483648];

#: limits for unsigned short
my $_limits_unsignedShort      = [-1, 65536];

#: limits for short
my $_limits_short              = [-32769, 32768];

#: limits for unsigned long
my $_limits_unsignedLong       = [-1, 18446744073709551616];

#: limits for long
my $_limits_long               = [-9223372036854775809, 9223372036854775808];

#: limits for positive integer
my $_limits_positiveInteger    = [0, undef];

#: limits for non positive integer
my $_limits_nonPositiveInteger = [undef, 1];

#: limits for non negative ingteger
my $_limits_nonNegativeInteger = [-1, undef];

#: limits for negative ingteger
my $_limits_negativeInteger    = [undef, 0];

sub _strToBoundNumeral
{
	my ($incoming_v, $interval, $conversion) = @_;
	
	$conversion ||= sub { Math::BigInt->new($_[0]); };
	
	return try
	{
		my $i = $conversion->($incoming_v);
		
		my $v = $i->bstr;
		$v =~ s/0+$//    if $v =~ /\./;    # remove trailing zeros
		$v =~ s/^(\-)?0+/$1/;              # remove leading zeros
		$v =~ s/\.$//;                     # remove trailing point
		$v =~ s/^(\-)?\./${1}0./;          # restore leading zero if abs($v) < 1.0
		$v = '0'         unless length $v; # empty string is '0'
		
		return RDF::Closure::DatatypeTuple::Decimal->new($v)
			if ( (!defined $interval->[0] or $interval->[0] < $i)
			and  (!defined $interval->[1] or $interval->[1] > $i) );
#	}
#	except
#	{
#		return RDF::Closure::DatatypeTuple::Decimal->new($incoming_v);
	};
	
	throw Error::Simple(sprintf('Invalid numerical value "%s"', $incoming_v));
}

# xsd:double and xsd:float are pairwise disjoint with xsd:decimal and its ilk.
# (xsd:decimal and its ilk are NOT disjoint with each other)
{
	my $floatey = sub
	{
		my ($incoming_v, $niceclass, $class, $ulim, $llim) = @_;
		
		(my $v = $incoming_v) =~ s/^\+//;
		return $class->new("NaN")   if $v =~ /^\-?NaN$/i;
		return $class->new("INF")   if $v =~ /^\-?INF$/i;
		return $class->new("0.0E0") if $v =~ /^\-?0+$/;
		
		throw Error::Simple(sprintf('Invalid %s (octal/hex-looking notation) "%s"', $niceclass, $incoming_v))
			if $v =~ /0[xb]/i;
		
		$v = Math::BigFloat->new($v);
		throw Error::Simple(sprintf('Invalid %s "%s"', $niceclass, $incoming_v))
			if $v->is_nan;

		my $avalue = $v->babs;
		if (defined $ulim and $avalue > $ulim)
		{
			throw Error::Simple(sprintf('Invalid %s (too big)"%s"', $niceclass, $incoming_v));
		}
		elsif (defined $llim and $avalue < $llim)
		{
			throw Error::Simple(sprintf('Invalid %s (too near zero)"%s"', $niceclass, $incoming_v));
		}
		
		my $formatted;
		my ($m, $e) = $v->parts;
		$m = $m->bstr;
		my ($m1, $mrest) = (substr($m,0,1), substr($m,1));
		$e += length($mrest);
		$mrest =~ s/0+$//;
		$mrest = '0' unless length $mrest;
		$formatted = sprintf('%s.%sE%s', $m1, $mrest, $e->bstr);
		
		return $class->new($formatted);	
	};	
	{
		my ($ulim, $llim);
		sub _strToDouble
		{
			$ulim ||= Math::BigFloat->new('1.0E+310');
			$llim ||= Math::BigFloat->new('1.0E-330');
			$floatey->($_[0], 'double', 'RDF::Closure::DatatypeTuple::Double', $ulim, $llim);
		}
	}

	{
		my ($ulim, $llim);
		sub _strToFloat
		{
			$ulim ||= Math::BigFloat->new('1.0E+40');
			$llim ||= Math::BigFloat->new('1.0E-50');
			$floatey->($_[0], 'float', 'RDF::Closure::DatatypeTuple::Float', $ulim, $llim);
		}
	}
}

sub _strToHexBinary
{
	my ($v) = @_;
	
	throw Error::Simple(sprintf('Invalid hex binary (odd number of digits) "%s"', $v))
		if length($v) % 2 == 1;
	
	throw Error::Simple(sprintf('Invalid hex binary (non-hex digits) "%s"', $v))
		unless $v =~ /^[0-9A-F]*$/i;
	
	$v =~ s/([a-fA-F0-9][a-fA-F0-9])/uc($1)/eg;
	return RDF::Closure::DatatypeTuple::HexBinary->new($v);
}

{
	my $format;
	
	sub _strToDateTimeAndStamp
	{
		my ($incoming_v, $timezone_required, $FORCE_UTC) = @_;
		$format ||= DateTime::Format::XSD->new;

		my $v = try
		{
			$format->parse_datetime($incoming_v);
		}
		except
		{
			throw Error::Simple(sprintf('Invalid dateTime (bad syntax) "%s"', $incoming_v));
		};
		throw Error::Simple(sprintf('Invalid dateTimeStamp (no timezone) "%s"', $incoming_v))
			if $v->time_zone->is_floating && $timezone_required;

		# XSD does this; OWL2 does not.
		if ($FORCE_UTC
		and !$v->time_zone->is_floating)
		{
			$v->set_time_zone('UTC'); # canonicalise TZ
		}
		
		my $formatted = $format->format_datetime($v);
		
		# DateTime::Format::XSD ignores fractional seconds :-(
		# DateTime::Format::XSD seems to assume UTC :-( :-(
		if ($v->nanosecond or $v->time_zone->is_floating)
		{
			my ($datetime, $zone) = ($formatted =~ m{^(.+?)(Z|[\+\-]\d{2}:\d{2})?$});
			
			if ($v->nanosecond)
			{
				$datetime .= $v->strftime('.%9N'); # append nine digits of fractional seconds
				$datetime =~ s/0+$//g; # remove trailing 0s
			}
			
			$formatted  = $datetime;
			$formatted .= $zone unless $v->time_zone->is_floating;
		}
		$formatted =~ s/[\+\-]00:00$/Z/;
		
		return RDF::Closure::DatatypeTuple::DateTime->new($formatted, $v);
	}

	sub _strToTime
	{
		my ($incoming_v, $FORCE_UTC) = @_;
		# Just pass through _strToDateTimeAndStamp with a fake date (which
		# shouldn't be too near any leap seconds!)
		my $rv = ''._strToDateTimeAndStamp("2009-02-12T${incoming_v}", FALSE, $FORCE_UTC);
		$rv =~ s/^\d{4}-\d{2}-\d{2}T//i;
		return RDF::Closure::DatatypeTuple::Time->new($rv);
	}
}

{
	my (%format, %format_tz);
	
	sub _strToDateOrPart
	{
		my ($incoming_v, $class, $pattern, $has_timezone) = @_;
		
		# DateTime always needs a year, month and day.
		my $processed_v       = $incoming_v;
		my $processed_pattern = $pattern;
		unless ($pattern =~ /\%y/i)
		{
			my $processing = '##%s## %s';
			$processed_pattern = sprintf($processing, '%Y', $pattern);
			$processed_v       = sprintf($processing, '2012', $incoming_v); # use a leap year!
		}
		unless ($pattern =~ /\%m/)
		{
			my $processing = '####%s#### %s';
			$processed_pattern = sprintf($processing, '%m', $processed_pattern);
			$processed_v       = sprintf($processing, '10', $processed_v); # use a 31 day month!
		}
		unless ($pattern =~ /\%d/)
		{
			my $processing = '######%s###### %s';
			$processed_pattern = sprintf($processing, '%d', $processed_pattern);
			$processed_v       = sprintf($processing, '24', $processed_v);
		}
		
		# strptime only understands '+0100' style timezones
		$processed_v =~ s/z$/\+0000/i;
		$processed_v =~ s/([\+\-]\d\d):(\d\d)$/$1$2/;
		
		$format{ $processed_pattern } ||= DateTime::Format::Strptime->new(
			pattern   => $processed_pattern,
			time_zone => DateTime::TimeZone->new(name=>'floating'),
			locale    => 'en_US',
			on_error  => 'undef',
			);
		$format_tz{ $processed_pattern } ||= DateTime::Format::Strptime->new(
			pattern   => $processed_pattern.'%z',
			locale    => 'en_US',
			on_error  => 'undef',
			);
		
		my $v = $format_tz{ $processed_pattern }->parse_datetime($processed_v)
		        || $format{ $processed_pattern }->parse_datetime($processed_v);
		
		throw Error::Simple(sprintf('Invalid date/date-part (unparsable) "%s"', $incoming_v))
			if !defined $v;
		
		throw Error::Simple(sprintf('Invalid date/date-part (no timezone) "%s"', $incoming_v))
			if $v->time_zone->is_floating && defined $has_timezone && $has_timezone==1;
		
		throw Error::Simple(sprintf('Invalid date/date-part (has timezone) "%s"', $incoming_v))
			if !$v->time_zone->is_floating && defined $has_timezone && $has_timezone==0;
		
		my $formatted = $v->strftime($pattern);
		
		unless ($v->time_zone->is_floating)
		{
			if ($v->time_zone->is_utc)
			{
				$formatted .= 'Z';
			}
			else
			{
				(my $tz = $v->strftime('%z')) =~ s/^(...)(..)$/$1:$2/;
				$formatted .= $tz;
			}
		}
		
		$class = sprintf('RDF::Closure::DatatypeTuple::%s', $class)
			unless $class =~ /::/;
		
		return $class->new($formatted, $v);
	}
}

#: regular expression for a 'language' datatype
my $_re_language  = qr/^[a-zA-Z]{1,8}(-[a-zA-Z0-9]{1,8})*$/;

#: regexp for NMTOKEN. It must be used with a re.U flag (the '(?U' regexp form did not work. It may depend on the locale...)
my $_re_NMTOKEN   = qr/^[\w:_.\-]+$/;

#: characters not permitted at a starting position for Name (otherwise Name is like NMTOKEN
my $_re_Name_ex   = [qw{. - 0 1 2 3 4 5 6 7 8 9}];

#: regexp for NCName. It must be used with a re.U flag (the '(?U' regexp form did not work. It may depend on the locale...)
my $_re_NCName    = qr/^[\w_.\-]+$/;

#: characters not permitted at a starting position for NCName
my $_re_NCName_ex = [qw{. - 0 1 2 3 4 5 6 7 8 9}];

# xsd:normalisedString
my $_re_normalString = qr"^[^\n\t\r]+$";

sub _strToVal_Regexp
{
	my ($v, $regexp, $excludeStart) = @_;
	$excludeStart ||= [];
	
	if (defined $regexp and $v !~ $regexp)
	{
		throw Error::Simple(sprintf('Invalid literal "%s"; does not match %s.', $v, $regexp));
	}
	my $firstChar = substr($v, 0, 1);
	if (grep { $_ eq $firstChar } @$excludeStart)
	{
		throw Error::Simple(sprintf('Invalid literal "%s"; starts with "%s" but should not.', $v, $firstChar));
	}
	
	return RDF::Closure::DatatypeTuple::String->new($v);
}

sub _strToToken
{
	my ($v) = @_;
	
	throw Error::Simple(sprintf('Invalid token (illegal whitespace character) "%s".', $v))
		unless $v =~ $_re_normalString;
	
	throw Error::Simple(sprintf('Invalid token (doubled space) "%s".', $v))
		if $v =~ /\s\s/;
	
	throw Error::Simple(sprintf('Invalid token (leading space) "%s".', $v))
		if $v =~ /^\s/;
		
	throw Error::Simple(sprintf('Invalid token (trailing space) "%s".', $v))
		if $v =~ /\s$/;
	
	return RDF::Closure::DatatypeTuple::String->new($v);
}

sub _strToPlainLiteral
{
	my ($v) = @_;
	my ($value, $lang) = ($v =~ m{^(.*)\@([^\@]+)?$});
	
	if (defined $lang and $lang !~ $_re_language)
	{
		throw Error::Simple(sprintf('Invalid language tag "%s"', $lang));
	}
	
	return RDF::Closure::DatatypeTuple::PlainLiteral->new(sprintf('%s@%s', $value, lc($lang||'')));
}

{
	my $parser;
	sub _strToXMLLiteral
	{
		my ($v) = @_;
		$parser ||= XML::LibXML->new;
		try
		{
			my $fragment = $parser->parse_balanced_chunk($v);
			my $canonical = join '', map
				{
					my $r; # we should use canonical XML,
					       # but that doesn't always work out. :-(
					$r = eval { $_->toStringEC14N(TRUE); };
					$r = eval { $_->toStringC14N(TRUE); } unless defined $r;
					$r = eval { $_->toString; }           unless defined $r;
				}
				$fragment->childNodes;
			return RDF::Closure::DatatypeTuple::XMLLiteral->new($canonical, $fragment);
		}
		except
		{
			throw Error::Simple(sprintf('Poorly-formed XML """%s"""', $v));
		};
	}
}


{
	my %mapping = (
		$XSD->language->uri  =>                 sub { _strToVal_Regexp($_[0], $_re_language); },
		$XSD->NMTOKEN->uri  =>                  sub { _strToVal_Regexp($_[0], $_re_NMTOKEN); },
		$XSD->Name->uri  =>                     sub { _strToVal_Regexp($_[0], $_re_NMTOKEN, $_re_Name_ex); },
		$XSD->NCName->uri  =>                   sub { _strToVal_Regexp($_[0], $_re_NCName, $_re_NCName_ex); },
		$XSD->token->uri  =>                    \&_strToToken,
		$RDF->PlainLiteral->uri  =>             \&_strToPlainLiteral,
		$XSD->boolean->uri  =>                  \&_strToBool,
		$XSD->decimal->uri  =>                  \&_strToDecimal,
		$XSD->anyURI->uri  =>                   \&_strToAnyURI,
		$XSD->base64Binary->uri  =>             \&_strToBase64Binary,
		$XSD->double->uri  =>                   \&_strToDouble,
		$XSD->float->uri  =>                    \&_strToFloat,
		$XSD->byte->uri  =>                     sub { _strToBoundNumeral($_[0], $_limits_byte); },
		$XSD->int->uri  =>                      sub { _strToBoundNumeral($_[0], $_limits_int); },
		$XSD->long->uri  =>                     sub { _strToBoundNumeral($_[0], $_limits_long); },
		$XSD->positiveInteger->uri  =>          sub { _strToBoundNumeral($_[0], $_limits_positiveInteger); },
		$XSD->nonPositiveInteger->uri  =>       sub { _strToBoundNumeral($_[0], $_limits_nonPositiveInteger); },
		$XSD->negativeInteger->uri  =>          sub { _strToBoundNumeral($_[0], $_limits_negativeInteger); },
		$XSD->nonNegativeInteger->uri  =>       sub { _strToBoundNumeral($_[0], $_limits_nonNegativeInteger); },
		$XSD->short->uri  =>                    sub { _strToBoundNumeral($_[0], $_limits_short); },
		$XSD->unsignedByte->uri  =>             sub { _strToBoundNumeral($_[0], $_limits_unsignedByte); },
		$XSD->unsignedShort->uri  =>            sub { _strToBoundNumeral($_[0], $_limits_unsignedShort); },
		$XSD->unsignedInt->uri  =>              sub { _strToBoundNumeral($_[0], $_limits_unsignedInt); },
		$XSD->unsignedLong->uri  =>             sub { _strToBoundNumeral($_[0], $_limits_unsignedLong); },
		$XSD->hexBinary->uri  =>                \&_strToHexBinary,
		$RDF->XMLLiteral->uri	 =>             \&_strToXMLLiteral,
		$XSD->integer->uri  =>                  sub { _strToBoundNumeral($_[0], [undef, undef]); },
		$XSD->string->uri  =>                   sub { _strToVal_Regexp($_[0]); },
		$XSD->normalizedString->uri  =>         sub { _strToVal_Regexp($_[0], $_re_normalString); },
		$XSD->dateTime->uri  =>                 sub { my $n = $_[1]||__PACKAGE->new; _strToDateTimeAndStamp($_[0], FALSE, $n->force_utc); },
		$XSD->dateTimeStamp->uri  =>            sub { my $n = $_[1]||__PACKAGE->new; _strToDateTimeAndStamp($_[0], TRUE, $n->force_utc); },
	#	# These are RDFS specific...
		$XSD->time->uri  =>                     \&_strToTime,
		$XSD->date->uri  =>                     sub { _strToDateOrPart($_[0], 'Date', '%Y-%m-%d'); },
		$XSD->gYearMonth->uri  =>               sub { _strToDateOrPart($_[0], 'GYearMonth', '%Y-%m'); },
		$XSD->gYear->uri  =>                    sub { _strToDateOrPart($_[0], 'GYear', '%Y'); },
		$XSD->gMonthDay->uri  =>                sub { _strToDateOrPart($_[0], 'GMonthDay', '--%m-%d'); },
		$XSD->gDay->uri  =>                     sub { _strToDateOrPart($_[0], 'GDay', '---%d'); },
		$XSD->gMonth->uri  =>                   sub { _strToDateOrPart($_[0], 'GMonth', '--%m'); },
	);
	
	my @ichecks = (
		sub 
		{
			my ($self, $lit1, $lit2) = @_;
			# Perhaps we have a plain literal and an xsd:string.
			# There's still a chance that they're identical!
			# (refer to the value space of rdf:PlainLiteral)
			if ($lit1->[0] eq $RDF->PlainLiteral->uri || $lit1->[0] eq 'RDF::Closure::DatatypeTuple::PlainLiteral'
			and $lit2->[0] eq $XSD->string->uri       || $lit2->[0] eq 'RDF::Closure::DatatypeTuple::String')
			{
				return TRUE if $lit1->[1] eq sprintf('%s@', $lit2->[1]);
			}
			return FALSE;
		},
	);

	sub new
	{
		my ($class, %args) = @_;
		my $self = bless {%args}, $class;
		while (my ($dt, $code) = each %mapping)
		{
			$self->{mapping}{$dt} ||= $code;
		}
		$self->{identity_checks} ||= [];
		push @{ $self->{identity_checks} }, @ichecks;
		return $self;
	}
}

sub force_utc
{
	my ($self) = @_;
	return $self->{force_utc} if defined $self->{force_utc};
	return FALSE; # default
}

sub mapping
{
	my ($self, $dt) = @_;
	if (defined $dt)
	{
		return $self->{mapping}{$dt};
	}
	return $self->{mapping};
}

sub _process_args
{
	my @args = @_;
	my $self;
	
	if (blessed($args[0]) and $args[0]->isa(__PACKAGE__))
	{
		$self = shift @args;
	}
	elsif (!ref($args[0])  and $args[0]->isa(__PACKAGE__))
	{
		$self = shift(@args)->new;
	}
	else
	{
		$self = __PACKAGE__->new;
	}
	
	return ($self, @args);
}

sub literal_to_perl
{
	my ($self, $lit) = _process_args(@_);
	
	my $dt = $lit->literal_datatype;
	if (!defined $dt)
	{
		return RDF::Closure::DatatypeHandling::StringWithLang->new($lit->literal_value, $lit->literal_value_language);
	}
	elsif ($dt eq $RDF->PlainLiteral->uri)
	{
		if ($lit->literal_value =~ /^(.*)@([^@]*)$/)
		{
			return RDF::Closure::DatatypeHandling::StringWithLang->new($1, $2);
		}
		return $lit->literal_value;
	}
	elsif (defined $self->mapping($dt))
	{
		my $r = $self->mapping($dt)->($lit->literal_value, $self);
		return defined $r->[1] ? $r->[1] : $r->[0];
	}
	
	return $lit->literal_value;
}

sub literal_tuple
{
	my ($self, $lit) = _process_args(@_);
	
	my $dt = $lit->literal_datatype;
	if (!defined $dt)
	{
		throw Error::Simple(sprintf('Plain literal language "%s" looks designed to trip me up!', $lit->literal_value_language))
			if ($lit->literal_value_language||'') =~ /\@/;
		
		return [ 'RDF::Closure::DatatypeTuple::PlainLiteral',
			sprintf('%s@%s', $lit->literal_value, lc($lit->literal_value_language||'')) ];
	}
	elsif (defined $self->mapping($dt))
	{
		my $r = $self->mapping($dt)->($lit->literal_value, $self);
		return [ ref($r), "$r" ];
	}
	
	return [ $dt, $lit->literal_value ];
}

sub literal_tuple_safe
{
	my ($self, $lit) = _process_args(@_);
	
	return try
	{
		return $self->literal_tuple($lit);
	}
	catch Error with
	{
		return [$lit->literal_datatype, $lit->literal_value];
	};
}

sub literal_valid
{
	my ($self, $lit) = _process_args(@_);
	
	my $r = try
	{
		return $self->literal_tuple($lit);
	}
	catch Error with
	{
		return undef;
	};
	return $r||TRUE
		if defined $r;
	return;
}

sub literal_canonical
{
	my ($self, $lit) = _process_args(@_);
	
	if (!$lit->has_datatype)
	{
		throw Error::Simple(sprintf('Plain literal language "%s" looks designed to trip me up!', $lit->literal_value_language))
			if ($lit->literal_value_language||'') =~ /\@/;
		
		return RDF::Trine::Node::Literal->new(
			sprintf('%s@%s', $lit->literal_value, lc($lit->literal_value_language||'')),
			undef,
			$RDF->PlainLiteral->uri,
			);
	}
	
	my $dt = $lit->literal_datatype;
	if (defined $dt and defined $self->mapping($dt))
	{
		return RDF::Trine::Node::Literal->new(
			$self->mapping($dt)->($lit->literal_value, $self)->to_string,
			undef,
			$dt,
			);
	}
	
	return $lit;
}

sub literal_canonical_safe
{
	my ($self, $lit) = _process_args(@_);

	return try
	{
		return $self->literal_canonical($lit);
	}
	catch Error with
	{
		return $lit;
	};
}

sub literals_identical
{
	my ($self, @args) = _process_args(@_);

	my ($lit1, $lit2) = map { $self->literal_tuple_safe($_); } @args[0..1];
	
	return [$lit1, $lit2]
		if ($lit1->[0] eq $lit2->[0] and $lit1->[1] eq $lit2->[1]);

	($lit1, $lit2) = sort {$a->[0] cmp $b->[0]} ($lit1, $lit2);
	foreach my $check (@{ $self->{identity_checks} })
	{
		return [$lit1, $lit2] if $check->($self, $lit1, $lit2);
	}
	
	return;
}

1;

package RDF::Closure::DatatypeHandling::StringWithLang;

use overload '""' => sub { $_[0]->value };

sub new
{
	my ($class, @args) = @_;
	return bless \@args, $class;
}
sub value { $_[0]->[0]; }
sub lang  { lc $_[0]->[1]; }
sub trine { RDF::Trine::Node::Literal->new($_[0]->value, $_[0]->lang); }

sub lang_range_check
{
	my ($self, $range) = @_;
	my $lang = $self->lang;
	
	$range =~ s/\s//g;
	$lang  =~ s/\s//g;
	
	my $match = sub
	{
		my ($r, $l) = @_;
		return ($r eq '*' || $r eq $l);
	};
	
	my @range = split /\-/, lc $range;
	my @lang  = split /\-/, lc $lang;
	
	return unless $match->($range[0], $lang[0]);
	
	my $rI = 1;
	my $rL = 1;
	
	LOOP: while ($rI < scalar(@range))
	{
		if ($range[$rI] eq '*')
		{
			$rI++;
			next LOOP;
		}
		
		if ($rL >= scalar(@lang))
		{
			return;
		}
		
		if ($match->($range[$rI], $lang[$rL]))
		{
			$rI++;
			$rL++;
			next LOOP;
		}
		
		if (length($lang[$rL]) == 1)
		{
			return;
		}
		
		$rL++;
	}

	return 1;
}

1;

=head1 NAME

RDF::Closure::DatatypeHandling - validate and canonicalise typed literals

=head1 ANALOGOUS PYTHON

RDFClosure/DatatypeHandling.py

=head1 DESCRIPTION

Provides datatype handling functions for OWL 2 RL and RDFS datatypes.

=head2 Functional Interface

This module can export four functions:

=over

=item * C<< literal_canonical($lit) >>

Given an RDF::Trine::Node::Literal, returns a literal with the canonical lexical
value for its given datatype. If the literal is not a valid lexical form for its datatype
throws an L<Error>.

If the literal is a plain literal, returns an rdf:PlainLiteral typed literal; if the
literal is of an unrecognised datatype, simply returns the original literal. 

Note that as per OWL 2 RL rules, xsd:dateTime literals are I<not> shifted to UTC,
even though XSD says that UTC is the canonical form. By setting the
C<< force_utc >> to true, you can force XSD-style canonicalisation. (See
the object-oriented interface.)

=item * C<< literal_canonical_safe($lit) >>

As per C<literal_canonical>, but in the case where a literal is not a valid lexical
form, simply returns the original literal.

=item * C<< literal_valid($lit) >>

Returns true iff the literal is a valid lexical form for its datatype. An example of
an invalid literal might be:

  "2011-02-29"^^xsd:date

=item * C<< literals_identical($lit1, $lit2) >>

Returns true iff the two literals are identical according to OWL 2 RL. Here are some
example pairs that are identical:

  # integers and decimals are drawn from the same pool of values
  "1.000"^^xsd:decimal
  "1"^^xsd:integer
  
  # different ways of writing the same datetime
  "2010-01-01T12:00:00.000Z"^^xsd:dateTime
  "2010-01-01T12:00:00+00:00"^^xsd:dateTime

Here are some example literals that are not identical:

  # floats and decimals are drawn from different pools of values
  "1.000"^^xsd:float
  "1"^^xsd:integer
  
  # according to OWL 2 these are "equal but not identical".
  "2010-01-01T12:00:00+00:00"^^xsd:dateTime
  "2010-01-01T11:00:00-01:00"^^xsd:dateTime

This latter example is affected by C<< force_utc >>.

=item * C<< literal_to_perl($lit) >>

Returns a scalar value for the literal, or an appropriate object with overloaded operators
(e.g. L<DateTime>, L<Math::BigInt>).

=back

Variables C<$RDF>, C<$RDFS>, C<$OWL> and C<$XSD> may also be exported
as a convenience. These are L<RDF::Trine::Namespace> objects. Don't
modify them.

=head2 Object-Oriented Interface

  use RDF::Trine;
  use RDF::Closure::DatatypeHandling qw[$XSD];
  
  my $lit     = RDF::Trine::Node::Literal->new(
    "2010-01-01T11:00:00-01:00", undef, $XSD->dateTime);
  my $handler = RDF::Closure::DatatypeHandling->new(force_utc => 1);
  print $handler->literal_canonical($lit)->as_ntriples;

=head1 SEE ALSO

L<RDF::Closure>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2011 Ivan Herman

Copyright 2011-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under any of the following licences:

=over

=item * The Artistic License 1.0 L<http://www.perlfoundation.org/artistic_license_1_0>.

=item * The GNU General Public License Version 1 L<http://www.gnu.org/licenses/old-licenses/gpl-1.0.txt>,
or (at your option) any later version.

=item * The W3C Software Notice and License L<http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231>.

=item * The Clarified Artistic License L<http://www.ncftp.com/ncftp/doc/LICENSE.txt>.

=back


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut


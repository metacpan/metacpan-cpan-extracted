package Net::DNS::ZoneParse;

use 5.008000;
use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use Exporter;
use Net::DNS;
use Net::DNS::ZoneParse::Zone;

@ISA = qw(Exporter);
$VERSION = 0.103;
@EXPORT = qw( );
%EXPORT_TAGS = (
	parser => [ qw( parse writezone ) ],
);

@EXPORT_OK = map { @{$_} } values %EXPORT_TAGS;

=pod

=head1 NAME

Net::DNS::ZoneParse - Perl extension for Parsing and Writing BIND8/9
(and RFC1035) compatible zone-files.

=head1 SYNOPSIS

Plain interface

  use Net::DNS::ZoneParse qw(parse, writezone);

  my $rr = parse("db.example.com");
  my $zonetext = writezone($rr);

Object oriented interface - supporting cached parsing

  use Net::DNS::ZoneParse;

  my $parser = Net::DNS::ZoneParse->new;
  my $zone = $parser->zone("example.com");
  $zone->rr->[0]->newserial if($zone->rr->[0]->{type} eq "SOA");
  $zone->save;


=head1 DESCRIPTION

This module is yet another caching parser/generator for RFC1035 compatible
zone-files. It aims to have a fast interface for parsing and support all RRs
known to Net::DNS::RR.

In some circumstances the parsing of an entry is too complicated for the
default _from_string-logic of the corresponding RR. For this cases,
N::D::ZoneParse extends the Interface of N::D::RR with the function
new_from_filestring. Per default this will call the responding new_from_string,
but may be implemented differently for a given RR.

When dealing not just with one Zonefile, the Object-oriented Interface
even becomes more handy. It provides an interface loading only the zonefiles
needed and those only once. Each Zone is then represented by a
Net::DNS::ZoneParse::Zone object.

=cut

#####################
# private functions #
#####################

# test if the given directive may be valid and set it up
sub _dns_test_set_origin {
	my ($origin, $param) = @_;

	return unless $origin;
	$origin .= "." unless (substr($origin, -1) eq ".");
	$origin = substr($origin, 1) if(substr($origin, 0, 1) eq ".");
	$param->{origin} = $origin;
	$param->{name} = substr($origin, 0, -1);
}

# read and validate the arguments
sub _parser_param {
	my $self = { dummy => 1 };
	$self = shift if(ref($_[0]) eq "Net::DNS::ZoneParse");
	my $file = shift unless(ref($_[0]));
	my $fh = shift if(ref($_[0]) eq "GLOB");
	my $param = {};
	$param = shift if(ref($_[0]) eq "HASH");
	my $rrs = [];
	$rrs = shift if(ref($_[0]) eq "ARRAY");
	$rrs = \@_ if(ref($_[0]) =~ m/^Net::DNS::RR/);

	if($param->{origin}) {
		_dns_test_set_origin($param->{origin}, $param);
	} else {
		$param->{origin} = "";
		$param->{name} = "";
	}

	$param->{ttl} = $param->{ttl} || $self->{$param->{name}}->{ttl} || 0;
	$param->{file} = $file || $param->{file} ||
			$self->{$param->{name}}->{filename} || "";
	$param->{fh} = $fh || $param->{fh};
	$param->{rrs} = $rrs if $rrs;
	if($param->{file} and not $param->{fh}) {
		open($param->{fh}, "<", $param->{file}) or return;
		$param->{fileopen} = 1;
	}
	$param->{nocache} = $self->{conf}->{nocache} unless $param->{nocache};
	$param->{parser} = $self->{conf}->{parser} || [ qw( Native ) ]
       		unless $param->{parser};
	$param->{parser_args} = {} unless $param->{parser_args};
	$param->{self} = $self;
	return $param;
}

=pod

=head2 METHODS

=head3 new

	$parser = Net::DNS::ZoneParse->new( [ $config ] )

Creating a new Net::DNS::ZoneParse object with the given configuration
for file-autoloading. The following parameters are currently supported:

=over

=item path

Path to the directory where all of the ZoneFiles can be found. The default is
the current working directory.

=item prefix

The prefix to the generate the filename out of the zonename.
The default is "db.". Thus using the default, loading "example.com" will
search for the file "db.example.com"

=item suffix

Similar to prefix, the default is the empty string.

=item dontload

If set to true, the zone() wont parsed the corresponding file automaticly

=item nocache

If set to true, loaded files won't be cached within this object automaticly.
In this case, extent has to be used.

=item parser

The parsers to use when reading files. These must be given within a
arrayreference. All of the given parsers must be found within
Net::DNS::ZoneParse::Parser. The default is [ "Native" ]. All
Parsers in the list will be used consecutively unless one has returned
contents of the file to read.

=item parser_args

A hashref with parser-names as keys. Some parser may allow further
options; these can be accessed using this argument.

=item generator

The generators to use when generating a new zonefile. The use is corresponding
to parsers. Generators must be found within Net::DNS::ZoneParse::Generator

=back

=cut

sub new {
	my ($self, $config) = @_;
	$config = {} unless(defined $config);
	my %conf = (
		path => $config->{path},
		prefix => $config->{prefix} || "db.",
		suffix => $config->{suffix} || "",
		dontload => $config->{dontload},
		nocache => $config->{nocache},
	);
	return bless({conf => \%conf});
}

=head3 zone

	$zone = $parser->zone("example.com" [, $param])

Returns the Net::DNS::ZoneParse::Zone object for the given domain. If there
where no corresponding zonefile found, an empty Object will be returned.
If the zone was loaded for the first time the corresponding file will be loaded,
otherwise the cached object will be returned.

$param is a hash-reference which can be used to adjust the behaviour.
If a parameter is not given here, it's value used at the time of the objects
generation will be used. Supported parameters are:

=over

=item path

=item filename

This will take precedence above prefix/suffix

=item prefix

=item suffix

=item dontload

=back

=cut

sub zone {
	my ($self, $zone, $prm) = @_;
	$prm = {} unless $prm;
	unless($self->{$zone}) {
		$self->{$zone} = Net::DNS::ZoneParse::Zone->new($zone, {
				path => $prm->{path} || $self->{conf}->{path},
				filename => $prm->{filename} || 
					($prm->{prefix} || $self->{conf}->{prefix} || "" ).$zone.($prm->{suffix} || $self->{conf}->{suffix} || ""),
				dontload => $prm->{dontload} ||
					$self->{conf}->{dontload},
				parent => $self,
			});
	}
	return $self->{$zone};
}

=pod

=head3 extent

	$parser->extent("example.com", $rrs);

Extent the cached entries for the given origin - "example.com" in the example
by the RRs given in $rrs. These might be an array or a reference to an array
of Net::DNS::RR-Objects.

=cut

sub extent {
	my ($self, $zone, @rrs) = @_;
	return unless $zone;
	$zone = $self->zone($zone, { dontload => 1 });
	$zone->add(@rrs);
	return;
}

=pod

=head3 uncache

	$parser->uncache("example.com");

Uncaching removes a zone from the zonecache. The exported instances of this zone
will stay alive, but the next call to zone() will generate a new object.

=cut

sub uncache {
	my ($self, $zone) = @_;

	return unless $self->{$zone};
	delete $self->{$zone};
}

=pod

=head2 EXPORT

=head3 writezone

	$zonetext = writezone($rr);
	# or
	$zonetext = $parser->writezone($zone);

$rr might be either an array of Net::DNS::RR object, or a reference to them.
If using the object-oriented interface, this can be used to by just using
the name of the zone to write. In that case, correct directives for $ORIGIN
and $TTL will be created, too.

writezone will then return a string with the contents of a corresponding
zone-file.

As last parameter, a additional Hash-ref can be used to tweak some of the
behavior. The following parameters are supported:

=over

=item origin

This may contain the zone-name, unless used in the object-oriented interface

=item ttl

The default TTL to be used in the generated file.

=item rr

The Resource-records to write

=item generator

the same as in new

=back

=cut

sub writezone {
	my $self = {};
	$self = shift if(ref($_[0]) eq "Net::DNS::ZoneParse");
	my $prm = (ref($_[-1]) eq "HASH")?pop(@_):{};
	my %param;
       	$param{origin} = ((not ref($_[0]))?shift():($prm->{origin} || ""));
	$param{ttl} = $prm->{ttl} || $self->{$param{origin}}->{ttl} || 0;
	$param{rr} = ((ref($_[0]) eq "ARRAY")?shift():
			(($#_>=0) ? \@_ :
				$prm->{rr} || $self->{$param{origin}}->rr));
	$param{generator} = $prm->{generator} || $self->{conf}->{generator} || [ qw( Native ) ];
	return unless $param{rr};

	for(@{$param{generator}}) {
		my $gen = $_;
		my $mod = "Net::DNS::ZoneParse::Generator::$gen";
		eval "require $mod";
		next if $@;
		$param{parser_arg} = $param{parser_args}->{$gen} || {};
		my $ret = $mod->generate(\%param);
		return $ret if $ret;
	}
	return undef;
}

=head3 parse

	$rr = parse($file);
	# or
	$rr = $parser->parse($file [, $param [, $rrin]]);

parse a specific zonefile and returns a reference to an array of 
Net::DNS::RR objects.

If the function-oriented interface is used and Net::DNS::ZoneFile::Fast is
installed, that parser is used instead.

$file might be either a filename or a open filehandle to be read.

$param is a HASH-ref, with the following entries. If given, those may change to
reflect the contents of the parsed file.

=over

=item origin

The current domains name

=item ttl

The default TTL for all RRs

=item fh

An already opened filehandle, $file can be ommitted, if this is given.

=item file

The name of the file to read, $file can be ommitted, if this is given

=item rrs

Resource Records, which will be added to these found in the file

=item nocache

if given, the parsed file will not be cached in the object.

=item parser

=item parser_args

Same as in the call of new().

=back

$rrin is a ARRAY-ref of Net::DNS::RR objects. If given, this list will be
extended.

=cut

sub parse {
	my $param = _parser_param(@_);
	return unless $param;
	return unless $param->{fh};

	my $ret;
	for(@{$param->{parser}}) {
		my $parser = $_;
		my $mod = "Net::DNS::ZoneParse::Parser::$_";
		eval "require $mod"; 
		next if $@;
		$param->{parser_arg} = $param->{parser_args}->{$parser} || {};
		$ret = $mod->parse($param);
		next unless $ret;
		last;
	}
	if($param->{fileopen}) {
		close($param->{fh});
		delete($param->{fh}); delete($param->{fileopen});
	};
	if((not $param->{self}->{dummy})
			and $param->{name} and not $param->{nocache}) {
		$param->{self}->extent($param->{name}, $ret);
	}
	delete $param->{self} if $param->{self}->{dummy};
	unshift(@{$ret}, @{$param->{rrs}}) if $param->{rrs};
	return $ret;
}

=head1 SEE ALSO

Net::DNS

=head1 AUTHOR

Benjamin Tietz E<lt>benjamin@micronet24.deE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by Benjamin Tietz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;


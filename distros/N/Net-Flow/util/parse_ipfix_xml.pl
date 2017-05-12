#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';
use feature qw(switch);    # For given/when syntax, perldoc perlsyn.

use Data::Dumper;
use XML::Simple qw(:strict);


# wget https://www.iana.org/assignments/ipfix/ipfix.xml
my $config = XMLin(
	'ipfix.xml',
	KeyAttr    => { registry => 'id' },
	ForceArray => ['registry']
);

#print Dumper($config);

my $registry = $config->{registry}->{'ipfix-information-elements'};
my $records  = $registry->{record};

my %informationElementsByName;
my %informationElementsById;
for my $record (@$records) {
	my $enterpriseId = 0;
	my $elementId    = $record->{elementId} // 'unknown';
	my $name         = $record->{name} || $enterpriseId . '_' . $elementId;
	$name =~ tr/ \t\n\r//d;
	my $dataTypeSemantics = $record->{dataTypeSemantics} || 'default';
	my $dataType          = $record->{dataType}          || 'octetArray';
	my $units             = $record->{units}             || 'none';
	my $reserved;
	my $applicability = $record->{applicability};
	my $group         = $record->{group};
	my $range         = $record->{range};
	my $status        = $record->{status};

  if ( $name =~ /^(reserved|unassigned|assignedfornetflowv9compatibility)$/i ) {
    $reserved = $1;
  }

	$range = '' if ref $range;

	# units is an enum in the DB and these are the valid values.
	$units = 'none' unless $units =~ /^(none|bits|octets|packets|flows|seconds|milliseconds|microseconds|nanoseconds|4-octet words|messages|hops|entries)$/;

	unless ( $reserved ) {
		$informationElementsById{$elementId} = {
			enterpriseId      => undef,                # $enterpriseId
			elementId         => $elementId,
			dataType          => $dataType,
			dataTypeSemantics => $dataTypeSemantics,
			name              => $name,
			units             => $units,
			range             => $range,
			group             => $group,
			applicability     => $applicability,
		};
		$informationElementsByName{$name} = $informationElementsById{$elementId};
	}
}


$Data::Dumper::Sortkeys = sub {
	my $h = shift;
	return [
		sort {
			if ( $a =~ /^\d+$/ && $b =~ /^\d+$/ ) {
				$a <=> $b;
			} else {
				lc($a) cmp lc($b);
			}
		} ( keys %$h )
	];
};
print Dumper ( \%informationElementsByName );
print Dumper ( \%informationElementsById );

1;

__END__


# Local Variables: ***
# mode:CPerl ***
# cperl-indent-level:2 ***
# perl-indent-level:2 ***
# tab-width: 2 ***
# indent-tabs-mode: nil ***
# End: ***
#
# vim: ts=2 sw=2 expandtab

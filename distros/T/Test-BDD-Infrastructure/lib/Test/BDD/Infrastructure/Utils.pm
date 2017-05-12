package Test::BDD::Infrastructure::Utils;

use strict;
use warnings;

# ABSTRACT: class with collection of some utility functions
our $VERSION = '1.005'; # VERSION

our (@ISA, @EXPORT_OK);

use Test::BDD::Infrastructure::Config;

use Time::Seconds;

BEGIN {
        require Exporter;

        @ISA = qw(Exporter);
        @EXPORT_OK = qw( &convert_unit &convert_cmp_operator $CMP_OPERATOR_RE
		convert_interval lookup_config lookup_config_node );
}


our $CMP_OPERATORS = {
	'at least' => '>=',
	'a maximum of' => '<=',
	'not more than' => '<=',
	'more than' => '>',
	'bigger than' => '>',
	'greater than' => '>',
	'less than' => '<',
	'smaller than' => '<',
	'equal' => '==',
	'exactly' => '==',
	'newer than' => '<',
	'older than' => '>',
	'the string' => 'eq',
	'the value' => 'eq',
	'not the string' => 'ne',
	'not the value' => 'ne',
};

our $CMP_OPERATOR_RE = '('.join('|', keys %$CMP_OPERATORS ).')';

sub convert_cmp_operator {
	my ( $str ) = @_;
	$str = lc $str;
	if( ! defined $CMP_OPERATORS->{ $str } ) {
		die('unknown operator: '.$str);
	}
	return $CMP_OPERATORS->{ $str };
}


our $UNITS = {
	'%' => 0.01,
	percent => 0.01,

	byte => 1,
	b => 1,

	kilobyte => 1000,
	kb => 1000,
	megabyte => 1000000,
	mb => 1000000,
	gigabyte => 1000000000,
	gb => 1000000000,
	terrabyte => 1000000000000,
	tb => 1000000000000,

	kibibyte => 1024,
	kib => 1024,
	mebibyte => 1024*1024,
	mib => 1024*1024,
	gibibyte => 1024*1024*1024,
	gib => 1024*1024*1024,
	tebibyte => 1024*1024*1024*1024,
	tib => 1024*1024*1024*1024,
};

sub convert_unit {
	my ( $size, $unit ) = @_;
	$unit = lc $unit;
	if( ! defined $UNITS->{$unit} ) {
		die('unknown unit '.$unit);
	}
	return( $size * $UNITS->{$unit} );
}


our $INTERVALS = {
	second => 1,
	seconds => 1,
	day => ONE_DAY,
	days => ONE_DAY,
	week => ONE_WEEK,
	weeks => ONE_WEEK,
	hour => ONE_HOUR,
	hours => ONE_HOUR,
	minute => ONE_MINUTE,
	minutes => ONE_MINUTE,
	month => ONE_MONTH,
	months => ONE_MONTH,
	year => ONE_YEAR,
	years => ONE_YEAR,
};

sub convert_interval {
	my ( $count, $unit ) = @_;
	$unit = lc $unit;
	if( ! defined $INTERVALS->{$unit} ) {
		die('unknown interval '.$unit);
	}
	return( $count * $INTERVALS->{$unit} );
}

sub _parse_var {
	my $str = shift;
	if( $str =~ /^\\\$/ ) { # escaped \$
		$str =~ s/^\\\$/\$/;
		return;
	}
	if( $str !~ /^\$/ ) {
		return;
	}
	$str =~ s/^\$//;
	my ( $scope, $path );
	if( ( $scope, $path ) = $str =~ /^([^:]*):(.*)$/ ) {
		if( $scope eq '' ) { $scope = 'c' }
	} else {
		$scope = 'c';
		$path = $str;
	}
	return( $scope, $path );
}


sub lookup_config {
	my $str = shift;

	if( my ( $scope, $path ) = _parse_var( $str ) ) {
		my $c = Test::BDD::Infrastructure::Config->new;
		return $c->get( $scope, $path );
	}

	return $str;
}


sub lookup_config_node {
	my $str = shift;

	if( my ( $scope, $path ) = _parse_var( $str ) ) {
		my $c = Test::BDD::Infrastructure::Config->new;
		return $c->get_node( $scope, $path );
	}

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure::Utils - class with collection of some utility functions

=head1 VERSION

version 1.005

=head1 Human readable operators

The Utils package provides human readable comparsion operators.

=head2 convert_cmp_operator( $op )

Returns the perl operator for $op as string.

=head2 $CMP_OPERATOR_RE

Contains a regex to match all supported operators.

=head2 Synopsis

  use Test::BDD::Infrastructure::Utils qw(
        convert_cmp_operator $CMP_OPERATOR_RE );

  Then qr/the file must contain $CMP_OPERATOR_RE (\d+) lines/, sub {
    my $op = convert_cmp_operator( $1 );
    my $count = $2;
    my $lines = calc_lines();
    cmp_ok( $lines, $op, $count, "the file must contain $op $count lines");
  }

=head2 Examples

  Then the file must contain at least 10 lines

=head2 Supported Operators

=over

=item at least

=item a maximum of

=item not more than

=item more than

=item bigger than

=item greater than

=item less than

=item smaller than

=item equal

=item exactly

=item newer than

=item older than

=back

=head1 Byte units

The module provides conversion of human readable byte units.

=head2 convert_unit( $size, $unit )

Returns the size in bytes.

=head2 Supported units

=over

=item percent, %

1/100

=item byte, b

1 byte

=item kilobyte, kb

1000 byte

=item megabyte, mb

1000000 byte

=item gigabyte, gb

1000000000 byte

=item terrabyte, tb

1000000000000 byte

=item kibibyte, kib

1024 byte

=item mebibyte, mib

1048576 byte

=item gibibyte, gib

1073741824 byte

=item tebibyte, tb

1099511627776 byte

=back

=head1 Intervals

The module provides conversion of human readable intervals.

=head2 convert_interval( $count, $unit )

Return the interval in seconds.

=head2 Supported intervals

=over

=item second(s)

=item day(s)

=item week(s)

=item hour(s)

=item minute(s)

=item month(s)

=item year(s)

=back

=head1 Configuration variables

A backend for retrieving configuration variables is
implemented in L<Test::BDD::Infrastrucuture::Config>.

The following short-cut methods could be used to implement configuration
variables in step file definitions.

The syntax for variables is $<path> or $<scope>:<path>

If the scope is omitted the default 'c' will be used.

=head2 Example usage

If the step file definition is:

  Then qr/the value (\S+) must be bla/, sub {
    my $value = lookup_config( $1 );
    ok( is_bla($value), 'value must be bla' );
  }

then it could be used with variables:

  Then the value $bla must be bla

=head2 lookup_config( $str )

Tries to lookup the configuration value for $str if $str starts with "$"
otherwise the string is returned as-is.

=head2 lookup_config_node( $str )

Tries to lookup the configuration node for $str otherwise undef is returned.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

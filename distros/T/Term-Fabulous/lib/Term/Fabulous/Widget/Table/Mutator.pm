package Term::Fabulous::Widget::Table::Mutator;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Exporter 'import';
our @EXPORT_OK   = qw(datetime date number percent bytes duration boolean lookup truncate sprintf_format chain);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Carp qw(croak);
use POSIX ();
use Term::Fabulous::Widget::Table::Value qw(is_blank number_of date_epoch);
use Term::Fabulous::Unicode qw(grapheme_clusters cluster_columns string_columns);

sub _options ( $function, $known, %options ) {
	my @unknown = grep { !exists $known->{$_} } sort keys %options;
	croak "Term::Fabulous::Widget::Table::Mutator: $function does not accept @unknown (known: " . join( ', ', sort keys %$known ) . ")" if @unknown;
	return { %$known, %options };
}

sub _non_negative_integer ( $function, $name, $value ) {
	croak "Term::Fabulous::Widget::Table::Mutator: $function $name must be a non-negative integer, got " . ( defined $value ? "'$value'" : 'undef' )
		unless defined $value && !ref $value && $value =~ /\A[0-9]+\z/;
	return $value + 0;
}

# A number with a fixed number of decimals and a separator between groups
# of three digits.
sub _format_number ( $number, $decimals, $separator, $point ) {
	my $text = sprintf "%.${decimals}f", $number;
	my ( $sign, $whole, $fraction ) = $text =~ /\A(-?)([0-9]+)(?:\.([0-9]+))?\z/;
	$sign = '' if $text =~ /\A-0(?:\.0*)?\z/;    # no "-0.00"
	1 while length $separator && $whole =~ s/\A([0-9]+)([0-9]{3})/$1$separator$2/;
	return $sign . $whole . ( defined $fraction ? $point . $fraction : '' );
}

sub datetime ( $format = '%Y-%m-%d %H:%M', %options ) {
	my $settings = _options( datetime => { utc => 0 }, %options );
	croak "Term::Fabulous::Widget::Table::Mutator: datetime needs a strftime format string" if ref $format || !length $format;
	return sub ( $value, $row = undef ) {
		my $epoch = date_epoch($value) // return is_blank($value) ? '' : "$value";
		return POSIX::strftime( $format, $settings->{utc} ? gmtime $epoch : localtime $epoch );
	};
}

sub date ( $format = '%Y-%m-%d', %options ) {
	return datetime( $format, %options );
}

sub number (%options) {
	my $settings = _options( number => { decimals => undef, separator => ',', point => '.', prefix => '', suffix => '' }, %options );
	$settings->{decimals} = _non_negative_integer( number => decimals => $settings->{decimals} ) if defined $settings->{decimals};
	return sub ( $value, $row = undef ) {
		my $number   = number_of($value)     // return is_blank($value) ? '' : "$value";
		my $decimals = $settings->{decimals} // ( "$number" =~ /\.([0-9]+)\z/ ? length $1 : 0 );
		return $settings->{prefix} . _format_number( $number, $decimals, $settings->{separator}, $settings->{point} ) . $settings->{suffix};
	};
}

sub percent (%options) {
	my $settings = _options( percent => { decimals => 0, scale => 100, separator => ',', point => '.' }, %options );
	$settings->{decimals} = _non_negative_integer( percent => decimals => $settings->{decimals} );
	croak "Term::Fabulous::Widget::Table::Mutator: percent scale must be a number" unless defined number_of( $settings->{scale} );
	return sub ( $value, $row = undef ) {
		my $number = number_of($value) // return is_blank($value) ? '' : "$value";
		return _format_number( $number * $settings->{scale}, $settings->{decimals}, $settings->{separator}, $settings->{point} ) . '%';
	};
}

sub bytes (%options) {
	my $settings = _options( bytes => { decimals => 1, binary => 1 }, %options );
	$settings->{decimals} = _non_negative_integer( bytes => decimals => $settings->{decimals} );
	my ( $step, @units ) = $settings->{binary} ? ( 1024, qw(B KiB MiB GiB TiB PiB EiB) ) : ( 1000, qw(B kB MB GB TB PB EB) );
	return sub ( $value, $row = undef ) {
		my $number = number_of($value) // return is_blank($value) ? '' : "$value";
		my ( $size, $unit ) = ( abs $number, 0 );
		while ( $size >= $step && $unit < $#units ) {
			$size /= $step;
			$unit++;
		}
		my $sign = $number < 0 ? '-' : '';
		return $unit == 0 ? "$sign$size $units[0]" : sprintf( "%s%.$settings->{decimals}f %s", $sign, $size, $units[$unit] );
	};
}

sub duration (%options) {
	my $settings = _options( duration => { parts => 2 }, %options );
	my $parts    = _non_negative_integer( duration => parts => $settings->{parts} );
	croak "Term::Fabulous::Widget::Table::Mutator: duration parts must be at least 1" unless $parts >= 1;
	my @units = ( [ d => 86400 ], [ h => 3600 ], [ m => 60 ], [ s => 1 ] );
	return sub ( $value, $row = undef ) {
		my $number = number_of($value) // return is_blank($value) ? '' : "$value";
		my $left   = int abs $number;
		my @shown;
		foreach my $unit (@units) {
			my ( $name, $seconds ) = @$unit;
			my $count = int( $left / $seconds );
			$left -= $count * $seconds;
			push @shown, ( @shown ? sprintf( '%02d', $count ) : $count ) . $name if $count || @shown;
			last if @shown == $parts;
		}
		@shown = ('0s') unless @shown;
		return ( $number < 0 ? '-' : '' ) . join ' ', @shown;
	};
}

sub boolean ( $true_text = 'yes', $false_text = 'no' ) {
	croak "Term::Fabulous::Widget::Table::Mutator: boolean takes two strings" if ref $true_text || ref $false_text;
	return sub ( $value, $row = undef ) {
		return '' unless defined $value;
		return $value ? $true_text : $false_text;
	};
}

sub lookup ( $table, %options ) {
	croak "Term::Fabulous::Widget::Table::Mutator: lookup needs a hash reference" unless ref $table eq 'HASH';
	my $settings = _options( lookup => { default => undef }, %options );
	my %text_of  = %$table;
	return sub ( $value, $row = undef ) {
		return '' unless defined $value;
		return $text_of{$value} if exists $text_of{$value};
		return $settings->{default} // "$value";
	};
}

sub truncate ( $columns, %options ) {
	$columns = _non_negative_integer( truncate => columns => $columns );
	my $settings = _options( truncate => { ellipsis => "\x{2026}" }, %options );
	my $ellipsis = $settings->{ellipsis};
	my $room     = $columns - string_columns($ellipsis);
	croak "Term::Fabulous::Widget::Table::Mutator: truncate needs more columns than the ellipsis takes" if $room < 0;
	return sub ( $value, $row = undef ) {
		return '' unless defined $value;
		return "$value" if string_columns("$value") <= $columns;
		my ( $kept, $used ) = ( '', 0 );
		foreach my $cluster ( grapheme_clusters("$value") ) {
			my $width = cluster_columns($cluster);
			last if $used + $width > $room;
			$kept .= $cluster;
			$used += $width;
		}
		return $kept . $ellipsis;
	};
}

sub sprintf_format ($format) {
	croak "Term::Fabulous::Widget::Table::Mutator: sprintf_format needs a format string" if ref $format || !defined $format;
	return sub ( $value, $row = undef ) {
		return is_blank($value) ? '' : sprintf( $format, $value );
	};
}

sub chain (@mutators) {
	foreach my $mutator (@mutators) {
		croak "Term::Fabulous::Widget::Table::Mutator: chain takes code references" unless ref $mutator eq 'CODE';
	}
	return sub ( $value, $row = undef ) {
		$value = $_->( $value, $row ) foreach @mutators;
		return $value;
	};
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Table::Mutator - Ready-made mutators for table columns

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Table;
	use Term::Fabulous::Widget::Table::Mutator qw(datetime number bytes boolean lookup truncate);

	my $table = Term::Fabulous::Widget::Table->new(
		id      => 'files',
		columns => [
			{ key => 'name',     title => 'Name', mutator => truncate(30) },
			{ key => 'size',     title => 'Size', type => 'number', mutator => bytes() },
			{ key => 'modified', title => 'Modified', type => 'date', mutator => datetime('%d.%m.%Y %H:%M') },
			{ key => 'price',    title => 'Price', type => 'number', mutator => number( decimals => 2, prefix => '$' ) },
			{ key => 'shared',   title => 'Shared', mutator => boolean( 'yes', '' ) },
			{ key => 'state',    title => 'State', mutator => lookup( { r => 'running', s => 'sleeping' }, default => '?' ) },
		],
	);

=head1 DESCRIPTION

A I<mutator> turns the raw value of a table cell into the text the cell
shows: a code reference called as C<< $mutator->( $value, $row ) >>
with the raw value and a copy of the row's data, returning the text.
Give a column one, or an array reference of several that run one after
the other, with its C<mutator> option (see
L<Term::Fabulous::Widget::Table::Column/mutator>). The table keeps the
raw value for sorting and, unless told otherwise, for filtering.

This module makes the common ones. Each function below returns a new
mutator; nothing is exported by default, C<:all> exports everything.
Unknown options die. Every mutator turns a blank value (C<undef>, and
except for L</boolean> and L</lookup> also C<''>) into C<''>, and a
value it cannot read (a word where a number belongs) into that value as
text, so bad data stays visible.

=head1 FUNCTIONS

=head2 datetime

	datetime()                          # 2024-05-03 14:30
	datetime('%d.%m.%Y %H:%M:%S')
	datetime( '%H:%M', utc => 1 )

A date or time in a L<POSIX/strftime> format, default
C<'%Y-%m-%d %H:%M'>. The value may be epoch seconds, a date string
(C<2024-05-03 14:30>) or an object with an C<epoch> method (see
L<Term::Fabulous::Widget::Table::Value/date_epoch>). Local time, or
UTC with C<< utc => 1 >>.

=head2 date

	date()             # 2024-05-03
	date('%e %b %Y')   #  3 May 2024

L</datetime> with the default format C<'%Y-%m-%d'>.

=head2 number

	number()                                      # 1234567.5 -> 1,234,567.5
	number( decimals => 2 )                       # 1,234,567.50
	number( decimals => 0, separator => '.' )     # 1.234.568
	number( decimals => 2, separator => "\x{202F}", point => ',', suffix => ' EUR' )

A number with a separator between groups of three digits. Options:
C<decimals> (default: as many as the value has), C<separator> (default
C<','>, C<''> for none), C<point> (the decimal point, default C<'.'>),
C<prefix> and C<suffix> (default C<''>).

=head2 percent

	percent()                     # 0.153 -> 15%
	percent( decimals => 1 )      # 15.3%
	percent( scale => 1 )         # 15.3 -> 15%

A fraction as a percentage. Options: C<decimals> (default 0), C<scale>
(what the value is multiplied by, default 100; use 1 for values that
are percentages already), C<separator> and C<point> (as for
L</number>).

=head2 bytes

	bytes()                         # 1536 -> 1.5 KiB
	bytes( binary => 0 )            # 1536 -> 1.5 kB
	bytes( decimals => 0 )          # 2 KiB

A size in bytes with a unit: B, KiB, MiB, GiB, ... (steps of 1024), or
with C<< binary => 0 >> B, kB, MB, GB, ... (steps of 1000). Option
C<decimals>, default 1; sizes below one step are shown as they are,
with the unit B (C<512 B>).

=head2 duration

	duration()                  # 3725 -> 1h 02m
	duration( parts => 3 )      # 1h 02m 05s

Seconds as days, hours, minutes and seconds, showing at most C<parts>
units (default 2) from the largest one that is not 0. Negative
durations get a minus sign; 0 is C<0s>.

=head2 boolean

	boolean()                     # yes / no
	boolean( "\x{2714}", '' )    # a check mark, nothing for false

The first text for true values, the second for false ones (Perl's
truth: C<0>, C<''> and C<'0'> are false). C<undef> gives C<''>.

=head2 lookup

	lookup( { r => 'running', s => 'sleeping' } )
	lookup( { 1 => 'high', 2 => 'normal' }, default => 'unknown' )

The text the hash gives for the value; a value it does not have gives
C<default>, or the value itself when there is no C<default>. The hash is
copied.

=head2 truncate

	truncate(20)                       # long text cut to 20 columns, with an ellipsis
	truncate( 20, ellipsis => '...' )

Text that is wider than that many terminal columns is cut so that it
fits with the ellipsis (default C<"\x{2026}">, one column). Wide
characters count as two columns; no character is cut in half. To keep
long text whole but narrow, give the column a maximum width instead
(C<< width => 'fit(0, 20)' >>), and it wraps.

=head2 sprintf_format

	sprintf_format('%05d')       # 42 -> 00042
	sprintf_format('%.1f %%')    # 12.34 -> 12.3 %

The value formatted with L<perlfunc/sprintf>.

=head2 chain

	chain( truncate(10), sub ( $text, $row ) { uc $text } )

One mutator that runs several in order, each getting the result of the
one before. A column's C<mutator> option does the same with an array
reference.

=head1 WRITING YOUR OWN

Any code reference with this signature is a mutator:

	my $temperature = sub ( $value, $row ) {
		return '' unless defined $value;
		return sprintf '%.1f %s', $value, $row->{unit} eq 'F' ? "\x{2109}" : "\x{2103}";
	};

It should return a character string and not change C<$row> (a copy is
passed anyway). It is called again whenever the row or the column
changes, and once per cell otherwise: the table keeps the results.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Widget::Table::Column>,
L<Term::Fabulous::Widget::Table::Value>,
L<Term::Fabulous::Manual::Tables/DISPLAY TEXT AND MUTATORS>,
L<Term::Fabulous::Cookbook::Tables/Format cells: dates, numbers, sizes and flags (mutators)>.

=cut

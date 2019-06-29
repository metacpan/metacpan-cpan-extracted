package Sport::Analytics::NHL::Util;

use strict;
use warnings FATAL => 'all';

use Carp;
use File::Basename;
use File::Path qw(mkpath);
use Data::Dumper;
use Time::HiRes qw(time);
use Storable qw(dclone);
use Date::Parse;

use parent 'Exporter';

$SIG{__DIE__} = sub { Carp::confess( @_ ) };

=head1 NAME

Sport::Analytics::NHL::Util - Simple system-independent utilities

=head1 SYNOPSIS

Provides simple system-independent utilities. For system-dependent utilities see Sports::Analytics::NHL::Tools .

  use Sport::Analytics::NHL::Util qw(:debug :file);
  debug "This is a debug message";
  verbose "This is a verbose message";
  my $content = read_file('some.file');
  write_file($content, 'some.file');
  $config = read_config('some.config');

By default nothing is exported. You can import the functions either by name, or by the tags listed below, or by tag ':all'.

:debug     : debug verbose gamedebug timedebug eventdebug dumper

:file      : read_file write_file read_config

:utils     : my_uniq convert_hash_to_table lg fill_broken str3time numerify_structure

:format    : alight_text_table shorten_float_item initialize normalize_string

:times     : get_season_slash_string get_seconds get_time

:shortcuts : iterate_2

=head1 FUNCTIONS

=over 2

=item C<debug>

Produces message to the STDERR if the DEBUG level is set ($ENV{HOCKEYDB_DEBUG})

=item C<verbose>

Produces message to the STDERR if the VERBOSE ($ENV{HOCKEYDB_VERBOSE})or the DEBUG level are set.

=item C<read_file>

 Reads a file into a scalar
 Arguments: the filename
 Returns: the scalar with the filename contents

=item C<write_file>

 Writes a file from a scalar, usually replacing the non-breaking space with regular space
 Arguments: the content scalar
            the filename
 Returns: the filename written

=item C<read_tab_file>

 Reads a tabulated file into an array of arrays
 Arguments: the tabulated file
 Returns: array of arrays with the data

=item C<fill_broken>

Fills a hash (player, event, etc.) with preset values. Usually happens with broken items.
Arguments:
 * the item to fill
 * the hash with the preset values to use
Returns: void.

=item C<get_seconds>

 Get the number of seconds in MM:SS string
 Arguments: the MM:SS string
 Returns: the number of seconds

=item C<str3time>

Wraps around str2time to fix its parsing the pre-1969 dates to the same timestamp as their 100 years laters.
Arguments: the str2time argument string
Returns: the correct timestamp (negative for pre-1969)

=item C<my_uniq>

An expansion of List::MoreUtils::uniq function that filters the items not only by their value, but by applying a function to that value. Effectively:

 uniq @list == my_uniq { $_ } @list

=item C<normalize_string>

Performs a string cleanup: replaces multiple whitespaces with one, trims edge whitespaces and converts the string to upper-case.

 Argument: the string
 Returns: the normalize string

=item C<align_text_table>

Center-aligns a table (2D-array) for future output, e.g. being converted to a fixed-font image and later sent via tweet.

 Argument: the 2D-array to format
 Returns: the formatted text

=item C<convert_hash_to_table>

Converts a multi-story hash reference to a table (2D-array) where the top row are the keys of the last story of the hash. I.e. something like this:

{ a => { b => 1, c => 1 }, d => { b => 2, c => 2 } }

becomes

[[b, c], [1, 1], [2, 2]]

 Arguments: the hash to convert
 [optional] the partially populated table
 [optional] a hook (sub ref) to execute on each bottom hash
 [optional] forced fields for header row
 Returns: the 2D-array

=item C<dumper>

A convenient wrapper around Data::Dumper, forcing certain values on some of the Data::Dumper constants, printing the origination of the dumping call and deviating to call HTML::Element->dump() on HTML::Element objects.

 Arguments: whatever you want to dump
 Returns: void

=item C<eventdebug>

Prepends debug output with an informative prefix and formats some information about the event being debugged.

 Arguments: the event
 [optional] the prefix, defaults to 'eventdebug'

 Returns: void

=item C<gamedebug>

Prepends debug output with an informative prefix and formats some information about the game being debugged.

 Arguments: the game
 [optional] the prefix, defaults to 'gamedebug'
 Returns: void

=item C<get_eventdebug>

Generates the string used by eventdebug() (q.v.)

 Arguments: the event
 [optional] the prefix, defaults to 'eventqdebug'

 Returns: the debug string

=item C<get_gamedebug>

Generates the string used by gamedebug() (q.v.)

 Arguments: the game
 [optional] the prefix, defaults to 'eventdebug'

 Returns: the debug string

=item C<get_season_slash_string>

Generates a string consisting of the starting year slash ending year, e.g. 1987/88

 Arguments: the YYYY of the starting year

 Returns: the slashed string

=item C<get_time>

Creates a colon-separated time string from a number of seconds given

 Arguments: the number of seconds
 [optional] the forced '--:--' string for zero

 Returns: the MM:SS string

=item C<initialize>

Generates a full name where the given name is initialed and appended with the last name, e.g. Wayne Gretzky becomes 'W. Gretzky' .

 Arguments: the name

 Returns: the initialized name

=item C<iterate_2>

A shortcut to iterate over a two-dimensional array consisting of two vectors, most frequently game rosters

 Arguments: the 2D array
            the optional sub-field where the vectors are stored
            the sub to apply to each vector member
            the arguments to the sub

 Returns: void, it runs the sub

=item C<lg>

Takes a 10-base logarithm of a number

 Arguments: a number

 Returns: decimal logarithm

=item C<numerify_structure>

Scans a complex data structure recursively, enforcing the valid numerical string to be numbers by adding a 0 to them.

 Arguments: the data structure

 Returns: void, modification in-place

=item C<shorten_float_item>

Shortens a valid floating number to be no longer than 3 digits past the period, but no less than one digit.

 Arguments: the reference to the floating number

 Returns: the shortened floating number

=item C<timedebug>

Produces debug output prepended by the current time as returned by current UNIX timestamp

 Arguments: the debug string

 Returns: void, prints output to STDERR

=back

=cut

my @debug     = qw(debug verbose gamedebug timedebug eventdebug dumper);
my @file      = qw(read_file write_file read_config);
my @utils     = qw(my_uniq convert_hash_to_table lg fill_broken str3time numerify_structure);
my @format    = qw(align_text_table shorten_float_item initialize normalize_string);
my @times     = qw(get_season_slash_string get_seconds get_time);
my @shortcuts = qw(iterate_2);

our @EXPORT_OK = (
	@debug, @file, @utils, @format, @times, @shortcuts
);

our %EXPORT_TAGS = (
	debug     => [@debug],
	file      => [@file],
	utils     => [@utils],
	format    => [@format],
	times     => [@times],
	shortcuts => [@shortcuts],
	all       => [@EXPORT_OK],
);
our $LN_10 = log(10);

sub debug ($) {

	my $message = shift;
#	my $timestamp = time;
	
	print STDERR "$message\n" if $ENV{HOCKEYDB_DEBUG};
}

sub verbose ($) {

	my $message = shift;

	print STDERR "$message\n" if $ENV{HOCKEYDB_VERBOSE} || $ENV{HOCKEYDB_DEBUG};
}

sub get_gamedebug ($$) {

	my $game   = shift;
	my $prefix = shift;

	"$prefix: $game->{_id} $game->{date} $game->{teams}[0]{name} $game->{teams}[0]{score} - $game->{teams}[1]{score} $game->{teams}[1]{name}";
}

sub gamedebug ($;$) {

	my $game   = shift;
	my $prefix = shift || 'gamedebug';

	debug get_gamedebug($game, $prefix);
}

sub get_eventdebug ($$) {

	my $event  = shift;
	my $prefix = shift;

	sprintf "%-30s %d \@%-5s", $prefix, $event->{_id}, $event->{ts};
}

sub eventdebug ($;$) {

	my $event = shift;
	my $prefix = shift || 'eventdebug';

	debug get_eventdebug($event, $prefix);
}

sub timedebug ($;$) {

	my $message = shift;
	my $timestamp = time;

	debug "$timestamp $message";
}

sub read_file ($;$) {

	my $filename = shift;
	my $no_strip = shift || 0;
	my $content;

	debug "Reading $filename ...";
	open(my $fh, '<', $filename) or die "Couldn't read file $filename: $!";
	{
		local $/ = undef;
		$content = <$fh>;
	}
	close $fh;
	$content =~ s/\xC2\xA0/ /g if $no_strip == 0;
	$content;
}

sub read_tab_file ($) {

	my $filename = shift;
	my $table = [];

	debug "Reading tabulated $filename ...";
	open(my $fh, '<', $filename) or die "Couldn't read file $filename: $!";
	while (<$fh>) {
		chomp;
		my @row = split(/\t/);
		push(@{$table}, [@row]);
	}
	close $fh;
	$table;
}

sub write_file ($$;$) {

	my $content  = shift;
	my $filename = shift;
	my $no_strip = shift || 1;

	debug "Writing $filename ...";
	mkpath(dirname($filename)) unless -d dirname($filename);
	$content =~ s/\xC2\xA0/ /g if $no_strip == 0;
	open(my $fh, '>', $filename) or die "Couldn't write file $filename: $!";
	binmode $fh, ':utf8';
	print $fh $content;
	close $fh;
	$filename;
}

sub fill_broken ($$) {

	my $item   = shift;
	my $broken = shift;

	return unless $broken;
	for my $field (keys %{$broken}) {
		if ($field eq 'description') {
			my $old_field = "old_$field";
			$item->{$old_field} = $item->{$field};
		}
		$item->{$field} = $broken->{$field};
	}
}

sub get_seconds ($) {

	my $time = shift;

	unless (defined $time) {
		print "No time supplied\n";
		die Dumper [caller];
	}
	return $time if $time =~ /^\d+$/;
	$time =~ /^\-?(\d+)\:(\d+)$/;
	$1*60 + $2;
}

sub get_time ($;$) {
	my $s = shift;
	my $z = shift || 0;
	$s ? sprintf("%02d:%02d", $s / 60, $s % 60) : $z ? 0 : '--:--';
}

sub lg ($) {

	my $num = shift;
	log($num) / $LN_10;
}

sub my_uniq (&@) {

	my $func = shift;
	my %seen = ();
	grep {! $seen{$func->($_)}++} @_;
}

sub normalize_string ($) {

	my $string = shift;

	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	$string =~ s/\s+/ /g;
	$string = uc $string;

	$string;
}

sub convert_hash_to_table ($;$$$);
sub convert_hash_to_table ($;$$$) {

	my $hash   = shift;
	my $table  = shift || [];
	my $hook   = shift || undef;
	my $fields = shift || undef;

	for my $key (keys %{$hash}) {
		if (ref $hash->{$key} && ref $hash->{$key} eq 'HASH') {
			convert_hash_to_table($hash->{$key}, $table, $hook, $fields);
		}
		else {
			my $result = $hook->($hash) if $hook;
			last if $result && ! ref $result && $result eq -255;
			unless (@{$table}) {
				push(@{$table}, $fields || [keys %{$hash}]);
			}
			push(@{$table}, [map($hash->{$_} || 0, @{$table->[0]})]);
			last;
		}
	}
	$table;
}

sub get_season_slash_string ($) {

	my $season = shift;
	sprintf("%d/%02d", $season, ($season+1) % 100);
}

sub shorten_float_item ($) {

	my $item   = shift;

	if ($$item && $$item =~ /^\-?(\d+)\.(\d+)/) {
		my $int = $1;
		my $n_format;
		if (length($int) > 2)     { $n_format = '%.1f'; }
		elsif (length($int) == 1) {	$n_format = '%.3f'; }
		else                      {	$n_format = '%.2f'; }
		$$item = sprintf($n_format, $$item);
	}
}

sub align_text_table ($;$) {

	my $table = shift;
	my $format = '';

	my @max_lengths = ();
	for my $row (@{$table}) {
		my $e = 0;
		for my $element (@{$row}) {
			shorten_float_item(\$element);
			$max_lengths[$e] ||= 0;
			my $element_length = length($element);
			$max_lengths[$e] = $element_length if $max_lengths[$e] < $element_length;
			$e++;
		}
	}
	for my $f (0..$#max_lengths) {
		if ($f < $#max_lengths/2) {
			$format .= "%-$max_lengths[$f]s ";
		}
		else {
			$format .= "%$max_lengths[$f]s ";
		}
	}
	chop $format;
	verbose "Using format $format";
	my $text_table = dclone $table;
	for my $row (@{$text_table}) {
		$row = sprintf($format, @{$row});
	}
	my $text = join("\n", @{$text_table}) . "\n";
	debug $text;
	$text;
}

=head2 read_config ($)

 Utility function that reads the sharepoint configuration file of whitespace separated values.
 Parameters: the configuration file
 Returns: Hash of configuration parameters and their values.

=cut

sub read_config ($) {

	my $config_file = shift;
	my $config      = {};

	open(my $conf_fh, '<', $config_file) or return 0;
	while (<$conf_fh>) {
		next if /^\#/;
		next unless /\S/;
		s/^\s+//;
		s/\s+$//;
		my ($key, $value) = split(/\s+/, $_, 2);
		unless ($value) {
			$config->{$key} = undef;
			next;
		}
		chomp $value;
		while ($value =~ /\\$/) {
			my $extra_value = <$conf_fh>;
			next if $extra_value =~ /^\#/;
			next unless $extra_value =~ /\S/;
			$extra_value =~ s/^\s+//;
			$extra_value =~ s/\s+$//;
			chop $value;
			$value =~ s/\s+$//;
			$value .= " $extra_value";
		}
		$config->{$key} = $value;
	}
	close $conf_fh;
	$config;
}

sub initialize ($) {

	my $name = shift;

	my (@parts) = split(/\s+/, $name);

	return uc(substr($parts[0], 0, 1)) . '. ' . uc($parts[-1]);
}

sub str3time ($) {

	my $str   = shift;

	my $time = str2time($str);
	my $year = substr($str, 0, 4);
	$time -= (31536000 + 3124224000) if $year <= 1969;
	$time;
}

sub numerify_structure ($);

sub numerify_structure ($) {

	my $structure = shift;

	my $ref = ref $structure;
	if ($ref) {
		if ($ref eq 'ARRAY') {
			for my $element (@{$structure}) {
				if (! ref $element) {
					if ($element && $element =~ /^[-+]?[0-9]*\.?[0-9]+$/) {
						$element += 0;
					}
				}
				else {
					numerify_structure($element);
				}
			}
		}
		elsif ($ref eq 'HASH' || $ref =~ /Sport::/) {
			for my $key (keys %{$structure}) {
				if (! ref $structure->{$key}) {
					next unless defined $structure->{$key};
					if ($structure->{$key} =~ /^[-+]?[0-9]*\.?[0-9]+$/) {
						$structure->{$key}  += 0;
					}
				}
				else {
					numerify_structure($structure->{$key});
				}
			}
		}
	}
}

sub dumper (@) {

	my ($package, $filename, $line) = caller;

	undef $package;
	print "Called in $filename: $line\n";
	$Data::Dumper::Trailingcomma ||= 1;
	$Data::Dumper::Deepcopy      ||= 1;
	$Data::Dumper::Sortkeys      ||= 1;
	$Data::Dumper::Deparse       ||= 1;

	if (ref $_[0] && ref $_[0] =~ /HTML::Element/) {
		print $_[0]->dump;
	}
	else {
		print Dumper @_;
	}
}

sub iterate_2 ($$$;@) {

	my $game         = shift;
	my $roster_field = shift || '';
	my $sub          = shift;

	for my $t (0,1) {
		my $roster = $roster_field ? $game->[$t]{$roster_field} : $game->[$t];
		for my $player (@{$roster}) {
			$sub->($player, $t, @_);
		}
	}
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Util>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Util

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Util>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Util>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Util>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Util>

=back

=cut

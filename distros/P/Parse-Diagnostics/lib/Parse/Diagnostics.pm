package Parse::Diagnostics;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/parse_diagnostics parse_diagnostics_pp parse_diagnostics_xs/;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
use Carp;
use Path::Tiny;
use C::Tokenize '$string_re';
our $VERSION = '0.03';

our $message_re = qr
/
    (
	"([^"]|\\")+"
    |
	'([^']|\\')+'
    )
    (?:,.*?)?
/x;

our $diagnostics_re = qr
/
    (
	croak
    |
	carp
    |
	die
    |
	warn
    |
	confess
    |
	cluck
    )
    \s*
    (
	\(
	$message_re
	\)
    |
	$message_re
    )
/x;

our $xs_diagnostics_re = qr
    /
	(
	    croak
	|
	    warn
	|
	    vwarn
	|
	    vcroak
	|
	    die
	|
	    croak_sv
	|
	    die_sv
	)
	\s*
	\(
	\s*
	($string_re)
    /x;

our $c_diagnostics_re = qr
    /
	(v?fprintf)
	\s*\(\s*
	stderr
	\s*,\s*
	($string_re)
    /x;

# Match "$regex" to "$contents" globally, and record the lines of each
# match.

sub regex_lines
{
    my ($contents, $regex) = @_;
    # Copy the contents, then delete chunks off the front of it as we
    # find diagnostics, so we can keep track of the line numbers.
    my $copycontents = $contents;
    my @diagnostics;
    my $line = 1;
    while ($copycontents =~ s/^(.*?)$regex//s) {
	my $leading = $1;
	my $type = $2;
	my $message = $3;
	# Count the lines in $leading.
	my $lines = ($leading =~ tr/\n//);
	push @diagnostics, {
	    type => $type,
	    message => $message,
	    line => $line + $lines,
	};
#	print "$message ", $line + $lines, "\n";
	# Add the lines in $lines and whatever lines may be in
	# $message to the current line.
	$line += $lines + ($message =~ tr/\n//);
    }
    return \@diagnostics;
}

sub parse_diagnostics_pp
{
    my ($contents, %options) = @_;
    return regex_lines ($contents, $diagnostics_re);
}

sub parse_diagnostics_xs
{
    my ($contents, %options) = @_;
    my @diagnostics;
    my $xs = regex_lines ($contents, $xs_diagnostics_re);
    push @diagnostics, @$xs;
    my $c = regex_lines ($contents, $c_diagnostics_re);
    push @diagnostics, @$c;
    return \@diagnostics;
}

sub parse_diagnostics
{
    my ($file, %options) = @_;
    my $contents = path ($file)->slurp ();
    my $diagnostics;
    if ($file =~ /\.(c|xs)$/) {
	$diagnostics = parse_diagnostics_xs ($contents, %options);
    }
    else {
	$diagnostics = parse_diagnostics_pp ($contents, %options);
    }
    # Get user-defined diagnostics
    if ($options{user_re}) {
	my $udiagnostics = regex_lines ($contents, $options{user_re});
	push @$diagnostics, @$udiagnostics;
    }
    # Hashmap of duplicates
    my %dl;
    my @diagnostics;
    # Eliminate duplicate diagnostics
    for my $d (@$diagnostics) {
	my $key = $d->{message} . "-" . $d->{line};
	if (! $dl{$key}) {
	    push @diagnostics, $d;
	    $dl{$key} = 1;
	}
    }
    # Sort by line
    @diagnostics = sort {$a->{line} <=> $b->{line}} @diagnostics;
    return \@diagnostics;
}

1;

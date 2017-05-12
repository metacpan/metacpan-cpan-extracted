package Sort::Fields;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require 5.003_03;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	make_fieldsort
	fieldsort
	make_stable_fieldsort
	stable_fieldsort
);
$VERSION = '0.90';

use Carp;

sub make_fieldsort {
	my $selfname;
	if ((caller)[0] eq 'Sort::Fields') {
		($selfname) = (caller 1)[3] =~ /([^:]*)$/;
	} else {
		$selfname = 'make_fieldsort'
	};
	unless (@_) {
		croak "$selfname requires argument(s)";
	}

	my ($sep, $cols);
	if (ref $_[0]) {
		$sep = '\\s+'
	} else {
		$sep = shift;
	}
	unless (ref($cols = shift) eq 'ARRAY') {
		croak "$selfname field specifiers must be in anon array";
	}
	my (@sortcode, @col);
	my $level = 1;
	my $maxcol = -1;
	my $stable = 0;
	if (@$cols and $$cols[0] eq '-') {
		shift @$cols;
		$stable = 1;
	}
	unless (@$cols) {
		croak "$selfname must have at least one field specifier";
	}
	for (@$cols) {
		unless (/^-?\d+n?$/) {
			croak "improperly formatted $selfname column specifier '$_'";
		}
		my ($a, $b) = /^-/ ? qw(b a) : qw(a b);
		my $op = /n$/ ? '<=>' : 'cmp';
		my ($col) = /^-?(\d+)/;
		if ($col == 0) {  # column 0 gives the entire string
			push @sortcode, "\$${a}->[0] $op \$${b}->[0]";
			next;
		} 
		push @col, (/(\d+)/)[0] - 1;
		$maxcol = $col[-1] if $maxcol < $col[-1];
		if ($stable) {
			# indices are offset by 1 in this case
			my $levp1 = $level + 1;
			push @sortcode, "\$${a}->[$levp1] $op \$${b}->[$levp1]";
		} else {
			push @sortcode, "\$${a}->[$level] $op \$${b}->[$level]";
		}
		$level++;
	}
	# have to check this all by itself, since if there's a regex
    # error it won't show up until the sub is called (urk!)
	eval '"" =~ /$sep/';
	if ($@) {
		croak "probable regexp error in $selfname arg: /$sep/\n$@";
	}
	my $splitfunc;
	$splitfunc = eval 'sub { (split /$sep/o, $_, $maxcol + 2)[@col] } ';
	if ($@) {
		die "eval failed in $selfname (internal error?)\n$@";
	}
	my $sortcode = join " or ", @sortcode;
	my $sub;
	if ($stable) {
		my $i;  # the $i for the stable sort closure
		$sub = eval qq{
			sub {
				if (\$^W and not wantarray) {
					carp "fieldsort called in scalar or void context";
				}
				\$i = 0;  # reset counter in case reusing this closure
				map \$_->[0],
					sort { $sortcode or \$a->[1] <=> \$b->[1] }
					map [\$_, \$i++, \$splitfunc->(\$_)],
					\@_;
			}
		}
	} else {
		$sub = eval qq{
			sub {
				if (\$^W and not wantarray) {
					carp "fieldsort called in scalar or void context";
				}
				map \$_->[0],
					sort { $sortcode }
					map [\$_, \$splitfunc->(\$_)],
					\@_;
			}
		}
	}
	if ($@) {
		die "eval failed in $selfname (internal error?)\n$@";
	}
	$sub;
}

sub make_stable_fieldsort {
	unless (@_) {
		croak "make_stable_fieldsort requires argument(s)";
	}
	if (ref $_[0] eq 'ARRAY') {
		unshift @{$_[0]}, '-';
	} elsif (@_ > 1 and ref $_[1] eq 'ARRAY') {
		unshift @{$_[1]}, '-';
	}
	make_fieldsort @_;
}

sub fieldsort {
	unless (@_) {
		croak "fieldsort requires argument(s)";
	}
	my ($sep, $cols);
	if (ref $_[0]) {
		$sep = '\\s+'
	} else {
		$sep = shift;
	}
	$cols = shift;
	make_fieldsort($sep, $cols)->(@_);
}

sub stable_fieldsort {
	unless (@_) {	
		croak "stable_fieldsort requires argument(s)";
	}
	my ($sep, $cols);
	if (ref $_[0] eq 'ARRAY') {
		$sep = '\\s+';
		unshift @{$_[0]}, '-';
	} elsif (@_ > 1 and ref $_[1] eq 'ARRAY') {
		$sep = shift;
		unshift @{$_[1]}, '-';
	}
	$cols = shift;
	make_fieldsort($sep, $cols)->(@_);
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Sort::Fields - Sort lines containing delimited fields

=head1 SYNOPSIS

  use Sort::Fields;
  @sorted = fieldsort [3, '2n'], @lines;
  @sorted = fieldsort '\+', [-1, -3, 0], @lines;

  $sort_3_2n = make_fieldsort [3, '2n'], @lines;
  @sorted = $sort_3_2n->(@lines);

=head1 DESCRIPTION

Sort::Fields provides a general purpose technique for efficiently sorting
lists of lines that contain data separated into fields.

Sort::Fields automatically imports two subroutines, C<fieldsort> and
C<make_fieldsort>, and two variants, C<stable_fieldsort> and 
C<make_stable_fieldsort>.  C<make_fieldsort> generates a sorting subroutine
and returns a reference to it.  C<fieldsort> is a wrapper for
the C<make_fieldsort> subroutine.

The first argument to make_fieldsort is a delimiter string, which is
used as a regular expression argument for a C<split> operator.  The
delimiter string is optional.  If it is not supplied, make_fieldsort
splits each line using C</\s+/>.

The second argument is an array reference containing one or more 
field specifiers.  The specifiers indicate what fields in the strings
will be used to sort the data.  The specifier "1" indicates the first
field, "2" indicates the second, and so on.  A negative specifier
like "-2" means to sort on the second field in reverse (descending)
order.  To indicate a numeric rather than alphabetic comparison,
append "n" to the specifier.  A specifier of "0" means the entire
string ("-0" means the entire string, in reverse order).

The order in which the specifiers appear is the order in which they
will be used to sort the data.  The primary key is first, the secondary
key is second, and so on.

C<fieldsort [1, 2], @data> is roughly equivalent to
C<make_fieldsort([1, 2])-E<gt>(@data)>.  Avoid calling fieldsort repeatedly
with the same sort specifiers.  If you need to use a particular
sort more than once, it is more efficient to call C<make_fieldsort>
once and reuse the subroutine it returns.

C<stable_fieldsort> and C<make_stable_fieldsort> are like their
"unstable" counterparts, except that the items that compare the same
are maintained in their original order.

=head1 EXAMPLES

Some sample data (in array C<@data>):

  123   asd   1.22   asdd
  32    ewq   2.32   asdd
  43    rewq  2.12   ewet
  51    erwt  34.2   ewet
  23    erww  4.21   ewet
  91    fdgs  3.43   ewet
  123   refs  3.22   asdd
  123   refs  4.32   asdd

  # alpha sort on column 1
  print fieldsort [1], @data;

  123   asd   1.22   asdd
  123   refs  3.22   asdd
  123   refs  4.32   asdd
  23    erww  4.21   ewet
  32    ewq   2.32   asdd
  43    rewq  2.12   ewet
  51    erwt  34.2   ewet
  91    fdgs  3.43   ewet

  # numeric sort on column 1
  print fieldsort ['1n'], @data;

  23    erww  4.21   ewet
  32    ewq   2.32   asdd
  43    rewq  2.12   ewet
  51    erwt  34.2   ewet
  91    fdgs  3.43   ewet
  123   asd   1.22   asdd
  123   refs  3.22   asdd
  123   refs  4.32   asdd

  # reverse numeric sort on column 1
  print fieldsort ['-1n'], @data;

  123   asd   1.22   asdd
  123   refs  3.22   asdd
  123   refs  4.32   asdd
  91    fdgs  3.43   ewet
  51    erwt  34.2   ewet
  43    rewq  2.12   ewet
  32    ewq   2.32   asdd
  23    erww  4.21   ewet

  # alpha sort on column 2, then alpha on entire line
  print fieldsort [2, 0], @data;

  123   asd   1.22   asdd
  51    erwt  34.2   ewet
  23    erww  4.21   ewet
  32    ewq   2.32   asdd
  91    fdgs  3.43   ewet
  123   refs  3.22   asdd
  123   refs  4.32   asdd
  43    rewq  2.12   ewet

  # alpha sort on column 4, then numeric on column 1, then reverse
  # numeric on column 3
  print fieldsort [4, '1n', '-3n'], @data;

  32    ewq   2.32   asdd
  123   refs  4.32   asdd
  123   refs  3.22   asdd
  123   asd   1.22   asdd
  23    erww  4.21   ewet
  43    rewq  2.12   ewet
  51    erwt  34.2   ewet
  91    fdgs  3.43   ewet

  # now, splitting on either literal period or whitespace
  # sort numeric on column 4 (fractional part of decimals) then
  # numeric on column 3 (whole part of decimals)
  print fieldsort '(?:\.|\s+)', ['4n', '3n'], @data;

  51    erwt  34.2   ewet
  43    rewq  2.12   ewet
  23    erww  4.21   ewet
  123   asd   1.22   asdd
  123   refs  3.22   asdd
  32    ewq   2.32   asdd
  123   refs  4.32   asdd
  91    fdgs  3.43   ewet

  # alpha sort on column 4, then numeric on the entire line
  # NOTE: produces warnings under -w
  print fieldsort [4, '0n'], @data;

  32    ewq   2.32   asdd
  123   asd   1.22   asdd
  123   refs  3.22   asdd
  123   refs  4.32   asdd
  23    erww  4.21   ewet
  43    rewq  2.12   ewet
  51    erwt  34.2   ewet
  91    fdgs  3.43   ewet

  # stable alpha sort on column 4 (maintains original relative order
  # among items that compare the same)
  print stable_fieldsort [4], @data;

  123   asd   1.22   asdd
  32    ewq   2.32   asdd
  123   refs  3.22   asdd
  123   refs  4.32   asdd
  43    rewq  2.12   ewet
  51    erwt  34.2   ewet
  23    erww  4.21   ewet
  91    fdgs  3.43   ewet

=head1 BUGS

Some rudimentary tests now.

Perhaps something should be done to catch things like:

  fieldsort '.', [1, 2], @lines;

C<'.'> translates to C<split /./> -- probably not what you want.

Passing blank lines and/or lines containing the wrong kind of
data (alphas instead of numbers) can result in copious warning messages
under C<-w>.

If the regexp contains memory parentheses (C<(...)> rather than C<(?:...)>),
split will function in "delimiter retention" mode, capturing the
contents of the parentheses as well as the stuff between the delimiters.
I could imagine how this could be useful, but on the other hand I
could also imagine how it could be confusing if encountered unexpectedly.
Caveat sortor.

Not really a bug, but if you are planning to sort a large text file,
consider using sort(1).  Unless, of course, your operating system
doesn't have sort(1).

=head1 AUTHOR

Joseph N. Hall, joseph@5sigma.com

=head1 SEE ALSO

perl(1).

=cut

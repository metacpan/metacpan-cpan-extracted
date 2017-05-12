# Number::Range::Regex

#
# Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.

package Number::Range::Regex;

use strict;
use Number::Range::Regex::Range;
use Number::Range::Regex::Iterator;
use Number::Range::Regex::Util;
use Number::Range::Regex::Util::inf qw( neg_inf pos_inf );
use vars qw ( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION );
eval { require warnings; }; #it's ok if we can't load warnings

require Exporter;
use base 'Exporter';
@ISA    = qw( Exporter );
@EXPORT = qw( range rangespec );
@EXPORT_OK = qw ( init regex_range ) ;
%EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

$VERSION = '0.32';

my $init_opts = $Number::Range::Regex::Range::default_opts;

sub init {
  my ($self, @opts) = @_;

  # vestigial limb: init( foo => "bar" ) == init( { foo => "bar" } );
  my %opts = (@opts == 1) ? %{$opts[0]} :
             (@opts % 2 == 0) ? @opts :
             die 'usage: init( $options_ref )';

  $init_opts = $Number::Range::Regex::Range::default_opts;
  # override any values of init_opts that were passed to init
  while (my ($key, $value) = each %opts) {
    $init_opts->{$key} = $value;
  }
}

# regex_range( $min, $max ); #undef = no limit, so. e.g.
#   regex_range(3, undef) yields the equivalent of qr/[+]?[3-9]|\d+/;
sub regex_range {
  my ($min, $max, $passed_opts) = @_;
  my $opts = option_mangler( $init_opts, $passed_opts );
  return range($min, $max, $opts)->regex();
}

sub range {
  my $opts = option_mangler( ref $_[-1] eq 'HASH' ? pop : undef );
  my ($min, $max) = @_;
  if(!defined $min && !defined $max) {
    die "for the set of all integers, you must specify min as '-inf' and max as '+inf', or use the allow_wildcard argument" if !$opts->{allow_wildcard};
  }
  $min = neg_inf  if  !defined $min;
  $max = pos_inf  if  !defined $max;
  return rangespec( "$min..$max", $opts );
}

sub rangespec {
  my $opts = option_mangler( ref $_[-1] eq 'HASH' ? pop : undef );
  # we allow (but do not like) e.g. rangespec(5,7,10..18);
  # we don't like it because it can make us run out of memory for
  # large ranges. preferred: rangespec('5,7,10..18');
  my $spec;
  if(@_ > 1) {
    warn "passed literal range to rangespec!\n";
    $spec = join $opts->{range_separator}, @_;
  } else {
    $spec = $_[0];
  }

  my $base = $opts->{base};
  my $base_digits = base_digits($base);
  my $base_max   = substr($base_digits, -1);

  my $digits_validate  = "[$base_digits]+";
  my $range_operator   = '\s*'.quotemeta( $opts->{range_operator} ).'\s*';
  my $range_separator  = '\s*'.quotemeta( $opts->{range_separator} ).'\s*';
  my $section_validate = qr/(?:-?$digits_validate|(?:-?$digits_validate|-inf)$range_operator(?:\+?inf|-?$digits_validate))/;
  my $range_validate   = qr/(?:|$section_validate(?:$range_separator$section_validate)*)/;
  die "invalid rangespec '$spec' !~ /$range_validate/"  unless  $spec =~ /^$range_validate$/;

  my @sections = split /$range_separator/, $spec;
  my @ranges;
  foreach my $section (@sections) {
    if($section =~ /^(-?$digits_validate)$/) {
      push @ranges, Number::Range::Regex::SimpleRange->new( $1, $1, $opts );
    } else {
      my ($min, $max) = map { s/^\s+//; s/\s+$//; $_ } split /$range_operator/, $section, 2;
      push @ranges, Number::Range::Regex::SimpleRange->new( $min, $max, $opts );
    }
  }
  my $warn_overlap = defined $opts->{warn_overlap} ?
                     $opts->{warn_overlap} : 'rangespec';
  # note: multi_union() will have the side effect of sorting
  #       and de-overlap-ify-ing the input ranges
  return multi_union( @ranges, { warn_overlap => $warn_overlap } );
}

1;

__END__

=head1 NAME

Number::Range::Regex - create regular expressions that check for
                       integers in a given range

=head1 SYNOPSIS

  use Number::Range::Regex;
  my $lt_20 = range( 0, 19 );

  print "foo($foo) contains an integer < 20" if $foo =~ /$lt_20/;
  print "foo($foo) is an integer < 20" if $foo =~ /^$lt_20$/;
  if( $line =~ /^\S+\s+($lt_20)\s/ ) {
    print "the second field ($1) is an integer < 20";
  }
  my $nice_numbers = rangespec( "42,175..192" );
  my $my_values = $lt_20->union( $nice_numbers );
  if( $line =~ /^\S+\s+($my_values)\s/ ) {
    print "the second field has one of my values ($1)";
  }

  my $lt_10        = rangespec( "0..9" );
  my $primes_lt_30 = rangespec( "2,3,5,7,11,13,17,19,23,29" );
  my $primes_lt_10 = $lt_10->intersection( $primes_lt_30 );
  my $nonprimes_lt_10 = $lt_10->minus( $primes_lt_30 );
  print "nonprimes under 10 contains: ".join",", $nonprimes_lt_10->to_string;
  if( $something =~ /^$nonprimes_lt_10$/ ) {
    print "something($something) is a nonprime less than 10";
  }
  if( $nonprimes_lt_10->contains( $something ) ) {
    print "something($something) is a nonprime less than 10";
  }

  my $octet = range(0, 255);
  my $ip4_match = qr/^$octet\.$octet\.$octet\.$octet$/;
  my $range_96_to_127 = range(96, 127);
  my $my_slash26_match = qr/^192\.168\.42\.$range_96_to_127$/;
  my $my_slash19_match = qr/^192\.168\.$range_96_to_127\.$octet$/;

  my $in_a_or_in_b_but_not_both = $a->xor($b);

  my $it = rangespec("-20..42,47..52")->iterator();
  $it->first;
  do { print $it->fetch } while ($it->next);
  $it->last;
  do { print $it->fetch } while ($it->prev);


=head1 DESCRIPTION

Number::Range::Regex lets you manage sets of integers and generate
regular expressions matching them. For example, here is one way
to match number ranges in a regular expression:

  $date =~ m/^0*(?:[1-9]|[12][0-9]|3[01])\/0*(?:[0-9]|1[012])$/;

here is another:

  my $day_range = range(1, 31);
  my $month_range = range(1, 12);
  $date =~ m/^$day_range\/$month_range$/;

which is more legible? (bonus points if you spotted the bug)


=head1 METHODS

=head2 RANGE CREATION

=over

=item range

  $range = range( $min, $max );

Create a range between the first argument and the last. For example,
$min==8 and $max==12, corresponds to the list containing 8, 9, 10, 11,
and 12. This method is exported by default.

=item rangespec

  $range = rangespec( '8..12,14,19..22' );

Create a "compound" range given the range specification passed. For
example, the range above would consist of 8, 9, 10, 11, 12, 14, 19,
20, 21, and 22. This method is exported by default.

=back

=head2 RANGE INTERROGATION

=over

=item contains

  $range->contains( $number );

Returns a true value if $range contains $number - otherwise, it returns
a false value.

=item overlaps

  $range->overlaps( $another_range );

Returns a true value if $range overlaps with $another_range - otherwise,
it returns a false value. e.g.

  rangespec('7..9')->overlaps( rangespec('4..6') )   => false
  rangespec('7..9')->overlaps( rangespec('10..12') ) => false
  rangespec('7..9')->overlaps( rangespec('6..10') )  => true
  rangespec('7..9')->overlaps( rangespec('6..7') )   => true


=back

=head2 RANGE DISPLAY

=over

=item to_string

  $range->to_string();

Return a compact representation of the range suitable for consumption
by a human, perl(1), or rangespec(). For example:

  $range = range( 6, 22 );
  print $range->to_string;

will output: "6..22", which can be parsed by perl(1) or rangespec().

=item regex

  $range->regex();

Return a regular expression matching members of this range. For example:

  $range = range( 6, 22 );
  print $range->regex;

will output something equivalent to:

  qr/0*(?:[6-9]|1\d|2[0-2])/

which, on my machine with perl v5.14.2 and a development version of
Number::Range::Regex between v0.12 and v0.13, is:

  (?^:(?# begin Number::Range::Regex::SimpleRange[6..22] )[+]?0*(?:(?^:[6-9])|(?^:1\d)|(?^:2[0-2]))(?# end Number::Range::Regex::SimpleRange[6..22] ))

=back

=head2 OVERLOADING

Please note that range objects are overloaded so that in regex
context, $range will be equivalent to $range->regex(). This
works in all versions of perl >= v5.6.0. When it is further
possible to distinguish regex context from string context (as
in overload v1.10 or higher, available in perl >= v5.12.0),
range objects will display in string but not regex context as
the terser, more legible $range->to_string() instead.

If you find any cryptic errors about overloading, please use
an explicit ->to_string or ->regex() and file a bug.

=head2 UNBOUNDED (aka "infinite") RANGES

It is also possible to specify unbounded ranges, ie the set of
all integers less than 17. This may be specified in any of the
following ways:

  range( undef, 17 );
  range( '-inf', 17);
  rangespec('-inf..17');

Similarly the set of all integers greater than 17:

  range( 17, undef );
  range( 17, '+inf' );
  rangespec('17..+inf');

Note carefully that, in order to prevent errors, it is not possible to
specify the set of all integers via range(undef, undef). If you try to
do so, Number::Range::Regex will complain that you "must specify either
a min or a max or use the allow_wildcard argument":

  range( undef, undef );   #boom

If you really want range() with no defined arguments to mean the set of
all possible integers, you can use one of the below:

  range( undef, undef, {allow_wildcard => 1} ) ;
  range( '-inf', '+inf' );

To test if a range is infinite, you can call is_infinite():

  1 == ! rangespec('3..7')->is_infinite();
  1 == rangespec('16..+inf')->is_infinite();
  1 == rangespec('')->not->is_infinite();

=head2 SET OPERATIONS

given $range2 = rangespec( '0,2,4,6,8' ) and
      $range3 = rangespec( '0,3,6,9' )

=over

=item union

  $range = $range2->union( $range3 );

Return the union of one range with another. In the example above,
$range would consist of: 0, 2, 3, 4, 6, 8, and 9. Note that union()
can take more than one argument, e.g.
  $range2->union( $range3, $range5, $range7, $range11, ... );

=item intersect

  $range = $range2->intersect( $range3 );

Return the intersection of one range with another. In the example
above, $range would consist of: 0 and 6. This method is also available
via the alias intersection.

=item xor

  $range = $range->xor( $another_range );

Return the symmetric difference of $range2 and $range3 (elements in one
or the other range, but not in both). In the example above, $range would
consist of 2, 3, 4, 8, and 9.

=item subtract

  $range = $range2->subtract( $range3 );

Return the relative complement of $range2 in $range3. In the example
above, $range would consist of: 2, 4, and 8. Note carefully that
this method is not symmetric - $range3->subtract( $range2 ) would be
a different range consisting of 3 and 9. This method is also
available via the aliases subtraction and minus.

=item invert

  $range = $range2->invert();

Return the absolute complement of $range2. In the example above,
$range would include:

=over

  any integer less than or equal to -1
  1, 3, 5, and 7,  and
  any integer greater than or equal to 9.

=back

that is, $range->to_string would be '-inf..-1,1,3,5,7,9..+inf'. This
method is also available via the alias not.

=back

=head2 ITERATORS

iterators let you examine large or infinite sets with minimal memory:

  $it = $range->iterator();
  $it->first();
  do {
    do_something_with_value( $it->fetch );
  } while ($it->next);

for more information, see Number::Range::Regex::Iterator

=head2 OTHER METHODS

=over

=item regex_range

  $regex = regex_range( $min, $max );

This is a shortcut for range( $min, $max )->regex(). Useful for
one-off use when overload.pm does not support regex context. It
should only be used with perl 5.10.X or lower where regex context
overloading is not possible. This method may be deprecated in a
future release of Number::Range::Regex. This method is not exported
by default.

=back

=head1 NOTES

It's usually better to check for number-ness only in the regular
expression and verify the range of the number separately, eg:
  $line =~ /^\S+\s+(\d+)/ && $1 > 15 && $1 < 32;
but it's not always practical to refactor in that way.

If you like one-liners, something like the following may suit you...
  m{^${\( range(1, 31) )}\/${\( range(1, 12) )}$}
but, for readability's sake, please don't do that!


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests through the
web interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Brian Szymanski  B<< <ski-cpan@allafrica.com> >> -- be sure to put
Number::Range::Regex in the subject line if you want me to read
your message.


=head1 LICENSE

Copyright 2012 Brian Szymanski.  All rights reserved.  This module is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.


=head1 SEE ALSO

perl(1), Number::Range, etc.


=cut

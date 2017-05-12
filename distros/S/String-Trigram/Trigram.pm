package String::Trigram;

use Carp;
use locale;

use 5.6.0;
use strict;
use warnings;

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = ('compare');
our $VERSION   = '0.12';

our $DEFAULT_MIN_SIM          = 0;
our $DEFAULT_WARP             = 1.0;
our $DEFAULT_IGNORE_CASE      = 1;
our $DEFAULT_KEEP_ONLY_ALNUMS = 0;
our $DEFAULT_DEBUG            = 0;
our $DEFAULT_NGRAM_LEN        = 3;
our $DEFAULT_PADDING          = $DEFAULT_NGRAM_LEN - 1;

sub new {
	my ( $pkg, %params ) = @_;

	my $seen = {};

	_setParams( \%params );

	foreach ( keys %params ) {
		croak "Unknown parameter $_!"
		  if ( $_ !~
/^(cmpBase|minSim|warp|ignoreCase|keepOnlyAlNums|padding|debug|ngram)$/
		  );
	}

	# check for reasonable values
	if ( ( !$params{cmpBase} ) or ( ref( @{ $params{cmpBase} } ne 'ARRAY' ) ) )
	{
		croak
"We need a base for comparison, so you should specify the parameter cmpBase as a reference to an anonymous array of strings being the base of comparison. Don't bother specifying anything else, but this we do need.\n";
	}

	if ( ( $params{minSim} < 0 ) || ( $params{minSim} > 1.0 ) ) {
		croak "Minimal similarity must be >= 0 and <= 1.0";
	}

	if ( defined $params{ngram} && ( $params{ngram} <= 0 ) ) {
		croak "n in n-gram must be > 0";
	}

	if ( $params{warp} == 0 ) {
		croak "Warp must be > 0";
	}

	if ( ( $params{padding} < 0 ) || ( $params{padding} > $params{ngram} - 1 ) )
	{
		croak "Padding must be between 0 and " . ( $params{ngram} - 1 ) . ".";
	}

	my $self = bless {
		ngram  => int( $params{ngram} ),
		minSim => $params{minSim},
		warp   => $params{warp},

		# index for trigrams
		trigIdx => _trigramify(
			$params{cmpBase},        $params{ignoreCase},
			$params{keepOnlyAlNums}, ' ' x $params{padding},
			undef,                   $params{ngram},
			$seen
		),

		# index of all strings fed to the object, so no string is
		# processed twice (this might lead to wrong results)
		seenStrings => $seen,

		ignoreCase     => $params{ignoreCase},
		keepOnlyAlNums => $params{keepOnlyAlNums},
		padding        => ' ' x $params{padding},
		debug          => $params{debug},

	}, $pkg;

	return $self;
}

sub compare {
	my ( $s1, $s2 ) = ( shift, shift );

	croak "I need at least 2 strings to compare as parameters, died"
	  unless defined $s2;

	my $result = {};

	new String::Trigram( cmpBase => [$s1], @_ )
	  ->getSimilarStrings( $s2, $result );

	$result->{$s1} || 0;
}

sub reInit {
	my ( $self, $newCmpBase ) = @_;

	if ( ( !$newCmpBase ) or ( ref( @$newCmpBase ne 'ARRAY' ) ) ) {
		croak
"We need a base for comparison, so, as a parameter to this method, we do need a reference to an anonymous array of strings being the base of comparison.\n";
	}

	$self->{seenStrings} = {};

	$self->_setTrigIdx(
		_trigramify(
			$newCmpBase,             $self->{ignoreCase},
			$self->{keepOnlyAlNums}, $self->{padding},
			undef,                   $self->{ngram},
			$self->{seenStrings}
		)
	);
}

sub extendBase {
	my ( $self, $newStrings ) = @_;

	if ( ( !$newStrings ) or ( ref( @$newStrings ne 'ARRAY' ) ) ) {
		croak
"We need to add to the base for comparison, so, as a parameter to this method, we do need a reference to an anonymous array of strings being added to the base of comparison.\n";
	}

	$self->_setTrigIdx(
		_trigramify(
			$newStrings,             $self->{ignoreCase},
			$self->{keepOnlyAlNums}, $self->{padding},
			$self->{trigIdx},        $self->{ngram},
			$self->{seenStrings}
		)
	);
}

sub minSim {
	my ( $self, $newMinSim ) = @_;

	if (   ( defined $newMinSim )
		&& ( ( ( $newMinSim < 0 ) || ( $newMinSim > 1.0 ) ) ) )
	{
		croak "Minimal similarity must be >= 0 and <= 1.0";
	}

	$self->{minSim} = $newMinSim if ($newMinSim);

	return $self->{minSim};
}

sub warp {
	my ( $self, $newWarp ) = @_;

	if ( ( defined $newWarp ) && ( $newWarp <= 0 ) ) {
		croak "Warp must be > 0";
	}

	$self->{warp} = $newWarp if ($newWarp);

	return $self->{warp};
}

sub ignoreCase {
	my ( $self, $newIgnoreCase ) = @_;

	$self->{ignoreCase} = $newIgnoreCase if ($newIgnoreCase);

	return $self->{ignoreCase};
}

sub keepOnlyAlNums {
	my ( $self, $newKeepOnlyAlNums ) = @_;

	$self->{keepOnlyAlNums} = $newKeepOnlyAlNums if ($newKeepOnlyAlNums);

	return $self->{keepOnlyAlNums};
}

sub padding {
	my ( $self, $newPadding ) = @_;

	if (   ( defined $newPadding )
		&& ( ( ( $newPadding < 0 ) || ( $newPadding > $self->{ngram} - 1 ) ) ) )
	{
		croak "Padding must be between 0 and " . $self->{ngram} - 1 . ".";
	}

	$self->{padding} = ' ' x $newPadding if ($newPadding);

	return length $self->{padding};
}

sub debug {
	my ( $self, $newDebug ) = @_;

	$self->{debug} = $newDebug if ( defined($newDebug) );

	return $self->{debug};
}

# Splits str into trigrams and looks up every trigram in trigIdx. If
# successfull, it finds a list of strings containing the trigram and
# increases the value of the string containing the trigram by 1 in the
# lexical $simInfo (ref. to hash). Uses _computeSimilarity() to compute
# the similarity value.
#
# Parameters
#
# result KEY = matching string, VALUE = similarity value
# str    string to be matched
# data   further key-val-pairs for min sim and warp
#
# Returns
#
# 0-n number of similar strings
# -1  no match found

sub getSimilarStrings {
	my $self   = shift;
	my $str    = shift;
	my $result = shift;
	my %data   = @_ if @_;

	my $curMinSim = $data{minSim};
	my $curWarp   = $data{warp};

	$curMinSim ||= $self->{minSim};
	$curWarp   ||= $self->{warp};

	croak
"I need a reference to a hash as second parameter for getSimilarStrings()!"
	  if ( ref($result) ne 'HASH' );

	my $trigram;     # contains current trigram
	my $matches;     # is pointed to all strings containing current trigram
	my $len;         # length of the string to compare
	my $actNum;      # that's how many times current trigram is found in string
	my $actName;     # this is a string containing current trigram
	my $actMatch;    # current match

	# KEY = trigram, SUBKEY = potentially similar string, VALUE = number
	# of times, trigrams is found in string.
	# Here the frequency of every trigram in every string is saved. The
	# table is filled with the existing strings containing some trigram
	# the frequencys of the trigram in the string are noted and decreased
	# every time, a matching trigram is found until the value is 0. If
	# the value is 0, a match cannot be counted anymore.
	my %trigNumBuf = ();

	# KEY = potentially similar string, VALUE = number of identical trigrams
	my $simInfo = {};

	$str =~ s/\W//g if $self->{keepOnlyAlNums};
	$str = lc $str if $self->{ignoreCase};

	$str = $self->{padding} . $str . $self->{padding};

	# Number of n-grams is length of string minus n + 1
	$len = length($str) - $self->{ngram} + 1;

	# **********************************************************
	# divide string to compare into trigrams and search trigrams
	# **********************************************************

	for ( my $i = 0 ; $i < $len ; $i++ ) {
		$trigram = substr( $str, $i, $self->{ngram} );

		# look for every trigram in $self->{trigIdx}
		# contine unless found
		next unless ( exists( $self->{trigIdx}->{$trigram} ) );

		# point matches to strings containing current trigram
		$matches = $self->{trigIdx}->{$trigram};

		# check every string containing current trigram
		while ( ( $actName, $actMatch ) = each %$matches ) {
			$actNum = $actMatch
			  ->{trigs};    # so many times current trigram is found in string

			$trigNumBuf{$trigram}->{$actName} = $actNum
			  unless ( exists( $trigNumBuf{$trigram}->{$actName} ) );

			# if there are instances of current trigram left for string
			if ( $trigNumBuf{$trigram}->{$actName} > 0 ) {

				# mark that we used on instance of current trigram
				$trigNumBuf{$trigram}->{$actName}--;

				# mark that we have found one more matching trigram for $actName
				$simInfo->{$actName}->{name}++;
				$simInfo->{$actName}->{len} = $actMatch->{len};
			}
		}
	}

	return $self->_computeSimilarity( $str, $simInfo, $result, $curMinSim,
		$curWarp );
}

# Uses getSimilarStrings() to get matching strings and filters out the
# best one(s).
#
# Parameters
#
# $inpStr     string to be matched
# $outStrList list of best strings
#
# Returns
#
# similarity value of best match or -1, of no match

sub getBestMatch {
	my $self       = shift;
	my $inpStr     = shift;
	my $outStrList = shift;

	croak
	  "I need a reference to an array as second parameter for getBestMatch()!"
	  if ( ref($outStrList) ne 'ARRAY' );

	my $maxVal   = -1;    # similarity of maximally similar string
	my $name     = "";    # current potentially similar string
	my $val      = -1;    # similarity of $name
	my $rslt     = {};    # KEY = similar name, VALUE = degree of similarity
	my @rsltKeys = ();    # contains keys(%rslt)

	# clear list ultimatively containing similar strings
	@$outStrList = ();

	# there are no similar strings at all
	if ( $self->getSimilarStrings( $inpStr, $rslt, @_ ) == 0 ) {
		return 0;
	}

	# there is at least one similar string
	@rsltKeys = keys(%$rslt);

	# looking for the best matching string, make the first one the best ...
	$name   = $rsltKeys[0];
	$maxVal = $rslt->{$name};

# since there might be several best strings (containing same degree of similarity)
# we put them into an array and not into a scalar
	push @$outStrList, $name;

	# ... and check if there are better ones
	for ( 1 .. @rsltKeys - 1 ) {
		$name = $rsltKeys[$_];
		$val  = $rslt->{ $rsltKeys[$_] };

		if ( $val == $maxVal ) {
			push @$outStrList, $name;
		}
		elsif ( $val > $maxVal ) {

# if we found a still better string, clear the array and put the better string into it
			@$outStrList = ();
			$maxVal      = $val;
			push @$outStrList, $name;
		}
	}

	return $maxVal;
}

sub _setTrigIdx {
	my ( $self, $newTrigIdx ) = @_;

	$self->{trigIdx} = $newTrigIdx;
}

sub _getTrigIdx {
	my $self = shift;
	return $self->{trigIdx};
}

# Computes similarity of potientially matching strings in hash
# newSimInfo. The result is saved in newResult. The computation of the
# similarity works like this:
#
# (a = all trigrams, d = different trigrams, e = warp)
#
# (a**e - d**e)/a**e
#
# The default for e is 1. If e is > 1.0, short strings are getting away
# better, if e is < 1.0 short strings are getting away worse.
#
# Parameters
#
# $newStr     string to be matched
# $newSimInfo KEY = potentially matching string, VALUE = number of matching trigrams
# $newResult  KEY = actually matching string, VALUE = similarity value
# $curMinSim  current minimal similarity
# $curWarp    current warp
#
# Returns
#
# number of matching strings

sub _computeSimilarity {
	my $self       = shift;
	my $newStr     = shift;
	my $newSimInfo = shift;
	my $newResult  = shift;
	my $curMinSim  = shift;
	my $curWarp    = shift;

	# clear hash containing the results
	%$newResult = ();

	my $strCnt = 0;    # number of similar strings (return value)
	my $allTrigs;      # number of all trigrams
	my $sameTrigs;     # number of same trigrams
	my $actSim;        # similarity (0 - 1)
	my $len =
	  length($newStr);    # length of string - $padNum for the padded blanks

# check every potientially similar string (i.e. every string containing at least one
# identical trigram)
	foreach ( keys(%$newSimInfo) ) {
		$sameTrigs = $newSimInfo->{$_}->{name};

# the number of n-grams in a string result from subtracting n from the length of
# the string and adding 1. If it is padded with blanks, there is one additional
# n-gram for each blank. So to compute the number of n-grams of two strings we
# subtract n twice, add 2 and add the number of padded blanks * 2. Since $newStr
# is already padded and the length noted for $_ contains already the padding we
# do not need to take the padding explicitly into account. Finally, to get
# $allTrigs (types not tokens) we need to subtract the number of matching trigrams
# - those occuring in both strings - once.
		$allTrigs =
		  $len + $newSimInfo->{$_}->{len} - 2 * $self->{ngram} - $sameTrigs + 2;

		$actSim = _computeActSim( $sameTrigs, $allTrigs, $curWarp );

		if ( $self->{debug} ) {
			my $tmpStr = $self->{padding} . $_ . $self->{padding};
			print STDERR "\nCompare\n";
			print STDERR "$newStr ->",
			  sort join( ":", $newStr =~ /(?=(...))/g ), "<-\n";
			print STDERR "$tmpStr ->",
			  sort join( ":", $tmpStr =~ /(?=(...))/g ), "<-\n";
			print STDERR "-" x
			  ( 22 + length($newStr) + 2 * length( $self->{padding} ) +
				  length($_) ), "\n";
			print STDERR "N-GRAM-LEN: ", $self->{ngram}, "\n";
			print STDERR "ALL :       ", $allTrigs,  "\n";
			print STDERR "SAME:       ", $sameTrigs, "\n";
			print STDERR "DIFF:       ", $allTrigs - $sameTrigs, "\n";
			print STDERR "ACTSIM:     ", $actSim, "\n";
			print STDERR "PADDING:    ", length $self->{padding}, "\n";
			print STDERR "MINSIM:     ", $self->{minSim}, "\n";
			print STDERR "WARP:       ", $curWarp, "\n\n";
		}

		# count string as similar only if similarity exceeds minimal similarity
		if ( $actSim > $curMinSim ) {
			$newResult->{$_} = $actSim;
			$strCnt++;
		}
	}

	return $strCnt;
}

# compute similarity
sub _computeActSim {
	my $sameTrigs = shift;
	my $allTrigs  = shift;
	my $curWarp   = shift;

	my $diffTrigs = -1;    # number of different trigrams
	my $actSim    = -1;    # similarity (0 - 1)

	# no warp here so skip the complicated stuff below
	if ( $curWarp == 1 ) {
		$actSim = $sameTrigs / $allTrigs;
	}
	else {
		# we've got to take warp into account
		$diffTrigs = $allTrigs - $sameTrigs;
		$actSim    =
		  ( ( $allTrigs**$curWarp ) - ( $diffTrigs**$curWarp ) ) /
		  ( $allTrigs**$curWarp );
	}
}

# Takes list of strings and puts them into an index of trigrams. KEY is a trigram,
# VALUE a list of strings containing that trigram. VALUE has two KEYS:
#
# trigs: count of trigram occurring in string
# len:   length of string (if $keepAlNums, after applying s/\W//g)
#
# Parameters
#
# $list       list of strings being the base of comparison
# $ignoreCase ignore case if 1
# $keepAlNums s/\W//g if 1
# $pad        contains 0 - 2 blanks for padding
#
# Returns
#
# trigram index

sub _trigramify {
	my $list       = shift;
	my $ignoreCase = shift;
	my $keepAlNums = shift;
	my $pad        = shift;
	my $trigs      = shift;
	my $ngram      = shift;
	my $seen       = shift;
	my $tmpStr;
	my $len;

	foreach (@$list) {
		$tmpStr = $_;

		$tmpStr =~ s/\W//g if $keepAlNums;
		$tmpStr = lc $tmpStr if $ignoreCase;

		next if exists $seen->{$tmpStr};
		$seen->{$tmpStr} = 1;

		$tmpStr = $pad . $tmpStr . $pad;

		$len = length($tmpStr);

		for ( my $i = 0 ; $i < ( length($tmpStr) - $ngram + 1 ) ; $i++ ) {
			$trigs->{ substr( $tmpStr, $i, $ngram ) }->{$_}->{trigs}++;
			$trigs->{ substr( $tmpStr, $i, $ngram ) }->{$_}->{len} = $len;
		}
	}

	return $trigs;
}

sub _setParams {
	my $params = shift;

	# set defaults, if not specified otherwise
	$params->{ngram}  = $DEFAULT_NGRAM_LEN unless exists $params->{ngram};
	$params->{minSim} = $DEFAULT_MIN_SIM   unless exists $params->{minSim};
	$params->{warp}   = $DEFAULT_WARP      unless exists $params->{warp};
	$params->{ignoreCase} = $DEFAULT_IGNORE_CASE
	  unless exists $params->{ignoreCase};
	$params->{keepOnlyAlNums} = $DEFAULT_KEEP_ONLY_ALNUMS
	  unless exists $params->{keepOnlyAlNums};
	$params->{padding} = $params->{ngram} - 1 unless exists $params->{padding};
	$params->{debug}   = $DEFAULT_DEBUG       unless exists $params->{debug};
}

1;
__END__

=head1 NAME

String::Trigram - Find similar strings by trigram (or 1, 2, 4, etc.-gram) method

=head1 SYNOPSIS

  use String::Trigram;

=head2 Object Oriented Interface

  my @cmpBase = qw(establishment establish establishes established disestablish disestablishmentarianism);

  my $trig = new String::Trigram(cmpBase => \@cmpBase);

  my $numOfSimStrings = $trig->getSimilarStrings("establishing", \%result);

  print "Found $numOfSimStrings similar strings.\n";

  foreach (keys %result) {
    printf ("Similar string $_ has a similarity of %.02f\n", ( $result{$_} * 100 ) );
  }

=head2 Functional Interface

  my $string1 = "foo";
  my $string2 = "boo";

  my $smlty = String::Trigram::compare( $string1, $string2 );

  printf( "%s and %s have a similarity of %.2f\n", ($string1, $string2, $smlty * 100 ) );

  $smlty = String::Trigram::compare( $string2, $string1 );

  printf( "%s and %s have a similarity of %.2f", ( $string2, $string1, $smlty * 100 ) );

=head1 DESCRIPTION

This module computes the similarity of two strings based on the
trigram method. This consists of splitting some string into triples of
characters and comparing those to the trigrams of some other
string. For example the string kangaroo has the trigrams C<{kan ang
nga gar aro roo}>. A wrongly typed kanagaroo has the trigrams C<{kan
ana nag aga gar aro roo}>. To compute the similarity we 
divide the number of matching trigrams (tokens not types) by the
number of all trigrams (types not tokens). For our example this means
dividing 4 / 9 resulting in 0.44.

To balance the disadvantage of the outer characters (every one of
which occurs in only one trigram - while the second and the
penultimate occur in two and the rest of the characters in three
trigrams each) somewhat we pad the string with blanks on either
side resulting in two more trigrams C<' ka'> and C<'ro '>, when using a padding of one blank.  Thus we
arrive at 6 matching trigrams and 11 trigrams all in all, resulting in
a similarity value of 0.55.

When using the trigram method there is one thing that might appear as a
problem: Two short strings with one (or two or three ...) different
trigrams tend to produce a lower similarity then two long ones. To counteract this
effect, you can set the module's C<warp> property. If you set it to
something greater than 1.0 (try something between 1.0 and 3.0, flying
at warp 9 won't get you anywhere here), this will lift the similarity
of short strings more and the similarity of long strings less,
resulting in the '%%%' curve in the (schematical) diagram below.


        1.0
  simi-  |                                   %            *      %
  larity |             %           *                   #         #
  value  |      %         *          #
         |            *     #
         |    %    *    #
         |       *   #
         |      *
         |   % * #
         |
         |   *
         |  % #
         |  *
         |                         ***  no warp (i.e. warp == 1.0)
         | %#                      %%%                    warp > 1
         | *                       ###                    warp < 1
         |________________________________________________________
        0.0
                                                  length of string

       Dependency of similarity value on length of string and warp

Don't hesitate to use this feature, it sometimes really helps
generating useful results where you otherwise wouldn't have got any.

Please be aware of that a C<warp> less than 1.0 will result in an inverse
effect pulling down the similarity of short strings a lot and the
similarity of long ones less, resulting in the '###' curve. I have no
idea what this can be good for, but it's just a side effect of the
method. How is all this done? Take a look at the code.

Splitting strings into trigrams is a time consuming affair and if you
want to compare a set of n strings to another set of m strings and you
do it on a member to member base you will have to do n * m
splittings. To avoid this, this module takes a set of strings as the
base of comparison and generates an index of every trigram occuring in
any of the members of the set (including the information, how often
the trigram occurs in a given member string). Then you can feed it the
members of the other set one by one. This results in an amount of n +
m splitting plus the overhead from generating the index. This way we
save a lot of time at the expense of memory, so - if you operate on a
great amount of strings - this might turn out to be somewhat of a
problem. But there you are. There's no such thing as a free lunch.

Anyway - the module is optimized for comparisons of sets of string
which results in single comparisons being slower than it might
be. So, if you use the C<compare()> function which compares single
strings in a functional interface, to be able to use the full
functionality of the module and not to get into the need to program
same things twice, internally a String::Trigram object is instantiated
and an index of the trigrams of one of the strings is generated. In
practice however this shouldn't be a big disadvantage since a single
comparison or just a few won't need too much (absolute) time.

=head1 METHODS

=head2 new

  my @base = qw(chimpanzee lion emu kangaroo);

  my $trig = new String::Trigram(cmpBase => \@base);

This is the constructor. Before we are able to do any computing of
similarities, it will want the parameter C<cmpBase> to point to a
reference to an array of strings (the base of comparison). Everything
else is taken care of unless you want to change the defaults:

  my $trig = new String::Trigram(cmpBase        => \@base,
                                 minSim         => 0.5,
                                 warp           => 1.6,
                                 ignoreCase     => 0,
                                 keepOnlyAlNums => 1,
                                 ngram          => 5,
                                 debug          => 1);

PARAMETERS:

=over 4

=item *

C<cmpBase> - Reference to array containing strings for base of
comparison.

=item *

C<minSim> - Minimal similarity you are prepared to accept. Specify a
value between 0 (not similar at all) and 1 (identity). Any string
matching with less (equals) than C<minSim> will not be returned in
C<getSimilarStrings()> and not counted as a match in C<getBestMatch()>,
even if it is the only one. Default is 0, so anything even remotely
matching will be returned.

=item *

C<ngram> - If you do not want to use trigrams, but some other n in n-gram, 
use this parameter, for example ngram => 5 for 5-grams.

=item *

C<warp> - Set warp attribute (see description). Default is 1.0 (no warp).

=item *

C<ignoreCase> - Just that. Default is 1 (do ignore case)


=item *

C<keepOnlyAlNums> - Remove any \W character before comparison. Default
is 0 (keep every character).

=item *

C<padding> - Set the number of blanks for padding string (see
above). The number has to be between 0 and n-1 (n from n-gram). Default is n-1.

=item *

C<debug> - print some debugging information to STDERR

=back

CROAKS IF ...

=over

=item *

it gets an unknown parameter

=item *

ngram is 0

=item *

parameter cmpBase does not point to a reference to an array

=item *

minimal similarity is out of bounds (should be 0 <= minSim <= 1)

=item *

warp is out of bounds (0 <= warp)

=item *

padding is out of bounds (should be 0 <= padding <= n-1)

=back

=head2 reInit

  $trig->reInit(["zebra", "tiger", "snake", "gorilla", "kangaroo"]);

Give the object a new base of comparison (deleting the old one).

CROAKS IF ...

=over

=item *

parameter does not point to a reference to an array

=back

=head2 extendBase

  $trig->extendBase(["zebra", "tiger", "snake", "gorilla", "kangaroo"]);

Add strings to object's base of comparison.

CROAKS IF ...

=over

=item *

parameter does not point to a reference to an array

=back

=head2 minSim

  $trig->minSim();
  $trig->minSim(0.8);

Get or set minimal accepted similarity (see above).

CROAKS IF ...

=over

=item *

minimal similarity is out of bounds (should be 0 <= minSim <= 1)

=back

=head2 warp

  $trig->warp();
  $trig->warp(1.4);

Get or set warp (see above).

CROAKS IF ...

=over

=item *

warp is out of bounds (should be 0 <= warp)

=back

=head2 ignoreCase

  $trig->ignoreCase();
  $trig->ignoreCase(0);

Get or set ignoreCase property (see above).

=head2 keepOnlyAlNums

  $trig->keepOnlyAlNums();
  $trig->keepOnlyAlNums(1);

Get or set keepOnlyAlNums property (see above).

=head2 padding

  $trig->padding();
  $trig->padding(2);

Get or set padding property (see above).

CROAKS IF ...

=over

=item *

padding is out of bounds (should be 0 <= padding <= n-1)

=back

=head2 debug

  $trig->debug();
  $trig->debug(1);

Get or set debug property. For debugging to STDERR, set to 1.

=head2 getSimilarStrings

  my %results = ();
  my $numOfSimStrings = $trig->getSimilarStrings("zebrilla", \%results [, minSim => 0.6, warp => 0.7]);

Get similar strings for first parameter from base of comparison. The result is
saved in the second parameter (a reference to a hash), the keys being the strings
and the values the similarity values. The method returns the number of found
similar strings.

If parameters minSim or warp are defined, those values are changed temporalily.

CROAKS IF ...

=over

=item *

second parameter is not a reference to a hash

=back

=head2 getBestMatch

  my @bestMatches = ();
  my $sim = $trig->getBestMatch("zebrilla", \@bestMatches [, minSim => 0.6, warp => 0.7]);

Don't bother about all those more or less similar strings, just get the best
one. This might actually be more than one, since several strings might result in
the same similarity value. So the second parameter is a reference to an array, taking the best similar strings,
the first parameter is the string to compare. Returns similarity of best match or 0 if there are no similar strings at all (please observe that in the case of no match the return value was -1 up to $VERSION == 0.02).

If parameters minSim or warp are defined, those values are changed temporarily.

CROAKS IF ...

=over

=item *

second parameter is not a reference to an array

=back

=head1 FUNCTIONS

=head2 compare

  my $sim = compare($string1, $string2);

or

  my $sim = compare($string1,
                    $string2,
                    minSim         => 0.3,
                    warp           => 1.8,
                    ignoreCase     => 0,
                    keepOnlyAlNums => 1,
                    ngram          => 5,
                    debug          => 1);

Use this if you don't want use the oo- interface. Returns resulting similarity.
Note that this is not a very fast way to use the module, if you do a lot of 
comparisons, since internally for every call to compare() a new Trigram object 
is initialized (and C<DESTROY>ed as it goes out of scope).

CROAKS IF ...

[same as using new() and getSimilarStrings()]

=head1 EXPORT_OK

  compare()

=head1 AUTHOR

Tarek Ahmed, E<lt>tarek@epost.deE<gt>

=head1 COPYRIGHT

Copyright (c) 2003 Tarek Ahmed. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=head1 SEE ALSO

=over

=item *

C<String::Similarity> - Uses edit scripts to compute similarity between strings.

=item *

C<String::Approx> - Uses Levenshtein edit distance to compute similarity between strings.

=item *

C<Text::Soundex> - Uses soundex method to compute similarity between strings.

=back

For an early description of the method, see:  R.C. Angell, G.E. Freund, and P. 
Willet. Automatic spelling correction using a trigram similarity measure. 
Information Processing and Management, 19(4):255--261, 1983.

=cut


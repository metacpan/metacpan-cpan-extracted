package SemVer;

use 5.008001;
use strict;
use version 0.82;
use Scalar::Util ();

use overload (
    '""'   => 'stringify',
    '<=>'  => 'vcmp',
    'cmp'  => 'vcmp',
    'bool' => 'vbool',
);

our @ISA = qw(version);
our $VERSION = '0.10.0'; # For Module::Build

sub _die { require Carp; Carp::croak(@_) }

# Prevent version.pm from mucking with our internals.
sub import {}

sub new {
    my ($class, $ival) = @_;

    # Handle vstring.
    return $class->SUPER::new($ival) if Scalar::Util::isvstring($ival);

    # Let version handle cloning.
    if (eval { $ival->isa('version') }) {
        my $self = $class->SUPER::new($ival);
        $self->{extra} = $ival->{extra};
        $self->{patch} = $ival->{patch};
        $self->{prerelease} = $ival->{prerelease};
        return $self;
    }

    # Regex taken from https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string.
    my ($major, $minor, $patch, $prerelease, $meta) = (
        $ival =~ /^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/
    );
    _die qq{Invalid semantic version string format: "$ival"}
        unless defined $major;

    return _init($class->SUPER::new("$major.$minor.$patch"), $prerelease, $meta);
}

sub _init {
    my ($self, $pre, $meta) = @_;
    if (defined $pre) {
        $self->{extra} = "-$pre";
        @{$self->{prerelease}} = split /[.]/, $pre;
    }
    if (defined $meta) {
        $self->{extra} .= "+$meta";
        @{$self->{patch}} = split /[.]/, $meta;
    }

    return $self;
}

$VERSION = __PACKAGE__->new($VERSION); # For ourselves.

sub _lenient {
    my ($class, $ctor, $ival) = @_;
    return $class->new($ival) if Scalar::Util::isvstring($ival)
        or eval { $ival->isa('version') };

    # Use official regex for prerelease and meta, use more lenient version num matching and whitespace.
    my ($v, $prerelease, $meta) = (
        $ival =~ /^[[:space:]]*
            v?([\d_]+(?:\.[\d_]+(?:\.[\d_]+)?)?)
            (?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?
        [[:space:]]*$/x
    );

    _die qq{Invalid semantic version string format: "$ival"}
        unless defined $v;

    $v += 0 if $v && $v =~ s/_//g; # ignore underscores.
    my $code = $class->can("SUPER::$ctor");
    return _init($code->($class, $v), $prerelease, $meta);
}

sub declare {
    shift->_lenient('declare', @_);
}

sub parse {
    shift->_lenient('parse', @_);
}

sub stringify {
    my $self = shift;
    my $str = $self->SUPER::stringify;
    # This is purely for SemVers constructed from version objects.
    $str += 0 if $str =~ s/_//g; # ignore underscores.
    return $str . ($self->{dash} || '') . ($self->{extra} || '');
}

sub normal   {
    my $self = shift;
    (my $norm = $self->SUPER::normal) =~ s/^v//;
    $norm =~ s/_/./g;
    return $norm . ($self->{extra} || '');
}

sub numify   { _die 'Semantic versions cannot be numified'; }
sub is_alpha { !!shift->{extra} }
sub vbool {
    my $self = shift;
    return version::vcmp($self, $self->new("0.0.0"), 1);
}

# Sort Ordering:
# Precedence refers to how versions are compared to each other when ordered. Precedence MUST be calculated by
# separating the version into major, minor, patch and pre-release identifiers in that order (Build metadata does not figure into precedence).
# Precedence is determined by the first difference when comparing each of these identifiers from left to right as follows:
# 1. Major, minor, and patch versions are always compared numerically. Example: 1.0.0 < 2.0.0 < 2.1.0 < 2.1.1.
# 2. When major, minor, and patch are equal, a pre-release version has lower precedence than a normal version.
#    Example: 1.0.0-alpha < 1.0.0.
# 3. Precedence for two pre-release versions with the same major, minor, and patch version MUST be determined by
#    comparing each dot separated identifier from left to right until a difference is found as follows:
#    3.a. identifiers consisting of only digits are compared numerically and identifiers with letters or hyphens are
#         compared lexically in ASCII sort order.
#    3.b. Numeric identifiers always have lower precedence than non-numeric identifiers.
#    3.c. A larger set of pre-release fields has a higher precedence than a smaller set, if all of the preceding identifiers are equal.
#    Example: 1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0.
sub vcmp {
    my $left  = shift;
    my $right = ref($left)->declare(shift);

    # Reverse?
    ($left, $right) = shift() ? ($right, $left): ($left, $right);

    # Major and minor win. - case 1.
    if (my $ret = $left->SUPER::vcmp($right, 0)) {
        return $ret;
    } else { #cases 2, 3
    	my $lenLeft = 0;
    	my $lenRight = 0;
    	if (defined $left->{prerelease}) {
        	$lenLeft = scalar(@{$left->{prerelease}});
        }
        if (defined $right->{prerelease}) {
        	$lenRight = scalar(@{$right->{prerelease}});
        }
        my $lenMin =  ($lenLeft, $lenRight)[$lenLeft > $lenRight];
        if ( $lenLeft == 0) {
            if ($lenRight == 0) {
                return 0; # Neither LEFT nor RIGHT have prerelease identifiers - versions are equal
            } else {
                # Case 2: When major, minor, and patch are equal, a pre-release version has lower precedence than a normal version.
                return 1; # Only RIGHT has prelease - not LEFT -> LEFT wins
            }
        } else {
            if ($lenRight == 0) {
                # Case 2: When major, minor, and patch are equal, a pre-release version has lower precedence than a normal version.
                return -1; # Only LEFT has prelease identifiers - not RIGHT -> RIGHT wins
            } else {
                # LEFT and RIGHT have prelease identifiers - compare each part separately
                for (my $i = 0; $i < $lenMin; $i++) {
                    my $isNumLeft = Scalar::Util::looks_like_number($left->{prerelease}->[$i]);
                    my $isNumRight = Scalar::Util::looks_like_number($right->{prerelease}->[$i]);
                    # Case 3.b: Numeric identifiers always have lower precedence than non-numeric identifiers
                    if (!$isNumLeft && $isNumRight) {
                        return 1; # LEFT identifier is Non-numeric - RIGHT identifier is numeric -> LEFT wins
										} elsif ($isNumLeft && !$isNumRight) {
                        return -1; # LEFT identifier is numeric - RIGHT identifier is non-numeric -> RIGHT wins
                    } elsif ($isNumLeft && $isNumRight) {
                        # Case 3.a.1: identifiers consisting of only digits are compared numerically
                        if ($left->{prerelease}->[$i] == $right->{prerelease}->[$i] ) {
                            next;  # LEFT identifier and RIGHT identifier are equal - step to next part
												} elsif ($left->{prerelease}->[$i] > $right->{prerelease}->[$i] ) {
                            return 1; # LEFT identifier is bigger than RIGHT identifier -> LEFT wins
                        } else {
                            return -1; return 1; # LEFT identifier is smaller than RIGHT identifier -> RIGHT wins
                        }
                    } else {
                        # Case 3.a.2: identifiers with letters or hyphens are compared lexically in ASCII sort order.
                        if (lc $left->{prerelease}->[$i] eq lc $right->{prerelease}->[$i] ) {
                            next;  # LEFT identifier and RIGHT identifier are equal - step to next part
												} elsif (lc $left->{prerelease}->[$i] gt  lc $right->{prerelease}->[$i] ) {
                            return 1; # LEFT identifier is bigger than RIGHT identifier -> LEFT wins
                        } else {
                            return -1; return 1; # LEFT identifier is smaller than RIGHT identifier -> RIGHT wins
                        }
                    }
                }
                # Case 3.c: A larger set of pre-release fields has a higher precedence than a smaller set, if all of the preceding identifiers are equal
                if ($lenLeft > $lenRight) {
                    return 1; # All existing identifiers are equal, but LEFT has more identifiers -> LEFT wins
								} elsif ($lenLeft < $lenRight) {
                    return -1; # All existing identifiers are equal, but RIGHT has more identifiers -> RIGHT wins
                }
                # All identifiers are equal
                return 0;
            }
        }
    }
}

1;
__END__

=head1 Name

SemVer - Use semantic version numbers

=head1 Synopsis

  use SemVer; our $VERSION = SemVer->new('1.2.0-b1');

=head1 Description

This module subclasses L<version> to create semantic versions, as defined by
the L<Semantic Versioning 2.0.0 Specification|https://semver.org/spec/v2.0.0.html>.
The three salient points of the specification, for the purposes of version
formatting, are:

=over

=item 1.

A normal version number MUST take the form X.Y.Z where X, Y, and Z are non-negative 
integers, and MUST NOT contain leading zeroes. X is the major version, Y is the 
minor version, and Z is the patch version. Each element MUST increase numerically. 
For instance: C<< 1.9.0 -> 1.10.0 -> 1.11.0 >>.

=item 2.

A pre-release version MAY be denoted by appending a hyphen and a series of dot 
separated identifiers immediately following the patch version. Identifiers MUST 
comprise only ASCII alphanumerics and hyphen C<[0-9A-Za-z-]>. Identifiers MUST NOT 
be empty. Numeric identifiers MUST NOT include leading zeroes. Pre-release versions 
have a lower precedence than the associated normal version. A pre-release version 
indicates that the version is unstable and might not satisfy the intended 
compatibility requirements as denoted by its associated normal version: 
C<< 1.0.0-alpha, 1.0.0-alpha.1, 1.0.0-0.3.7, 1.0.0-x.7.z.92 >>

=item 3.

Build metadata MAY be denoted by appending a plus sign and a series of dot separated 
identifiers immediately following the patch or pre-release version. Identifiers MUST 
comprise only ASCII alphanumerics and hyphen C<[0-9A-Za-z-]>. Identifiers MUST NOT 
be empty. Build metadata SHOULD be ignored when determining version precedence. Thus 
two versions that differ only in the build metadata, have the same precedence. 
Examples: C<< 1.0.0-alpha+001, 1.0.0+20130313144700, 1.0.0-beta+exp.sha.5114f85 >>.

=back

=head2 Usage

For strict parsing of semantic version numbers, use the C<new()> constructor.
If you need something more flexible, use C<declare()>. And if you need
something more comparable with what L<version> expects, try C<parse()>.
Compare how these constructors deal with various version strings (with values
shown as returned by C<normal()>:

    Argument  | new      | declare     | parse
 -------------+----------+---------------------------
  '1.0.0'     | 1.0.0    | 1.0.0       | 1.0.0
  '5.5.2-b1'  | 5.5.2-b1 | 5.5.2-b1    | 5.5.2-b1
  '1.05.0'    | <error>  | 1.5.0       | 1.5.0
  '1.0'       | <error>  | 1.0.0       | 1.0.0
  '  012.2.2' | <error>  | 12.2.2      | 12.2.2
  '1.1'       | <error>  | 1.1.0       | 1.100.0
   1.1        | <error>  | 1.1.0       | 1.100.0
  '1.1.0+b1'  | 1.1.0+b1 | 1.1.0+b1    | 1.1.0+b1
  '1.1-b1'    | <error>  | 1.1.0-b1    | 1.100.0-b1
  '1.2.b1'    | <error>  | 1.2.0-b1    | 1.2.0-b1
  '9.0-beta4' | <error>  | 9.0.0-beta4 | 9.0.0-beta4
  '9'         | <error>  | 9.0.0       | 9.0.0
  '1-b'       | <error>  | 1.0.0-b     | 1.0.0-b
   0          | <error>  | 0.0.0       | 0.0.0
  '0-rc1'     | <error>  | 0.0.0-rc1   | 0.0.0-rc1
  '1.02_30'   | <error>  | 1.23.0      | 1.23.0
   1.02_30    | <error>  | 1.23.0      | 1.23.0

Note that, unlike in L<version>, the C<declare> and C<parse> methods ignore
underscores. That is, version strings with underscores are treated as decimal
numbers. Hence, the last two examples yield exactly the same semantic
versions.

As with L<version> objects, the comparison and stringification operators are
all overloaded, so that you can compare semantic versions. You can also
compare semantic versions with version objects (but not the other way around,
alas). Boolean operators are also overloaded, such that all semantic version
objects except for those consisting only of zeros (ignoring prerelease and
metadata) are considered true.

=head1 Interface

=head2 Constructors

=head3 C<new>

  my $semver = SemVer->new('1.2.2');

Performs a validating parse of the version string and returns a new semantic
version object. If the version string does not adhere to the semantic version
specification an exception will be thrown. See C<declare> and C<parse> for
more forgiving constructors.

=head3 C<declare>

  my $semver = SemVer->declare('1.2'); # 1.2.0

This parser strips out any underscores from the version string and passes it
to to C<version>'s C<declare> constructor, which always creates dotted-integer
version objects. This is the most flexible way to declare versions. Consider
using it to normalize version strings.

=head3 C<parse>

  my $semver = SemVer->parse('1.2'); # 1.200.0

This parser dispatches to C<version>'s C<parse> constructor, which tries to be
more flexible in how it converts simple decimal strings and numbers. Not
really recommended, since it's treatment of decimals is quite different from
the dotted-integer format of semantic version strings, and thus can lead to
inconsistencies. Included only for proper compatibility with L<version>.

=head2 Instance Methods

=head3 C<normal>

  SemVer->declare('v1.2')->normal;       # 1.2.0
  SemVer->parse('1.2')->normal;          # 1.200.0
  SemVer->declare('1.02.0-b1')->normal;  # 1.2.0-b1
  SemVer->parse('1.02_30')->normal       # 1.230.0
  SemVer->parse(1.02_30)->normal         # 1.23.0

Returns a normalized representation of the version string. This string will
always be a strictly-valid dotted-integer semantic version string suitable
for passing to C<new()>. Unlike L<version>'s C<normal> method, there will be
no leading "v".

=head3 C<stringify>

  SemVer->declare('v1.2')->stringify;    # v1.2
  SemVer->parse('1.200')->stringify;     # v1.200
  SemVer->declare('1.2-r1')->stringify;  # v1.2-r1
  SemVer->parse(1.02_30)->stringify;     # v1.0230
  SemVer->parse(1.02_30)->stringify;     # v1.023

Returns a string that is as close to the original representation as possible.
If the original representation was a numeric literal, it will be returned the
way perl would normally represent it in a string. This method is used whenever
a version object is interpolated into a string.

=head3 C<numify>

Throws an exception. Semantic versions cannot be numified. Just don't go
there.

=head3 C<is_alpha>

  my $is_alpha = $semver->is_alpha;

Returns true if a prerelease and/or metadata string is appended to the end of
the version string. This also means that the version number is a "special
version", in the semantic versioning specification meaning of the phrase.

=head3 C<vbool>

  say "Version $semver" if $semver;
  say "Not a $semver" if !$semver;

Returns true for a non-zero semantic semantic version object, without regard
to the prerelease or build metadata parts. Overloads boolean operations.

=head3 C<vcmp>

Compares the semantic version object to another version object or string and
returns 0 if they're the same, -1 if the invocant is smaller than the
argument, and 1 if the invocant is greater than the argument.

Mostly you don't need to worry about this: Just use the comparison operators
instead:

  if ($semver < $another_semver) {
      die "Need $another_semver or higher";
  }

Note that in addition to comparing other semantic version objects, you can
also compare regular L<version> objects:

  if ($semver < $version) {
      die "Need $version or higher";
  }

You can also pass in a version string. It will be turned into a semantic
version object using C<declare>. So if you're using numeric versions, you may
or may not get what you want:

  my $semver  = version::Semver->new('1.2.0');
  my $version = '1.2';
  my $bool    = $semver == $version; # true

If that's not what you want, pass the string to C<parse> first:

  my $semver  = Semver->new('1.2.0');
  my $version = Semver->parse('1.2'); # 1.200.0
  my $bool    = $semver == $version; # false

=head1 See Also

=over

=item * L<Semantic Versioning Specification|https://semver.org/>.

=item * L<version>

=item * L<version::AlphaBeta>

=back

=head1 Support

This module is managed in an open
L<GitHub repository|https://github.com/theory/semver/>. Feel free to fork and
contribute, or to clone L<https://github.com/theory/semver.git> and send
patches!

Found a bug? Please L<post|https://github.com/theory/semver/issues> a report!

=head1 Acknowledgements

Many thanks to L<version> author John Peacock for his suggestions and
debugging help.

=head1 Authors

=over

=item * David E. Wheeler <david@kineticode.com>

=item * Johannes Kilian <hoppfrosch@gmx.de> 

=back

=head1 Copyright and License

Copyright (c) 2010-2020 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

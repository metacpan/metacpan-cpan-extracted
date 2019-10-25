# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# Perl-Critic-Pulp is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


package Perl::Critic::Policy::ValuesAndExpressions::RequireNumericVersion;
use 5.006;
use strict;
use warnings;
use Scalar::Util;
use version (); # but don't import qv()

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils 'precedence_of';
use Perl::Critic::Pulp::Utils;

# uncomment this to run the ### lines
#use Smart::Comments;

use constant supported_parameters => ();
use constant default_severity => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes   => qw(pulp bugs);
use constant applies_to       => ('PPI::Token::Symbol');

my $perl_510 = version->new('5.10.0');
my $assignment_precedence = precedence_of('=');

our $VERSION = 97;

sub violates {
  my ($self, $elem, $document) = @_;
  ### NumericVersion violates()

  ### canonical: $elem->canonical
  my $package = _symbol_is_mod_VERSION($elem)
    || return;

  my $assign = $elem->snext_sibling || return;
  ### assign: "$assign"
  $assign eq '=' or return;

  my $value = $assign->snext_sibling || return;
  ### value: "$value"

  if (! $value->isa('PPI::Token::Quote')) {
    ### an expression, or a number, not a string, so ok ...
    return;
  }
  if (_following_expression ($value)) {
    ### can't check an expression (though it starts with a string) ...
    return;
  }

  my $str = $value->string;
  if ($value->isa ('PPI::Token::Quote::Double')
      || $value->isa ('PPI::Token::Quote::Interpolate')) {
    ### double quote, check only up to an interpolation
    $str =~ s/[\$\@].*//;
  }

  if (_any_eval_VERSION ($document, $package)) {
    return;
  }

  if (! defined(Perl::Critic::Pulp::Utils::version_if_valid($str))) {
    return $self->violation
      ('Non-numeric VERSION string (not recognised by version.pm)',
       '',
       $value);
  }

  # Float number strings like "1e6" are usually rejected by version.pm, but
  # have seen perl 5.10 and version.pm 0.88 with pure-perl "version::vpp"
  # accept them.  Not sure why that's so, but explicitly reject to be sure.
  # Such a string form in fact works in perl 5.8.x but not in 5.10.x.
  #
  if ($str =~ /e/i) {
    return $self->violation
      ('Non-numeric VERSION string (exponential string like "1e6" no good in perl 5.10 and up)',
       '',
       $value);
  }

  my $got_perl = $document->highest_explicit_perl_version;
  if (defined $got_perl && $got_perl >= $perl_510) {
    # for 5.10 up only need to satisfy version.pm
    return;
  }

  # for 5.8 or unspecified version must be plain number, not "1.2.3" etc
  if (! Scalar::Util::looks_like_number($str)) {
    return $self->violation ('Non-numeric VERSION string',
                             '',
                             $value);
  }
  return;
}

sub _following_expression {
  my ($elem) = @_;
  my $after = $elem->snext_sibling
    or return 0;

  if ($after->isa('PPI::Token::Structure')) {
    return 0;
  } elsif ($after->isa('PPI::Token::Operator')) {
    if (precedence_of($after) >= $assignment_precedence) {
      return 0;
    }
    if ($after eq '.') {
      return 0;
    }
  }
  return 1;
}

# $elem is a PPI::Token::Word
# return its module, such as "Foo::Bar"
# or if it's in "main" then return undef
#
sub _symbol_is_mod_VERSION {
  my ($elem) = @_;

  # canonical() turns $::VERSION into $main::VERSION
  $elem->canonical =~ /^\$((\w+::)*)VERSION$/
    or return undef; # not $VERSION or $Foo::VERSION
  my $package = substr($1,0,-2);

  if ($package eq '') {
    # $elem is an unqualified symbol, find containing "package Foo"
    my $pelem = Perl::Critic::Pulp::Utils::elem_package($elem)
      || return undef; # not in a package, not a module $VERSION
    $package = $pelem->namespace;
  }

  if ($package eq 'main') {
    return undef; # "package main" or "$main::VERSION", not a module
  }
  return $package;
}

# return true if there's a "$VERSION = eval $VERSION" somewhere in
# $document, acting on the "$VERSION" of $want_package
#
sub _any_eval_VERSION {
  my ($document, $want_package) = @_;

  my $aref = $document->find('PPI::Token::Symbol') || return 0;
  foreach my $elem (@$aref) {
    my $got_package = _symbol_is_mod_VERSION($elem) || next;
    $got_package eq $want_package || next;

    my $assign = $elem->snext_sibling || next;
    $assign eq '=' or next;

    my $value = $assign->snext_sibling || next;
    $value->isa('PPI::Token::Word') || next;
    $value eq 'eval' or next;

    $value = $value->snext_sibling || next;
    $value->isa('PPI::Token::Symbol') || next;
    $got_package = _symbol_is_mod_VERSION($value) || next;
    $got_package eq $want_package || next;

    return 1;
  }
  return 0;
}

1;
__END__

=for stopwords toplevel ie CPAN pre-release args exponentials multi-dots v-nums YYYYMMDD Ryde builtin MakeMaker runtime filename

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::RequireNumericVersion - $VERSION a plain number

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you to use a plain number in a module C<$VERSION> so that
Perl's builtin version works.

Any literal number is fine, or a string which is a number,

    $VERSION = 123;           # ok
    $VERSION = '1.5';         # ok
    $VERSION = 1.200_001;     # ok

For Perl 5.10 and higher the extra forms of the C<version> module too,

    use 5.010;
    $VERSION = '1.200_001';   # ok for 5.10 up, version.pm

But a non-number string is not allowed,

    $VERSION = '1.2alpha';    # bad

The idea of this requirement is that a plain number is needed for Perl's
builtin module version checking like the following, and on that basis this
policy is under the "bugs" theme (see L<Perl::Critic/POLICY THEMES>).

    use Foo 1.0;
    Foo->VERSION(1);

A plain number is also highly desirable so applications can do their own
compares like

    if (Foo->VERSION >= 1.234) {

In each case if C<$VERSION> is not a number then it provokes warnings, and
may end up appearing as a lesser version than intended.

    Argument "1.2.alpha" isn't numeric in subroutine entry

If you've loaded the C<version.pm> module then a C<$VERSION> not accepted by
C<version.pm> will in fact croak, which is an unpleasant variant behaviour.

    use version ();
    print "version ",Foo->VERSION,"\n";
    # croaks "Invalid version format ..." if $Foo::VERSION is bad

=head2 Scripts

This policy only looks at C<$VERSION> in modules.  C<$VERSION> in a script
can be anything since it won't normally be part of C<use> checks etc.
A script C<$VERSION> is anything outside any C<package> statement scope, or
under an explicit C<package main>.

    package main;
    $VERSION = '1.5.prerelease';  # ok, script

    $main::VERSION = 'blah';      # ok, script
    $::VERSION = 'xyzzy';         # ok, script

A fully-qualified package name is recognised as belonging to a module,

    $Foo::Bar::VERSION = 'xyzzy'; # bad

=head2 Underscores in Perl 5.8 and Earlier

In Perl 5.8 and earlier a string like "1.200_333" is truncated to the
numeric part, ie. 1.200, and can thus fail to satisfy

    $VERSION = '1.222_333';   # bad
    use Foo 1.222_331;  # not satisfied by $VERSION='string' form

But an actual number literal with an "_" is allowed.  Underscores in
literals are stripped out (see L<perldata>), but not in the automatic string
to number conversion so a string like C<$VERSION = '1.222_333'> provokes a
warning and stops at 1.222.

    $VERSION = 1.222_333;     # ok

On CPAN an underscore in a distribution version number is rated as a
developer pre-release.  But don't put it in module C<$VERSION> strings due
to the problems above.  The suggestion is to include the underscore in the
distribution filename but either omit it from the C<$VERSION> or make it a
number literal not a string,

    $VERSION = 1.002003;    # ok
    $VERSION = 1.002_003;   # ok, but not for VERSION_FROM

C<ExtUtils::MakeMaker> C<VERSION_FROM> will take the latter as its numeric
value, ie. "1.002003" not "1.002_003" as the distribution version.  For the
latter you can either put an explicit C<VERSION> in F<Makefile.PL>

    use ExtUtils::MakeMaker;
    WriteMakefile (VERSION => '1.002_003');

Or you can trick MakeMaker with a string plus C<eval>,

    $VERSION = '1.002_003';    # ok evalled down
    $VERSION = eval $VERSION;

C<MakeMaker> sees the string "1.002_003" but at runtime the C<eval> crunches
it down to a plain number 1.002003.  C<RequireNumericVersion> notices such
an C<eval> and anything in C<$VERSION>.  Something bizarre in C<$VERSION>
won't be noticed, but that's too unlikely to worry about.

=head2 C<version> module in Perl 5.10 up

In Perl 5.10 C<use> etc module version checks parse C<$VERSION> with the
C<version.pm> module.  This policy allows the C<version> module forms if
there's an explicit C<use 5.010> or higher in the file.

    use 5.010;
    $VERSION = '1.222_333';   # ok for 5.10
    $VERSION = '1.2.3';       # ok for 5.10

But this is still undesirable, as an application check like

    if (Foo->VERSION >= 1.234) {

gets the raw string from C<$VERSION> and thus a non-numeric warning and
truncation.  Perhaps applications should let C<UNIVERSAL.pm> do the work
with say

    if (eval { Foo->VERSION(1.234) }) {

or apply C<version-E<gt>new()> to one of the args.  Maybe another policy to
not explicitly compare C<$VERSION>, or perhaps an option to tighten this
policy to require numbers even in 5.10?

=head2 Exponential Format

Exponential strings like "1e6" are disallowed

    $VERSION = '2.125e6';   # bad

Except with the C<eval> trick as per above

    $VERSION = '2.125e6';   # ok
    $VERSION = eval $VERSION;

Exponential number literals are fine.

    $VERSION = 1e6;         # ok

Exponential strings don't work in Perl 5.10 because they're not recognised
by the C<version> module (v0.82).  They're fine in Perl 5.8 and earlier, but
in the interests of maximum compatibility this policy treats such a string
as non-numeric.  Exponentials in versions should be unusual anyway.

=head2 Disabling

If you don't care about this policy at all then you can disable from your
F<.perlcriticrc> in the usual way (see L<Perl::Critic/CONFIGURATION>),

    [-ValuesAndExpressions::RequireNumericVersion]

=head2 Other Ways to Do It

The version number system with underscores, multi-dots, v-nums, etc is
diabolical mess, and each new addition to it just seems to make it worse.
Even the original floating point in version checks is asking for rounding
error trouble, though normally fine in practice.  A radical simplification
is to just use integer version numbers.

    $VERSION = 123;

If you want sub-versions then increment by 100 or some such.  Even a
YYYYMMDD date is a possibility.

    $VERSION = 20110328;

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

L<Perl::Critic::Policy::Modules::RequireVersionVar>,
L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitComplexVersion>,
L<Perl::Critic::Policy::ValuesAndExpressions::RequireConstantVersion>

L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings>,
L<Perl::Critic::Policy::Modules::ProhibitUseQuotedVersion>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.

=cut


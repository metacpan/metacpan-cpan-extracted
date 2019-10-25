# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019 Kevin Ryde

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


package Perl::Critic::Policy::Compatibility::ConstantLeadingUnderscore;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;
use Perl::Critic::Pulp::Utils;
use Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders;
use version (); # but don't import qv()

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 97;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes       => qw(pulp compatibility);
use constant applies_to           => 'PPI::Document';

my $perl_ok_version = version->new('5.006');
my $constant_ok_version = version->new('1.02');

sub violates {
  my ($self, $elem, $document) = @_;

  my @violations;
  my $perlver; # a "version" object
  my $modver;  # a "version" object

  my $aref = $document->find ('PPI::Statement::Include')
    || return; # if no includes at all
  foreach my $inc (@$aref) {

    $inc->type eq 'use'
      || ($inc->type eq 'require'
          && Perl::Critic::Pulp::Utils::elem_in_BEGIN($inc))
        || next;

    if (my $ver = $inc->version) {
      # "use 5.006" etc perl version
      $ver = version->new ($ver);
      if (! defined $perlver || $ver > $perlver) {
        $perlver = $ver;  # maximum seen so-far

        if ($perlver >= $perl_ok_version) {
          # adequate perl version demanded, stop here
          last;
        }
      }
      next;
    }

    ($inc->module||'') eq 'constant' || next;

    if (my $ver = Perl::Critic::Pulp::Utils::include_module_version ($inc)) {
      ### $ver
      # PPI::Token::Number::Float
      $ver = version->new ($ver->content);
      if (! defined $modver || $ver > $modver) {
        $modver = $ver;

        if ($modver >= $constant_ok_version) {
          # adequate "constant" version demanded, stop here
          last;
        }
      }
    }

    my $name = _use_constant_single_name ($inc);
    if (defined $name && $name =~ /^_/) {
      push @violations, $self->violation
        ("'use constant' with leading underscore requires perl 5.6 or constant 1.02 (at this point have "
         . (defined $perlver ? "perl $perlver" : "no perl version")
         . (defined $modver ? ", constant $modver)" : ", no constant version)"),
         '',
         $inc);
    }
  }

  return @violations;
}

# $inc is a PPI::Statement::Include with type "use" and module "constant".
# If it's a single-name "use constant foo => ..." then return the name
# string "foo".  If it's a multi-constant or something unrecognised then
# return undef..
#
sub _use_constant_single_name {
  my ($inc) = @_;
  my $arg = Perl::Critic::Pulp::Utils::include_module_first_arg ($inc)
    || return undef; # empty "use constant" or version "use constant 1.05"

  if ($arg->isa('PPI::Token::Word')) {
    # use constant FOO ...
    return $arg->content;
  }
  if ($arg->isa('PPI::Token::Quote::Single')
      || $arg->isa('PPI::Token::Quote::Literal')) {
    # use constant 'FOO', ...
    # use constant q{FOO}, ...
    return $arg->literal;
  }
  if ($arg->isa('PPI::Token::Quote::Double')
      || $arg->isa('PPI::Token::Quote::Interpolate')) {
    # ENHANCE-ME: use $arg->interpolations() when available also on
    # PPI::Token::Quote::Interpolate
    my $str = $arg->string;
    if (! Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders::_string_any_vars($str)) {
      # use constant "FOO", ...
      # use constant qq{FOO}, ...
      # not quite right, but often close enough
      return $str;
    }
  }
  # a hash or an expression or something unrecognised
  return undef;
}

# $str is the contents of a "" or qq{} string
# return true if it has any $ or @ interpolation forms
sub _string_any_vars {
  my ($str) = @_;
  return ($str =~ /(^|[^\\])(\\\\)*[\$@]/);
}

1;
__END__

=for stopwords multi-constant multi-constants CPAN perl ok ConstantLeadingUnderscore backports prereqs Ryde subr inlined

=head1 NAME

Perl::Critic::Policy::Compatibility::ConstantLeadingUnderscore - new enough "constant" module for leading underscores

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks that if you have a constant with a leading underscore,

    use constant _FOO ...  # leading underscore on name

then you explicitly declare C<use 5.6> or C<use constant 1.02>, or higher,
since C<constant.pm> before that did not allow leading underscores.

    use constant _FOO => 123;        # bad

    use 5.006;
    use constant _FOO => 123;        # ok

    use constant 1.02;
    use constant _FOO => 123;        # ok

    use constant 1.02 _FOO => 123;   # ok

The idea is to avoid trouble in code which might run on Perl 5.005, or might
in principle still run there.  On that basis this policy is under the
"compatibility" theme (see L<Perl::Critic/POLICY THEMES>).

Asking for the new enough module C<use constant 1.02> is suggested, since
it's the module feature which is required and the code might then still run
on Perl 5.005 or earlier if the user has a suitable C<constant.pm> from
CPAN.

=head2 Details

A version declaration must be before the first leading underscore, so it's
checked before the underscore is attempted (and would give an error).

    use constant _FOO => 123;        # bad
    use 5.006;

A C<require> for the Perl version is not enough since C<use constant> is at
C<BEGIN> time, before plain code.

    require 5.006;                   # doesn't run early enough
    use constant _FOO => 123;        # bad

But a C<require> within a C<BEGIN> block is ok (a past style, still found
occasionally).

    BEGIN { require 5.006 }
    use constant _FOO => 123;        # ok

    BEGIN {
      require 5.006;
      and_other_setups ...;
    }
    use constant _FOO => 123;        # ok

Currently C<ConstantLeadingUnderscore> pays no attention to any conditionals
within the C<BEGIN>, it assumes any C<require> there always runs.  It might
be tricked by obscure tests but hopefully anything like that is rare or does
the right thing anyway.

A quoted version number like

    use constant '1.02';    # no good

is no good, only a bare number is recognised by the C<use> statement as a
version check.  A string like that in fact goes through to C<constant> as a
name to define, and which it will reject.

Leading underscores in a multi-constant hash are not flagged, since new
enough C<constant.pm> to have multi-constants is new enough to have
underscores.  See
L<Compatibility::ConstantPragmaHash|Perl::Critic::Policy::Compatibility::ConstantPragmaHash>
for multi-constants version check.

    use constant { _FOO => 1 };      # not checked

Leading double-underscore is disallowed by all versions of C<constant.pm>.
That's not reported by this policy since the code won't run at all.

    use constant __FOO => 123;  # not allowed by any constant.pm

=head2 Drawbacks

Explicitly adding required version numbers in the code can be irritating,
especially if other things you're doing only run on 5.6 up anyway.  But
declaring what code needs is accurate, it allows maybe for backports of
modules, and explicit versions can be grepped out to create or check
F<Makefile.PL> or F<Build.PL> prereqs.

As always, if you don't care about this or if you only ever use Perl 5.6
anyway then you can disable C<ConstantLeadingUnderscore> from your
F<.perlcriticrc> in the usual way (see L<Perl::Critic/CONFIGURATION>),

    [-Compatibility::ConstantLeadingUnderscore]

=head1 OTHER WAYS TO DO IT

It's easy to write your own constant subr and it can have any name at all
(anything acceptable to Perl), bypassing the sanity checks or restrictions
in C<constant.pm>.  Only the C<()> prototype is a bit obscure.

    sub _FOO () { return 123 }

The key benefit of subs like this, whether from C<constant.pm> or
explicitly, is that the value is inlined and can be constant-folded in an
arithmetic expression etc (see L<perlsub/Constant Functions>).

    print 2*_FOO;   # folded to 246 at compile-time

The purpose of a leading underscore is normally a hint that the sub is meant
to be private to the module and/or its friends.  If you don't need the
constant folding then a C<my> scalar is even more private, being invisible
to anything outside relevant scope,

    my $FOO = 123;         # more private
    # ...
    do_something ($FOO);   # nothing to constant-fold anyway

The scalar returned from C<constant.pm> subs is flagged read-only, which
might prevent accidental mis-use when passed around.  The C<Readonly> module
gives the same effect on variables.  If you have C<Readonly::XS> then it's
just a flag too (no performance penalty on using the value).

    use Readonly;
    Readonly::Scalar my $FOO => 123;

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<Perl::Critic::Policy::Compatibility::ConstantPragmaHash>,
L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma>,
L<Perl::Critic::Policy::Modules::RequirePerlVersion>

L<constant>, L<perlsub/Constant Functions>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019 Kevin Ryde

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

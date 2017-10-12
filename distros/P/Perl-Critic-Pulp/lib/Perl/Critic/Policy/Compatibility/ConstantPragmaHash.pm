# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


package Perl::Critic::Policy::Compatibility::ConstantPragmaHash;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;
use Perl::Critic::Pulp::Utils;
use version (); # but don't import qv()

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 95;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes       => qw(pulp compatibility);
use constant applies_to           => 'PPI::Document';

my $perl_ok_version = version->new('5.008');
my $constant_ok_version = version->new('1.03');

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
      # "use 5.008" etc perl version
      $ver = version->new ($ver);
      if (! defined $perlver || $ver > $perlver) {
        $perlver = $ver;

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

    if (_use_constant_is_multi ($inc)) {
      push @violations, $self->violation
        ("'use constant' with multi-constant hash requires perl 5.8 or constant 1.03 (at this point have "
         . (defined $perlver ? "perl $perlver" : "no perl version")
         . (defined $modver ? ", constant $modver)" : ", no constant version)"),
         '',
         $inc);
    }
  }

  return @violations;
}

# $inc is a PPI::Statement::Include with type "use" and module "constant".
# Return true if it has a multi-constant hash as its argument like
# "use constant { X => 1 };"
#
# The plain "use constant { x=>1 }" comes out as
#
#   PPI::Statement::Include
#     PPI::Token::Word    'use'
#     PPI::Token::Word    'constant'
#     PPI::Structure::Constructor         { ... }
#       PPI::Statement
#         PPI::Token::Word        'x'
#         PPI::Token::Operator    '=>'
#         PPI::Token::Number      '1'
#
# Or as of PPI 1.203 with a version number "use constant 1.03 { x=>1 }" is
# different
#
#   PPI::Statement::Include
#     PPI::Token::Word    'use'
#     PPI::Token::Word    'constant'
#     PPI::Token::Number::Float   '1.03'
#     PPI::Structure::Block       { ... }
#       PPI::Statement
#         PPI::Token::Word        'x'
#         PPI::Token::Operator    '=>'
#         PPI::Token::Number      '1'
#
sub _use_constant_is_multi {
  my ($inc) = @_;
  my $arg = Perl::Critic::Pulp::Utils::include_module_first_arg ($inc)
    || return 0; # empty "use constant" or version "use constant 1.05"
  return ($arg->isa('PPI::Structure::Constructor') # without version number
          || $arg->isa('PPI::Structure::Block'));  # with version number
}


1;
__END__

=for stopwords multi-constant CPAN perl ok ConstantPragmaHash backports prereqs Ryde

=head1 NAME

Perl::Critic::Policy::Compatibility::ConstantPragmaHash - new enough "constant" module for multiple constants

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It requires that when you use the hash style multiple constants of
C<use constant> that you explicitly declare either Perl 5.8 or C<constant>
1.03 or higher.

    use constant { AA => 1, BB => 2 };       # bad

    use 5.008;
    use constant { CC => 1, DD => 2 };       # ok

    use constant 1.03;
    use constant { EE => 1, FF => 2 };       # ok

    use constant 1.03 { GG => 1, HH => 2 };  # ok

The idea is to keep you from using the multi-constant feature in code which
might run on Perl 5.6, or might in principle still run there.  On that basis
this policy is under the "compatibility" theme (see L<Perl::Critic/POLICY
THEMES>).

If you declare C<constant 1.03> then the code can still run on Perl 5.6 and
perhaps earlier if the user gets a suitably newer C<constant> module from
CPAN.  Or of course for past compatibility just don't use the hash style at
all!

=head2 Details

A version declaration must be before the first multi-constant, so it's
checked before the multi-constant is attempted (and gives an obscure error).

    use constant { X => 1, Y => 2 };       # bad
    use 5.008;

A C<require> for the perl version is not adequate since the C<use constant>
is at C<BEGIN> time, before plain code.

    require 5.008;
    use constant { X => 1, Y => 2 };       # bad

But a C<require> within a C<BEGIN> block is ok (an older style, still found
occasionally).

    BEGIN { require 5.008 }
    use constant { X => 1, Y => 2 };       # ok

    BEGIN {
      require 5.008;
      and_other_setups ...;
    }
    use constant { X => 1, Y => 2 };       # ok

Currently ConstantPragmaHash pays no attention to any conditionals within
the C<BEGIN>, it assumes any C<require> there always runs.  It could be
tricked by some obscure tests but hopefully anything like that is rare.

A quoted version number like

    use constant '1.03';    # no good

is no good, only a bare number is recognised by C<use> and acted on by
ConstantPragmaHash.  A string like that goes through to C<constant> as if a
name to define (which you'll see it objects to as soon as you try run it).

=head2 Drawbacks

Explicitly adding version numbers to your code can be irritating if other
modules you're using only run on 5.8 anyway.  But declaring what your own
code wants is accurate, it allows maybe for backports of those other things,
and explicit versions can be grepped out to create or check F<Makefile.PL>
or F<Build.PL> prereqs.

As always if you don't care about this and in particular if you only ever
use Perl 5.8 anyway then you can disable C<ConstantPragmaHash> from your
F<.perlcriticrc> in the usual way (see L<Perl::Critic/CONFIGURATION>),

    [-Compatibility::ConstantPragmaHash]

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<Perl::Critic::Policy::Compatibility::ConstantLeadingUnderscore>,
L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma>,
L<Perl::Critic::Policy::Modules::RequirePerlVersion>

L<perlsub/Constant Functions>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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

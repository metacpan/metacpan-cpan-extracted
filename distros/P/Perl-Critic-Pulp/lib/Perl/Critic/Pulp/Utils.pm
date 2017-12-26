# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# This file is part of Perl-Critic-Pulp.

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


package Perl::Critic::Pulp::Utils;
use 5.006;
use strict;
use warnings;
use version (); # but don't import qv()

our $VERSION = 96;

use base 'Exporter';
our @EXPORT_OK = qw(parameter_parse_version
                    version_if_valid
                    include_module_version
                    elem_package
                    elem_in_BEGIN
                    elem_is_comma_operator
                    %COMMA);

our %COMMA = (','  => 1,
              '=>' => 1);

sub parameter_parse_version {
  my ($self, $parameter, $str) = @_;

  my $version;
  if (defined $str && $str ne '') {
    $version = version_if_valid ($str);
    if (! defined $version) {
      $self->throw_parameter_value_exception
        ($parameter->get_name,
         $str,
         undef, # source
         'invalid version number string');
    }
  }
  $self->__set_parameter_value ($parameter, $version);
}

# return a version.pm object, or undef if $str is invalid
sub version_if_valid {
  my ($str) = @_;
  # this is a nasty hack to notice "not a number" warnings, and for version
  # 0.81 possibly throwing errors too
  my $good = 1;
  my $version;
  { local $SIG{'__WARN__'} = sub { $good = 0 };
    eval { $version = version->new($str) };
  }
  return ($good ? $version : undef);
}

# This regexp is what Perl's toke.c S_force_version() demands, as of
# versions 5.004 through 5.8.9.  A version number in a "use" must start with
# a digit and then have only digits, dots and underscores.  In particular
# other normal numeric forms like hex or exponential are not taken to be
# version numbers, and even omitting the 0 from a decimal like ".25" is not
# a version number.
#
our $use_module_version_number_re = qr/^v?[0-9][0-9._]*$/;

sub include_module_version {
  my ($inc) = @_;

  # only a module style "use Foo", not a perl version num like "use 5.010"
  defined ($inc->module) || return undef;

  my $ver = $inc->schild(2) || return undef;
  # ENHANCE-ME: when PPI recognises v-strings may have to extend this
  $ver->isa('PPI::Token::Number') || return undef;

  $ver->content =~ $use_module_version_number_re or return undef;

  # must be followed by whitespace, or comment, or end of statement, so
  #
  #    use Foo 10 -3;    <- version 10, arg -3
  #    use Foo 10-3;     <- arg 7
  #
  #    use Foo 10#       <- version 10, arg -3
  #    -3;
  #
  if (my $after = $ver->next_sibling) {
    unless ($after->isa('PPI::Token::Whitespace')
            || $after->isa('PPI::Token::Comment')
            || ($after->isa('PPI::Token::Structure')
                && $after eq ';')) {
      return undef;
    }
  }

  return $ver;
}

# $inc is a PPI::Statement::Include.
# Return the element which is the start of the first argument to its
# import() or unimport(), for "use" or "no" respectively.
#
# A "require" is treated the same as "use" and "no", but arguments to it
# like "require Foo::Bar '-init';" is in fact a syntax error.
#
sub include_module_first_arg {
  my ($inc) = @_;
  defined ($inc->module) || return;
  my $arg;
  if (my $ver = include_module_version ($inc)) {
    $arg = $ver->snext_sibling;
  } else {
    # eg. "use Foo 'xxx'"
    $arg = $inc->schild(2);
  }
  # don't return terminating ";"
  if ($arg
      && $arg->isa('PPI::Token::Structure')
      && $arg->content eq ';'
      && ! $arg->snext_sibling) {
    return;
  }
  return $arg;
}

# Hack to set Perl::Critic::Violation location to $linenum in $doc_str.
# Have thought about validating _location and _source fields before mangling
# them, but hopefully there'll be a documented interface to use before long.
#
sub _violation_override_linenum {
  my ($violation, $doc_str, $linenum) = @_;

  #   if ($violation->can('set_line_number_offset')) {
  #     $violation->set_line_number_offset ($linenum - 1);
  #   } else {

  bless $violation, 'Perl::Critic::Pulp::PodMinimumVersionViolation';
  $violation->{_Pulp_linenum_offset} = $linenum - 1;
  $violation->{'_source'} = _str_line_n ($doc_str, $linenum);

  return $violation;
}

# starting contents of line number $n within $str
# $n==0 is the first line
sub _str_line_n {
  my ($str, $n) = @_;
  $n--;
  return ($str =~ /^(.*\n){$n}(.*)/ ? $2 : '');
}

sub elem_package {
  my ($elem) = @_;
  for (;;) {
    $elem = $elem->sprevious_sibling || $elem->parent
      || return undef;
    if ($elem->isa ('PPI::Statement::Package')) {
      return $elem;
    }
  }
}

sub elem_in_BEGIN {
  my ($elem) = @_;
  while ($elem = $elem->parent) {
    if ($elem->isa('PPI::Statement::Scheduled')) {
      return ($elem->type eq 'BEGIN');
    }
  }
  return 0;
}

sub elem_is_comma_operator {
  my ($elem) = @_;
  return ($elem->isa('PPI::Token::Operator')
          && $Perl::Critic::Pulp::Utils::COMMA{$elem});
}

1;
__END__

=for stopwords perlcritic Ryde ie

=head1 NAME

Perl::Critic::Pulp::Utils - shared helper code for the Pulp perlcritic add-on

=head1 SYNOPSIS

 use Perl::Critic::Pulp::Utils;

=head1 DESCRIPTION

This is a bit of a grab bag, but works as far as it goes.

=head1 FUNCTIONS

=head2 Element Functions

=over

=item C<$pkgelem = Perl::Critic::Pulp::Utils::elem_package ($elem)>

C<$elem> is a C<PPI::Element>.  Return the C<PPI::Statement::Package>
containing C<$elem>, or C<undef> if C<$elem> is not in the scope of any
package statement.

The search upwards begins with the element preceding C<$elem>, so if
C<$elem> itself is a C<PPI::Statement::Package> then that's not the one
returned, instead its containing package.

=item C<$bool = Perl::Critic::Pulp::Utils::elem_in_BEGIN ($elem)>

Return true if C<$elem> (a C<PPI::Element>) is within a C<BEGIN> block
(ie. a C<PPI::Statement::Scheduled> of type "BEGIN").

=item C<$bool = Perl::Critic::Pulp::Utils::elem_is_comma_operator ($elem)>

Return true if C<$elem> (a C<PPI::Element>) is a comma operator
(C<PPI::Token::Operator>), either "," or "=>'.

=cut

# Not sure about this just yet.  This first_arg would be a matching pair.
# 
# =item C<$numelem = Perl::Critic::Pulp::Utils::include_module_version ($incelem)>
# 
# C<$incelem> is a C<PPI::Statement::Include>.  If it's a module type C<use>
# or C<no> with a version number for Perl to check then return that version
# number element, otherwise return C<undef>.
# 
#     use Foo 1.23 qw(arg1 arg2);
#     no Bar 0.1;
# 
# A module version is a literal number following the module name, with either
# nothing after it for that statement, or with no comma before the statement
# arguments.
# 
# C<Exporter> and other module C<import> handlers may interpret a number
# argument as a version to be checked, but C<include_module_version> looks
# only for version numbers which Perl itself will check.
# 
# A module C<require> type C<$incelem> is treated the same as C<use> and
# C<no>, but a module version number like "require Foo::Bar 1.5" is a Perl
# syntax error.  A Perl version C<$incelem> like C<use 5.004> is not a module
# include and the return is C<undef> for it.
# 
# As of PPI 1.203 there's no v-number parsing, so the returned element is only
# ever a C<PPI::Token::Number>.  Perhaps that will change.
# 
# C<PPI::Statement::Include> has a similar C<$incelem-E<gt>module_version>
# method, but it's wrong as of PPI 1.209.  It takes all numbers as version
# numbers, whereas Perl doesn't accept exponential format floats, only the
# restricted number forms of Perl's F<toke.c> C<S_force_version()>.

=back

=head2 Policy Parameter Functions

=over

=item C<Perl::Critic::Pulp::Utils::parameter_parse_version ($self, $parameter, $str)>

This is designed for use as the C<parser> field of a policy's
C<supported_parameters> entry for a parameter which is a version number.

    { name        => 'above_version',
      description => 'Check only above this version of Perl.',
      behavior    => 'string',
      parser      => \&Perl::Critic::Pulp::Utils::parameter_parse_version,
    }    

C<$str> is parsed with the C<version.pm> module.  If valid then the
parameter is set with C<$self-E<gt>__set_parameter_value> to the resulting
C<version> object (so for example field $self->{'_above_version'}).  If
invalid then an exception is thrown per
C<$self-E<gt>throw_parameter_value_exception>.

=back

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested in usual
C<Exporter> style,

    use Perl::Critic::Pulp::Utils 'elem_in_BEGIN';
    if (elem_in_BEGIN($elem)) {
      # ...
    }

There's no C<:all> tag since this module is meant as a grab-bag of functions
and importing as-yet unknown things would be asking for name clashes.

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<PPI>

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

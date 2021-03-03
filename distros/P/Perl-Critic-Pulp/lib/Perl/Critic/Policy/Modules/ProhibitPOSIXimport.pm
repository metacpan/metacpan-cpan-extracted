# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

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


package Perl::Critic::Policy::Modules::ProhibitPOSIXimport;
use 5.006;
use strict;
use warnings;
use List::MoreUtils;
use POSIX ('abort'); # must import something to initialize @POSIX::EXPORT
use Scalar::Util;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(is_function_call
                           split_nodes_on_comma);
use Perl::Critic::Utils::PPI qw(is_ppi_expression_or_generic_statement);
use Perl::Critic::Pulp::Utils;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 99;

use constant _ALLOWED_CALL_COUNT => 15;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes       => qw(pulp efficiency);
use constant applies_to           => ('PPI::Statement::Include');

my %posix_function;

sub initialize_if_enabled {
  my ($self, $config) = @_;
  @posix_function{@POSIX::EXPORT} = ();  # hash slice
  ### POSIX EXPORT count: scalar(keys %posix_function)
  return 1;
}


sub violates {
  my ($self, $elem, $document) = @_;

  return unless ($elem->module||'') eq 'POSIX';  # "use POSIX"
  return unless (_inc_exporter_imports_type($elem) eq 'default');
  return if _elem_is_in_package_main($elem);     # within main ok
  return if _count_posix_calls($document) >= _ALLOWED_CALL_COUNT;

  return $self->violation
    ("Don't import the whole of POSIX into a module",
     '',
     $elem);
}

# $inc is a PPI::Statement::Include of a module using Exporter.pm.
# Return 'no_import' -- $inc doesn't call import() at all
#        'default'   -- $inc gets Exporter's default imports
#        'explicit'  -- $inc chooses certain imports explicitly
#
sub _inc_exporter_imports_type {
  my ($inc) = @_;

  $inc->type eq 'use'
    or return 'no_import'; # "require Foo" or "no Foo" don't import

  my $mfirst = Perl::Critic::Pulp::Utils::include_module_first_arg ($inc)
    || return 'default'; # no args or only a version check

  my @elems = _elem_and_snext_siblings ($mfirst);
  _chomp_trailing_semi (\@elems);
  ### elems count: scalar(@elems)
  ### elems: "@elems"
  if (@elems == 1 && _elem_is_empty_list($elems[0])) {
    return 'no_import'; # "use Foo ()" doesn't call import() at all
  }

  my @args = _parse_args (@elems);
  if (@args >= 1 && _arg_is_number($args[0])) {
    shift @args; # use Foo '123',... Exporter skips version number
  }
  return (@args ? 'explicit' : 'default');
}

# return true if PPI $elem is within the "package main", either an explicit
# "package main" or main as the default when no "package" statement at all
#
sub _elem_is_in_package_main {
  my ($elem) = @_;
  my $package = Perl::Critic::Pulp::Utils::elem_package($elem)
    || return 1; # no package statement
  ### within_package: "$package"
  return ($package->namespace eq 'main'); # explicit "package main"
}

sub _parse_args {
  my @first = split_nodes_on_comma (@_);
  ### first split: scalar(@first)
  ### @first

  # if (DEBUG) {
  #   require PPI::Dumper;
  #   foreach my $aref (@first) {
  #     print "  aref:\n";
  #     foreach my $elem (@$aref) {
  #       PPI::Dumper->new($elem)->print;
  #     }
  #   }
  # }

  my @ret;
  while (@first) {
    my $aref = shift @first;
    next unless defined $aref;
    if (@$aref == 1) {
      my $elem = $aref->[0];
      if ($elem->isa('PPI::Structure::List')) {
        my @children = $elem->schildren;
        if (@children == 0) {
          next; # empty list elided
        }
        if (@children == 1) {
          $elem = $children[0];
          if ($elem->isa('PPI::Statement')) {
            @children = $elem->schildren;
            if (@children) {
              unshift @first, split_nodes_on_comma (@children);
              next;
            }
          }
        }
      }
    }
    push @ret, $aref;
  }

  ### final ret: scalar(@ret)
  # if (DEBUG) {
  #   require PPI::Dumper;
  #   foreach my $aref (@ret) {
  #     print "  aref:\n";
  #     foreach my $elem (@$aref) {
  #       PPI::Dumper->new($elem)->print;
  #     }
  #   }
  # }

  return @ret;
}

sub _chomp_trailing_semi {
  my ($aref) = @_;
  while (@$aref
         && $aref->[-1]->isa('PPI::Token::Structure')
         && $aref->[-1]->content eq ';') {
    pop @$aref;
  }
}

sub _elem_and_snext_siblings {
  my ($elem) = @_;
  my @ret = ($elem);
  while ($elem = $elem->snext_sibling) {
    push @ret, $elem;
  }
  return @ret;
}

sub _elem_is_empty_list {
  my ($elem) = @_;
  for (;;) {
    $elem->isa('PPI::Structure::List') || return 0;
    my @children = $elem->schildren;
    if (@children == 0) {
      return 1; # empty list
    }
    if (@children == 1) {
      $elem = $children[0];
      if ($elem->isa('PPI::Statement')) {
        @children = $elem->schildren;
        if (@children == 1) {
          $elem = $children[0];
          next;
        }
      }
    }
    return 0;
  }
}

# $aref is an arrayref of PPI elements which are function arguments.
# Return true if the argument is a number, including a numeric string.
#
# ENHANCE-ME: Do some folding of constant concats or numeric calculations.
#
sub _arg_is_number {
  my ($aref) = @_;

  @$aref == 1 || return 0; # only single elements for now
  my $arg = $aref->[0];
  return ($arg->isa('PPI::Token::Number')

          || (($arg->isa('PPI::Token::Quote::Single')
               || $arg->isa('PPI::Token::Quote::Literal'))
              && Scalar::Util::looks_like_number ($arg->literal)));
}


# return a count of calls to POSIX module functions within $document
sub _count_posix_calls {
  my ($document) = @_;

  # function calls like "dup()", with is_function_call() used to exclude
  # method calls like $x->dup on unrelated objects or classes
  my $aref = $document->find ('PPI::Token::Word') || [];
  my $count = List::MoreUtils::true
    { exists $posix_function{$_->content} && is_function_call($_)
    } @$aref;
  ### count func calls: $count

  # symbol references \&dup or calls &dup(6)
  $aref = $document->find ('PPI::Token::Symbol') || [];
  $count += List::MoreUtils::true
    { my $symbol = $_->symbol;
      $symbol =~ /^&/ && exists $posix_function{substr($symbol,1)}
    } @$aref;
  ###   plus symbols gives: $count

  return $count;
}

1;
__END__

=for stopwords POSIX kbytes Ryde

=head1 NAME

Perl::Critic::Policy::Modules::ProhibitPOSIXimport - don't import the whole of POSIX into a module

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you not to C<use POSIX> with an import of all the symbols
from that module if you're only using a few things.

    package Foo;
    use POSIX;    # bad

The aim is to save some memory, and maybe run a bit faster.  A full C<POSIX>
import adds about 550 symbols to your module and that's about 30 to 40
kbytes in Perl 5.10 on a 32-bit system, or about 115 kbytes in Perl 5.8.  If
lots of modules do this then it adds up.

As noted in the C<POSIX> module docs, the way it exports everything by
default is an historical accident, not something to encourage.

=head2 Allowed Forms

A full import is allowed in C<package main>, which is the top-level of a
script etc, since in a script you want convenience rather than a bit of
memory, at least initially.

    #!/usr/bin/perl
    use POSIX;        # ok

An import of no symbols is allowed and you then add a C<POSIX::> qualifier
to each call or constant.  Qualifiers like this can make it clear where the
function is coming from.

    package Foo;
    use POSIX (); # ok

    my $fd = POSIX::dup(0);
    if ($! == POSIX::ENOENT())

An import of an explicit set of functions and constants is allowed.  This
allows short names without the memory penalty of a full import.  However it
can be error-prone to update the imports with what you actually use (see
C<ProhibitCallsToUndeclaredSubs> for some checking).

    package Foo;
    use POSIX qw(dup ENOENT); # ok
    ...
    my $fd = dup(0);

A full import is allowed in a module if there's 15 or more calls to C<POSIX>
module functions.  This rule might change or be configurable in the future,
but the intention is that a module making heavy use of C<POSIX> shouldn't be
burdened by a C<POSIX::> on every call or by maintaining a list of explicit
imports.

    package Foo;
    use POSIX;         # ok
    ...
    tzset(); dup(1)... # 15 or more calls to POSIX stuff

=head2 Disabling

If you don't care this sort of thing you can always disable
C<ProhibitPOSIXimport> from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Modules::ProhibitPOSIXimport]

=head1 SEE ALSO

L<POSIX>,
L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<Perl::Critic::Policy::Subroutines::ProhibitCallsToUndeclaredSubs>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

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

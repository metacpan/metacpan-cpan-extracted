# Copyright 2009, 2010, 2011, 2013, 2015 Kevin Ryde

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


package Perl::Critic::Policy::Compatibility::inprogressTestMore;
use 5.006;
use strict;
use warnings;
use List::Util;
use version (); # but don't import qv()
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(is_function_call);
use Perl::Critic::Pulp::Utils;

use constant DEBUG => 0;

use constant supported_parameters => ();
use constant default_severity => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes   => qw(pulp bugs);
use constant applies_to       => ('PPI::Token::Word', 'PPI::Token::Symbol');

my %functions = ('explain' => { module  => 'Test::More',
                                modver  => version->new('0.82'),
                                perlver => version->new('5.010001'),
                                export  => 1 }
                );

sub violates {
  my ($self, $elem, $document) = @_;

  my $elem_str;
  if ($elem->isa('PPI::Token::Symbol')) {
    $elem->symbol_type eq '&'
      or return; # not &foo function
    $elem_str = substr ($elem->symbol, 1);
  } else {
    # PPI::Token::Word
    $elem_str = $elem->content;
  }

  my ($elem_qualifier, $elem_basename) = _qualifier_and_basename ($elem_str);
  if (defined $elem_qualifier && $elem_qualifier ne 'Test::More') {
    return;  # some other Foo::Bar::func()
  }

  my $want = $functions{$elem_basename} || return;

  is_function_call ($elem)
    or return;

  my $got_perl = $document->highest_explicit_perl_version;
  if (defined $got_perl
      && ref $got_perl
      && $got_perl >= $want->{'perlver'}) {
    return;  # high enough "use 5.010" or whatnot
  }

  my $got_testmore = _highest_explicit_module_version ($document,'Test::More');
  if (! defined $got_testmore && ! defined $elem_qualifier) {
    return; # no "use Test::More", so unqualified foo() is not it
  }
  if (defined $got_testmore
      && ref $got_testmore
      && $got_testmore >= $want->{'modver'}) {
    return;  # high enough "use Test::More 0.90" etc
  }

  return $self->violation
    ("$elem requires Test::More $want->{'modver'} or perl $want->{'perlver'}, but file has "
     . (defined $got_testmore && ref $got_testmore
        ? "Test::More $got_testmore"
        : "no version for Test::More")
     . (defined $got_perl && ref $got_perl
        ? ", and perl $got_perl"
        : ", and no perl version"),
     '',
     $elem);
}

sub _qualifier_and_basename {
  my ($str) = @_;
  return ($str =~ /(?:(.*)::)?(.*)/)
}

# return true if $document has a "use" of $module (string name of a package)
sub _document_uses_module {
  my ($document, $module) = @_;

  my $aref = $document->find ('PPI::Statement::Include')
    || return;  # if no Includes at all
  return List::Util::first {$_->type eq 'use'
                              && (($_->module || '') eq $module)
                            } @$aref;
}

# return a "version" object which is the highest explicit use for $module (a
# string) in $document
#
# A call like Foo::Bar->VERSION(123) is a version check, but not sure that's
# worth looking for.
#
# If there's no version number on any "use" of $module then the return is
# version->new(0).  If there's no "use" of $module at all then the return is
# undef.
#
sub _highest_explicit_module_version {
  my ($document, $module) = @_;

  my $cache_key = __PACKAGE__.'::_highest_explicit_module_version--'.$module;
  if (exists $document->{$cache_key}) { return $document->{$cache_key}; }

  my $aref = $document->find ('PPI::Statement::Include')
    || return; # if no Includes at all
  my @incs = grep {$_->type eq 'use'
                     && (($_->module || '') eq $module)} @$aref;
  if (DEBUG) { local $, = "\n";
               print " all incs",@$aref,'';
               print " matched incs",@incs,''; }
  if (! @incs) { return undef; }

  my @vers = map { _include_module_version_with_exporter($_) } @incs;
  if (DEBUG) { local $,=' / '; print " versions",@vers,"\n"; }
  @vers = grep {defined} @vers;
  if (! @vers) { return 0; }

  @vers = map {version->new($_)} @vers;
  my $maxver = List::Util::reduce {$a >= $b ? $a : $b} @vers;
  return ($document->{$cache_key} = $maxver);
}


# $inc is a PPI::Statement::Include.
#
# If $inc has a version number, either in perl's native form or as a string
# or number as handled by the Exporter package, then return that as a
# version object.
#
sub _include_module_version_with_exporter {
  my ($inc) = @_;

  if (my $ver = Perl::Critic::Pulp::Utils::include_module_version ($inc)) {
    return version->new ($ver->content);
  }

  if (my $ver = Perl::Critic::Pulp::Utils::include_module_first_arg ($inc)) {
    if ($ver->isa('PPI::Token::Number')) {
      $ver = $ver->content;
    } elsif ($ver->isa('PPI::Token::Quote')) {
      $ver = $ver->string;
    } else {
      return undef;
    }
    # Exporter looks only for a leading digit before calling ->VERSION, but
    # be tighter here to avoid errors from version.pm about bad values
    if ($ver =~ $Perl::Critic::Pulp::Utils::use_module_version_number_re) {
      return version->new ($ver);
    }
  }

  return undef;
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::Compatibility::inprogressTestMore - new enough Test::More for its functions

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It checks ...


As always if you don't care about this then you can disable C<inprogressTestMore>
from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Compatibility::inprogressTestMore]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2013, 2015 Kevin Ryde

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

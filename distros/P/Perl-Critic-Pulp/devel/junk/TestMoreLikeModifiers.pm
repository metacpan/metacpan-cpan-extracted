# Copyright 2008, 2009, 2010 Kevin Ryde

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


package Perl::Critic::Policy::Compatibility::TestMoreLikeModifiers;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(:severities parse_arg_list);
use Perl::Critic::Utils::PPIRegexp qw(:all);
use version;

our $VERSION = 0;

use constant DEBUG => 0;


sub supported_parameters { return; }
sub default_severity { return $SEVERITY_MEDIUM;   }
sub default_themes   { return qw(pulp bugs);      }
sub applies_to       { return 'PPI::Token::Word'; }

my $perl_ok_version = version->new('5.10.0');

sub violates {
  my ($self, $elem, $document) = @_;

  my $word = $elem->content;
  $word eq 'Test::More::like'
    || ($word eq 'like' && _document_uses_Test_More($document))
      || return;
  if (DEBUG) { print "word $word\n"; }

  if (my $version = $document->highest_explicit_perl_version) {
    if ($version >= $perl_ok_version) {
      return;  # $document is demanding new enough perl
    }
  }

  my @args_arefs = parse_arg_list ($elem);
  my @re_elems = @{$args_arefs[1]};
  @re_elems = grep {$_->significant} @re_elems;

  @re_elems == 1 || return;
  my $re_elem = $re_elems[0];
  if (DEBUG) { print "re_elem ",ref($re_elem),": $re_elem\n"; }
  my ($subdoc, $ext_elem) = _string_elem_to_regexp ($re_elem);

  $ext_elem->isa('PPI::Token::QuoteLike::Regexp')
    || $ext_elem->isa('PPI::Token::Regexp')
      || return;  # not a regexp (maybe a variable containing a regexp ...)

  my $mhash = $ext_elem->{'modifiers'}
    || return;  # no modifiers
  if (DEBUG) {
    require Data::Dumper;
    print "mhash ",Data::Dumper::Dumper($mhash),"\n";
  }
  my %modifiers = %$mhash;    # copy;
  delete $modifiers{'x'};     # /x is ok
  if (%modifiers) { return; } # no other modifiers is good

  my $modifiers = join ('', sort keys %modifiers);
  return $self->violation
    ("Modifiers /$modifiers don't work with like() until Perl $perl_ok_version",
     '',
     $re_elem);
}

sub _string_elem_to_regexp {
  my ($elem) = @_;

  if ($elem->isa('PPI::Token::Quote')) {
    # literal() from Single, string() from Double
    # the latter is only really an approximation, but is often good enough
    my $str = ($elem->can('literal')
               ? $elem->literal : $elem->string);
    if (DEBUG) { print "sub-parse: $str\n"; }

    # Eg. parses to
    #     PPI::Document
    #         PPI::Statement
    #             PPI::Token::Regexp::Match   '/pattern/i'
    #
    if (my $subdoc = PPI::Document->new (\$str)) {
      my $subelem = $subdoc->schild(0);
      if ($subelem && $subelem->isa('PPI::Statement')) {
        $subelem = $subelem->schild(0);
        if ($subelem->isa('PPI::Token::Regexp::Match')) {
          if (DEBUG) { print " got: ",ref($subelem),": $subelem\n"; }
          return ($subdoc, $subelem);
        }
      }
    }
  }
  # otherwise given elem
  return (undef, $elem);
}


sub _document_uses_Test_More {
  my ($document) = @_;
  my $key = __PACKAGE__ . '--using-Test::More';
  if (exists $document->{$key}) { return $document->{$key}; }

  my $ret = $document->find_any
    (sub {
       my ($document, $elem) = @_;
       return ($elem->isa ('PPI::Statement::Include')
               && $elem ne 'no'
               && (($elem->module || '') eq 'Test::More'));
     });
  if (DEBUG) { print "using Test::More -- ", ($ret?"yes":"no"), "\n"; }
  return ($document->{$key} = $ret);
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::Compatibility::TestMoreLikeModifiers - don't use regexp modifiers with like() tests

=head1 DESCRIPTION

This policy is part of the Perl::Critic::Pulp addon.  It warns about regexp
modifiers like C</i> and C</m> passed to C<like> tests with C<Test::More>,
because such modifiers don't end up propagated to the test until Perl 5.10.
For example,

    use Test::More tests => 1;
    like ('My String', qr/str/i);     # bad
    like ("abc\ndef\n", '/^abc$/m');  # bad

If you've got an explicit C<use 5.010> or similar then you'll only be
running and this check is not applied.

As always if you don't care about C<__END__> you can always disable
C<TestMoreLikeModifiers> from your F<.perlcriticrc> in the usual way,

    [-Compatibility::TestMoreLikeModifiers]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see L<http://www.gnu.org/licenses>.

=cut

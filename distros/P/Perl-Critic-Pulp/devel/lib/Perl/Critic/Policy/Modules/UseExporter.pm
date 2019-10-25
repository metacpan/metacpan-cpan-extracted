# Copyright 2015, 2016, 2017 Kevin Ryde

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


# Or any @ISA should have a use ?


package Perl::Critic::Policy::Modules::UseExporter;
use 5.006;
use strict;
use warnings;
use Scalar::Util;
use Perl::Critic::Policy::Modules::ProhibitPOSIXimport;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(is_function_call
                           split_nodes_on_comma);
use Perl::Critic::Utils::PPI qw(is_ppi_expression_or_generic_statement);
use Perl::Critic::Pulp::Utils;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 97;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes       => qw(pulp bugs);
use constant applies_to           => ('PPI::Token::Symbol');

my %Exporter_symbols = ('@EXPORT'      => 1,
                        '@EXPORT_OK'   => 1,
                        '%EXPORT_TAGS' => 1,
                       );

sub violates {
  my ($self, $elem, $document) = @_;

  $Exporter_symbols{$elem->symbol} || return;
  return if _document_has_use_Exporter ($document, 'Exporter');

  return $self->violation
    ("\@EXPORT etc without \"use Exporter\"",
     '',
     $elem);
}

# return true if $document has require Exporter, use Exporter,
# use base 'Exporter', etc
sub _document_has_use_Exporter {
  my ($document) = @_;

  my $aref = $document->find ('PPI::Statement::Include');
  foreach my $elem (@$aref) {
    ### elem: "$elem"
    next if $elem->type eq 'no';
    my $module = $elem->module || next;
    if ($module eq 'Exporter') {
      ### yes, use or require Exporter ...
      return 1;
    }

    if ($module eq 'base' || $module eq 'parent') {
      my $child = $elem->schild(2) // next;
      ### $child
      my @args = Perl::Critic::Policy::Modules::ProhibitPOSIXimport::_elem_and_snext_siblings($child);
      ### @args
      @args = Perl::Critic::Policy::Modules::ProhibitPOSIXimport::_parse_args(@args);
      foreach my $arg (@args) {
        _arg_strip_semis($arg);
        @$arg == 1 or next;
        my $a = $arg->[0];
        ### $a
        if ($a->isa('PPI::Token::Quote')
            && $arg->[0]->string eq 'Exporter') {
          ### yes, quoted string ...
          return 1;
        }
        if ($a->isa('PPI::Token::QuoteLike::Words')
            && grep {$_ eq 'Exporter'} $a->literal) {
          ### yes, quoted words ...
          return 1;
        }
      }
    }
  }
  return 0;
}

# $arg is an arrayref of PPI elements
sub _arg_strip_semis {
  my ($arg) = @_;
  while (@$arg && _elem_is_semicolon($arg->[-1])) {
    pop @$arg;
  }
}

sub _elem_is_semicolon {
  my ($elem) = @_;
  return $elem->isa('PPI::Token::Structure') && $elem eq ';';
}

1;
__END__

=for stopwords Ryde

=head1 NAME

Perl::Critic::Policy::Modules::UseExporter - check for "use Exporter" when applicable

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It checks that if you set an C<@EXPORT> etc then you have a C<use
Exporter>.

    package Foo;
    @ISA = ('Exporter');
    @EXPORT = ('foo');         # bad, missing use Exporter

=head2 Disabling

If you don't care this sort of thing you can always disable
C<UseExporter> from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Modules::UseExporter]

=head1 SEE ALSO

L<POSIX>,
L<Perl::Critic::Pulp>,
L<Perl::Critic>,

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2015, 2016, 2017 Kevin Ryde

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

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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


# maybe allow comma for
# =head1 Foo
# And something,
# =head2 Item

# perlcritic -s ProhibitParagraphEndComma ProhibitParagraphEndComma.pm
# perlcritic -s ProhibitParagraphEndComma /usr/share/perl5/IO/Socket/INET6.pm
# perlcritic -s ProhibitParagraphEndComma /usr/share/perl5/MIME/Body.pm /usr/share/perl5/XML/Twig.pm


package Perl::Critic::Policy::Documentation::ProhibitParagraphEndComma;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 93;


use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOWEST;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### ProhibitParagraphEndComma on: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::ProhibitParagraphEndComma->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  $parser->check_last;
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::ProhibitParagraphEndComma;
use strict;
use warnings;
use base 'Perl::Critic::Pulp::PodParser';

sub new {
  my $class = shift;
  ### new() ...
  return $class->SUPER::new (last_text => '',
                             last_command => '',
                             @_);
}
sub command {
  my ($self, $command, $text, $linenum, $paraobj) = @_;
  ### command(): $command

  # "=begin :foo" means pod markup continues.  Ignore the =begin and
  # continue processing POD within it.  Any other begin is a new block
  # something and preceding comma not allowed.
  #
  if ($command eq 'for'
      || $command eq 'pod'
      || ($command eq 'begin' && $text =~ /^\s*:/)
      || $command eq 'end') {
    return;  # ignore these completely
  }

  if ($command eq 'item' && $self->{'last_command'} eq 'item') {
    # Paragraphs in =item list can end in successive commas.

  } elsif ($command eq 'over') {

  } else {
    $self->check_last;
  }
  $self->{'last_text'} = '';
  $self->{'last_command'} = $command;
}
sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### textblock(): $text
  $self->check_last;
  # sometimes $text=undef from Pod::Parser
  if (! defined $text) { $text = ''; }
  $self->{'last_linenum'} = $linenum;
  $self->{'last_text'} = $text;
}
sub verbatim {
  my ($self, $text, $linenum, $paraobj) = @_;
  # anything before a verbatim is ok
  $self->{'last_text'} = '';
}

sub check_last {
  my ($self) = @_;
  ### check_last() ...
  ### in_begin: $self->{'in_begin'}

  if ($self->{'in_begin'} && $self->{'in_begin'} !~ /^:/) {
    # =begin block of non-: means not pod markup

  } elsif ($self->{'last_text'} =~ /(,\s*)$/s) {
    ### last_text ends comma ...
    my $pos = length($self->{'last_text'}) - length($1); # position of comma
    $self->violation_at_linenum_and_textpos
      ("Paragraph ends with comma",
       $self->{'last_linenum'}, $self->{'last_text'}, $pos);
  }
  $self->{'last_text'} = '';
}

1;
__END__

=for stopwords Ryde

=head1 NAME

Perl::Critic::Policy::Documentation::ProhibitParagraphEndComma - avoid comma at end of section

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It asks you not to end a POD paragraph with a comma.

    Some text,       # bad, meant to be a full-stop?

    Some more text.

Usually such a comma is meant to be a full-stop, or perhaps omitted at the
end of a "SEE ALSO" list

=for ProhibitVerbatimMarkup allow next 2

    =head1 SEE ALSO

    L<Foo>,
    L<Bar>,          # bad, meant to be omitted?

A paragraph before an C<=over> or a verbatim block is allowed to end with a
comma, that being taken as introducing a quotation or example,

    For example,     # ok, introduce an example

        foo(1+2+3)

    Or one of,       # ok, introduce an itemized list

    =over

    =item Foo

=head2 Disabling

If you don't care about this you can disable C<ProhibitParagraphEndComma>
from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-Documentation::ProhibitParagraphEndComma]

=head1 SEE ALSO

L<Perl::Critic::Pulp>, L<Perl::Critic>

L<Perl::Critic::Policy::Documentation::ProhibitParagraphTwoDots>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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

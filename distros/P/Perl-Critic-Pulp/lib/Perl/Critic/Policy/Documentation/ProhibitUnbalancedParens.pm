# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

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


# perlcritic -s ProhibitUnbalancedParens ProhibitUnbalancedParens.pm

# unclosed:
#  perlcritic -s ProhibitUnbalancedParens /usr/share/perl/5.12/CGI.pm

# smiley close:
#  perlcritic -s ProhibitUnbalancedParens /usr/share/perl5/accessors.pm


package Perl::Critic::Policy::Documentation::ProhibitUnbalancedParens;
use 5.006;
use strict;
use warnings;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 99;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_LOW;
use constant default_themes       => qw(pulp cosmetic);
use constant applies_to           => 'PPI::Document';

sub violates {
  my ($self, $elem, $document) = @_;
  ### ProhibitUnbalancedParens on: $elem->content

  my $parser = Perl::Critic::Pulp::PodParser::ProhibitUnbalancedParens->new
    (policy => $self);
  $parser->parse_from_elem ($elem);
  return $parser->violations;
}

package Perl::Critic::Pulp::PodParser::ProhibitUnbalancedParens;
use strict;
use warnings;
use Pod::ParseLink;
use base 'Perl::Critic::Pulp::PodParser';

sub command {
  my $self = shift;
  my ($command, $text, $linenum, $paraobj) = @_;
  $self->SUPER::command(@_);  # maintain 'in_begin'

  if ($command eq 'for'
      && $text =~ /^ProhibitUnbalancedParens\b\s*(.*)/) {
    my $directive = $1;
    ### $directive
    if ($directive =~ /^allow next( (\d+))?/) {
      # numbered "allow next 5" means up to that many following
      # unnumbered "allow next" means one following
      $self->{'allow_next'} = (defined $2 ? $2 : 1);
    }
  }
  return $self->command_as_textblock(@_);
}

my %open_to_close = ('(' => ')',
                     '[' => ']',
                     '{' => '}');
my %close_to_open = reverse %open_to_close;

sub textblock {
  my ($self, $text, $linenum, $paraobj) = @_;
  ### textblock: "linenum=$linenum"

  if (($self->{'allow_next'}||0) > 0) {
    $self->{'allow_next'}--;
    return '';
  }

  # process outside =begin, and inside =begin which is ":" markup
  unless ($self->{'in_begin'} eq '' || $self->{'in_begin'} =~ /^:/) {
    return '';
  }

  my $interpolated = $self->interpolate($text, $linenum);
  ### $text
  ### $interpolated

  my @parens;
  while ($interpolated
         =~ m/
               ([][({})])       # $1 open or close
             |([:;]-?\)         # $2 smiley face optional close
               |\b[a-zA-Z1-9]\) #    "middle a) or 1) item"
               |(?<!\$)\$\)     #    perlvar $), and not $$
               )
             |(["'])[][(){}]+\3 # $3 "(" quoted
             |[:;]-?[(]         # smiley face not an open
             |(?<!\$)\$\$       # perlvar $$ consumed
             |\$\(\w*\)         # makefile var $(abc)
             |\$\[\w*\]         # perhaps template $[abc]
             |(?<!\$)\$[][(]    # perlvars $[, $(, $], and not $$
             |^\s*(\d+|[A-Za-z])\.?\)   # initial "1.5) something"
             /xg) {
    ### match: $&
    ### $1
    ### $2
    ### $3
    if (defined $1) {
      push @parens, { char => $1,
                      pos  => pos($interpolated)-1,
                    };

    } elsif (defined $2) {
      push @parens, { char => ')',
                      pos => pos($interpolated)-1,
                      optional => 1,
                    };
    }
  }
  ### @parens

  # sort optional closes to after hard closes
  {
    my @optional;
    my @new;
    foreach my $p (@parens) {
      if (@optional && $optional[0]->{'char'} ne $p->{'char'}) {
        push @new, splice @optional;
      }
      if ($p->{'optional'}) {
        push @optional, $p;
      } else {
        push @new, $p;
      }
    }
    @parens = (@new, @optional);
  }
  ### sorted: @parens

  my @opens;
  foreach my $p (@parens) {
    ### $p
    my $char = $p->{'char'};
    if (my $want_openchar = $close_to_open{$char}) {
      # a close
      if (my $o = pop @opens) {
        my $openchar = $o->{'char'};
        if ($openchar ne $want_openchar) {
          if ($p->{'optional'}) {
            ### mismatched optional close, skip
            push @opens, $o;
            next;
          }
          $self->violation_at_linenum_and_textpos
            ("Mismatched closing paren \"$char\" expected \"$open_to_close{$openchar}\"",
             $linenum, $interpolated, $p->{'pos'});
        }

      } else {
        if ($p->{'optional'}) {
          ### unopened optional close, skip
          next;
        }
        $self->violation_at_linenum_and_textpos
          ("Unopened close paren \"$char\"",
           $linenum, $interpolated, $p->{'pos'});
      }

    } else {
      # an open
      push @opens, $p;
    }
  }
  foreach my $p (@opens) {
    $self->violation_at_linenum_and_textpos
      ("Unclosed paren \"$p->{'char'}\"",
       $linenum, $interpolated, $p->{'pos'});
  }
  return '';
}

*interior_sequence = \&interior_sequence_as_displayed_noncode_text;

sub interior_sequence_as_displayed_noncode_text {
  my ($self, $cmd, $text, $pod_seq) = @_;

  if ($cmd eq 'X' || $cmd eq 'C') {
    ### $cmd
    ### X,C keep only the newlines: $text
    $text =~ tr/\n//cd;

  } elsif ($cmd eq 'L') {
    my ($display, $inferred, $name, $section, $type)
      = Pod::ParseLink::parselink ($text);
    ### $text
    ### $display
    ### $inferred
    ### $name
    return $inferred;  # the display part, or the name part if no display
  }
  return $text;
}

1;
__END__

=for stopwords Ryde paren parens ie deref there'd backslashing Parens

=head1 NAME

Perl::Critic::Policy::Documentation::ProhibitUnbalancedParens - don't leave an open bracket or paren

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It reports unbalanced or mismatched parentheses, brackets and braces
in POD text paragraphs,

    Blah blah (and something.    # bad

    Blah blah ( [ ).             # bad

    Blah blah brace }.           # bad

This is only cosmetic and normally only a minor irritant to readability so
this policy is low severity and under the "cosmetic" theme (see
L<Perl::Critic/POLICY THEMES>).

Text and command paragraphs are checked, but verbatim paragraphs can have
anything.  There are some exceptions to paren balancing.  The intention is
to be forgiving of common or reasonable constructs.  Currently this means,

=over

=item *

Anything in C<CE<lt>E<gt>> code markup is ignored

=for ProhibitVerbatimMarkup allow next

    In code C<anything [ is allowed>.  # ok

Perhaps this will change, though there'd have to be extra exceptions in
C<CE<lt>E<gt>>, such as various backslashing.

Sometimes a prematurely ending C<CE<lt>E<gt>> may look like an unbalanced
paren, for example

=for ProhibitVerbatimMarkup allow next

    Call C<foo(key=>value)> ...    # bad

=for ProhibitUnbalancedParens allow next

This is bad because the C<CE<lt>E<gt>> ends at the C<=E<gt>>, leaving
"value)" unbalanced plain text.  This is an easy mistake to make.  (The
author's C<perl-pod-gt.el> can show warning face on this in Emacs.)

=item *

Quoted "(" is taken to be describing the char and is not an open or close.

    Any of "(" or '[' or "[{]".   # ok

This only applies to quoted parens alone (one or more), not larger quoted
text.

=item *

Item parens

    a) the first thing, or b) the second thing   # ok

    1) one, 2) two     # ok

Exactly how much is recognised as an "a)" etc is not quite settled.  In the
current code a "1.5)" is recognised at the start of a paragraph, but in the
middle only "1)" style.

=item *

Smiley faces are an "optional" close,

    (Some thing :-).                # ok

    Bare smiley :).                 # ok

    (Or smile :-) and also close.)  # ok

=item *

Sad smiley faces are not an opening paren,

    :( :-(.     # ok

=item *

Perl variables C<$(> and C<$[> are not opening parens,

    Default is group $( blah blah.  # ok

C<${> brace is still an open and expected to have a matching close, because
it's likely to be a deref or delimiter,

    Deref with ${foo()} etc etc.

Variables or expressions like this will often be in C<CE<lt>E<gt>> markup
and skipped for that reason instead, as described above.

=item *

C<$)> and C<$]> are optional closes, since they might be Perl variables to
skip, or might be "$" at the end of a parens,

   blah blah (which in TeX is $1\cdot2$).

Perhaps the conditions for these will be restricted a bit, though again
C<CE<lt>E<gt>> markup around sample code like this will be usual.

=item *

C<LE<lt>display|linkE<gt>> links are processed as the "display" text part.
The link target (POD document name and section) can have anything.

=back

C<=begin :foo> ... C<=end :foo> sections with a format name ":foo" starting
with a ":" are POD markup and are processed accordingly.  Other C<=begin>
sections are skipped.

=head2 Unrecognised Forms

A mathematical half-open range like the following is not recognised.

    [1,2)             # bad, currently

Perhaps just numbers like this would be unambiguous, but if it's an
expression then it's hard to distinguish a parens typo from some
mathematics.  The suggestion for now is an C<=for> per below to flag it as
an exception.  Another way would be to write S<1 E<lt>= X E<lt> 2>, which
might be clearer to mathematically unsophisticated readers.

Parens spanning multiple paragraphs are not recognised,

    (This is some     # bad

    thing.)           # bad

Hopefully this is uncommon, and probably better style not to be
parenthetical about something so big that it runs to multiple paragraphs or
has a verbatim block in the middle etc.

=head2 Disabling

If an unbalanced paren is intended you can add an C<=for> to tell
C<ProhibitUnbalancedParens> to allow it.

    =for ProhibitUnbalancedParens allow next

    Something ( deliberately unclosed.

Or with a count of paragraphs to ignore,

    =for ProhibitUnbalancedParens allow next 2

    First deliberate [ unclosed.

    Second (.

The usual no critic

    ## no critic (ProhibitUnbalancedParens)

works too as a whole-file disable, but the annotation must be before any
C<__END__> token, and if the POD is after the C<__END__> then
C<Perl::Critic> 1.112 up is required.  Individual C<=for> has the advantage
of being with an exception.

As always if you don't care about this at all you can disable
C<ProhibitUnbalancedParens> completely from your F<.perlcriticrc> in
the usual way (see L<Perl::Critic/CONFIGURATION>),

    [-Documentation::ProhibitUnbalancedParens]

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

L<http://user42.tuxfamily.org/perl-pod-gt/index.html>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

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

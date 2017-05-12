# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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


package Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash;
use 5.006;
use strict;
use warnings;

# 1.084 for Perl::Critic::Document highest_explicit_perl_version()
use Perl::Critic::Policy 1.084;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils;

use Perl::Critic::Pulp;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 93;

use constant DEBUG => 0;


use constant supported_parameters =>
  ({ name           => 'single',
     description    => 'Checking of single-quote strings.',
     behavior       => 'string',
     default_string => 'none',
   },
   { name           => 'double',
     description    => 'Checking of double-quote strings.',
     behavior       => 'string',
     default_string => 'all',
   },
   { name           => 'heredoc',
     description    => 'Checking of interpolated here-documents.',
     behavior       => 'string',
     default_string => 'all',
   });
use constant default_severity => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes   => qw(pulp cosmetic);

sub applies_to {
  my ($policy) = @_;
  return (($policy->{'_single'} ne 'none'
           ? ('PPI::Token::Quote::Single',    # ''
              'PPI::Token::Quote::Literal')   # q{}
           : ()),

          ($policy->{'_single'} ne 'none'
           || $policy->{'_double'} ne 'none'
           ? ('PPI::Token::QuoteLike::Command')  # qx{} or qx''
           : ()),

          ($policy->{'_double'} ne 'none'
           ? ('PPI::Token::Quote::Double',       # ""
              'PPI::Token::Quote::Interpolate',  # qq{}
              'PPI::Token::QuoteLike::Backtick') # ``
           : ()),

          ($policy->{'_heredoc'} ne 'none'
           ? ('PPI::Token::HereDoc')
           : ()));
}

# for violation messages
my %charname = ("\n" => '{newline}',
                "\r" => '{cr}',
                "\t" => '{tab}',
                " "  => '{space}');

use constant _KNOWN => (
                        't'      # \t   tab
                        . 'n'    # \n   newline
                        . 'r'    # \r   carriage return
                        . 'f'    # \f   form feed
                        . 'b'    # \b   backspace
                        . 'a'    # \a   bell
                        . 'e'    # \e   esc
                        . '0123' # \377 octal
                        . 'x'    # \xFF \x{FF} hex
                        . 'c'    # \cX  control char

                        . 'l'    # \l   lowercase one char
                        . 'u'    # \u   uppercase one char
                        . 'L'    # \L   lowercase string
                        . 'U'    # \U   uppercase string
                        . 'E'    # \E   end case or quote
                        . 'Q'    # \Q   quotemeta
                        . '$'    # non-interpolation
                        . '@'    # non-interpolation
                       );

use constant _CONTROL_KNOWN =>
  '?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_abcdefghijklmnopqrstuvwxyz'; ## no critic (RequireInterpolationOfMetachars)

my $quotelike_re = qr/^(?:(q[qrwx]?)  # $1 "q" if present
                    (?:(?:\s(?:\s*\#[^\n]*\n)*)\s*)?  # possible comments
                  )?    # possible "q"
                  (.)   # $2 opening quote
                  (.*)  # $3 guts
                  (.)$  # $4 closing quote
                 /xs;

# extra explanation for double-quote interpolations
my %explain = ('%' => '  (hashes are not interpolated)',
               '&' => '  (function calls are not interpolated)',
               '4' => '  (until Perl 5.6 octal wide chars)',
               '5' => '  (until Perl 5.6 octal wide chars)',
               '6' => '  (until Perl 5.6 octal wide chars)',
               '7' => '  (until Perl 5.6 octal wide chars)',
               'N' => '  (without "use charnames" in scope)',
              );

sub violates {
  my ($self, $elem, $document) = @_;

  my $content = $elem->content;
  my $close = substr ($content, -1, 1);
  my $single = 0;
  my ($param, $str);

  if ($elem->isa('PPI::Token::HereDoc')) {
    return if ($close eq "'"); # uninterpolated
    $param = $self->{_heredoc};
    $str = join ('', $elem->heredoc);

  } else {
    if ($elem->can('string')) {
      $str = $elem->string;
    } else {
      $elem =~ $quotelike_re or die "Oops, didn't match quotelike_re";
      $str = $3;
    }
    $str =~ s{((^|\G|[^\\])(\\\\)*)\\\Q$close}{$close}sg;

    if ($elem->isa('PPI::Token::Quote::Single')
        || $elem->isa('PPI::Token::Quote::Literal')
        || ($elem->isa('PPI::Token::QuoteLike::Command')
            && $close eq "'")) {
      $single = 1;
      $param = $self->{_single};

    } else {
      $param = $self->{_double};
    }
  }
  return if ($param eq 'none');

  my $known = $close;

  if (! $single) {
    $known .= _KNOWN;

    # Octal chars above \377 are in 5.6 up.
    # Consider known if no "use 5.x" at all, or if present and 5.6 up,
    # so only under explicit "use 5.005" or lower are they not allowed.
    my $perlver = $document->highest_explicit_perl_version;
    if (! defined $perlver || $perlver >= 5.006) {
      $known .= '4567';
    }
  }

  ### elem: ref $elem
  ### $content
  ### $str
  ### close char: $close
  ### $known
  ### perlver: $document->highest_explicit_perl_version

  my $have_charnames;
  my $interpolate_var_end = -1;
  my $interpolate_var_colon;
  my @violations;

  while ($str =~ /(\$.                     # $ not at end-of-string
                  |\@[[:alnum:]:'\{\$+-])  # @ forms per toke.c S_scan_const()
                |(\\+)   # $2 run of backslashes
                 /sgx) {
    if (defined $1) {
      # $ or @
      unless ($single) {  # no variables in single-quote
        ### interpolation at: pos($str)
        pos($str) = _pos_after_interpolate_variable ($str,
                                                     pos($str) - length($1));
        ### ends at: pos($str)
        if (substr($str,pos($str)-1,1) =~ /(\w)|[]}]/) {
          $interpolate_var_colon = $1;
          $interpolate_var_end = pos($str);
          ### interpolate_var_end set to: $interpolate_var_end
        }
      }
      next;
    }

    if ((length($2) & 1) == 0) {
      # even number of backslashes, not an escape
      next;
    }

    # shouldn't have \ as the last char in $str, but if that happends then
    # $c is empty string ''

    my $c = substr($str,pos($str),1);
    pos($str)++;

    if (! $single) {
      if ($c eq 'N') {
        if (! defined $have_charnames) {
          $have_charnames = _charnames_in_scope($elem);
        }
        if ($have_charnames) {
          next;
        }

      } elsif ($c eq 'c') {
        # \cX control char.
        # If \c is at end-of-string then new $c is '' and pos() will goes past
        # length($str).  That pos() is ok, the loop regexp gives no-match and
        # terminates.
        $c = substr ($str, pos($str)++, 1);
        if ($c eq '') {
          push @violations,
            $self->violation ('Control char \\c at end of string', '', $elem);
          next;
        }
        if (index (_CONTROL_KNOWN, $c) >= 0) {
          next;  # a known escape
        }
        push @violations,
          $self->violation ('Unknown control char \\c' . _printable($c),
                            '', $elem);
        next;

      } elsif ($c eq ':') {
        if ($interpolate_var_colon) {
          ### backslash colon, pos: pos($str)
          ### $interpolate_var_end
          ### substr: substr ($str, $interpolate_var_end, 2)
          if (pos($str) == $interpolate_var_end+2
              || (pos($str) == $interpolate_var_end+4
                  && substr ($str, $interpolate_var_end, 2) eq '\\:')) {
            next;
          }
        }

      } elsif ($c eq '[' || $c eq '{') {
        ### backslash bracket, pos: pos($str)
        ### $interpolate_var_end
        if (pos($str) == $interpolate_var_end+2) {
          next;
        }

      } elsif ($c eq '-') {
        ### backslash dash: pos($str)
        if ($str =~ /\G>[[{]/) {
          ### is for bracket or brace, pos now: pos($str)
          next;
        }
      }
    }

    if ($param eq 'quotemeta') {
      # only report on chars quotemeta leaves unchanged
      next if $c ne quotemeta($c);
    } elsif ($param eq 'alnum') {
      # only report unknown alphanumerics, like perl does
      # believe perl only reports ascii alnums as bad, wide char alphas ok
      next if $c !~ /[a-zA-Z0-9]/;
    }

    # if $c eq '' for end-of-string then index() returns 0, for no violation
    if (index ($known, $c) >= 0) {
      # a known escape
      next;
    }

    my $explain = !$single && ($explain{$c} || '');
    my $message = ('Unknown or unnecessary backslash \\'._printable($c)
                   . $explain);
    push @violations, $self->violation ($message, '', $elem);

    # would have to take into account HereDoc begins on next line ...
    # _violation_elem_offset ($violation, $elem, pos($str)-2);
  }
  return @violations;
}

# $pos is a position within $str of a "$" or "@" interpolation
# return the position within $str after that variable or expression
#
sub _pos_after_interpolate_variable {
  my ($str, $pos) = @_;
  $str = substr ($str, $pos);
  ### _pos_after_interpolate_variable
  ### $str

  require PPI::Document;
  my $doc = PPI::Document->new(\$str);
  my $elem = $doc->child(0)->child(0);
  if (DEBUG) {
    print "  elem @{[ref $elem]} '$elem' len @{[length $elem->content]}\n";
  }
  $pos += length($elem->content);

  if ($elem->isa('PPI::Token::Cast')) {
    # get the PPI::Structure::Block following "$" or "@", can have
    # whitespace before it too
    while ($elem = $elem->next_sibling) {
      if (DEBUG) { print "  and '$elem' @{[length $elem->content]}\n"; }
      $pos += length($elem->content);
      last if $elem->isa('PPI::Structure::Block');
    }

  } elsif ($elem->isa('PPI::Token::Symbol')) {
    # any subscripts 'PPI::Structure::Subscript' following, like "$hash{...}"
    # whitespace stops the subscripts, so that Struct alone
    for (;;) {
      $elem = $elem->next_sibling || last;
      $elem->isa('PPI::Structure::Subscript') || last;
      if (DEBUG) { print "  and '$elem' @{[length $elem->content]}\n"; }
      $pos += length($elem->content);
    }
  }

  return $pos;
}

# use Perl::Critic::Policy::Compatibility::PodMinimumVersion;
sub _violation_elem_offset {
  my ($violation, $elem, $offset) = @_;
  return $violation;

  #
  #   my $pre = substr ($elem->content, 0, $offset);
  #   my $newlines = ($pre =~ tr/\n//);
  #
  #   my $document = $elem->document;
  #   my $doc_str = $document->content;
  #
  #   return Perl::Critic::Pulp::Utils::_violation_override_linenum ($violation, $doc_str, $newlines - 1);
}

sub _printable {
  my ($c) = @_;
  $c =~ s{([^[:graph:]]|[^[:ascii:]])}
         { $charname{$1} || sprintf('{0x%X}',ord($1)) }e;
  return $c;
}

# return true if $elem has a 'use charnames' in its lexical scope
sub _charnames_in_scope {
  my ($elem) = @_;
  for (;;) {
    $elem = $elem->sprevious_sibling || $elem->parent
      || return 0;
    if ($elem->isa ('PPI::Statement::Include')
        && $elem->type eq 'use'
        && ($elem->module || '') eq 'charnames') {
      return 1;
    }
  }
}


#-----------------------------------------------------------------------------
# unused bits

# # $elem is a PPI::Token::Quote, PPI::Token::QuoteLike or PPI::Token::HereDoc
# sub _string {
#   my ($elem) = @_;
#   if ($elem->can('heredoc')) {
#     return join ('', $elem->heredoc);
#   }
#   if ($elem->can('string')) {
#     return $elem->string;
#   }
#   $elem =~ $quotelike_re
#     or die "Oops, didn't match quote_re";
#   return $3;
# }

# # $elem is a PPI::Token::Quote or PPI::Token::QuoteLike
# # return ($q, $open, $close) where $q is the "q" intro or empty string if
# # none, and $open and $close are the quote chars
# sub _quote_delims {
#   my ($elem) = @_;
#   if ($elem->can('heredoc')) {
#     return '"', '"';
#   }
#   $elem =~ $quotelike_re
#     or die "Oops, didn't match quote_re";
#   return ($1||'', $2, $4);
# }

# perlop "Quote and Quote-like Operators"
#   my $known = '';
#   if ($elem->isa ('PPI::Token::Quote::Double')
#       || $elem->isa ('PPI::Token::Quote::Interpolate')
#       || $elem->isa ('PPI::Token::QuoteLike::Backtick')
#       || ($elem->isa ('PPI::Token::QuoteLike::Command')
#           && $close ne '\'') # no interpolation in qx'echo hi'
#      ) {
#     $known = 'tnrfbae0123xcluLUQE$@';
#
#     # \N and octals bigger than 8-bits are in 5.6 up, and allow them if no
#     # "use 5.x" at all too
#     my $perlver = $document->highest_explicit_perl_version;
#     if (! defined $perlver || $perlver >= 5.006) {
#       $known .= 'N456789';
#     }
#   }
#   $known .= $close;
#
# my $re = qr/\\+[^\\$known$close]/;
#   my $unknown = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
#   $unknown =~ s{(.)}
#                {index($known,$1) >= 0 ? '' : $1}eg;

1;
__END__

=for stopwords backslashed upcase FS unicode ascii non-ascii ok alnum quotemeta backslashing backticks Ryde coderef alphanumerics arrowed

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash - don't use undefined backslash forms

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It checks for unknown backslash escapes like

    print "\*.c";      # bad

This is harmless, assuming the intention is a literal "*" (which it gives),
but unnecessary, and on that basis this policy is under the C<cosmetic>
theme (see L<Perl::Critic/POLICY THEMES>).  Sometimes it can be a
misunderstanding or a typo though, for instance a backslashed newline is a
newline, but perhaps you thought it meant a continuation.

    print "this\       # bad
    is a newline";

Perl already warns about unknown escaped alphanumerics like C<\v> under
C<perl -w> or C<use warnings> (see L<perldiag/Unrecognized escape \%c passed
through>).

    print "\v";        # bad, and provokes Perl warning

This policy extends to report on any unknown escape, with options below to
vary the strictness and to check single-quote strings too if desired.

=head2 Control Characters \c

Control characters C<\cX> are checked and only the conventional A-Z a-z @ [
\ ] ^ _ ? are considered known.

    print "\c*";       # bad

Perl accepts any C<\c> and does an upcase xor 0x40, so C<\c*> is letter "j",
at least on an ASCII system.  But that's obscure and likely to be a typo or
error.

For reference, C<\c\> is the ASCII FS "file separator" and the second
backslash is not an escape, except for a closing quote character, which it
does escape (basically because Perl scans for a closing quote before
considering interpolations).  Thus,

    print " \c\  ";     # ok, control-\ FS
    print " \c\" ";     # bad, control-" is unknown
    print qq[ \c\]  ];  # ok, control-] GS

=head2 Ending Interpolation

A backslashed colon, bracket, brace or dash is allowed after an interpolated
variable or element to stop interpolation at that point.

    print "$foo\::bar";    # ok, $foo
    print "@foo\::";       # ok, @foo

    print "$foo[0]\[1]";   # ok, is $foo[0]
    print "$esc\[1m";      # ok

    print "$foo\{k}";      # ok
    print "$foo\{k}";      # ok
    print "$foo{k}\[0]";   # ok, is $foo{k}
    print "@foo\{1,2}";    # ok, is @foo

    print "$foo\->[0]";    # ok, is $foo
    print "$foo\->{zz}";   # ok

A single backslash like C<"\::"> is enough for the colon case, but
backslashing the second too as C<"\:\:"> is quite common and is allowed.

    print "$#foo\:\:bar";  # ok

Only a C<-E<gt>[]> or C<-E<gt>{}> needs a C<\-> to stop interpolation.
Other cases such as an apparent method call or arrowed coderef call don't
interpolate and the backslash is treated as unknown since unnecessary.

    print "$coderef\->(123)";        # bad, unnecessary
    print "Usage: $class\->foo()";   # bad, unnecessary

For reference, the alternative in all the above is to write C<{}> braces
around the variable or element to delimit from anything following.  Doing so
may be clearer than backslashing,

    print "${foo}::bar";    # alternatives
    print "@{foo}::bar";
    print "$#{foo}th";
    print "${foo[0]}[1]";   # array element $foo[0]

The full horror story of backslashing interpolations can be found in
L<perlop/Gory details of parsing quoted constructs>.

=head2 Octal Wide Chars

Octal escapes above C<\400> to C<\777> for wide chars 256 to 511 are new in
Perl 5.6.  They're considered unknown in 5.005 and earlier (where they end
up chopped to 8-bits 0 to 255).  Currently if there's no C<use> etc Perl
version then it's presumed a high octal is intentional and is allowed.

    print "\400";    # ok

    use 5.006;
    print "\777";    # ok

    use 5.005;
    print "\777";    # bad in 5.005 and earlier


=head2 Named Chars

Named chars C<\N{SOME THING}> are added by L<charnames> (new in Perl 5.6)
and are treated as known if there's a C<use charnames> in the lexical scope.

    {
      use charnames ':full';
      print "\N{APOSTROPHE}";  # ok
    }
    print "\N{COLON}";         # bad without charnames

A C<\N> without C<charnames> is a compile error in Perl 5.6 or higher so is
normally seen immediately anyway.

=head2 Other Notes

In the violation messages a non-ascii or non-graphical escaped char is shown
as hex like C<\{0x263A}>, to ensure the message is printable and
unambiguous.

Interpolated C<$foo> or C<@{expr}> variables and expressions are parsed like
Perl does, so backslashes for refs within are ok, in particular tricks like
C<${\scalar ...}> are fine (see L<perlfaq4/How do I expand function calls in
a string?>).

    print "this ${\(some()+thing())}";   # ok

=head2 Disabling

As always, if you're not interested in any of this then you can disable
C<ProhibitUnknownBackslash> from your F<.perlcriticrc> in the usual way (see
L<Perl::Critic/CONFIGURATION>),

    [-ValuesAndExpressions::ProhibitUnknownBackslash]

=head1 CONFIGURATION

=over 4

=item C<double> (string, default "all")

=item C<heredoc> (string, default "all")

C<double> applies to double-quote strings C<"">, C<qq{}>, C<qx{}>, etc.
C<heredoc> applies to interpolated here-documents C<E<lt>E<lt>HERE> etc.
The possible values are

    none       don't report anything
    alnum      report unknown alphanumerics, like Perl's warning
    quotemeta  report anything quotemeta() doesn't escape
    all        report all unknowns

"alnum" does no more than compiling with C<perl -w>, but might be good for
checking code you don't want to run.

"quotemeta" reports escapes not produced by C<quotemeta()>.  For example
C<quotemeta> escapes a C<*>, so C<\*> is not reported, but it doesn't escape
an underscore C<_>, so C<\_> is reported.  The effect is to prohibit a few
more escapes than "alnum".  One use is to check code generated by other code
where you've used C<quotemeta> to produce double-quoted strings and thus may
have escaping which is unnecessary but works fine.

=item C<single> (string, default "none")

C<single> applies to single-quote strings C<''>, C<q{}>, C<qx''>, etc.  The
possible values are as above, though only "all" or "none" make much sense.

    none       don't report anything
    all        report all unknowns

The default is "none" because literal backslashes in single-quotes are
usually both what you want and quite convenient.  Setting "all" effectively
means you must write backslashes as C<\\>.

    print 'c:\my\msdos\filename';     # bad under "single=all"
    print 'c:\\my\\msdos\\filename';  # ok

Doubled backslashing like this is correct, and can emphasize that you really
did want a backslash, but it's tedious and not easy on the eye and so is
left only as an option.

For reference, single-quote here-documents C<E<lt>E<lt>'HERE'> don't have
any backslash escapes and so are not considered by this policy.  C<qx{}>
command backticks are double-quote but as C<qx''> is single-quote and in
each case treated under the corresponding single/double option.

=back

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>

L<perlop/Quote and Quote-like Operators>

=head1 HOME PAGE

http://user42.tuxfamily.org/perl-critic-pulp/index.html

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

Perl-Critic-Pulp is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Perl-Critic-Pulp is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses>.

=cut

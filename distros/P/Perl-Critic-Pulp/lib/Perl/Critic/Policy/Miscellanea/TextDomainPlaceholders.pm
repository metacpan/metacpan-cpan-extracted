# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

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


package Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders;
use 5.006;
use strict;
use warnings;

use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw(is_function_call
                           parse_arg_list
                           interpolate);

# uncomment this to run the ### lines
# use Smart::Comments;

our $VERSION = 99;

use constant supported_parameters => ();
use constant default_severity     => $Perl::Critic::Utils::SEVERITY_MEDIUM;
use constant default_themes       => qw(pulp bugs);
use constant applies_to           => 'PPI::Token::Word';

my %funcs = (__x   => 1,
             __nx  => 1,
             __xn  => 1,

             __px  => 1,
             __npx => 1);

sub violates {
  my ($self, $elem, $document) = @_;

  my $funcname = $elem->content;
  $funcname =~ s/^Locale::TextDomain:://;
  $funcs{$funcname} || return;
  ### TextDomainPlaceholders: $elem->content

  is_function_call($elem) || return;

  my @violations;

  # The arg crunching bits assume one parsed expression results in one arg,
  # which is not true if the expressions are an array, a hash, or a function
  # call returning multiple values.  The one-arg-one-value assumption is
  # reasonable on the whole though.
  #
  # In the worst case you'd have to take any function call value part like
  # "foo => FOO()" to perhaps return multiple values -- which would
  # completely defeat testing of normal cases, so don't want to do that.
  #
  # ENHANCE-ME: One bit that could be done though is to recognise a %foo arg
  # as giving an even number of values, so keyword checking could continue
  # past it.

  # each element of @args is an arrayref containing PPI elements making up
  # the arg
  my @args = parse_arg_list ($elem);
  ### got total arg count: scalar(@args)

  if ($funcname =~ /p/) {
    # msgctxt context arg to __p, __npx
    shift @args;
  }

  # one format to __x, two to __nx and other "n" funcs
  my @format_args = splice @args, 0, ($funcname =~ /n/ ? 2 : 1);

  if ($funcname =~ /n/) {
    # count arg to __nx and other "n" funcs
    my $count_arg = shift @args;
    if (! $count_arg
        || do {
          # if it looks like a keyword symbol foo=> or 'foo' etc
          my ($str, $any_vars) = _arg_word_or_string ($count_arg, $document);
          ($str =~ /^[[:alpha:]_]\w*$/ && ! $any_vars)
        }) {
      push @violations, $self->violation
        ("Probably missing 'count' argument to $funcname",
         '',
         $count_arg->[0] || $elem);
    }
  }

  ### got data arg count: scalar(@args)

  my $args_any_vars = 0;
  my %arg_keys;
  while (@args) {
    my $arg = shift @args;
    my ($str, $any_vars) = _arg_word_or_string ($arg, $document);
    $args_any_vars ||= $any_vars;
    ### arg: @$arg
    ### $str
    ### $any_vars
    if (! $any_vars) {
      $arg_keys{$str} = $arg;
    }
    shift @args; # value part
  }

  my %format_keys;
  my $format_any_vars;

  foreach my $format_arg (@format_args) {
    my ($format_str, $any_vars) = _arg_string ($format_arg, $document);
    $format_any_vars ||= $any_vars;

    while ($format_str =~ /\{(\w+)\}/g) {
      my $format_key = $1;
      ### $format_key
      $format_keys{$format_key} = 1;

      if (! $args_any_vars && ! exists $arg_keys{$format_key}) {
        push @violations, $self->violation
          ("Format key '$format_key' not in arg list",
           '',
           $format_arg->[0] || $elem);
      }
    }
  }

  if (! $format_any_vars) {
    foreach my $arg_key (keys %arg_keys) {
      if (! exists $format_keys{$arg_key}) {
        my $arg = $arg_keys{$arg_key};
        push @violations, $self->violation
          ("Argument key '$arg_key' not used by format"
           . (@format_args == 1 ? '' : 's'),
           '',
           $arg->[0] || $elem);
      }
    }
  }
  ### total violation count: scalar(@violations)

  return @violations;
}

sub _arg_word_or_string {
  my ($arg, $document) = @_;
  if (@$arg == 1 && $arg->[0]->isa('PPI::Token::Word')) {
    return ("$arg->[0]", 0);
  } else {
    return _arg_string ($arg, $document);
  }
}

# $arg is an arrayref of PPI::Element which are an argument
# if it's a constant string or "." concat of such then
# return ($str, $any_vars) where $str is the string content
# and $any_vars is true if there's any variables to be interpolated in $str
#
sub _arg_string {
  my ($arg, $document) = @_;
  ### _arg_string() ...

  my @elems = @$arg;
  my $ret = '';
  my $any_vars = 0;

  while (@elems) {
    my $elem = shift @elems;

    if ($elem->isa('PPI::Token::Quote')) {
      my $str = $elem->string;
      if ($elem->isa('PPI::Token::Quote::Double')
          || $elem->isa('PPI::Token::Quote::Interpolate')) {
        # ENHANCE-ME: use $arg->interpolations() when available also on
        # PPI::Token::Quote::Interpolate
        $any_vars ||= _string_any_vars ($str);
      }
      $ret .= $str;

    } elsif ($elem->isa('PPI::Token::HereDoc')) {
      my $str = join('',$elem->heredoc);
      if ($elem =~ /`$/) {
        $str = ' '; # no idea what running backticks might produce
        $any_vars = 1;
      } elsif ($elem !~ /'$/) {
        # explicit "HERE" or default HERE expand vars
        $any_vars ||= _string_any_vars ($str);
      }
      $ret .= $str;

    } elsif ($elem->isa('PPI::Token::Number')) {
      ### number can work like a constant string ...
      $ret .= $elem->content;

    } elsif ($elem->isa('PPI::Token::Word')) {
      ### word ...
      my $next;
      if ($elem eq '__PACKAGE__') {
        $ret .= _elem_package_name($elem);

      } elsif ($elem eq '__LINE__') {
        ### logical line: $elem->location->[3]
        $ret .= $elem->location->[3]; # logical line using any #line directives

      } elsif ($elem eq '__FILE__') {
        my $filename = _elem_logical_filename($elem,$document);
        if (! defined $filename) {
          $filename = 'unknown-filename.pl';
        }
        ### $filename
        $ret .= $filename;

      } elsif (($next = $elem->snext_sibling)
               && $next->isa('PPI::Token::Operator')
               && $next eq '=>') {
        ### word quoted by => ...
        $ret .= $elem->content;
        last;
      } else {
        ### some function call or something ...
        return ('', 2);
      }

    } else {
      ### some variable or expression or something ...
      return ('', 2);
    }


    if (! @elems) { last; }
    my $op = shift @elems;
    if (! ($op->isa('PPI::Token::Operator') && $op eq '.')) {
      # something other than "." concat
      return ('', 2);
    }
  }
  return ($ret, $any_vars);
}

# $str is the contents of a "" or qq{} string
# return true if it has any $ or @ interpolation forms
sub _string_any_vars {
  my ($str) = @_;
  return ($str =~ /(^|[^\\])(\\\\)*[\$@]/);
}

# $elem is a PPI::Element
# Return the name (a string) of its containing package, or "main" if not
# under any package statement.
#
sub _elem_package_name {
  my ($elem) = @_;
  if (my $packelem = Perl::Critic::Pulp::Utils::elem_package($elem)) {
    if (my $name = $packelem->namespace) {
      return $name;
    }
  }
  return 'main';
}

# As per perlsyn.pod, except \2 instead of \g2 since \g only in perl 5.10 up.
# Is this in a module somewhere?
my $line_directive_re =
  qr/^\#   \s*
     line \s+ (\d+)   \s*
     (?:\s("?)([^"]+)\2)? \s*
     $/xm;

# $elem is a PPI::Element
# Return its logical filename (a string).
# This is from a "#line" comment directive, or the $document filename if no
# such.
#
sub _elem_logical_filename {
  my ($elem, $document) = @_;
  ### _elem_logical_filename(): "$elem"

  my $filename;
  $document->find_first (sub {
                           my ($doc, $e) = @_;
                           # ### comment: (ref $e)."  ".$e->content
                           if ($e == $elem) {
                             ### not found before target elem, stop ...
                             return undef;
                           }
                           if ($e->isa('PPI::Token::Comment')
                               && $e->content =~ $line_directive_re) {
                             $filename = $3;
                             ### found line directive: $filename
                           }
                           return 0; # continue
                         });
  if (defined $filename) {
    return $filename;
  } else {
    ### not found, use document: $document->filename
    return $document->filename;
  }
}

1;
__END__

=for stopwords args arg Gettext Charset runtime Ryde unexpanded

=head1 NAME

Perl::Critic::Policy::Miscellanea::TextDomainPlaceholders - check placeholder names in Locale::TextDomain calls

=head1 DESCRIPTION

This policy is part of the L<C<Perl::Critic::Pulp>|Perl::Critic::Pulp>
add-on.  It checks the placeholder arguments in format strings to the
following functions from C<Locale::TextDomain>.

    __x __nx __xn __px __npx

Calls with a key missing from the args or args unused by the format are
reported.

    print __x('Searching for {data}',  # bad
              datum => 123);

    print __nx('Read one file',
               'Read {num} files',     # bad
               $n,
               count => 123);

This is normally a mistake, so this policy is under the "bugs" theme (see
L<Perl::Critic/POLICY THEMES>).  An error can easily go unnoticed because
(as of Locale::TextDomain version 1.16) a placeholder without a
corresponding arg goes through unexpanded and any extra args are ignored.

The way Locale::TextDomain parses the format string allows anything between
S<< C<< { } >> >> as a key, but for the purposes of this policy only symbols
(alphanumeric plus "_") are taken to be a key.  This is almost certainly
what you'll want to use, and it's then possible to include literal braces in
a format string without tickling this policy all the time.  (Symbol
characters are per Perl C<\w>, so non-ASCII is supported, though the Gettext
manual in node "Charset conversion" recommends message-IDs should be
ASCII-only.)

=head1 Partial Checks

If the format string is not a literal then it might use any args, so all are
considered used.

    # ok, 'datum' might be used
    __x($my_format, datum => 123);

Literal portions of the format are still checked.

    # bad, 'foo' not present in args
    __x("{foo} $bar", datum => 123);

Conversely if the args have some non-literals then they could be anything,
so everything in the format string is considered present.

    # ok, $something might be 'world'
    __x('hello {world}', $something => 123);

But again if some args are literals they can be checked.

    # bad, 'blah' is not used
    __x('hello {world}', $something => 123, blah => 456);

If there's non-literals both in the format and in the args then nothing is
checked, since it could all match up fine at runtime.

=head2 C<__nx> Count Argument

A missing count argument to C<__nx>, C<__xn> and C<__npx> is sometimes
noticed by this policy.  For example,

    print __nx('Read one file',
               'Read {numfiles} files',
               numfiles => $numfiles);   # bad

If the count argument looks like a key then it's reported as a probable
mistake.  This is not the main aim of this policy but it's done because
otherwise no violations would be reported at all.  (The next argument would
be the key, and normally being an expression it would be assumed to fulfill
the format strings at runtime.)

=head1 SEE ALSO

L<Perl::Critic::Pulp>,
L<Perl::Critic>,
L<Locale::TextDomain>,
L<Perl::Critic::Policy::Miscellanea::TextDomainUnused>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/perl-critic-pulp/index.html>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019, 2021 Kevin Ryde

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

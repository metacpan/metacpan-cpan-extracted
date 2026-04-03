use v5.36.0;

package Sieve::Generator::Sugar 0.002;
# ABSTRACT: constructor functions for building Sieve generator objects

use JSON::MaybeXS ();
use Params::Util qw(_ARRAY0 _HASH0 _SCALAR0);

use experimental 'builtin', 'for_list';
use builtin 'blessed';

use Sub::Exporter -setup => [ qw(
  blank
  block
  command
  test
  comment
  set
  sieve
  heredoc
  ifelse

  allof
  anyof
  noneof

  bool
  hasflag
  qstr
  terms
  var_eq
  var_ne
) ];

use Sieve::Generator::Lines::Block;
use Sieve::Generator::Lines::Command;
use Sieve::Generator::Lines::Comment;
use Sieve::Generator::Lines::Document;
use Sieve::Generator::Lines::Heredoc;
use Sieve::Generator::Lines::IfElse;
use Sieve::Generator::Lines::Junction;
use Sieve::Generator::Text::Qstr;
use Sieve::Generator::Text::QstrList;
use Sieve::Generator::Text::Terms;

#pod =head1 SYNOPSIS
#pod
#pod   use Sieve::Generator::Sugar '-all';
#pod
#pod   my $script = sieve(
#pod     command('require', [ qw(fileinto imap4flags) ]),
#pod     blank(),
#pod     ifelse(
#pod       header_exists('X-Spam'),
#pod       block(
#pod         command('addflag', '$Junk'),
#pod         command('fileinto', 'Spam'),
#pod       ),
#pod     ),
#pod   );
#pod
#pod   print $script->as_sieve;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module exports constructor functions for building
#pod L<Sieve::Generator> object trees.  All functions can be imported at once
#pod with the C<-all> tag.
#pod
#pod Because many of the function names (C<block>, C<size>, C<terms>, and so on)
#pod are common words that may clash with existing code, L<Sub::Exporter> allows
#pod all imported symbols to be given a prefix:
#pod
#pod   use Sieve::Generator::Sugar -all => { -prefix => 'sv_' };
#pod
#pod With that import, each function is available under its prefixed name, e.g.
#pod C<sv_sieve>, C<sv_ifelse>, C<sv_block>, and so on.
#pod
#pod =func comment
#pod
#pod   my $comment = comment($text);
#pod   my $comment = comment($text, { hashes => 2 });
#pod
#pod This function creates a L<Sieve::Generator::Lines::Comment> with the given
#pod content.  The content may be a plain string or an object doing
#pod L<Sieve::Generator::Text>.  The optional second argument is a hashref; its
#pod C<hashes> key controls how many C<#> characters prefix each line, defaulting
#pod to one.
#pod
#pod =cut

sub comment ($content, $arg = undef) {
  return Sieve::Generator::Lines::Comment->new({
    ($arg ? %$arg : ()),
    content => $content,
  });
}

#pod =func command
#pod
#pod   my $cmd = command($identifier, (\%tagged?), @args);
#pod
#pod This function creates a L<Sieve::Generator::Lines::Command> with the given
#pod identifier and arguments.  Arguments may be plain strings or objects doing
#pod L<Sieve::Generator::Text>.  The command renders as a semicolon-terminated
#pod Sieve statement.
#pod
#pod =cut

my sub _command ($identifier, $meta_arg, @args) {
  my $tagged_args;

  if (@args && _HASH0($args[0]) && !blessed($args[0])) {
    my $tagged_input = shift @args;

    for my ($k, $v) (%$tagged_input) {
      # The underlying data structure is designed so we can represent this:
      #
      #   :arg v1 v2 v3
      #
      # ...but there's currently
      $tagged_args->{$k} = !defined $v  ? []
                         : blessed($v)  ? [ $v ]
                         : !ref $v      ? [ Sieve::Generator::Text::Qstr->new({ str => $v }) ]
                         : _ARRAY0($v)  ? [ Sieve::Generator::Text::QstrList->new({ strs => $v }) ]
                         : _SCALAR0($v) ? [ Sieve::Generator::Text::Terms->new({ terms => [$$v] }) ]
                         : Carp::confess("unknown reference type $v passed in Sieve command sugar's tagged args");
    }
  }

  my @autoquoted_args = map {;
                           blessed($_)  ? $_
                         : !ref $_      ? Sieve::Generator::Text::Qstr->new({ str => $_ })
                         : _ARRAY0($_)  ? Sieve::Generator::Text::QstrList->new({ strs => $_ })
                         : _SCALAR0($_) ? Sieve::Generator::Text::Terms->new({ terms => [$$_] })
                         : Carp::confess("unknown reference type $_ passed in Sieve command sugar's positional args");
                        } @args;

  return Sieve::Generator::Lines::Command->new({
    %$meta_arg,

    identifier  => $identifier,
    tagged_args => $tagged_args // {},
    positional_args => \@autoquoted_args,
  });
}

sub command ($identifier, @args) {
  _command($identifier, {}, @args);
}

#pod =func test
#pod
#pod   my $test = test($identifier, (\%tagged?), @args);
#pod
#pod This function creates a L<Sieve::Generator::Lines::Command> with the given
#pod identifier and arguments -- and semicolon-at-the-end turned off.  In the
#pod future, this might produce a distinct object, but for now, and really in Sieve,
#pod commands and tests are I<nearly> the same thing.
#pod
#pod =cut

sub test ($identifier, @args) {
  _command($identifier, { autowrap => 0, semicolon => 0 }, @args);
}

#pod =func set
#pod
#pod   my $cmd = set($variable, $value);
#pod
#pod This function creates a L<Sieve::Generator::Lines::Command> for the Sieve
#pod C<set> command (RFC 5229).  Both C<$variable> and C<$value> are automatically
#pod quoted as Sieve strings.
#pod
#pod =cut

sub set ($var, $val) {
  return Sieve::Generator::Lines::Command->new({
    identifier => 'set',
    positional_args => [
      Sieve::Generator::Text::Qstr->new({ str => $var }),
      Sieve::Generator::Text::Qstr->new({ str => $val }),
    ],
  });
}

#pod =func ifelse
#pod
#pod   my $if = ifelse($condition, $block);
#pod   my $if = ifelse($cond, $if_block, [ $condN, $elsif_blockN ] ..., $else_block);
#pod
#pod This function creates a L<Sieve::Generator::Lines::IfElse>.  The first two
#pod arguments are the condition and the block to execute when it is true.
#pod Additional condition/block pairs render as C<elsif> clauses.  If the total
#pod number of trailing arguments is odd, the final argument is used as the plain
#pod C<else> block.
#pod
#pod =cut

sub ifelse ($cond, $if_true, @rest) {
  my $else = @rest % 2 ? (pop @rest) : undef;

  return Sieve::Generator::Lines::IfElse->new({
    cond   => $cond,
    true   => $if_true,
    elsifs => \@rest,
    ($else ? (else => $else) : ()),
  });
}

#pod =func blank
#pod
#pod   my $blank = blank();
#pod
#pod This function creates an empty L<Sieve::Generator::Lines::Document>.  It is
#pod typically used to insert a blank line between sections of a Sieve script.
#pod
#pod =cut

sub blank () {
  return Sieve::Generator::Lines::Document->new({ things => [] });
}

#pod =func sieve
#pod
#pod   my $doc = sieve(@things);
#pod
#pod This function creates a L<Sieve::Generator::Lines::Document> from the given
#pod C<@things>.  The document is the top-level container for a Sieve script; its
#pod C<as_sieve> method renders the full script as a string.
#pod
#pod =cut

sub sieve (@things) {
  return Sieve::Generator::Lines::Document->new({ things => \@things });
}

#pod =func block
#pod
#pod   my $block = block(@things);
#pod
#pod This function creates a L<Sieve::Generator::Lines::Block> containing the
#pod given C<@things>.  A block renders as a brace-delimited, indented sequence of
#pod statements, as used in Sieve C<if>/C<elsif>/C<else> constructs.
#pod
#pod =cut

sub block (@things) {
  return Sieve::Generator::Lines::Block->new({ things => \@things });
}

#pod =func allof
#pod
#pod   my $test = allof(@tests);
#pod
#pod This function creates a L<Sieve::Generator::Lines::Junction> that renders as
#pod a Sieve C<allof(...)> test, which is true only when all of the given tests
#pod are true.
#pod
#pod =cut

sub allof (@things) {
  return Sieve::Generator::Lines::Junction->new({
    type => 'allof',
    things => \@things,
  });
}

#pod =func anyof
#pod
#pod   my $test = anyof(@tests);
#pod
#pod This function creates a L<Sieve::Generator::Lines::Junction> that renders as
#pod a Sieve C<anyof(...)> test, which is true when any of the given tests is
#pod true.
#pod
#pod =cut

sub anyof (@things) {
  return Sieve::Generator::Lines::Junction->new({
    type => 'anyof',
    things => \@things,
  });
}

#pod =func noneof
#pod
#pod   my $test = noneof(@tests);
#pod
#pod This function creates a L<Sieve::Generator::Lines::Junction> that renders as
#pod a Sieve C<not anyof(...)> test, which is true only when none of the given
#pod tests are true.
#pod
#pod =cut

sub noneof (@things) {
  return Sieve::Generator::Lines::Junction->new({
    type => 'noneof',
    things => \@things,
  });
}

#pod =func terms
#pod
#pod   my $terms = terms(@terms);
#pod
#pod This function creates a L<Sieve::Generator::Text::Terms> from the given
#pod C<@terms>.  Each term may be a plain string or an object doing
#pod L<Sieve::Generator::Text>; all terms are joined with single spaces when
#pod rendered.  This is the general-purpose constructor for Sieve test expressions
#pod and argument sequences.
#pod
#pod =cut

sub terms (@terms) {
  return Sieve::Generator::Text::Terms->new({ terms => \@terms });
}

#pod =func heredoc
#pod
#pod   my $hd = heredoc($text);
#pod
#pod This function creates a L<Sieve::Generator::Lines::Heredoc> containing the
#pod given C<$text>.  The text renders using the Sieve C<text:>/C<.> multiline
#pod string syntax.  Any line beginning with C<.> is automatically escaped to
#pod C<..>.
#pod
#pod =cut

sub heredoc ($text) {
  return Sieve::Generator::Lines::Heredoc->new({ text => $text });
}

#pod =func qstr
#pod
#pod   my $q    = qstr($string);
#pod   my @qs   = qstr(@strings);
#pod   my $list = qstr(\@strings);
#pod
#pod This function creates Sieve string objects.  A plain scalar produces a
#pod L<Sieve::Generator::Text::Qstr> that renders as a quoted Sieve string.  An
#pod array reference produces a L<Sieve::Generator::Text::QstrList> that renders
#pod as a bracketed Sieve string list.  When given a list of arguments, it maps
#pod over each and returns a corresponding list of objects.
#pod
#pod =cut

sub qstr (@inputs) {
  return map {;
    ref ? Sieve::Generator::Text::QstrList->new({ strs => $_ })
        : Sieve::Generator::Text::Qstr->new({ str => $_ })
  } @inputs;
}

#pod =func hasflag
#pod
#pod   my $test = hasflag($flag);
#pod
#pod This function creates an RFC 5232 C<hasflag> test that is true if the message
#pod has the given flag set.  The C<$flag> is automatically quoted as a Sieve
#pod string.
#pod
#pod =cut

sub hasflag ($flag) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ 'hasflag', Sieve::Generator::Text::Qstr->new({ str => $flag }) ],
  });
}

#pod =func bool
#pod
#pod   my $test = bool($value);
#pod
#pod This function returns a Terms representing a literal C<true> or C<false>
#pod depending on the truthiness of C<$value>.
#pod
#pod =cut

sub bool ($value) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ $value ? 'true' : 'false' ],
  });
}

#pod =func var_eq
#pod
#pod   my $test = var_eq($var, $value);
#pod
#pod This produces a string "is" test checking that the given variable name equals
#pod the given value, by producing something like C<string :is "${$var}" "$value">.
#pod
#pod =cut

sub var_eq ($var, $value) {
  return Sieve::Generator::Lines::Command->new({
    autowrap  => 0,
    semicolon => 0,

    identifier  => 'string',
    tagged_args => { is => [] },
    positional_args => [
      Sieve::Generator::Text::Qstr->new({ str => "\${$var}" }),
      qstr($value),
    ],
  });
}

#pod =func var_ne
#pod
#pod   my $test = var_ne($var, $value);
#pod
#pod This produces an inverted string "is" test checking that the given variable
#pod name equals the given value, by producing something like C<not string :is
#pod "${$var}" "$value">.
#pod
#pod =cut

sub var_ne ($var, $value) {
  return Sieve::Generator::Lines::Command->new({
    autowrap  => 0,
    semicolon => 0,

    identifier  => 'not string',
    tagged_args => { is => [] },
    positional_args => [
      Sieve::Generator::Text::Qstr->new({ str => "\${$var}" }),
      qstr($value),
    ],
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Sugar - constructor functions for building Sieve generator objects

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Sieve::Generator::Sugar '-all';

  my $script = sieve(
    command('require', [ qw(fileinto imap4flags) ]),
    blank(),
    ifelse(
      header_exists('X-Spam'),
      block(
        command('addflag', '$Junk'),
        command('fileinto', 'Spam'),
      ),
    ),
  );

  print $script->as_sieve;

=head1 DESCRIPTION

This module exports constructor functions for building
L<Sieve::Generator> object trees.  All functions can be imported at once
with the C<-all> tag.

Because many of the function names (C<block>, C<size>, C<terms>, and so on)
are common words that may clash with existing code, L<Sub::Exporter> allows
all imported symbols to be given a prefix:

  use Sieve::Generator::Sugar -all => { -prefix => 'sv_' };

With that import, each function is available under its prefixed name, e.g.
C<sv_sieve>, C<sv_ifelse>, C<sv_block>, and so on.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is
no promise that patches will be accepted to lower the minimum required perl.

=head1 FUNCTIONS

=head2 comment

  my $comment = comment($text);
  my $comment = comment($text, { hashes => 2 });

This function creates a L<Sieve::Generator::Lines::Comment> with the given
content.  The content may be a plain string or an object doing
L<Sieve::Generator::Text>.  The optional second argument is a hashref; its
C<hashes> key controls how many C<#> characters prefix each line, defaulting
to one.

=head2 command

  my $cmd = command($identifier, (\%tagged?), @args);

This function creates a L<Sieve::Generator::Lines::Command> with the given
identifier and arguments.  Arguments may be plain strings or objects doing
L<Sieve::Generator::Text>.  The command renders as a semicolon-terminated
Sieve statement.

=head2 test

  my $test = test($identifier, (\%tagged?), @args);

This function creates a L<Sieve::Generator::Lines::Command> with the given
identifier and arguments -- and semicolon-at-the-end turned off.  In the
future, this might produce a distinct object, but for now, and really in Sieve,
commands and tests are I<nearly> the same thing.

=head2 set

  my $cmd = set($variable, $value);

This function creates a L<Sieve::Generator::Lines::Command> for the Sieve
C<set> command (RFC 5229).  Both C<$variable> and C<$value> are automatically
quoted as Sieve strings.

=head2 ifelse

  my $if = ifelse($condition, $block);
  my $if = ifelse($cond, $if_block, [ $condN, $elsif_blockN ] ..., $else_block);

This function creates a L<Sieve::Generator::Lines::IfElse>.  The first two
arguments are the condition and the block to execute when it is true.
Additional condition/block pairs render as C<elsif> clauses.  If the total
number of trailing arguments is odd, the final argument is used as the plain
C<else> block.

=head2 blank

  my $blank = blank();

This function creates an empty L<Sieve::Generator::Lines::Document>.  It is
typically used to insert a blank line between sections of a Sieve script.

=head2 sieve

  my $doc = sieve(@things);

This function creates a L<Sieve::Generator::Lines::Document> from the given
C<@things>.  The document is the top-level container for a Sieve script; its
C<as_sieve> method renders the full script as a string.

=head2 block

  my $block = block(@things);

This function creates a L<Sieve::Generator::Lines::Block> containing the
given C<@things>.  A block renders as a brace-delimited, indented sequence of
statements, as used in Sieve C<if>/C<elsif>/C<else> constructs.

=head2 allof

  my $test = allof(@tests);

This function creates a L<Sieve::Generator::Lines::Junction> that renders as
a Sieve C<allof(...)> test, which is true only when all of the given tests
are true.

=head2 anyof

  my $test = anyof(@tests);

This function creates a L<Sieve::Generator::Lines::Junction> that renders as
a Sieve C<anyof(...)> test, which is true when any of the given tests is
true.

=head2 noneof

  my $test = noneof(@tests);

This function creates a L<Sieve::Generator::Lines::Junction> that renders as
a Sieve C<not anyof(...)> test, which is true only when none of the given
tests are true.

=head2 terms

  my $terms = terms(@terms);

This function creates a L<Sieve::Generator::Text::Terms> from the given
C<@terms>.  Each term may be a plain string or an object doing
L<Sieve::Generator::Text>; all terms are joined with single spaces when
rendered.  This is the general-purpose constructor for Sieve test expressions
and argument sequences.

=head2 heredoc

  my $hd = heredoc($text);

This function creates a L<Sieve::Generator::Lines::Heredoc> containing the
given C<$text>.  The text renders using the Sieve C<text:>/C<.> multiline
string syntax.  Any line beginning with C<.> is automatically escaped to
C<..>.

=head2 qstr

  my $q    = qstr($string);
  my @qs   = qstr(@strings);
  my $list = qstr(\@strings);

This function creates Sieve string objects.  A plain scalar produces a
L<Sieve::Generator::Text::Qstr> that renders as a quoted Sieve string.  An
array reference produces a L<Sieve::Generator::Text::QstrList> that renders
as a bracketed Sieve string list.  When given a list of arguments, it maps
over each and returns a corresponding list of objects.

=head2 hasflag

  my $test = hasflag($flag);

This function creates an RFC 5232 C<hasflag> test that is true if the message
has the given flag set.  The C<$flag> is automatically quoted as a Sieve
string.

=head2 bool

  my $test = bool($value);

This function returns a Terms representing a literal C<true> or C<false>
depending on the truthiness of C<$value>.

=head2 var_eq

  my $test = var_eq($var, $value);

This produces a string "is" test checking that the given variable name equals
the given value, by producing something like C<string :is "${$var}" "$value">.

=head2 var_ne

  my $test = var_ne($var, $value);

This produces an inverted string "is" test checking that the given variable
name equals the given value, by producing something like C<not string :is
"${$var}" "$value">.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

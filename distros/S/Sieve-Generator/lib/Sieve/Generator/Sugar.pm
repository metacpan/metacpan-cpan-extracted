use v5.36.0;

package Sieve::Generator::Sugar 0.001;
# ABSTRACT: constructor functions for building Sieve generator objects

use JSON::MaybeXS ();

use Sub::Exporter -setup => [ qw(
  blank
  block
  command
  comment
  set
  sieve
  heredoc
  ifelse

  allof
  anyof
  noneof

  bool
  fourpart
  hasflag
  header_exists
  not_header_exists
  not_string_test
  qstr
  size
  string_test
  terms
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
#pod     command('require', qstr([ qw(fileinto imap4flags) ])),
#pod     blank(),
#pod     ifelse(
#pod       header_exists('X-Spam'),
#pod       block(
#pod         command('addflag', qstr('$Junk')),
#pod         command('fileinto', qstr('Spam')),
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
#pod   my $cmd = command($identifier, @args);
#pod
#pod This function creates a L<Sieve::Generator::Lines::Command> with the given
#pod identifier and arguments.  Arguments may be plain strings or objects doing
#pod L<Sieve::Generator::Text>.  The command renders as a semicolon-terminated
#pod Sieve statement.
#pod
#pod =cut

sub command ($identifier, @args) {
  return Sieve::Generator::Lines::Command->new({
    identifier => $identifier,
    args => \@args,
  });
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
    args => [
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

#pod =func fourpart
#pod
#pod   my $test = fourpart($identifier, $tag, $arg1, $arg2);
#pod
#pod This function creates a L<Sieve::Generator::Text::Terms> representing a
#pod four-part Sieve test of the form C<identifier :tag arg1 arg2>.  C<$identifier>
#pod and C<$tag> are used as-is (with C<:> prepended to C<$tag>); C<$arg1> and
#pod C<$arg2> are each quoted automatically, with array references becoming Sieve
#pod string lists and plain scalars becoming quoted strings.
#pod
#pod =cut

sub fourpart ($identifier, $tag, $arg1, $arg2) {
  return Sieve::Generator::Text::Terms->new({
    terms => [
      $identifier,
      ":$tag",
      (ref $arg1 ? Sieve::Generator::Text::QstrList->new({ strs => $arg1 })
                 : Sieve::Generator::Text::Qstr->new({ str => $arg1 })),
      (ref $arg2 ? Sieve::Generator::Text::QstrList->new({ strs => $arg2 })
                 : Sieve::Generator::Text::Qstr->new({ str => $arg2 })),
    ],
  });
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

#pod =func header_exists
#pod
#pod   my $test = header_exists($header);
#pod
#pod This function creates an RFC 5228 C<exists> test that is true if the named
#pod header field is present in the message.  The C<$header> is automatically
#pod quoted as a Sieve string.
#pod
#pod =cut

sub header_exists ($header) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ 'exists', Sieve::Generator::Text::Qstr->new({ str => $header }) ],
  });
}

#pod =func not_header_exists
#pod
#pod   my $test = not_header_exists($header);
#pod
#pod This function creates a C<not exists> test that is true if the named header
#pod field is absent from the message.  The C<$header> is automatically quoted as
#pod a Sieve string.
#pod
#pod =cut

sub not_header_exists ($header) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ 'not exists', Sieve::Generator::Text::Qstr->new({ str => $header }) ],
  });
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

#pod =func string_test
#pod
#pod   my $test = string_test($comparator, $key, $value);
#pod
#pod This function creates an RFC 5229 C<string> test using the given comparator
#pod tag (e.g. C<is>, C<contains>, C<matches>).  The C<$key> and C<$value> should
#pod be objects doing L<Sieve::Generator::Text>, typically produced by L</qstr>.
#pod
#pod =cut

sub string_test ($comparator, $key, $value) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ "string :$comparator", $key, $value ],
  });
}

#pod =func not_string_test
#pod
#pod   my $test = not_string_test($comparator, $key, $value);
#pod
#pod This function creates the negation of an RFC 5229 C<string> test.  It accepts
#pod the same arguments as L</string_test>.
#pod
#pod =cut

sub not_string_test ($comparator, $key, $value) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ "not string :$comparator", $key, $value ],
  });
}

#pod =func size
#pod
#pod   my $test = size($comparator, $value);
#pod
#pod This function creates an RFC 5228 C<size> test using the given comparator
#pod (C<over> or C<under>) and size value (e.g. C<100K>).  The value is not quoted
#pod and is passed through as-is.
#pod
#pod =cut

sub size ($comparator, $value) {
  return Sieve::Generator::Text::Terms->new({
    terms => [ "size :$comparator", $value ],
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sieve::Generator::Sugar - constructor functions for building Sieve generator objects

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Sieve::Generator::Sugar '-all';

  my $script = sieve(
    command('require', qstr([ qw(fileinto imap4flags) ])),
    blank(),
    ifelse(
      header_exists('X-Spam'),
      block(
        command('addflag', qstr('$Junk')),
        command('fileinto', qstr('Spam')),
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

  my $cmd = command($identifier, @args);

This function creates a L<Sieve::Generator::Lines::Command> with the given
identifier and arguments.  Arguments may be plain strings or objects doing
L<Sieve::Generator::Text>.  The command renders as a semicolon-terminated
Sieve statement.

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

=head2 fourpart

  my $test = fourpart($identifier, $tag, $arg1, $arg2);

This function creates a L<Sieve::Generator::Text::Terms> representing a
four-part Sieve test of the form C<identifier :tag arg1 arg2>.  C<$identifier>
and C<$tag> are used as-is (with C<:> prepended to C<$tag>); C<$arg1> and
C<$arg2> are each quoted automatically, with array references becoming Sieve
string lists and plain scalars becoming quoted strings.

=head2 qstr

  my $q    = qstr($string);
  my @qs   = qstr(@strings);
  my $list = qstr(\@strings);

This function creates Sieve string objects.  A plain scalar produces a
L<Sieve::Generator::Text::Qstr> that renders as a quoted Sieve string.  An
array reference produces a L<Sieve::Generator::Text::QstrList> that renders
as a bracketed Sieve string list.  When given a list of arguments, it maps
over each and returns a corresponding list of objects.

=head2 header_exists

  my $test = header_exists($header);

This function creates an RFC 5228 C<exists> test that is true if the named
header field is present in the message.  The C<$header> is automatically
quoted as a Sieve string.

=head2 not_header_exists

  my $test = not_header_exists($header);

This function creates a C<not exists> test that is true if the named header
field is absent from the message.  The C<$header> is automatically quoted as
a Sieve string.

=head2 hasflag

  my $test = hasflag($flag);

This function creates an RFC 5232 C<hasflag> test that is true if the message
has the given flag set.  The C<$flag> is automatically quoted as a Sieve
string.

=head2 string_test

  my $test = string_test($comparator, $key, $value);

This function creates an RFC 5229 C<string> test using the given comparator
tag (e.g. C<is>, C<contains>, C<matches>).  The C<$key> and C<$value> should
be objects doing L<Sieve::Generator::Text>, typically produced by L</qstr>.

=head2 not_string_test

  my $test = not_string_test($comparator, $key, $value);

This function creates the negation of an RFC 5229 C<string> test.  It accepts
the same arguments as L</string_test>.

=head2 size

  my $test = size($comparator, $value);

This function creates an RFC 5228 C<size> test using the given comparator
(C<over> or C<under>) and size value (e.g. C<100K>).  The value is not quoted
and is passed through as-is.

=head2 bool

  my $test = bool($value);

This function returns a Terms representing a literal C<true> or C<false>
depending on the truthiness of C<$value>.

=head1 AUTHOR

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

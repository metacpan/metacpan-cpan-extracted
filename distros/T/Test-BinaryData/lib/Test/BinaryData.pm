use strict;
use warnings;
package Test::BinaryData;
{
  $Test::BinaryData::VERSION = '0.014';
}
# ABSTRACT: compare two things, give hex dumps if they differ

use 5.006;


use Carp ();
use Test::Builder;
require Exporter;
@Test::BinaryData::ISA = qw(Exporter);
@Test::BinaryData::EXPORT = qw(is_binary);

sub import {
  my($self) = shift;
  my $pack = caller;

  my $Test = Test::Builder->new;

  $Test->exported_to($pack);
  $Test->plan(@_) if @_;

  $self->export_to_level(1, $self, @Test::BinaryData::EXPORT);
}


sub _widths {
  my ($total) = @_;

  $total = $total
         - 2 # the "# " that begins each diagnostics line
         - 3 # the " ! " or " = " line between got / expected
         - 2 # the space between hex/ascii representations
         ;

  my $sixth = int($total / 6);
  return ($sixth * 2, $sixth);
}

sub is_binary {
  my ($have, $want, $comment, $arg) = @_;

  my $Test = Test::Builder->new;

  $arg ||= {};

  unless (defined $arg->{columns}) {
    if (($ENV{COLUMNS}||'') =~ /\A\d+\z/ and $ENV{COLUMNS} > 0) {
      $arg->{columns} = $ENV{COLUMNS} - 1;
    } else {
      $arg->{columns} = 79;
    }
  }

  Carp::croak 'minimum columns is 44' if $arg->{columns} < 44;

  my ($hw, $aw) = _widths($arg->{columns});

  if (ref $want) {
    $want = join q{}, map { chr hex } map { unpack "(a2)*", $_ } @$want;
  }

  my $have_is_wide = grep { ord > 255 } split //, $have;
  my $want_is_wide = grep { ord > 255 } split //, $want;

  if ($have_is_wide or $want_is_wide) {
    $Test->ok(0, $comment);

    $Test->diag("value for 'have' contains wide bytes") if $have_is_wide;
    $Test->diag("value for 'want' contains wide bytes") if $want_is_wide;

    return;
  }

  if ($have eq $want) {
    return $Test->ok(1, $comment);
  }

  $Test->ok(0, $comment);

  my $max_length = (sort map { length($_) } $have, $want)[1];

  $Test->diag(
    sprintf "%-${hw}s %-${aw}s   %-${hw}s %-${aw}s",
      map {; "$_ (hex)", "$_" } qw(have want)
  );

  my $seen_diffs = 0;
  CHUNK: for (my $pos = 0; $pos < $max_length; $pos += $aw) {
    if ($arg->{max_diffs} and $seen_diffs == $arg->{max_diffs}) {
      $Test->diag("...");
      last CHUNK;
    }

    my $g_substr = substr($have, $pos, $aw);
    my $e_substr = substr($want, $pos, $aw);

    my $eq = $g_substr eq $e_substr;

    my $g_hex =
      join q{},
      map { sprintf '%02x', ord(substr($g_substr, $_, 1)) }
      0 .. length($g_substr) - 1;

    my $e_hex =
      join q{},
      map { sprintf '%02x', ord(substr($e_substr, $_, 1)) }
      0 .. length($e_substr) - 1;

    for my $str ($g_substr, $e_substr) {
      for my $pos (0 .. length($str) - 1) {
        my $c = substr($str, $pos, 1);
        substr($str, $pos, 1, q{.}) if ord($c) < 0x20 or ord($c) > 0x7e;
      }
    }

    $_ = sprintf "%-${aw}s", $_ for ($g_substr, $e_substr);
    $_ .= q{-} x ($hw - length($_)) for ($g_hex, $e_hex);

    $Test->diag(
      "$g_hex $g_substr",
      ($eq ? q{ = } : q{ ! }),
      "$e_hex $e_substr"
    );

    $seen_diffs++ unless $eq;
  }

  return;
}


1;

__END__

=pod

=head1 NAME

Test::BinaryData - compare two things, give hex dumps if they differ

=head1 VERSION

version 0.014

=head1 SYNOPSIS

  use Test::BinaryData;
  
  my $computed_data = do_something_complicated;
  my $expected_data = read_file('correct.data');

  is_binary(
    $computed_data,
    $expected_data,
    "basic data computation",
  );

=head1 DESCRIPTION

Sometimes using Test::More's C<is> test isn't good enough.  Its diagnostics may
make it easy to miss differences between strings.

For example, given two strings which differ only in their line endings, you can
end up with diagnostic output like this:

  not ok 1
  #   Failed test in demo.t at line 8.
  #          got: 'foo
  # bar
  # '
  #     expected: 'foo
  # bar
  # '

That's not very helpful, except to tell you that the alphanumeric characters
seem to be in the right place.  By using C<is_binary> instead of C<is>, this
output would be generated instead:

  not ok 2
  #   Failed test in demo.t at line 10.
  # have (hex)           have         want (hex)           want
  # 666f6f0a6261720a---- foo.bar.   ! 666f6f0d0a6261720d0a foo..bar..

The "!" tells us that the lines differ, and we can quickly scan the bytes that
make up the line to see which differ.

When comparing very long strings, we can stop after we've seen a few
differences.  Here, we'll just look for two:

  # have (hex)           have         want (hex)           want    
  # 416c6c20435220616e64 All CR and = 416c6c20435220616e64 All CR and
  # 206e6f204c46206d616b  no LF mak = 206e6f204c46206d616b  no LF mak
  # 6573204d616320612064 es Mac a d = 6573204d616320612064 es Mac a d
  # 756c6c20626f792e0d41 ull boy..A = 756c6c20626f792e0d41 ull boy..A
  # 6c6c20435220616e6420 ll CR and  = 6c6c20435220616e6420 ll CR and 
  # 6e6f204c46206d616b65 no LF make = 6e6f204c46206d616b65 no LF make
  # 73204d61632061206475 s Mac a du = 73204d61632061206475 s Mac a du
  # 6c6c20626f792e0d416c ll boy..Al ! 6c6c20626f792e0a416c ll boy..Al
  # 6c20435220616e64206e l CR and n = 6c20435220616e64206e l CR and n
  # 6f204c46206d616b6573 o LF makes = 6f204c46206d616b6573 o LF makes
  # 204d616320612064756c  Mac a dul = 204d616320612064756c  Mac a dul
  # 6c20626f792e0d416c6c l boy..All ! 6c20626f792e0a416c6c l boy..All
  # 20435220616e64206e6f  CR and no = 20435220616e64206e6f  CR and no
  # ...

=head1 FUNCTIONS

=head2 is_binary

  is_binary($have, $want, $comment, \%arg);

This test behaves like Test::More's C<is> test, but if the given data are not
string equal, the diagnostics emits four columns, describing the strings in
parallel, showing a simplified ASCII representation and a hexadecimal dump.

If C<$want> is an arrayref, it's treated as a sequence of strings giving hex
values for expected bytes.  For example, this is a passing test:

  is_binary(
    "Mumblefrotz",
    [ qw(4d75 6d62 6c65 6672 6f74 7a0a) ],
  );

Notice that each string in the sequence is broken into two-character pieces.
This makes this interface accept the kind of dumps produced by F<xxd> or
Test::BinaryData itself.

Between the got and expected data for each line, a "=" or "!" indicates whether
the chunks are identical or different.

The C<$comment> and C<%arg> arguments are optional.  Valid arguments are:

  columns   - the number of screen columns available
              if the COLUMNS environment variable is an positive integer, then
              COLUMNS - is used; otherwise, the default is 79

  max_diffs - if given, this is the maximum number of differing lines that will
              be compared; if output would have been given beyond this line, 
              it will be replaced with an elipsis ("...")

=head1 WARNING

This library is for comparing B<binary> data.  That is, B<byte strings>.
Often, in Perl 5, it is not clear whether a scalar contains a byte string or a
character strings.  You should use this library for comparing byte strings
only.  If either the "have" or "want" values contain wide characters -- that is,
characters that won't fit in one byte -- then the test will fail.

=head1 TODO

=over 4

=item *

optional position markers

     have (hex)       have       want (hex)       want
  00 46726f6d206d6169 From mai = 46726f6d206d6169 From mai
  08 3130353239406c6f 10529@lo = 3130353239406c6f 10529@lo
  16 63616c686f737420 calhost  = 63616c686f737420 calhost 
  24 5765642044656320 Wed Dec  = 5765642044656320 Wed Dec 
  32 31382031323a3037 18 12:07 = 31382031323a3037 18 12:07
  40 3a35352032303032 :55 2002 = 3a35352032303032 :55 2002
  48 0a52656365697665 .Receive ! 0d0a526563656976 ..Receiv

=item *

investigate probably bugs with wide chars, multibyte strings

I wrote this primarily for detecting CRLF problems, but it's also very useful
for dealing with encoded strings.

=back

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

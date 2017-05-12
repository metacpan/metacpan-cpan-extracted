package Regexp::Keep;

use 5.006;
use strict;
use warnings;
use overload;

require DynaLoader;

our @ISA = qw(DynaLoader);
our $VERSION = '0.02';

bootstrap Regexp::Keep $VERSION;

my %tr = (
  K => '.{0}(?{ Regexp::Keep::KEEP })',
);

sub import {
  overload::constant('qr' => sub {
    my $raw = shift;
    $raw =~ s/\\(\C)/$tr{$1} || "\\$1"/eg;
    return $raw;
  })
}

1;

__END__

=head1 NAME

Regexp::Keep - filter to allow the C<\K> escape in regexes

=head1 SYNOPSIS

  use Regexp::Keep;

  # slow and inefficient
  my $r = "abc.def.ghi.jkl";
  $r =~ s/(.*)\..*/$1/;

  # fast and efficient
  my $s = "abc.def.ghi.jkl";
  $s =~ s/.*\K\..*//;

=head1 DESCRIPTION

This allows you to use the C<\K> escape in your regexes, which fools the
regex engine into thinking it has only just started matching your regex.
This means you can turn the inefficient replace-with-itself construct

  s/(save)delete/$1/;

into the more efficient

  s/save\Kdelete//;

construct.

=head1 IMPLEMENTATION

What C<\K> filters into is C<.{0}(?{ Regexp::Keep::KEEP })>, which is an XS
function call embedded into the regex.  The function sets C<PL_regstartp[0]>
to the current location in the string.  This means that C<$&> now starts
where C<\K> is seen.  That means a replacement will begin being replaced
there.

=head1 EXAMPLES

Here's are short examples to show you the abilities of C<\K>:

  "alphabet" =~ /([^aeiou][a-z][aeiou])[a-z]/;
  # $1 is "pha", $& is "phab"

  "alphabet" =~ /\K([^aeiou][a-z][aeiou])[a-z]/;
  # $1 is "pha", $& is "phab"

  "alphabet" =~ /([^aeiou]\K[a-z][aeiou])[a-z]/;
  # $1 is "pha", $& is "hab"

  "alphabet" =~ /([^aeiou][a-z]\K[aeiou])[a-z]/;
  # $1 is "pha", $& is "ab"

  "alphabet" =~ /([^aeiou][a-z][aeiou])\K[a-z]/;
  # $1 is "pha", $& is "b"

  "alphabet" =~ /([^aeiou][a-z][aeiou])[a-z]\K/;
  # $1 is "pha", $& is ""

=head1 BUGS

I fixed a bug where C<\K> following a simple thing (like a letter that isn't
followed by a quantifier) didn't work properly.

If you're using this module, you don't have a version of Perl with the C<\K>
escape built-in.  Bummer.  I should try to make it built-in.

=head1 HISTORY

=over 4

=item 0.02

Fixed C</a\Kb/> to become C</a.{0}\Kb/>, which makes a nasty bug disappear.

=item 0.01

Original release.

=back

=head1 AUTHOR

Jeff C<japhy> Pinyan, F<japhy@pobox.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by japhy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut

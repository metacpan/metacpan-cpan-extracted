package Regexp::Profanity::US;
BEGIN {
  $Regexp::Profanity::US::VERSION = '4.112150';
}


use strict;
use warnings;
use Carp qw(croak confess);

use Regexp::Common qw/profanity_us/;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(profane profane_list);


my $RE = $RE{profanity}{us}{normal}{label}{-keep};

sub profane {
  my $word   = shift or confess 'must supply word to match';
  ( $word =~ /$RE/i )[0] || '0';
}

sub profane_list {
  my $word   = shift or confess 'must supply word to match';
  ( $word =~ /$RE/ig )
}

1;

__END__

=head1 NAME

Regexp::Profanity::US - Simple functions for detecting U.S. profanity

=head1 SYNOPSIS

  use Regexp::Profanity::US;

  my $degree  = 'definite'; # or 'ambiguous';

  my $profane = profane     ($string, $degree);
  my @profane = profane_list($string, $degree);

=head1 DESCRIPTION

This module provides an API for checking strings for strings containing
various degrees of profanity, per US standards.

=head1 FUNCTIONS

=head2 $profane_word = profane($string, $degree)

Check C<$string> for profanity of degree C<$degree>, where
$degree eq 'definite' or $degree eq 'ambiguous'

For positive matches, returns TRUE, with TRUE being the first match in the
string.

For negative matches, FALSE is returned.

=head2 @profane_word = profane_list($string, $degree)

The sub returns a list of all profane words found in C<$string>, or an
empty list if none were found.


=head1 EXPORT

C<profane()> and C<profane_list>

=head1 DEPENDENCIES

L<Regexp::Common|Regexp::Common> and
L<Regexp::Common::profanity_us|Regexp::Common::profanity_us>

=head1 OTHER

There is another module supporting profanity checking, namely
L<Regexp::Common::profanity|Regexp::Common::profanity>, but many
of the profane words were of European origin and I did not find
them profane at all from an American standpoint.

=head1 AUTHOR

T. M. Brannon, tbone@cpan.org

Refactored by Matthew Simon Cavalletto, evo@cpan.org.

=cut

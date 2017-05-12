package Sort::Key::Top;

our $VERSION = '0.08';

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( top
                     ltop
                     ntop
                     itop
                     utop
                     rtop
                     rltop
                     rntop
                     ritop
                     rutop
                     keytop
                     lkeytop
                     nkeytop
                     ikeytop
                     ukeytop
                     rkeytop
                     rlkeytop
                     rnkeytop
                     rikeytop
                     rukeytop
                     part
                     lpart
                     npart
                     ipart
                     upart
                     rpart
                     rlpart
                     rnpart
                     ripart
                     rupart
                     keypart
                     lkeypart
                     nkeypart
                     ikeypart
                     ukeypart
                     rkeypart
                     rlkeypart
                     rnkeypart
                     rikeypart
                     rukeypart
                     partref
                     lpartref
                     npartref
                     ipartref
                     upartref
                     rpartref
                     rlpartref
                     rnpartref
                     ripartref
                     rupartref
                     keypartref
                     lkeypartref
                     nkeypartref
                     ikeypartref
                     ukeypartref
                     rkeypartref
                     rlkeypartref
                     rnkeypartref
                     rikeypartref
                     rukeypartref
                     topsort
                     ltopsort
                     ntopsort
                     itopsort
                     utopsort
                     rtopsort
                     rltopsort
                     rntopsort
                     ritopsort
                     rutopsort
                     keytopsort
                     lkeytopsort
                     nkeytopsort
                     ikeytopsort
                     ukeytopsort
                     rkeytopsort
                     rlkeytopsort
                     rnkeytopsort
                     rikeytopsort
                     rukeytopsort
                     atpos
                     latpos
                     natpos
                     iatpos
                     uatpos
                     ratpos
                     rlatpos
                     rnatpos
                     riatpos
                     ruatpos
                     keyatpos
                     lkeyatpos
                     nkeyatpos
                     ikeyatpos
                     ukeyatpos
                     rkeyatpos
                     rlkeyatpos
                     rnkeyatpos
                     rikeyatpos
                     rukeyatpos
                     head
                     lhead
                     nhead
                     ihead
                     uhead
                     rhead
                     rlhead
                     rnhead
                     rihead
                     ruhead
                     keyhead
                     lkeyhead
                     nkeyhead
                     ikeyhead
                     ukeyhead
                     rkeyhead
                     rlkeyhead
                     rnkeyhead
                     rikeyhead
                     rukeyhead
                     tail
                     ltail
                     ntail
                     itail
                     utail
                     rtail
                     rltail
                     rntail
                     ritail
                     rutail
                     keytail
                     lkeytail
                     nkeytail
                     ikeytail
                     ukeytail
                     rkeytail
                     rlkeytail
                     rnkeytail
                     rikeytail
                     rukeytail
 );

for ((@EXPORT_OK)) {
    my $slot = $_;
    $slot =~ s/key/slot/ and
        push @EXPORT_OK, $slot;
}

require XSLoader;
XSLoader::load('Sort::Key::Top', $VERSION);

1;
__END__

=head1 NAME

Sort::Key::Top - select and sort top n elements

=head1 SYNOPSIS

  use Sort::Key::Top (nkeytop top);

  # select 5 first numbers by absolute value:
  @top = nkeytop { abs $_ } 5 => 1, 2, 7, 5, 5, 1, 78, 0, -2, -8, 2;
         # ==> @top = (1, 2, 1, 0, -2)

  # select 5 first numbers by absolute value and sort accordingly:
  @top = nkeytopsort { abs $_ } 5 => 1, 2, 7, 5, 5, 1, 78, 0, -2, -8, 2;
         # ==> @top = (0, 1, 1, 2, -2)

  # select 5 first words by lexicographic order:
  @a = qw(cat fish bird leon penguin horse rat elephant squirrel dog);
  @top = top 5 => @a;
         # ==> @top = qw(cat fish bird elephant dog);

=head1 DESCRIPTION

The functions available from this module select the top n elements from a list
using several common orderings and custom key extraction procedures.

They are all variations around

  keytopsort { CALC_KEY($_) } $n => @data;

In array context, this function calculates the ordering key for every
element in C<@data> using the expression inside the block. Then it
selects and orders the C<$n> elements with the lower keys when
compared lexicographically.

It is equivalent to the pure Perl expression:

  (sort { CALC_KEY($a) cmp CALC_KEY($b) } @data)[0 .. $n-1];

If $n is negative, the last C<$n> elements from the bottom are selected:

  topsort 3 => qw(foo doom me bar doz hello);
       # ==> ('bar', 'doz', 'doom')

  topsort -3 => qw(foo doom me bar doz hello);
       # ==> ('foo', 'hello', 'me')

  top 3 => qw(foo doom me bar doz hello);
       # ==> ('doom', 'bar', 'doz')

  top -3 => qw(foo doom me bar doz hello);
       # ==> ('foo', 'me', 'hello')

In scalar context, the value returned by the functions on this module
is the cutoff value allowing to select nth element from the
array. For instance:

  # n = 5;
  scalar(topsort 5 => @data) eq (sort @data)[4]    # true

  # n = -5;
  scalar(topsort -5 => @data) eq (sort @data)[-5]  # true

Note that on scalar context, the C<sort> variations (see below) are
usually the right choice:

  scalar topsort 3 => qw(me foo doz doom me bar hello); # ==> 'doz'

  scalar top 3 => qw(me foo doz doom me bar hello); # ==> 'bar'

Note also, that the index is 1-based (it starts at one instead of at
zero). The C<atpos> set of functions explained below do the same and
are 0-based.

Variations allow to:

=over 4

=item - use the own values as the ordering keys

  topsort 5 => qw(a b ab t uu g h aa aac);
     # ==> a aa aac ab b

=item - use an array or hash index instead of a subroutine to extract
the key

  slottop 0, 2, [4], [1], [3], [2], [4];
     # ==> [1], [2]

=item - return the selected values in the original order

  top 5 => qw(a b ab t uu g h aa aac);
     # ==> a b ab aa aac

=item - use a different ordering

For instance comparing the keys as numbers, using the locale
configuration or in reverse order:

  rnkeytop { length $_ } 3 => qw(a ab aa aac b t uu g h);
     # ==> ab aa aac

  rnkeytopsort { length $_ } 3 => qw(a ab aa aac b t uu g h);
     # ==> aac ab aa

A prefix is used to indicate the required ordering:

=over 4

=item (no prefix)

lexicographical ascending order

=item r

lexicographical descending order

=item l

lexicographical ascending order obeying locale configuration

=item r

lexicographical descending order obeying locale configuration

=item n

numerical ascending order

=item rn

numerical descending order

=item i

numerical ascending order but converting the keys to integers first

=item ri

numerical descending order but converting the keys to integers first

=item u

numerical ascending order but converting the keys to unsigned integers first

=item ru

numerical descending order but converting the keys to unsigned integers first

=back

=item - select the head element from the list sorted

  nhead 6, 7, 3, 8, 9, 9;
      # ==> 3

  nkeyhead { length $_ } qw(a ab aa aac b t uu uiyii)
      # ==> 'a'

=item - select the tail element from the list sorted

  tail qw(a ab aa aac b t uu uiyii);
      # ==> 'uu'

  nkeytail { length $_ } qw(a ab aa aac b t uu uiyii)
      # ==> 'uiyii'

=item - select the element at position n from the list sorted

  atpos 3, qw(a ab aa aac b t uu uiyii);
      # ==> 'ab';

  rnkeyatpos { abs $_ } 2 => -0.3, 1.1, 4, 0.1, 0.9, -2;
      # ==> 1.1

  rnkeyatpos { abs $_ } -2 => -0.3, 1.1, 4, 0.1, 0.9, -2;
      # ==> -0.3

Note that for the C<atpos> set of functions indexes start at zero.

=item - return a list composed by the elements with the first n
ordered keys and then the remaining ones.

  ikeypart { length $_ } 3 => qw(a bbbb cc ddddd g fd);
      # ==> a cc g bbbb ddddd fd

=item - return two arrays references, the first array containing the
elements with the first n ordered keys and the second with the rest.

  keypartref { length $_ } 3 => qw(a bbbb cc ddddd g fd);
      # ==> [a cc g] [bbbb ddddd fd]

=back


The full list of available functions is:

  top ltop ntop itop utop rtop rltop rntop ritop rutop

  keytop lkeytop nkeytop ikeytop ukeytop rkeytop rlkeytop rnkeytop
  rikeytop rukeytop

  slottop lslottop nslottop islottop uslottop rslottop rlslottop rnslottop
  rislottop ruslottop

  topsort ltopsort ntopsort itopsort utopsort rtopsort rltopsort
  rntopsort ritopsort rutopsort

  keytopsort lkeytopsort nkeytopsort ikeytopsort ukeytopsort
  rkeytopsort rlkeytopsort rnkeytopsort rikeytopsort rukeytopsort

  slottopsort lslottopsort nslottopsort islottopsort uslottopsort
  rslottopsort rlslottopsort rnslottopsort rislottopsort ruslottopsort

  head lhead nhead ihead uhead rhead rlhead rnhead rihead ruhead

  keyhead lkeyhead nkeyhead ikeyhead ukeyhead rkeyhead rlkeyhead
  rnkeyhead rikeyhead rukeyhead

  slothead lslothead nslothead islothead uslothead rslothead rlslothead
  rnslothead rislothead ruslothead

  tail ltail ntail itail utail rtail rltail rntail ritail rutail

  keytail lkeytail nkeytail ikeytail ukeytail rkeytail rlkeytail
  rnkeytail rikeytail rukeytail

  slottail lslottail nslottail islottail uslottail rslottail rlslottail
  rnslottail rislottail ruslottail

  atpos latpos natpos iatpos uatpos ratpos rlatpos rnatpos riatpos
  ruatpos

  keyatpos lkeyatpos nkeyatpos ikeyatpos ukeyatpos rkeyatpos
  rlkeyatpos rnkeyatpos rikeyatpos rukeyatpos

  slotatpos lslotatpos nslotatpos islotatpos uslotatpos rslotatpos
  rlslotatpos rnslotatpos rislotatpos ruslotatpos

  part lpart npart ipart upart rpart rlpart rnpart ripart
  rupart

  keypart lkeypart nkeypart ikeypart ukeypart rkeypart
  rlkeypart rnkeypart rikeypart rukeypart

  slotpart lslotpart nslotpart islotpart uslotpart rslotpart
  rlslotpart rnslotpart rislotpart ruslotpart


=head1 SEE ALSO

L<Sort::Key>, L<perlfunc/sort>.

L<Sort::Key::Top::PP> by Toby Inkster, provides a subset of the API of
Sort::Key::Top and is written in pure Perl.

The Wikipedia article about selection algorithms
L<http://en.wikipedia.org/wiki/Selection_algorithm>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008, 2011, 2012, 2014 by Salvador FandiE<ntilde>o
(sfandino@yahoo.com).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

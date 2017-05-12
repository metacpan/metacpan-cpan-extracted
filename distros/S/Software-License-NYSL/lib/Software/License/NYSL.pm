package Software::License::NYSL;

use utf8;
use strict;
use warnings;

# ABSTRACT: The "public-domain"-like NYSL license, version 0.9982
our $VERSION = 'v0.0.1'; # VERSION

use base qw(Software::License);

sub name { 'NYSL License, Version 0.9982' }
sub url  { 'http://www.kmonos.net/nysl/' }

sub meta_name  { 'unrestricted' }

1;

=pod

=head1 NAME

Software::License::NYSL - The "public-domain"-like NYSL license, version 0.9982

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

B<NYSL> means 'Niru nari Yaku nari Suki ni shiro License' in Japanese.
It is originally written by L<k.inaba|http://www.kmonos.net>.
Translated into English, it means like 'Do what you want'.
So, basic stance is similar as L<WTFPL|Software::License::WTFPL_2>.
However, threre are the following differences:

=over 4

=item *

"No warranty" disclaimer is explicitly included.

=item *

Modified version of the software MUST be distributed under the responsibility of the distributer.

=item *

Official version is written in Japanese.

=back

=head1 SEE ALSO

=over 4

=item *

L<Software::License>

=item *

L<http://www.kmonos.net/nysl>

=back

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__NOTICE__
This software is "Everyone'sWare", licensed under {{ $self->name }} by {{$self->holder}}.
__LICENSE__
NYSL Version 0.9982
----------------------------------------

A. 本ソフトウェアは Everyone'sWare です。このソフトを手にした一人一人が、
   ご自分の作ったものを扱うのと同じように、自由に利用することが出来ます。

  A-1. フリーウェアです。作者からは使用料等を要求しません。
  A-2. 有料無料や媒体の如何を問わず、自由に転載・再配布できます。
  A-3. いかなる種類の 改変・他プログラムでの利用 を行っても構いません。
  A-4. 変更したものや部分的に使用したものは、あなたのものになります。
       公開する場合は、あなたの名前の下で行って下さい。

B. このソフトを利用することによって生じた損害等について、作者は
   責任を負わないものとします。各自の責任においてご利用下さい。

C. 著作者人格権は {{$self->holder}} に帰属します。著作権は放棄します。

D. 以上の３項は、ソース・実行バイナリの双方に適用されます。



NYSL Version 0.9982 (en) (Unofficial)
----------------------------------------
A. This software is "Everyone'sWare". It means:
  Anybody who has this software can use it as if he/she is
  the author.

  A-1. Freeware. No fee is required.
  A-2. You can freely redistribute this software.
  A-3. You can freely modify this software. And the source
      may be used in any software with no limitation.
  A-4. When you release a modified version to public, you
      must publish it with your name.

B. The author is not responsible for any kind of damages or loss
  while using or misusing this software, which is distributed
  "AS IS". No warranty of any kind is expressed or implied.
  You use AT YOUR OWN RISK.

C. Copyrighted to {{$self->holder}}

D. Above three clauses are applied both to source and binary
  form of this software.

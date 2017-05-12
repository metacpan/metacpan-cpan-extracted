#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most tests => 4;

use Pod::Parser::Groffmom;

ok my $parser = Pod::Parser::Groffmom->new,
  'We should be able to create a new parser';
my $file = 't/test_pod.pod';
open my $fh, '<', $file or die "Cannot open ($file) for reading: $!";

can_ok $parser, 'parse_from_filehandle';
warning_like { $parser->parse_from_filehandle($fh) }
    qr/^Found \Q(=item * Second item)\E outside of list at line \d+/,
    '... and it should parse the file with a warning a bad =item';
eq_or_diff $parser->mom, get_mom(),
    '... and it should render the correct mom';

sub get_mom {
    my $mom = <<'END_MOM';
.TITLE "Some Doc"
.SUBTITLE "Some subtitle"
.AUTHOR "Curtis \[dq]Ovid\[dq] Poe"
.COPYRIGHT "2009, Some company"
.COVER TITLE SUBTITLE AUTHOR COPYRIGHT
.PRINTSTYLE TYPESET
\#
.FAM H
.PT_SIZE 12
\#
.NEWCOLOR Alert        RGB #0000ff
.NEWCOLOR BaseN        RGB #007f00
.NEWCOLOR BString      RGB #c9a7ff
.NEWCOLOR Char         RGB #ff00ff
.NEWCOLOR Comment      RGB #7f7f7f
.NEWCOLOR DataType     RGB #0000ff
.NEWCOLOR DecVal       RGB #00007f
.NEWCOLOR Error        RGB #ff0000
.NEWCOLOR Float        RGB #00007f
.NEWCOLOR Function     RGB #007f00
.NEWCOLOR IString      RGB #ff0000
.NEWCOLOR Operator     RGB #ffa500
.NEWCOLOR Others       RGB #b03060
.NEWCOLOR RegionMarker RGB #96b9ff
.NEWCOLOR Reserved     RGB #9b30ff
.NEWCOLOR String       RGB #ff0000
.NEWCOLOR Variable     RGB #0000ff
.NEWCOLOR Warning      RGB #0000ff

.START
.HEAD "This is an attempt to generate a groff_mom file"

.SUBHEAD "This is another subheader"

We want POD text to \f[I]automatically\f[P] be converted to the correct format.

.L_MARGIN 1.25i
.LIST BULLET
.ITEM
First item
.ITEM
Second item
.LIST END

.L_MARGIN 1i
.NEWPAGE
.SUBHEAD "Verbatim sample"

.FAM C
.PT_SIZE 10
.LEFT
.L_MARGIN 1.25i
 If at first you don't succeed ...
 :wq
.QUAD
.L_MARGIN 1i
.FAM H
.PT_SIZE 12

.SUBHEAD "This is a \[dq]subheader"

This is a paragraph

.SUBHEAD "Code sample"

.FAM C
.PT_SIZE 10
.LEFT
.L_MARGIN 1.25i
 ok \f[B]my\f[P] \*[DataType]$parser\*[black] = \*[Function]Pod::Parser\*[black]::\*[Function]Groffmom\*[black]->new,
   \*[Operator]'\*[black]\*[String]We should be able to create a new parser\*[black]\*[Operator]'\*[black];
 \f[B]my\f[P] \*[DataType]$file\*[black] = \*[Operator]'\*[black]\*[String]t/test_pod.pod\*[black]\*[Operator]'\*[black];
 \*[Function]open\*[black] \f[B]my\f[P] \*[DataType]$fh\*[black], \*[Operator]'\*[black]\*[String]<\*[black]\*[Operator]'\*[black], \*[DataType]$file\*[black] \*[Operator]or\*[black] \*[Function]die\*[black] \*[Operator]"\*[black]\*[String]Cannot open (\*[black]\*[DataType]$file\*[black]\*[String]) for reading: \*[black]\*[Variable]\f[B]$!\f[P]\*[black]\*[Operator]"\*[black];
.QUAD
.L_MARGIN 1i
.FAM H
.PT_SIZE 12

.FAM C
.PT_SIZE 10
.LEFT
.L_MARGIN 1.25i
 can_ok \*[DataType]$parser\*[black], \*[Operator]'\*[black]\*[String]parse_from_filehandle\*[black]\*[Operator]'\*[black];
 warning_like { \*[DataType]$parser\*[black]->\*[DataType]parse_from_filehandle\*[black](\*[DataType]$fh\*[black]) }
     \*[Operator]qr/\*[black]\*[Char]^\*[black]\*[Others]Found \*[black]\*[Char]\\Q(\*[black]\*[Others]=item \*[black]\*[Char]*\*[black]\*[Others] Second item\*[black]\*[Char])\\E\*[black]\*[Others] outside of list at line \*[black]\*[BaseN]\\d\*[black]\*[Char]+\*[black]\*[Operator]/\*[black],
     \*[Operator]'\*[black]\*[String]... and it should parse the file with a warning a bad =item\*[black]\*[Operator]'\*[black];
 is \*[DataType]$parser\*[black]->\*[DataType]mom\*[black], get_mom(),
     \*[Operator]'\*[black]\*[String]... and it should render the correct mom\*[black]\*[Operator]'\*[black];
.QUAD
.L_MARGIN 1i
.FAM H
.PT_SIZE 12

Test name is Salvador Fandi\N'241'o

.TOC
END_MOM
}

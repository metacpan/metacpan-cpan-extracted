#!/usr/bin/env perl

use strict;
use warnings;

use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Weaver::Plugin::Ditaa;

my $str = do { local $/; <DATA> };

my $doc = Pod::Elemental->read_string($str);

Pod::Elemental::Transformer::Pod5->new->transform_node($doc);
Pod::Elemental::Transformer::Ditaa->new->transform_node($doc);

print $doc->as_pod_string;

__DATA__
=pod

=begin ditaa

    +--------+   +-------+    +-------+
    |        | --+ ditaa +--> |       |
    |  Text  |   +-------+    |diagram|
    |Document|   |!magic!|    |       |
    |     {d}|   |       |    |       |
    +---+----+   +-------+    +-------+
        :                         ^
        |       Lots of work      |
        +-------------------------+

=end ditaa

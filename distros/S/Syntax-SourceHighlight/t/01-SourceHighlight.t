#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 1;

use Syntax::SourceHighlight;

my $lm = Syntax::SourceHighlight::LangMap->new();
my $hl = Syntax::SourceHighlight->new();

ok( $hl->highlightString( 'my $_ = 42;', $lm->getMappedFileName('perl') ),
    'String highlighting functionality' );

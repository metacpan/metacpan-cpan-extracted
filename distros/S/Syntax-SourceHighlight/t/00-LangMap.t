#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 2;

use Syntax::SourceHighlight;

my $lm = Syntax::SourceHighlight::LangMap->new();
my $lang;

ok( $lang = $lm->getMappedFileName('perl'),
    'Language name mapping and presence of Perl language definition' );

ok(
    $lang eq $lm->getMappedFileNameFromFileName('./test.perl'),
    'File name mapping and consistency with language name mapping'
);

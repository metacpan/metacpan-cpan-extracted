#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 1;

use Syntax::SourceHighlight;

my $lm = Syntax::SourceHighlight::LangMap->new();
my $hl = Syntax::SourceHighlight->new();

my $nvars;

$hl->setHighlightEventListener(
    sub {
        my ($evt) = @_;

        $nvars++
          if (  $evt->type == $Syntax::SourceHighlight::HighlightEvent::FORMAT
            and $evt->token->matched->[0] =~ m/^variable:/ );
    }
);

$hl->highlightString( 'my $x = 42; return $x * $x;',
    $lm->getMappedFileName('perl') );

ok( $nvars == 3, 'Event counting' );

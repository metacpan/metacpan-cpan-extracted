#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::Simple tests => 6;

use Syntax::SourceHighlight;

my $lm = Syntax::SourceHighlight::LangMap->new();
my $hl = Syntax::SourceHighlight->new();

my $code = 'my $_ = "%%% E = m𝑐² %%%";';
my ( $output, $suffix, $matched );

$hl->setHighlightEventListener(
    sub {
        my $e = shift;
        return
          unless $e->type == $Syntax::SourceHighlight::HighlightEvent::FORMAT;
        $suffix = $1 if $e->token->{suffix} =~ m/%%% (.*?) %%%/s;
        $matched = $1
          if $e->token->{matched}->[0]
          and $e->token->{matched}->[0] =~ m/^string:"%%% (.*) %%%"/s;
    }
);

$output = $hl->highlightString( $code, $lm->getMappedFileName('perl') );
$output =~ s/^.*%%% (.*?) %%%.*$/$1/s;
ok( length($output) == 7,  'highlightString() UTF-8' );
ok( length($suffix) == 7,  'highlightEvent->{suffix}' );
ok( length($matched) == 7, 'highlightEvent->{matched}' );

utf8::encode($code);
$output = $hl->highlightString( $code, $lm->getMappedFileName('perl') );
$output =~ s/^.*%%% (.*?) %%%.*$/$1/s;
ok( length($output) == 11, 'highlightString() binary' );
ok( length($suffix) == 7,  'highlightEvent->{suffix}' );
ok( length($matched) == 7, 'highlightEvent->{matched}' );

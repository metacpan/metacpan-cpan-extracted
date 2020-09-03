#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

my $dh = select(*STDOUT);
$| = 1;
select(*STDERR);
$| = 1;
select($dh);

use FindBin;
use Syntax::SourceHighlight;

my $hl = Syntax::SourceHighlight->new('esc.outlang');

my ( $isfile, $in ) = do {
    if ( not @ARGV or $ARGV[0] eq '-f' ) {
        ( 1, $ARGV[1] // $FindBin::Script );
    }
    elsif ( $ARGV[0] eq '-s' ) {
        die "No source specified" unless ( defined $ARGV[1] );
        ( 0, $ARGV[1] );
    }
    else {
        die
          "First parameter should be -f for file input or -s for string input";
    }
};

my $lang = eval {
    my $lm = Syntax::SourceHighlight::LangMap->new();

    if ( $ARGV[2] ) {
        $lm->getMappedFileName( $ARGV[2] );
    }
    elsif ($isfile) {
        $lm->getMappedFileNameFromFileName($in);
    }
    else {
        die "Language cannot be guessed";
    }
};
unless ($lang) {
    warn "Problems determining source language, assuming Perl: $@";
    $lang = 'perl.lang';
}

my $nvars = 0;
my $cvars = 0;

$hl->setHighlightEventListener(
    sub {
        my ($evt) = @_;

        if (    $evt->type == $Syntax::SourceHighlight::HighlightEvent::FORMAT
            and $evt->token->matched->[0] =~ m/^variable:/ )
        {
            $nvars++;
            $cvars += $evt->token->matchedSize;
        }
    }
);

if ($isfile) {
    $hl->highlightFile( $in, '', $lang );
}
else {
    say $hl->highlightString( $in, $lang );
}

say
"The program contained $nvars variable references occupying $cvars source characters.";

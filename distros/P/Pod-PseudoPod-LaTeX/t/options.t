#! perl

use strict;
use warnings;

use Test::More tests => 5;
use IO::String;
use File::Spec::Functions;

use_ok('Pod::PseudoPod::LaTeX') or exit;

subtest "default options" => sub {
    plan tests => 3;

    my $parser = Pod::PseudoPod::LaTeX->new();
    ok !$parser->{'keep_ligatures'}, "default keep_ligatures value";
    ok !$parser->{'captions_below'}, "default captions_below value";
    ok !$parser->{'full'},           "default full value";
};

subtest "set options explicitly" => sub {
    plan tests => 3;

    my $parser = Pod::PseudoPod::LaTeX->new(
        keep_ligatures => 1,
        captions_below => 1,
        full           => 1,
    );
    ok $parser->{'keep_ligatures'}, "keep_ligatures turned on";
    ok $parser->{'captions_below'}, "captions_below turned on";
    ok $parser->{'full'},           "full option turned on";
};

subtest "full option produces standalone document elements" => sub {
    plan tests => 4;

    my $fh = IO::String->new();
    my $parser = Pod::PseudoPod::LaTeX->new( full => 1 );
    $parser->output_fh($fh);
    $parser->parse_file( catfile(qw( t test_file.pod )) );

    $fh->setpos(0);
    my $text = join( '', <$fh> );

    like(
        $text,
        qr/\\documentclass\[12pt,a4paper\]\{book}/,
        "standard document class defined"
    );
    like(
        $text,
        qr/
            \\usepackage\{fancyvrb}\s+
            \\usepackage\{url}\s+
            \\usepackage\{titleref}\s+
            \\usepackage\[T1\]\{fontenc}\s+
            \\usepackage\{textcomp}
        /x,
        "base packages package used"
    );
    like( $text, qr/\\begin\{document}/, "document is begun" );
    like( $text, qr/\\end\{document}/,   "document is ended" );
};

subtest "full option disabled does not produce standalone elements" => sub {
    plan tests => 4;

    my $fh = IO::String->new();
    my $parser = Pod::PseudoPod::LaTeX->new( full => 0 );
    $parser->output_fh($fh);
    $parser->parse_file( catfile(qw( t test_file.pod )) );

    $fh->setpos(0);
    my $text = join( '', <$fh> );

    unlike(
        $text,
        qr/\\documentclass\[12pt,a4paper\]\{book}/,
        "standard document class not defined"
    );
    unlike( $text, qr/\\usepackage/,      "no packages are used" );
    unlike( $text, qr/\\begin\{document}/, "document is not begun" );
    unlike( $text, qr/\\end\{document}/,   "document is not ended" );
};

# vim: expandtab shiftwidth=4

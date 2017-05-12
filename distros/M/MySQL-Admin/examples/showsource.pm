package showsource;
use strict;
use warnings;
require Exporter;
use vars qw($color_Keys $formatter $perldoc_Keys @EXPORT @ISA );
@ISA                = qw(Exporter);
@showsource::EXPORT = qw(showSource);
use Syntax::Highlight::Engine::Kate;

sub showSource {

    my $hl = new Syntax::Highlight::Engine::Kate(
        language      => "Perl",
        substitutions => {
            "<" => "&lt;",
            ">" => "&gt;",
            "&" => "&amp;",

        },
        format_table => {
             Alert    => [ "<font color=\"#0000ff\">",    "</font>" ],
             BaseN    => [ "<font color=\"#007f00\">",    "</font>" ],
             BString  => [ "<font color=\"#c9a7ff\">",    "</font>" ],
             Char     => [ "<font color=\"#ff00ff\">",    "</font>" ],
             Comment  => [ "<font color=\"#7f7f7f\"><i>", "</i></font>" ],
             DataType => [ "<font color=\"#0000ff\">",    "</font>" ],
             DecVal   => [ "<font color=\"#00007f\">",    "</font>" ],
             Error => [ "<font color=\"#ff0000\"><b><i>", "</i></b></font>" ],
             Float => [ "<font color=\"#00007f\">",       "</font>" ],
             Function     => [ "<font color=\"#007f00\">",    "</font>" ],
             IString      => [ "<font color=\"#ff0000\">",    "" ],
             Keyword      => [ "<b>",                         "</b>" ],
             Normal       => [ "",                            "" ],
             Operator     => [ "<font color=\"#ffa500\">",    "</font>" ],
             Others       => [ "<font color=\"#b03060\">",    "</font>" ],
             RegionMarker => [ "<font color=\"#96b9ff\"><i>", "</i></font>" ],
             Reserved     => [ "<font color=\"#9b30ff\"><b>", "</b></font>" ],
             String       => [ "<font color=\"#ff0000\">",    "</font>" ],
             Variable     => [ "<font color=\"#0000ff\"><b>", "</b></font>" ],
             Warning =>
                 [ "<font color=\"#0000ff\"><b><i>", "</b></i></font>" ],
        },
    );

    my ( $m_sFile, $out ) = @_;
    open( IN, "$m_sFile" ) or die "$!: $m_sFile";
    my @lines;
    while (<IN>) {
        $_ =~ s|#!/usr/bin/perl ?-?w?||;
        push @lines, $_;
    }
    print
        q(<div  align="center"><div align="left" style="width:600px;overflow:auto;"><pre>)
        . $hl->highlightText("@lines")
        . "</pre></div></div>";
    print $@ if $@;
}

1;

#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(../lib lib);
use Syntax::Highlight::CSS;

my $CSS =<<'END';
@charset 'UTF-8';
@import 'bar.css';
* { margin: 0; padding: 0; }
@media screen {
    a:hover { font-weight: bold; }
}
/* just an example */
END

print print_css_coloring();

my $p = Syntax::Highlight::CSS->new(nnn=>1);
print $p->parse($CSS);


sub print_css_coloring {
    return <<'END';
    <style type="text/css">
    .css-code {
        font-family: 'DejaVu Sans Mono Book', monospace;
        color: #000;
        background: #fff;
    }
        .ch-sel, .ch-p, .ch-v, .ch-ps, .ch-at {
            font-weight: bold;
        }
        .ch-sel { color: #007; } /* Selectors */
        .ch-com {                /* Comments */
            font-style: italic;
            color: #777;
        }
        .ch-p {                  /* Properties */
            font-weight: bold;
            color: #000;
        }
        .ch-v {                  /* Values */
            font-weight: bold;
            color: #880;
        }
        .ch-ps {                /* Pseudo-selectors and Pseudo-elements */
            font-weight: bold;
            color: #11F;
        }
        .ch-at {                /* At-rules */
            font-weight: bold;
            color: #955;
        }
        .ch-n {
            color: #888;
        }
    </style>
END
}

__END__



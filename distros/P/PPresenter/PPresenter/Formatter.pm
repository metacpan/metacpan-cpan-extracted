# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Formatter;

use strict;
use PPresenter::StyleElem;
use base 'PPresenter::StyleElem';

use constant ObjDefaults =>
{ type         => 'formatter'
, -nestIndents => [ [ '+0', '10%'  ]
                  , [ '+0', '17%'  ]
                  , [ '-1', '23%'  ]
                  , [ '+0', '28%'  ] ]
 
, -lineSkip    => 0.4    # an empty line.
, -listSkip    => 0.3    # above each list-item.
, -imageHSpace => '10%'
, -imageVSpace => '10%'
};

#
# strip
#    Remove all formatting info from the string.
#

sub strip($$$)
{   my ($former, $show, $slide, $string) = @_;

    warn "WARNING: formatter ", ref $former, " does not implement strip.\n";
    return $string;
}

#
# To be extended by all implementations.
#

sub prepareSlide($$)
{   my ($former, $slide, $view) = @_;
    die "Formatter " .$former->{-name} . " must implement prepareSlide()\n";
}

sub createSlide($$$$)
{   my ($former, $show, $slide, $view, $dx) = @_;
    die "Formatter " .$former->{-name} . " must implement createSlide()\n";
}

#
# Information about nesting of lists.
#

sub nestInfo($$)
{   my ($former, $view, $nest) = @_;
    my $nr_nests = @{$former->{-nestIndents}};
    my $takenest = $nest > $nr_nests ? $nr_nests : $nest;

    (@{$former->{-nestIndents}[$takenest]}, $view->nestImage($nest));
}

1;

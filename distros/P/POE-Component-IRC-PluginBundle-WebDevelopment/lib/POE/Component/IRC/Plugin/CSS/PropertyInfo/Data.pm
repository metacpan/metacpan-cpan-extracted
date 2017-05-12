package POE::Component::IRC::Plugin::CSS::PropertyInfo::Data;

use strict;
use warnings;

our $VERSION = '2.001003'; # VERSION

sub _make_property_data;
sub _make_vt_data;

sub _make_property_data {
    return (
    'azimut' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#center#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#<angle> | [[ left-side | far-left | left | center-left | center | center-right | right | far-right | right-side ] || behind ] | leftwards | rightwards | inherit#,
    },
    'background' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#see individual properties#,
        media       => q#visual#,
        percentages => q#allowed on `background-position`#,
        values      => q#['background-color' || 'background-image' || 'background-repeat' || 'background-attachment' || 'background-position'] | inherit#,
    },
    'background-attachment' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#scroll#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#scroll | fixed | inherit#,
    },
    'background-color' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#transparent#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<color> | transparent | inherit#,
    },
    'background-image' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#none#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<uri> | none | inherit#,
    },
    'background-position' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#0% 0%#,
        media       => q#visual#,
        percentages => q#refer to the size of the box itself#,
        values      => q#[ [ <percentage> | <length> | left | center | right ] [ <percentage> | <length> | top | center | bottom ]? ] | [ [ left | center | right ] || [ top | center | bottom ] ] | inherit#,
    },
    'background-repeat' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#repeat#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#repeat | repeat-x | repeat-y | no-repeat | inherit#,
    },
    'border' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#see individual properties#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#[ <border-width> || <border-style> || 'border-top-color' ] | inherit#,
    },
    'border-bottom' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#see individual properties#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#[ <border-width> || <border-style> || 'border-top-color' ] | inherit#,
    },
    'border-bottom-color' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#the value of the 'color' property#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<color> | transparent | inherit#,
    },
    'border-bottom-style' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#none#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<border-style> | inherit#,
    },
    'border-bottom-width' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#medium#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<border-width> | inherit#,
    },
    'border-collapse' => {
        applies_to  => q#'table' and 'inline-table' elements#,
        inherited   => q#yes#,
        initial     => q#separate#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#collapse | separate | inherit#,
    },
    'border-color' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#see individual properties#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#[ <color> | transparent ]{1,4} | inherit#,
    },
    'border-left' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#see individual properties#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#[ <border-width> || <border-style> || 'border-top-color' ] | inherit#,
    },
    'border-left-color' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#the value of the 'color' property#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<color> | transparent | inherit#,
    },
    'border-left-style' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#none#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<border-style> | inherit#,
    },
    'border-left-width' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#medium#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<border-width> | inherit#,
    },
    'border-right' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#see individual properties#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#[ <border-width> || <border-style> || 'border-top-color' ] | inherit#,
    },
    'border-right-color' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#the value of the 'color' property#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<color> | transparent | inherit#,
    },
    'border-right-style' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#none#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<border-style> | inherit#,
    },
    'border-right-width' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#medium#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<border-width> | inherit#,
    },
    'border-spacing' => {
        applies_to  => q#'table' and 'inline-table' elements #,
        inherited   => q#yes#,
        initial     => q#0#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<length> <length>? | inherit#,
    },
    'border-style' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#see individual properties#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<border-style>{1,4} | inherit#,
    },
    'border-top' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#see individual properties#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#[ <border-width> || <border-style> || 'border-top-color' ] | inherit#,
    },
    'border-top-color' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#the value of the 'color' property#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<color> | transparent | inherit#,
    },
    'border-top-style' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#none#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<border-style> | inherit#,
    },
    'border-top-width' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#medium#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<border-width> | inherit#,
    },
    'border-width' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#see individual properties#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<border-width>{1,4} | inherit#,
    },
    'bottom' => {
        applies_to  => q#positioned elements#,
        inherited   => q#no#,
        initial     => q#auto#,
        media       => q#visual#,
        percentages => q#refer to height of containing block#,
        values      => q#<length> | <percentage> | auto | inherit#,
    },
    'caption-side' => {
        applies_to  => q#'table-caption' elements#,
        inherited   => q#yes#,
        initial     => q#top#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#top | bottom | inherit#,
    },
    'clear' => {
        applies_to  => q#block-level elements#,
        inherited   => q#no#,
        initial     => q#none#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#none | left | right | both | inherit#,
    },
    'color' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#depends on user agent#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<color> | inherit#,
    },
    'content' => {
        applies_to  => q#:before and :after pseudo-elements#,
        inherited   => q#no#,
        initial     => q#normal#,
        media       => q#all elements#,
        percentages => q#N/A#,
        values      => q#normal | none | [ <string> | <uri> | <counter> | attr(<identifier>) | open-quote | close-quote | no-open-quote | no-close-quote ]+ | inherit#,
    },
    'counter-increment' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#none#,
        media       => q#all elements#,
        percentages => q#N/A#,
        values      => q#[ <identifier> <integer>? ]+ | none | inherit#,
    },
    'counter-reset' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#none#,
        media       => q#all elements#,
        percentages => q#N/A#,
        values      => q#[ <identifier> <integer>? ]+ | none | inherit#,
    },
    'cue' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#see individual properties#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#[ 'cue-before' || 'cue-after' ] | inherit#,
    },
    'cue-after' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#none#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q# <uri> | none | inherit#,
    },
    'cue-before' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#none#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#<uri> | none | inherit#,
    },
    'cursor' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#auto#,
        media       => q#visual, interactive#,
        percentages => q#N/A#,
        values      => q#[ [<uri> ,]* [ auto | crosshair | default | pointer | move | e-resize | ne-resize | nw-resize | n-resize | se-resize | sw-resize | s-resize | w-resize | text | wait | help | progress ] ] | inherit#,
    },
    'direction' => {
        applies_to  => q#all elements, but see prose ( http://w3.org/TR/CSS21/visuren.html\#propdef-direction )#,
        inherited   => q#yes#,
        initial     => q#ltr#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#ltr | rtl | inherit#,
    },
    'display' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#inline#,
        media       => q#all elements#,
        percentages => q#N/A#,
        values      => q#inline | block | list-item | run-in | inline-block | table | inline-table | table-row-group | table-header-group | table-footer-group | table-row | table-column-group | table-column | table-cell | table-caption | none | inherit#,
    },
    'elevation' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#level#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#<angle> | below | level | above | higher | lower | inherit#,
    },
    'empty-cells' => {
        applies_to  => q#'table-cell' elements#,
        inherited   => q#yes#,
        initial     => q#show#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#show | hide | inherit#,
    },
    'float' => {
        applies_to  => q#all, but see http://www.w3.org/TR/CSS21/visuren.html\#dis-pos-flo#,
        inherited   => q#no#,
        initial     => q#none#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#left | right | none | inherit#,
    },
    'font' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#see individual properties#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#[ [ 'font-style' || 'font-variant' || 'font-weight' ]? 'font-size' [ / 'line-height' ]? 'font-family' ] | caption | icon | menu | message-box | small-caption | status-bar | inherit#,
    },
    'font-family' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#depends on user agent#,
        media       => q#visual#,
        percentages => q#refer to parent element's font size#,
        values      => q#[[ <family-name> | <generic-family> ] [, <family-name>| <generic-family>]* ] | inherit#,
    },
    'font-size' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#medium#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<absolute-size> | <relative-size> | <length> | <percentage> | inherit#,
    },
    'font-style' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#normal#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#normal | italic | oblique | inherit#,
    },
    'font-variant' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#normal#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#normal | small-caps | inherit#,
    },
    'font-weight' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#normal#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#normal | bold | bolder | lighter | 100 | 200 | 300 | 400 | 500 | 600 | 700 | 800 | 900 | inherit#,
    },
    'height' => {
        applies_to  => q#all elements but non-replaced inline elements, table columns, and column groups#,
        inherited   => q#no#,
        initial     => q#auto#,
        media       => q#visual#,
        percentages => q#see prose ( http://w3.org/TR/CSS21/visudet.html\#propdef-height )#,
        values      => q#<length> | <percentage> | auto | inherit#,
    },
    'left' => {
        applies_to  => q#positioned elements#,
        inherited   => q#no#,
        initial     => q#auto#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<length> | <percentage> | auto | inherit#,
    },
    'letter-spacing' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#normal#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#normal | <length> | inherit#,
    },
    'line-height' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#normal#,
        media       => q#visual#,
        percentages => q#refer to the font size of the element itself#,
        values      => q#normal | <number> | <length> | <percentage> | inherit#,
    },
    'list-style' => {
        applies_to  => q#elements with 'display: list-item'#,
        inherited   => q#yes#,
        initial     => q#see individual properties#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#[ 'list-style-type' || 'list-style-position' || 'list-style-image' ] | inherit#,
    },
    'list-style-image' => {
        applies_to  => q#elements with 'display: list-item'#,
        inherited   => q#yes#,
        initial     => q#none#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#<uri> | none | inherit#,
    },
    'margin' => {
        applies_to  => q#all elements except elements with table display types other than table-caption, table and inline-table#,
        inherited   => q#no#,
        initial     => q#see individual properties#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<margin-width>{1,4} | inherit#,
    },
    'margin-bottom' => {
        applies_to  => q#all elements except elements with table display types other than table-caption, table and inline-table#,
        inherited   => q#no#,
        initial     => q#0#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<margin-width> | inherit#,
    },
    'margin-left' => {
        applies_to  => q#all elements except elements with table display types other than table-caption, table and inline-table#,
        inherited   => q#no#,
        initial     => q#0#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<margin-width> | inherit#,
    },
    'margin-right' => {
        applies_to  => q#all elements except elements with table display types other than table-caption, table and inline-table#,
        inherited   => q#no#,
        initial     => q#0#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<margin-width> | inherit#,
    },
    'margin-top' => {
        applies_to  => q#all elements except elements with table display types other than table-caption, table and inline-table#,
        inherited   => q#no#,
        initial     => q#0#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<margin-width> | inherit#,
    },
    'max-height' => {
        applies_to  => q#all elements but non-replaced inline elements, table columns, and column groups#,
        inherited   => q#no#,
        initial     => q#none#,
        media       => q#visual#,
        percentages => q#see prose ( http://w3.org/TR/CSS21/visudet.html\#propdef-max-height )#,
        values      => q#<length> | <percentage> | none | inherit#,
    },
    'max-width' => {
        applies_to  => q#all elements but non-replaced inline elements, table rows, and row groups#,
        inherited   => q#no#,
        initial     => q#none#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<length> | <percentage> | none | inherit#,
    },
    'min-height' => {
        applies_to  => q#all elements but non-replaced inline elements, table columns, and column groups#,
        inherited   => q#no#,
        initial     => q#0#,
        media       => q#visual#,
        percentages => q#see prose ( http://w3.org/TR/CSS21/visudet.html\#propdef-min-height )#,
        values      => q#<length> | <percentage> | inherit#,
    },
    'min-width' => {
        applies_to  => q#all elements but non-replaced inline elements, table rows, and row groups#,
        inherited   => q#no#,
        initial     => q#0#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<length> | <percentage> | inherit#,
    },
    'orphans' => {
        applies_to  => q#block-level elements#,
        inherited   => q#yes#,
        initial     => q#2#,
        media       => q#visual, paged#,
        percentages => q#N/A#,
        values      => q#<integer> | inherit#,
    },
    'outline' => {
        applies_to  => q#see individual properies#,
        inherited   => q#no#,
        initial     => q#see individual properties#,
        media       => q#visual, interactive#,
        percentages => q#N/A#,
        values      => q#[ 'outline-color' || 'outline-style' || 'outline-width' ] | inherit#,
    },
    'outline-color' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#invert#,
        media       => q#visual, interactive#,
        percentages => q#N/A#,
        values      => q#<color> | invert | inherit#,
    },
    'outline-style' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#none#,
        media       => q#visual, interactive#,
        percentages => q#N/A#,
        values      => q#<border-style> | inherit#,
    },
    'outline-width' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#medium#,
        media       => q#visual, interactive#,
        percentages => q#N/A#,
        values      => q#<border-width> | inherit#,
    },
    'overflow' => {
        applies_to  => q#non-replaced block-level elements, table cells, and inline-block elements#,
        inherited   => q#no#,
        initial     => q#visible#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#visible | hidden | scroll | auto | inherit#,
    },
    'padding' => {
        applies_to  => q#all elements except table-row-group, table-header-group, table-footer-group, table-row, table-column-group and table-column#,
        inherited   => q#no#,
        initial     => q#see individual properties#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<padding-width>{1,4} | inherit#,
    },
    'padding-bottom' => {
        applies_to  => q#all elements except table-row-group, table-header-group, table-footer-group, table-row, table-column-group and table-column#,
        inherited   => q#no#,
        initial     => q#0#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<padding-width> | inherit#,
    },
    'padding-left' => {
        applies_to  => q#all elements except table-row-group, table-header-group, table-footer-group, table-row, table-column-group and table-column#,
        inherited   => q#no#,
        initial     => q#0#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<padding-width> | inherit#,
    },
    'padding-right' => {
        applies_to  => q#all elements except table-row-group, table-header-group, table-footer-group, table-row, table-column-group and table-column#,
        inherited   => q#no#,
        initial     => q#0#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<padding-width> | inherit#,
    },
    'padding-top' => {
        applies_to  => q#all elements except table-row-group, table-header-group, table-footer-group, table-row, table-column-group and table-column#,
        inherited   => q#no#,
        initial     => q#0#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<padding-width> | inherit#,
    },
    'page-break-after' => {
        applies_to  => q#block-level elements#,
        inherited   => q#no#,
        initial     => q#auto#,
        media       => q#visual, paged#,
        percentages => q#N/A#,
        values      => q#auto | always | avoid | left | right | inherit#,
    },
    'page-break-before' => {
        applies_to  => q#block-level elements#,
        inherited   => q#no#,
        initial     => q#auto#,
        media       => q#visual, paged#,
        percentages => q#N/A#,
        values      => q#auto | always | avoid | left | right | inherit#,
    },
    'page-break-inside' => {
        applies_to  => q#block-level elements#,
        inherited   => q#no#,
        initial     => q#auto#,
        media       => q#visual, paged#,
        percentages => q#N/A#,
        values      => q#avoid | auto | inherit#,
    },
    'pause' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#see individual properties#,
        media       => q#aural#,
        percentages => q#see descriptions of 'pause-before' and 'pause-after'#,
        values      => q#[ [<time> | <percentage>]{1,2} ] | inherit#,
    },
    'pause-after' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#0#,
        media       => q#aural#,
        percentages => q#see prose ( http://www.w3.org/TR/CSS21/aural.html\#propdef-pause-after )#,
        values      => q#<time> | <percentage> | inherit#,
    },
    'pause-before' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#0#,
        media       => q#aural#,
        percentages => q#see prose ( http://www.w3.org/TR/CSS21/aural.html\#propdef-pause-before )#,
        values      => q#<time> | <percentage> | inherit#,
    },
    'pitch' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#medium#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#<frequency> | x-low | low | medium | high | x-high | inherit#,
    },
    'pitch-range' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#50#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#<number> | inherit#,
    },
    'play-during' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#auto#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#<uri> [ mix || repeat ]? | auto | none | inherit#,
    },
    'position' => {
        applies_to  => q#all elements#,
        inherited   => q#no#,
        initial     => q#static#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#static | relative | absolute | fixed | inherit#,
    },
    'quotes' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#depends on user agent#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#[<string> <string>]+ | none | inherit#,
    },
    'richness' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#50#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#<number> | inherit#,
    },
    'right' => {
        applies_to  => q#positioned elements#,
        inherited   => q#no#,
        initial     => q#auto#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<length> | <percentage> | auto | inherit#,
    },
    'speak' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#normal#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#normal | none | spell-out | inherit#,
    },
    'speak-header' => {
        applies_to  => q#elements that have table header information#,
        inherited   => q#yes#,
        initial     => q#once#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#once | always | inherit#,
    },
    'speak-numeral' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#continuous#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#digits | continuous | inherit#,
    },
    'speak-punctuation' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#continuous#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#code | none | inherit#,
    },
    'speech-rate' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#medium#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#<number> | x-slow | slow | medium | fast | x-fast | faster | slower | inherit#,
    },
    'stress' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#50#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#<number> | inherit#,
    },
    'table-layout' => {
        applies_to  => q#'table' and 'inline-table' elements#,
        inherited   => q#no#,
        initial     => q#auto#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#auto | fixed | inherit#,
    },
    'text-align' => {
        applies_to  => q#block-level elements, table cells and inline blocks#,
        inherited   => q#yes#,
        initial     => q#a nameless value that acts as 'left' if 'direction' is 'ltr', 'right' if 'direction' is 'rtl'#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#left | right | center | justify | inherit#,
    },
    'text-decoration' => {
        applies_to  => q#all elements#,
        inherited   => q#no (see prose ( http://www.w3.org/TR/CSS21/text.html\#propdef-text-decoration ))#,
        initial     => q#none#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#none | [ underline || overline || line-through || blink ] | inherit#,
    },
    'text-indent' => {
        applies_to  => q#block-level elements, table cells and inline blocks#,
        inherited   => q#yes#,
        initial     => q#0#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<length> | <percentage> | inherit#,
    },
    'text-transform' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#none#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#capitalize | uppercase | lowercase | none | inherit#,
    },
    'top' => {
        applies_to  => q#positioned elements#,
        inherited   => q#no#,
        initial     => q#auto#,
        media       => q#visual#,
        percentages => q#refer to height of containing block#,
        values      => q#<length> | <percentage> | auto | inherit#,
    },
    'unicode-bidi' => {
        applies_to  => q#all elements, but see prose ( http://www.w3.org/TR/CSS21/visuren.html\#propdef-unicode-bidi )#,
        inherited   => q#no#,
        initial     => q#normal#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#normal | embed | bidi-override | inherit#,
    },
    'vertical-align' => {
        applies_to  => q#inline-level and 'table-cell' elements#,
        inherited   => q#no#,
        initial     => q#baseline#,
        media       => q#visual#,
        percentages => q#refer to the 'line-height' of the element itself#,
        values      => q#baseline | sub | super | top | text-top | middle | bottom | text-bottom | <percentage> | <length> | inherit#,
    },
    'visibility' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#visible#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#visible | hidden | collapse | inherit#,
    },
    'voice-family' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#depends on user agent#,
        media       => q#aural#,
        percentages => q#N/A#,
        values      => q#[[<specific-voice> | <generic-voice> ],]* [<specific-voice> | <generic-voice> ] | inherit#,
    },
    'volume' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#medium#,
        media       => q#aural#,
        percentages => q#refer to inherited value#,
        values      => q#<number> | <percentage> | silent | x-soft | soft | medium | loud | x-loud | inherit#,
    },
    'white-space' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#normal#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#normal | pre | nowrap | pre-wrap | pre-line | inherit#,
    },
    'widows' => {
        applies_to  => q#block-level elements#,
        inherited   => q#yes#,
        initial     => q#2#,
        media       => q#visual, paged#,
        percentages => q#N/A#,
        values      => q#<integer> | inherit#,
    },
    'width' => {
        applies_to  => q#all elements but non-replaced inline elements, table rows, and row groups#,
        inherited   => q#no#,
        initial     => q#auto#,
        media       => q#visual#,
        percentages => q#refer to width of containing block#,
        values      => q#<length> | <percentage> | auto | inherit#,
    },
    'word-spacing' => {
        applies_to  => q#all elements#,
        inherited   => q#yes#,
        initial     => q#normal#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#normal | <length> | inherit#,
    },
    'z-index' => {
        applies_to  => q#positioned elements#,
        inherited   => q#no#,
        initial     => q#auto#,
        media       => q#visual#,
        percentages => q#N/A#,
        values      => q#auto | <integer> | inherit#,
    },
    );
}

sub _make_vt_data {
    return (
    'margin-width' =>
        q#http://www.w3.org/TR/CSS21/box.html\#value-def-margin-width#,
    'absolute-size' =>
        q#http://www.w3.org/TR/CSS21/fonts.html\#value-def-absolute-size#,
    'number' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-number#,
    'time' =>
        q#http://www.w3.org/TR/CSS21/aural.html\#value-def-time#,
    'string' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-string#,
    'border-width' =>
        q#http://www.w3.org/TR/CSS21/box.html\#value-def-border-width#,
    'border-style' =>
        q#http://www.w3.org/TR/CSS21/box.html\#value-def-border-style#,
    'frequency' =>
        q#http://www.w3.org/TR/CSS21/aural.html\#value-def-frequency#,
    'identifier' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-identifier#,
    'color' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-color#,
    'integer' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-integer#,
    'specific-voice' =>
        q#http://www.w3.org/TR/CSS21/aural.html\#value-def-specific-voice#,
    'relative-size' =>
        q#http://www.w3.org/TR/CSS21/fonts.html\#value-def-relative-size#,
    'generic-voice' =>
        q#http://www.w3.org/TR/CSS21/aural.html\#value-def-generic-voice#,
    'padding-width' =>
        q#http://www.w3.org/TR/CSS21/box.html\#value-def-padding-width#,
    'angle' =>
        q#http://www.w3.org/TR/CSS21/aural.html\#value-def-angle#,
    'percentage' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-percentage#,
    'family-name' =>
        q#http://www.w3.org/TR/CSS21/fonts.html\#value-def-family-name#,
    'uri' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-uri#,
    'length' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-length#,
    'generic-family' =>
        q#http://www.w3.org/TR/CSS21/fonts.html\#value-def-generic-family#,
    'shape' =>
        q#http://www.w3.org/TR/CSS21/visufx.html\#value-def-shape#,
    'counter' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-counter#,
    );
}

1;
__END__

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::CSS::PropertyInfo::Data - internal data file for POE::Component::IRC::Plugin::CSS::PropertyInfo module

=head1 DESCRIPTION

This module is used internally by
L<POE::Component::IRC::Plugin::CSS::PropertyInfo> module and is a simple
data file.

B<NOTE:> if for some really strange reason you'll decide to use this
module directly (that is not using the
L<POE::Component::IRC::Plugin::CSS::PropertyInfo> module) I recommend
you tell the author at C<zoffix@cpan.org> otherwise anything here B<might
change> without notice.

=head1 WHAT DOES IT HAVE

The module provides two class methods:

=head2 C<_make_property_data>

This class method returns a hash with keys being lower cased
CSS properties and value being hashrefs which look like this:

    'azimut' => {
        applies_to  => 'all elements',
        inherited   => 'yes',
        initial     => 'center',
        media       => 'aural',
        percentages => 'N/A',
        values      => '<angle> | [[ left-side | far-left | left | center-left | center | center-right | right | far-right | right-side ] || behind ] | leftwards | rightwards | inherit',
    },

=head2 C<_make_vt_data>

This class method returns a hash of "value types" with keys being the
"value types" and value being the links pointing to documentation.
Full list of value types known to this module is as follows:

    'margin-width' =>
        q#http://www.w3.org/TR/CSS21/box.html\#value-def-margin-width#,
    'absolute-size' =>
        q#http://www.w3.org/TR/CSS21/fonts.html\#value-def-absolute-size#,
    'number' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-number#,
    'time' =>
        q#http://www.w3.org/TR/CSS21/aural.html\#value-def-time#,
    'string' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-string#,
    'border-width' =>
        q#http://www.w3.org/TR/CSS21/box.html\#value-def-border-width#,
    'border-style' =>
        q#http://www.w3.org/TR/CSS21/box.html\#value-def-border-style#,
    'frequency' =>
        q#http://www.w3.org/TR/CSS21/aural.html\#value-def-frequency#,
    'identifier' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-identifier#,
    'color' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-color#,
    'integer' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-integer#,
    'specific-voice' =>
        q#http://www.w3.org/TR/CSS21/aural.html\#value-def-specific-voice#,
    'relative-size' =>
        q#http://www.w3.org/TR/CSS21/fonts.html\#value-def-relative-size#,
    'generic-voice' =>
        q#http://www.w3.org/TR/CSS21/aural.html\#value-def-generic-voice#,
    'padding-width' =>
        q#http://www.w3.org/TR/CSS21/box.html\#value-def-padding-width#,
    'angle' =>
        q#http://www.w3.org/TR/CSS21/aural.html\#value-def-angle#,
    'percentage' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-percentage#,
    'family-name' =>
        q#http://www.w3.org/TR/CSS21/fonts.html\#value-def-family-name#,
    'uri' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-uri#,
    'length' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-length#,
    'generic-family' =>
        q#http://www.w3.org/TR/CSS21/fonts.html\#value-def-generic-family#,
    'shape' =>
        q#http://www.w3.org/TR/CSS21/visufx.html\#value-def-shape#,
    'counter' =>
        q#http://www.w3.org/TR/CSS21/syndata.html\#value-def-counter#,

to C<bug-POE-Component-IRC-PluginBundle-WebDevelopment at rt.cpan.org>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/POE-Component-IRC-PluginBundle-WebDevelopment>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/POE-Component-IRC-PluginBundle-WebDevelopment/issues>

If you can't access GitHub, you can email your request
to C<bug-POE-Component-IRC-PluginBundle-WebDevelopment at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut


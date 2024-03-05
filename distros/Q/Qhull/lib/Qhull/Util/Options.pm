package Qhull::Util::Options;

# ABSTRACT: Options for Qhull and gang

use v5.26;
use strict;
use warnings;
use experimental 'signatures', 'lexical_subs', 'declared_refs';
use Log::Any '$log';

our $VERSION = '0.01';

use parent 'Exporter::Tiny';

use Readonly::Tiny 'readonly';
use Regexp::Common 'number';
use List::Util 'first';
use CXC::Exporter::Util ':all';
use Ref::Util 'is_arrayref', 'is_hashref';

our @CARP_NOT = qw( Qhull::PP Qhull::Options );

BEGIN {
    install_CONSTANTS( {
            CATEGORIES => {
                map { ( "CAT_\U$_" => $_ ) }
                  qw(
                  compute
                  control
                  input
                  input_format
                  output
                  output_format
                  output_format_amend
                  output_geom
                  precision
                  print
                  trace
                  ),
            },
        } );
    install_EXPORTS;
}

install_EXPORTS( {
        func    => [qw( parse_options )],
        Option  => [qw( %Option )],
        TypesQR => [
            qw( $Int $PositiveOrZeroInt $NegativeInt
              $Num $PositiveOrZeroNum $NegativeNum
            ),
        ],
    } );

my sub croak {
    require Carp;
    goto \&Carp::croak;
}

## no critic (Variables::ProhibitPackageVars)
## no critic (Community::MultidimensionalArrayEmulation)
# there isn't any of the above in the below; the Perl::Critic rule is
# just confused

our $Int               = $RE{num}{int};
our $PositiveOrZeroInt = $RE{num}{int}{ -sign => q{} };
our $NegativeInt       = $RE{num}{int}{ -sign => q{-} };
our $Num               = $RE{num}{real};
our $PositiveOrZeroNum = $RE{num}{real}{ -sign => q{} };
our $NegativeNum       = $RE{num}{real}{ -sign => q{-} };


# our mapping of Qhull's esoteric options formulation onto
# something we can use. Validation of options is not the point
# here, just the ability to uniquely identify the option.
# At some point this might be extended to providing a more
# Perlish interface (or at the least, a more sane way of
# specifying options).


my %Option = map {    ## no critic (BuiltinFunctions::ProhibitComplexMappings)
    my $name;
    if ( 'ARRAY' eq ref $_ ) {    ## no critic (BuiltinFunctions::ProhibitUselessTopic)
        $name = $_->[0]{name};
        $_->{strip} //= !!0 for $_->@*;
    }
    else {
        $name = $_->{name};
        $_->{strip} //= !!0;
    }
    $name => $_;
} ( {
        name     => 'd',
        category => CAT_COMPUTE,
        what     => 'delaunay',
        cmd      => ['qhull'],
    },

    {
        name     => 'f',
        category => CAT_OUTPUT_FORMAT,
        what     => 'facets',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'i',
        category => CAT_OUTPUT_FORMAT,
        what     => 'incidences',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'm',
        category => CAT_OUTPUT_FORMAT,
        what     => 'mathematica',
        cmd      => [ 'qhull', 'qconvex', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'n',
        category => CAT_OUTPUT_FORMAT,
        what     => 'normals',
        cmd      => [ 'qhull', 'qconvex', ],
    },

    {
        name     => 'o',
        category => CAT_OUTPUT_FORMAT,
        what     => 'offFile',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'p',
        category => CAT_OUTPUT_FORMAT,
        what     => 'points',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 's',
        category => CAT_OUTPUT_FORMAT,
        what     => 'summary',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'v',
        category => CAT_COMPUTE,
        what     => 'voronoi',
        cmd      => ['qhull'],
    },

    [ {
            name     => 'A',
            regexp   => qr/A $NegativeNum/x,
            category => CAT_PRECISION,
            what     => 'angle-postmerge',
            cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
        },

        {
            name     => 'A',
            regexp   => qr/A $PositiveOrZeroNum /x,
            category => CAT_PRECISION,
            what     => 'angle-premerge',
            cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
        },
    ],

    [ {
            name     => 'C',
            regexp   => qr/C $NegativeNum /x,
            category => CAT_PRECISION,
            what     => 'centrum-postmerge',
            cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
        },

        {
            name     => 'C',
            regexp   => qr/C $PositiveOrZeroNum/x,
            category => CAT_PRECISION,
            what     => 'centrum-premerge',
            cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
        },
    ],

    {
        name     => 'E',
        regexp   => qr/E $PositiveOrZeroNum/x,
        category => CAT_PRECISION,
        what     => 'distance-roundoff',
        cmd      => [ 'qhull', ],
    },

    [ {
            name     => 'H',
            category => CAT_COMPUTE,
            what     => 'halfspace',
            cmd      => [ 'qhull', 'qhull', 'qhalf' ],
        },

        {
            name     => 'H',
            regexp   => qr/H[.]+/x,
            category => CAT_COMPUTE,
            what     => 'halfspace-about',
            cmd      => [ 'qhull', 'qhull', 'qhalf' ],
        },
    ],

    {
        name     => 'R',
        regexp   => qr/R $PositiveOrZeroNum/x,
        category => CAT_PRECISION,
        what     => 'random-perturb',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'V',
        regexp   => qr/V $PositiveOrZeroNum/x,
        category => CAT_PRECISION,
        what     => 'minimum-distance-visible',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'U',
        regexp   => qr/U $PositiveOrZeroNum/x,
        category => CAT_PRECISION,
        what     => 'maximum-coplanar-distance',
        cmd      => [ 'qhull', 'qhull', 'qconvex', 'qhalf', ],
    },

    {
        name     => 'W',
        regexp   => qr/W $PositiveOrZeroNum/x,
        category => CAT_PRECISION,
        what     => 'minimum-outside-width',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Fa',
        category => CAT_OUTPUT_FORMAT_AMEND,
        what     => 'area',
        cmd      => [ 'qhull', 'qconvex', 'qdelaunay', ],
    },

    {
        name     => 'FA',
        category => CAT_OUTPUT_FORMAT,
        what     => 'area-total',
        cmd      => [ 'qhull', 'qconvex', 'qdelaunay', ],
    },

    {
        name     => 'Fc',
        category => CAT_OUTPUT_FORMAT,
        what     => 'coplanars',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'FC',
        category => CAT_OUTPUT_FORMAT,
        what     => 'centrums',
        cmd      => [ 'qhull', 'qconvex', ],
    },

    {
        name     => 'Fd',
        category => CAT_INPUT_FORMAT,
        what     => 'cdd-in',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'FD',
        category => CAT_OUTPUT_FORMAT,
        strip    => !!1,
        what     => 'cdd-out',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qdelaunay', ],
    },

    {
        name     => 'FF',
        category => CAT_OUTPUT_FORMAT,
        what     => 'facets-xridge',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Fi',
        category => CAT_OUTPUT_FORMAT,
        what     => 'facets-inner',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', ],
    },

    {
        name     => 'FI',
        category => CAT_OUTPUT_FORMAT,
        what     => 'facet-ids',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Fm',
        category => CAT_OUTPUT_FORMAT,
        what     => 'merges',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'FM',
        category => CAT_OUTPUT_FORMAT,
        strip    => !!1,
        what     => 'maple',
        cmd      => [ 'qhull', 'qconvex', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Fn',
        category => CAT_OUTPUT_FORMAT,
        what     => 'facet-neighbors',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'FN',
        category => CAT_OUTPUT_FORMAT,
        what     => 'neighbors-vertex',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Fo',
        category => CAT_OUTPUT_FORMAT,
        what     => 'facet-outer',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', ],
    },

    {
        name     => 'FO',
        category => CAT_OUTPUT_FORMAT,
        strip    => !!1,
        what     => 'names',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Fp',
        category => CAT_OUTPUT_FORMAT,
        what     => 'point-intersect',
        cmd      => [ 'qhull', 'qhalf', ],
    },

    {
        name     => 'FP',
        category => CAT_OUTPUT_FORMAT,
        what     => 'point-nearest',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'FQ',
        category => CAT_OUTPUT_FORMAT,
        strip    => !!1,
        what     => 'command-line',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Fs',
        category => CAT_OUTPUT_FORMAT,
        what     => 'summary',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'FS',
        category => CAT_OUTPUT_FORMAT,
        what     => 'size',
        cmd      => [ 'qhull', 'qconvex', 'qdelaunay', ],
    },

    {
        name     => 'Ft',
        category => CAT_OUTPUT_FORMAT,
        what     => 'triangles',
        cmd      => [ 'qhull', 'qconvex', ],
    },

    {
        name     => 'Fv',
        category => CAT_OUTPUT_FORMAT,
        what     => 'vertices',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'FV',
        category => CAT_OUTPUT_FORMAT,
        what     => 'vertex-average',
        cmd      => [ 'qhull', 'qconvex', ],
    },

    {
        name     => 'Fx',
        category => CAT_OUTPUT_FORMAT,
        what     => 'extremes',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'G',
        category => CAT_OUTPUT_GEOM,
        what     => 'geom',
        cmd      => [ 'qhull', 'qconvex', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Ga',
        category => CAT_OUTPUT_GEOM,
        what     => 'all-points',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Gc',
        category => CAT_OUTPUT_GEOM,
        what     => 'centrums',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'GD',
        regexp   => qr/GD $PositiveOrZeroInt/x,
        category => CAT_OUTPUT_GEOM,
        what     => 'drop-dim',
        cmd      => [ 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Gh',
        category => CAT_OUTPUT_GEOM,
        what     => 'intersections',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Gi',
        category => CAT_OUTPUT_GEOM,
        what     => 'inner',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Gn',
        category => CAT_OUTPUT_GEOM,
        what     => 'noplanes',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Go',
        category => CAT_OUTPUT_GEOM,
        what     => 'outer',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Gp',
        category => CAT_OUTPUT_GEOM,
        what     => 'coplanar',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Gr',
        category => CAT_OUTPUT_GEOM,
        what     => 'ridges',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Gt',
        category => CAT_OUTPUT_GEOM,
        what     => 'transparent',
        cmd      => [ 'qhull', 'qdelaunay', ],
    },

    {
        name     => 'Gv',
        category => CAT_OUTPUT_GEOM,
        what     => 'spheres',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'PA',
        regexp   => qr/PA $PositiveOrZeroInt/x,
        category => CAT_PRINT,
        what     => 'area-keep',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Pd',
        regexp   => qr/Pd .+/x,
        category => CAT_PRINT,
        what     => 'drop-facets-dim-less',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'PD',
        regexp   => qr/PD .+/x,
        category => CAT_PRINT,
        what     => 'drop-facets-dim-more',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'PF',
        regexp   => qr/PF $PositiveOrZeroNum/x,
        category => CAT_PRINT,
        what     => 'facet-area-keep',
        cmd      => [ 'qhull', 'qdelaunay', ],
    },

    {
        name     => 'Pg',
        category => CAT_PRINT,
        what     => 'good-facets',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'PG',
        category => CAT_PRINT,
        what     => 'good-facet-neighbors',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'PM',
        regexp   => qr/PM .+/x,
        category => CAT_PRINT,
        what     => 'merge-keep',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Po',
        category => CAT_PRINT,
        what     => 'output-forced',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Pp',
        category => CAT_PRINT,
        what     => 'precision-ignore',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Qa',
        category => CAT_CONTROL,
        what     => 'allow-short',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'QbB',
        category => CAT_CONTROL,
        what     => 'bound-unit-box',
        cmd      => [ 'qhull', 'qconvex', ],
    },

    {
        name     => 'Qbb',
        category => CAT_CONTROL,
        what     => 'bound-last',
        cmd      => [ 'qhull', ],
    },

    [ {
            name     => 'Qb',
            regexp   => qr/Qb $PositiveOrZeroInt :0B $PositiveOrZeroInt :0 /x,
            category => CAT_CONTROL,
            what     => 'project-dim',
            cmd      => [ 'qhull', 'qconvex', 'qhalf', ],
        },

        {
            name     => 'Qb',
            regexp   => qr/Qb $PositiveOrZeroInt : $Num /x,
            category => CAT_CONTROL,
            what     => 'bound-dim-low',
            cmd      => [ 'qhull', 'qconvex', ],
        },
    ],

    {
        name     => 'QB',
        regexp   => qr/QB $PositiveOrZeroInt : $Num /x,
        category => CAT_CONTROL,
        what     => 'bound-dim-high',
        cmd      => [ 'qhull', 'qconvex', ],
    },

    {
        name     => 'Qc',
        category => CAT_CONTROL,
        what     => 'coplanar-keep',
        cmd      => [ 'qhull', 'qconvex', 'qhalf', ],
    },

    {
        name     => 'Qf',
        category => CAT_CONTROL,
        what     => 'furthest-outside',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Qg',
        category => CAT_CONTROL,
        what     => 'good-facets-only',
        cmd      => [ 'qhull', ],
    },

    [ {
            name     => 'QG',
            regexp   => qr/QG $PositiveOrZeroInt/x,
            category => CAT_CONTROL,
            what     => 'good-if-see-point',
            cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
        },

        {
            name     => 'QG',
            regexp   => qr/QG $NegativeInt /x,
            category => CAT_CONTROL,
            what     => 'good-if-dont-see-point',
            cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
        },
    ],

    {
        name     => 'Qi',
        category => CAT_CONTROL,
        what     => 'interior-keep',
        cmd      => [ 'qhull', 'qconvex', 'qhalf', ],
    },

    [ {
            name     => 'QJ',
            category => CAT_CONTROL,
            what     => 'joggle',
            cmd      => [ 'qconvex', 'qhalf', 'qdelaunay', ],
        },

        {
            name     => 'QJ',
            regexp   => qr/QJ .+/x,
            category => CAT_CONTROL,
            what     => 'joggle',
            cmd      => [ 'qconvex', 'qhalf', 'qdelaunay', ],
        },
    ],

    {
        name     => 'Qm',
        category => CAT_CONTROL,
        what     => 'max-outside-only',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Qr',
        category => CAT_CONTROL,
        what     => 'random-outside',
        cmd      => [ 'qhull', ],
    },

    [ {
            name     => 'QR',
            regexp   => qr/QR $PositiveOrZeroInt /x,
            category => CAT_CONTROL,
            what     => 'rotate-id',
            cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
        },
        {
            name     => 'QR',
            regexp   => qr/QR $NegativeInt /x,
            category => CAT_CONTROL,
            what     => 'random-seed',
            cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', ],
        },
    ],

    {
        name     => 'Qs',
        category => CAT_CONTROL,
        what     => 'search-initial-simplex',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Qt',
        category => CAT_CONTROL,
        what     => 'triangulate',
        cmd      => [ 'qhull', 'qconvex', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'QT',
        category => CAT_CONTROL,
        what     => 'testpoints',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Qu',
        category => CAT_CONTROL,
        what     => 'upper-delaunay',
        cmd      => [ 'qhull', 'qvoronoi', 'qdelaunay', ],
    },

    {
        name     => 'Qv',
        category => CAT_CONTROL,
        what     => 'vertex-neighbors-convex',
        cmd      => [ 'qhull', ],
    },

    [ {
            name     => 'QV',
            regexp   => qr/QV $NegativeInt /x,
            category => CAT_CONTROL,
            what     => 'good-facets-not-point',
            cmd      => [ 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
        },
        {
            name     => 'QV',
            regexp   => qr/QV $PositiveOrZeroInt /x,
            category => CAT_CONTROL,
            what     => 'good-facets-point',
            cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', ],
        },
    ],

    {
        name     => 'Qw',
        category => CAT_CONTROL,
        what     => 'warn-allow',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Qx',
        category => CAT_CONTROL,
        what     => 'exact-merge',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Qz',
        category => CAT_CONTROL,
        what     => 'z-infinity-point',
        cmd      => [ 'qhull', 'qvoronoi', 'qdelaunay', ],
    },

    {
        name     => 'Q0',
        category => CAT_CONTROL,
        what     => 'no-premerge',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Q1',
        category => CAT_CONTROL,
        what     => 'angle-merge',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Q2',
        category => CAT_CONTROL,
        what     => 'no-merge-independent',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Q3',
        category => CAT_CONTROL,
        what     => 'no-merge-vertices',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Q4',
        category => CAT_CONTROL,
        what     => 'avoid-old-into-new',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Q5',
        category => CAT_CONTROL,
        what     => 'no-check-outer',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Q6',
        category => CAT_CONTROL,
        what     => 'no-concave-merge',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Q7',
        category => CAT_CONTROL,
        what     => 'no-breadth-first',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Q8',
        category => CAT_CONTROL,
        what     => 'no-near-inside',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Q9',
        category => CAT_CONTROL,
        what     => 'pick-furthest',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Q10',
        category => CAT_CONTROL,
        what     => 'no-narrow',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Q11',
        category => CAT_CONTROL,
        what     => 'trinormals-triangulate',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'Q12',
        category => CAT_CONTROL,
        what     => 'allow-wide',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Q14',
        category => CAT_CONTROL,
        what     => 'merge-pinched-vertices',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Q15',
        category => CAT_CONTROL,
        what     => 'check-duplicates',
        cmd      => [ 'qhull', ],
    },

    {
        name     => 'T',
        regexp   => qr/T $Int /x,
        category => CAT_TRACE,
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Ta',
        category => CAT_TRACE,
        what     => 'annotate-output',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'TA',
        regexp   => qr/TA $PositiveOrZeroInt/x,
        category => CAT_TRACE,
        what     => 'stop-add',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Tc',
        category => CAT_TRACE,
        what     => 'check-frequently',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Tf',
        category => CAT_TRACE,
        what     => 'flush',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Ts',
        category => CAT_TRACE,
        what     => 'statistics',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Tv',
        category => CAT_TRACE,
        what     => 'verify',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'Tz',
        category => CAT_TRACE,
        what     => 'z-stdout',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'TC',
        regexp   => qr/TC $PositiveOrZeroInt/x,
        category => CAT_TRACE,
        what     => 'cone-stop',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'TF',
        regexp   => qr/TF $PositiveOrZeroInt/x,
        category => CAT_TRACE,
        what     => 'facet-log',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'TI',
        category => CAT_INPUT,
        what     => 'input-file',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'TO',
        category => CAT_OUTPUT,
        what     => 'output-file',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    [ {
            name     => 'TP',
            regexp   => qr/TP $Int /x,
            category => CAT_TRACE,
            what     => 'trace-point',
            cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
        },

        {
            name     => 'TP-1',
            category => CAT_TRACE,
            what     => 'trace-point_-1',
            cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
        },
    ],

    {
        name     => 'TM',
        regexp   => qr/TM $PositiveOrZeroInt /x,
        category => CAT_TRACE,
        what     => 'trace-merge',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

    {
        name     => 'TR',
        regexp   => qr/TR $PositiveOrZeroInt /x,
        category => CAT_TRACE,
        what     => 'rerun',
        cmd      => [ 'qhull', ],
    },

    [ {
            name     => 'TV',
            regexp   => qr/TV $NegativeInt /x,
            category => CAT_TRACE,
            what     => 'stop-before-point',
            cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
        },

        {
            name     => 'TV',
            regexp   => qr/TV $PositiveOrZeroInt /x,
            category => CAT_TRACE,
            what     => 'stop-after-point',
            cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', ],
        },
    ],

    {
        name     => 'TW',
        regexp   => qr/TW $PositiveOrZeroNum/x,
        category => CAT_TRACE,
        what     => 'wide-trace',
        cmd      => [ 'qhull', 'qconvex', 'qvoronoi', 'qhalf', 'qdelaunay', ],
    },

);
readonly \%Option;

install_CONSTANTS( {
    OPTIONS => { map { ( "OPTION_$_", $_ ) } keys %Option },
} );
install_EXPORTS;



































sub parse_options ( $user_options ) {

    my @user_options = $user_options->@*;

    my @specs;

    while ( @user_options ) {
        my $option = shift @user_options;

        # these are the only options which have a separate argument;
        # for the rest, the argument is concatenated with the option name
        if ( $option eq 'TI' or $option eq 'TO' ) {
            push @specs, [ $option, $Option{$option}, shift( @user_options ) ];
            next;
        }

        my $found;

        my $maybe = $Option{ substr( $option, 0, 4 ) } // $Option{ substr( $option, 0, 3 ) }
          // $Option{ substr( $option, 0, 2 ) } // $Option{ substr( $option, 0, 1 ) };


        if ( is_hashref( $maybe ) ) {
            $found = $maybe
              if !exists $maybe->{regexp} || $option =~ $maybe->{regexp};
        }

        elsif ( is_arrayref( $maybe ) ) {
            # these should be in order of highest to least precedence
            $found = first { $_->{regexp} && $option =~ $_->{regexp} || $option eq $_->{name} } $maybe->@*;
        }

        croak( "unknown qhull option: $option" ) if !$found;

        my $spec = [ $option, $found ];
        push @specs, $spec;
    }

    return \@specs;
}

1;

#
# This file is part of Qhull
#
# This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory qhull

=head1 NAME

Qhull::Util::Options - Options for Qhull and gang

=head1 VERSION

version 0.01

=head1 SYNOPSIS

=head1 SUBROUTINES

=head2 parse_options

  \@specs = parse_options( \@qhull_options );

Recognize and categorize B<Qhull> options.

Returns an arrayref of arrays, one per option.  The information encoded per option is

=over

=item Z<>0

the option name

=item Z<>1

An internal structure with option information

=item Z<>2

I<Optional>: the option value.  Currently only available for the B<TI> and B<TO> options.

=back

Future: options with regexps could be used to extract values for
options with values.  This would most likely slow parsing, as most
options only require a string match to recognize them.  Also, the code
to turn an option spec back into an option assumes that the value is
specified separately from the option when passed to B<qhull>, as
that's what B<TI> and B<TO> do.  Will need to append to the option
name for other options.

=for Pod::Coverage CATEGORIES
CAT_COMPUTE
CAT_CONTROL
CAT_INPUT
CAT_INPUT_FORMAT
CAT_OUTPUT
CAT_OUTPUT_FORMAT
CAT_OUTPUT_FORMAT_AMEND
CAT_OUTPUT_GEOM
CAT_PRECISION
CAT_PRINT
CAT_TRACE
OPTIONS
OPTION_A
OPTION_C
OPTION_E
OPTION_FA
OPTION_FC
OPTION_FD
OPTION_FF
OPTION_FI
OPTION_FM
OPTION_FN
OPTION_FO
OPTION_FP
OPTION_FQ
OPTION_FS
OPTION_FV
OPTION_Fa
OPTION_Fc
OPTION_Fd
OPTION_Fi
OPTION_Fm
OPTION_Fn
OPTION_Fo
OPTION_Fp
OPTION_Fs
OPTION_Ft
OPTION_Fv
OPTION_Fx
OPTION_G
OPTION_GD
OPTION_Ga
OPTION_Gc
OPTION_Gh
OPTION_Gi
OPTION_Gn
OPTION_Go
OPTION_Gp
OPTION_Gr
OPTION_Gt
OPTION_Gv
OPTION_H
OPTION_PA
OPTION_PD
OPTION_PF
OPTION_PG
OPTION_PM
OPTION_Pd
OPTION_Pg
OPTION_Po
OPTION_Pp
OPTION_Q0
OPTION_Q1
OPTION_Q10
OPTION_Q11
OPTION_Q12
OPTION_Q14
OPTION_Q15
OPTION_Q2
OPTION_Q3
OPTION_Q4
OPTION_Q5
OPTION_Q6
OPTION_Q7
OPTION_Q8
OPTION_Q9
OPTION_QB
OPTION_QG
OPTION_QJ
OPTION_QR
OPTION_QT
OPTION_QV
OPTION_Qa
OPTION_Qb
OPTION_QbB
OPTION_Qbb
OPTION_Qc
OPTION_Qf
OPTION_Qg
OPTION_Qi
OPTION_Qm
OPTION_Qr
OPTION_Qs
OPTION_Qt
OPTION_Qu
OPTION_Qv
OPTION_Qw
OPTION_Qx
OPTION_Qz
OPTION_R
OPTION_T
OPTION_TA
OPTION_TC
OPTION_TF
OPTION_TI
OPTION_TM
OPTION_TO
OPTION_TP
OPTION_TR
OPTION_TV
OPTION_TW
OPTION_Ta
OPTION_Tc
OPTION_Tf
OPTION_Ts
OPTION_Tv
OPTION_Tz
OPTION_U
OPTION_V
OPTION_W
OPTION_d
OPTION_f
OPTION_i
OPTION_m
OPTION_n
OPTION_o
OPTION_p
OPTION_s
OPTION_v

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-qhull@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Qhull>

=head2 Source

Source is available at

  https://gitlab.com/djerius/p5-qhull

and may be cloned from

  https://gitlab.com/djerius/p5-qhull.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Qhull|Qhull>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

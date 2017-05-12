# Module makefile for Object::InsideOut (using Module::Build)

use strict;
use warnings;

use Module::Build;


# Check for Scalar::Util::weaken()
eval { require Scalar::Util; };
if ($@) {
    # Not found - require minimum version
    $Scalar::Util::VERSION = 1.10;
} elsif (! Scalar::Util->can('weaken')) {
    # Pure Perl version only
    if ($Scalar::Util::VERSION < 1.10) {
        # Require minimum version
        $Scalar::Util::VERSION = 1.10;
    } else {
        # Require next higher version
        $Scalar::Util::VERSION += 0.01;
    }
}


my %more_recommends = ();
if ($] >= 5.008) {
    %more_recommends = (
        'threads'             => 1.43,
        'threads::shared'     => 1.03,
    );
}

# Create make file
Module::Build->new(
    'module_name' => 'Object::InsideOut',
    'license'     => 'perl',
    'dist_author' => 'Jerry D. Hedden <jdhedden AT cpan DOT org>',

    'build_requires' => {
                            'Test::More'          => 0.50,
                        },

    'requires'       => {
                            'perl'                => '5.6.0',
                            'strict'              => 0,
                            'warnings'            => 0,
                            'attributes'          => 0,
                            'overload'            => 0,
                            'Config'              => 0,
                            'B'                   => 0,
                            'Data::Dumper'        => 0,
                            'Scalar::Util'        => $Scalar::Util::VERSION,
                            'Exception::Class'    => 1.22,
                        },

    'recommends'     => {
                            'Want'                      => 0.12,
                            'Storable'                  => 2.15,
                            'Test::Pod'                 => 1.26,
                            'Test::Pod::Coverage'       => 1.08,
                            'Math::Random::MT::Auto'    => 5.04,
                            %more_recommends
                        },
)->create_build_script();

# EOF

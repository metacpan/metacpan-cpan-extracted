
use strict;
use warnings;

use Moose                 ( );
use MooseX::MarkAsMethods ( );

use Test::More ();

BEGIN {
    {
        package TestClass::Funky;

        use Moose::Exporter;

        my ($import, $unimport, $init_meta) = Moose::Exporter->build_import_methods(
            install => [ qw{ unimport init_meta } ],
        );

        sub import {

            my $target = scalar caller;
            MooseX::MarkAsMethods->import({ into => $target }, autoclean => 1);

            goto &$import;
        }
    }

    $INC{'TestClass/Funky.pm'} = 1;
}
{
    package TestClass;

    use Moose;
    use TestClass::Funky;

    use overload q{""} => sub { shift->stringify }, fallback => 1;

    has class_att => (isa => 'Str', is => 'rw');
    sub stringify { 'from class' }
}

use Test::More 0.92;
use Test::Moose;

require 't/funcs.pm' unless eval { require funcs };

does_ok(TestClass->meta, 'MooseX::MarkAsMethods::MetaRole::MethodMarker');

check_sugar_removed_ok('TestClass');

my $t = make_and_check(
    'TestClass',
    undef,
    [ 'class_att' ],
);

check_overloads($t, '""' => 'from class');

done_testing;

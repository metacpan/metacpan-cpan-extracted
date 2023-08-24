use strict;
use warnings;
use Test2::V0              qw( done_testing ok );
use Namespace::Subroutines ();

use lib 't/lib';

my %subroutines;
Namespace::Subroutines::find(
    'ToDo::Controller',
    sub {
        my ( $modules, $name, $ref, $attrs ) = @_;
        $subroutines{$name} = 1;
    }
);

ok( $subroutines{foo},      'finds subroutine "foo"' );
ok( $subroutines{bar},      'finds subroutine "bar"' );
ok( keys %subroutines == 2, 'finds exactly two subroutines' );

done_testing;

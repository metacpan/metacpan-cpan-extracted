use Test::More tests => 8;

use strict;
use warnings;
use FindBin;
use File::Spec::Functions;

use lib $FindBin::Bin . '/lib';

my @methods = qw(
    render
    template_engine
);

use_ok( 'Farm::Cow' );

isa_ok( my $cow = Farm::Cow->new( spots => 8 ), 'Farm::Cow' );

can_ok( $cow, @methods );

is( $cow->render, "This cow has 8 spots and goes Moooooooo!\n",
    'default render' );

my $engine = $cow->template_engine;

isa_ok( $engine, 'MooseX::Templated::Engine' );

is( $engine->view_class, 'MooseX::Templated::View::TT', 'template view class' );

is( $engine->template_suffix, '.tt', 'template source suffix' );

is( $engine->template_root, '__LIB__', 'template root dir' );

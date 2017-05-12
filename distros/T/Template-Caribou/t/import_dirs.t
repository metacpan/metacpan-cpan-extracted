use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

use lib 't/lib';

use WithDirs::One;

is( WithDirs::One->new->alpha => 'alpha here' );

-d $_ or mkdir $_ for map "t/$_", qw/ foo bar /;

{ 
    package Bar;

    use Moose::Role;
    use Template::Caribou;

    with 'Template::Caribou::Files' => {
        dirs => [ 't/bar' ],
    };
}

{ 
    package Foo;

    use Moose;
    use Template::Caribou;

    with 'Template::Caribou::Files' => {
        dirs => [ 't/foo' ],
        intro => [
            q{ use experimental 'signatures'; }
        ],
    };
    with 'Bar';
}

my $foo = Foo->new;

is_deeply [ $foo->all_template_dirs ], [ map "t/$_", qw/ foo bar / ], 
    'all_template_dirs';


dies_ok {
    $foo->add_template_file( 't/corpus/misc/quux.bou');
} "can't add templates on regular instances";

ok !$foo->can('quux');

lives_ok {
    $foo->can_add_templates(1);
    $foo->add_template_file( 't/corpus/misc/quux.bou');
} "can_add_templates does it";

ok $foo->can( 'quux' );

is( $foo->quux => 'quux' );



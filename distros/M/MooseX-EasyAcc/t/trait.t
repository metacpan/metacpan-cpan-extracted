use strict;
use warnings;

use Test::More tests => 3;
{
    package MyApp;
    use Moose;
    use MooseX::EasyAcc::Role::Attribute;

    has 'everything' => (
        is => 'rw',
        isa => 'Str',
        traits => ['MooseX::EasyAcc::Role::Attribute'],
    );
    # Creates methods everything, set_everything, and has_everything
  
}

ok ( MyApp->can('everything'),     'MyApp->everything exists');
ok ( MyApp->can('set_everything'), 'MyApp->set_everything exists');
ok ( MyApp->can('has_everything'), 'MyApp->has_everything exists');


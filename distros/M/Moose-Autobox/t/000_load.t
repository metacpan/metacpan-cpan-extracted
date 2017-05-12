use strict;
use warnings;

use Test::More tests => 14;

BEGIN {
    use_ok('Moose::Autobox');

    use_ok('Moose::Autobox::Array');
    use_ok('Moose::Autobox::Code');
    use_ok('Moose::Autobox::Defined');
    use_ok('Moose::Autobox::Hash');
    use_ok('Moose::Autobox::Indexed');
    use_ok('Moose::Autobox::Item');
    use_ok('Moose::Autobox::List');
    use_ok('Moose::Autobox::Number');
    use_ok('Moose::Autobox::Ref');
    use_ok('Moose::Autobox::Scalar');
    use_ok('Moose::Autobox::String');
    use_ok('Moose::Autobox::Undef');
    use_ok('Moose::Autobox::Value');
}

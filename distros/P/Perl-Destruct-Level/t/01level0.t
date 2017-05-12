use Test::More tests => 1;

use Perl::Destruct::Level level => 0;

is(Perl::Destruct::Level::get_destruct_level(), 0);

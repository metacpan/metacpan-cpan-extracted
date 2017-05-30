use strict;
use warnings;
# Add 't/lib' @INC to use MyModule
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

use Reply::Plugin::Autocomplete::ExportedSymbols;

is_deeply [Reply::Plugin::Autocomplete::ExportedSymbols::_export_symbols('MyModule')], [
    qw/:qux bar foo foobar foobaz/
];

my $instance = Reply::Plugin::Autocomplete::ExportedSymbols->new(publisher => sub {});

is_deeply [$instance->tab_handler('use MyModule qw/ ')],           [qw/:qux bar foo foobar foobaz/];
is_deeply [$instance->tab_handler('use MyModule qw/ bar foo')],    [qw/foo foobar foobaz/];
is_deeply [$instance->tab_handler('use MyModule qw/ :')],          [qw/:qux/];
is_deeply [$instance->tab_handler('use MyModule::NotFound qw/ ')], [];

done_testing;

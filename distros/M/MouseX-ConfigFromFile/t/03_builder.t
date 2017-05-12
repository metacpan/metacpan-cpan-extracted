use strict;
use Test::More;
use File::Spec;

my $file = File::Spec->catfile('path/to/myapp.conf');

do {
    package MyApp;
    use Mouse;
    use File::Spec;

    with 'MouseX::ConfigFromFile';

    has 'name' => (is => 'rw', isa => 'Str');
    has 'host' => (is => 'rw', isa => 'Str');
    has 'port' => (is => 'rw', isa => 'Int');

    has '+configfile' => (builder => '_build_configfile');

    sub _build_configfile { $file }

    sub get_config_from_file {
        return +{ host => 'localhost', port => 3000 };
    }
};

my $app = MyApp->new_with_config(name => 'MyApp');

is $app->configfile => $file, 'configfile ok';
is $app->host => 'localhost', 'get_config_from_file ok';
is $app->port => 3000, 'get_config_from_file ok';
is $app->name => 'MyApp', 'extra params ok';

done_testing;

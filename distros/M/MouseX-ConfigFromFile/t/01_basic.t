use strict;
use Test::More;
use File::Spec;

do {
    package MyApp;
    use Mouse;

    with 'MouseX::ConfigFromFile';

    has 'name' => (is => 'rw', isa => 'Str');
    has 'host' => (is => 'rw', isa => 'Str');
    has 'port' => (is => 'rw', isa => 'Int');

    sub get_config_from_file {
        my (undef, $file) = @_;
        return +{ host => 'localhost', port => 3000 };
    }
};

my $file = File::Spec->catfile('path/to/myapp.conf');
my $app = MyApp->new_with_config(
    name       => 'MyApp',
    configfile => $file,
);

is $app->configfile => $file, 'configfile ok';
is $app->host => 'localhost', 'get_config_from_file ok';
is $app->port => 3000, 'get_config_from_file ok';
is $app->name => 'MyApp', 'extra params ok';

done_testing;

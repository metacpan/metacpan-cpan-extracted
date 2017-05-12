#!perl
use Test::More tests => 11;

use File::HomeDir qw(home);
use File::Spec::Functions qw(catfile);

use strict;

BEGIN { use_ok('Module::Checkstyle::Config'); } # 1

eval <<'END_OF_BUILD';
package Module::Checkstyle::Check::Package;
    
sub test {
    my $config = pop;
    Test::More::is($config->get_directive('max-per-file'), 1); # 7
}
END_OF_BUILD
    
{
    my $config = Module::Checkstyle::Config->new('this-shouldnt-exist');
    ok(!defined $config->get_directive('_', '_config-path')); # 2
}

# Check if we have an $ENV{HOME}/.module-checkstyle/config
{
    my $path = catfile(home, '.module-checkstyle', 'config');
    if (-e $path && -f $path) {
        my $config = Module::Checkstyle::Config->new();
        is($config->get_directive('_', '_config-path'), $path); # 3
    }
    else {
        pass("No ~/.module-checkstyle/cdonfig.. skipping"); # 3
    }
}

# Test existing file
{
    my $config = Module::Checkstyle::Config->new('config');
    is($config->get_directive('_', '_config-path'), 'config'); # 4
    
    is($config->get_directive('Package', 'max-per-file'), 1); # 5
    is($config->get_directive('Package', 'matches-name'), q{qr/^([A-Z][A-Za-z]+)(::[A-Z][A-Za-z]+)*$/}); # 6
    
    Module::Checkstyle::Check::Package->test($config);
}

{
    my $config_str = <<'END_OF_CONFIG';
[Package]
max-per-file = 1
END_OF_CONFIG
        
    my $config = Module::Checkstyle::Config->new(\$config_str);

    ok(!defined $config->get_directive('_', '_config_path')); # 8
    is($config->get_directive('Package', 'max-per-file'), 1); # 9
}

{
    my $config = Module::Checkstyle::Config->new(\*DATA);
    ok(!defined $config->get_directive('_', '_config_path')); # 10
    is($config->get_directive('Package', 'max-per-file'), 1); # 11
}

1;

__DATA__
[Package]
max-per-file = 1

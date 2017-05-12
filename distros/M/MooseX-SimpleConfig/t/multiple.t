use strict;
use warnings;

use Test::More;
use Test::Fatal;
use File::Temp 'tempdir';
use File::Spec::Functions;
use lib 't/lib';

BEGIN {

    eval "use YAML::Syck ()";
    if($@) {
        eval "use YAML ()";
        if($@) {
            plan skip_all => "YAML or YAML::Syck required for this test";
        }
    }

    plan tests => 5;

    use_ok('MXSimpleConfigTest');
}

# Can it load a multiple YAML files with options
{
    my $tempdir = tempdir(DIR => 't', CLEANUP => 1);
    my $configfile1 = catfile($tempdir, 'test.yaml');
    my $configfile2 = catfile($tempdir, 'test2.yaml');

    my $test_yaml; # generic filehandle
    open $test_yaml, '>', $configfile1 or die "Cannot create $configfile1: $!";
    print {$test_yaml} "direct_attr: 123\ninherited_ro_attr: asdf\n";
    close $test_yaml or die "Cannot close $configfile1: $!";

    open $test_yaml, '>', $configfile2 or die "Cannot create $configfile2: $!";
    print {$test_yaml} "req_attr: foo\n";
    close $test_yaml or die "Cannot close $configfile2: $!";

    my $foo;
    is(
        exception {
            $foo = MXSimpleConfigTest->new_with_config(
                configfile => [ $configfile1, $configfile2 ]
            );
        },
        undef,
        'Did not die with two YAML config files',
    );

    is($foo->req_attr, 'foo', 'req_attr works');
    is($foo->direct_attr, 123, 'direct_attr works');
    is($foo->inherited_ro_attr, 'asdf', 'inherited_ro_attr works');
}

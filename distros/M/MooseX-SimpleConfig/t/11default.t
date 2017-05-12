use strict;
use warnings;

use lib 't/lib';
use Test::More;
use Test::Fatal;
use File::Temp 'tempdir';
use File::Spec::Functions;

our @classes;
BEGIN {

    @classes = qw/ MXDefaultConfigTest MXDefaultMultipleConfigsTest /;

    eval "use YAML::Syck ()";
    if($@) {
        eval "use YAML ()";
        if($@) {
            plan skip_all => "YAML or YAML::Syck required for this test";
        }
    }

    use_ok($_) for @classes;
}

# Can it load a simple YAML file with the options
#  based on a default in the configfile attr

my $tempdir = tempdir(DIR => 't', CLEANUP => 1);
{
    my $configfile = catfile($tempdir, 'test.yaml');

    open(my $test_yaml, '>', $configfile)
      or die "Cannot create $configfile: $!";
    print $test_yaml "direct_attr: 123\ninherited_ro_attr: asdf\nreq_attr: foo\n";
    close($test_yaml);
}

chdir $tempdir;

foreach my $class (@classes) {
    my $foo;
    is(
        exception { $foo = $class->new_with_config() },
        undef,
        'Did not die with good YAML configfile',
    );

    is($foo->req_attr, 'foo', 'req_attr works');
    is($foo->direct_attr, 123, 'direct_attr works');
    is($foo->inherited_ro_attr, 'asdf', 'inherited_ro_attr works');
}

done_testing;

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 6;
use Test::Fatal;
use File::Temp 'tempdir';
use File::Spec::Functions;

BEGIN {
    use_ok('MXDriverArgsConfigTest');
}

# Does it work with no configfile and not barf?
{
    eval { MXDriverArgsConfigTest->new(req_attr => 'foo') };
    ok(!$@, 'Did not die with no configfile specified')
        or diag $@;
}

# Can it load a simple YAML file with the options
{
    my $tempdir = tempdir(DIR => 't', CLEANUP => 1);
    my $configfile = catfile($tempdir, 'test.pl');

    open(my $test_pl, '>', $configfile)
      or die "Cannot create $configfile: $!";
    print $test_pl <<EOM;
{
    direct_attr => 123,
    inherited_ro_attr => 'asdf',
    req_attr => 'foo',
}
EOM
    close($test_pl);

    my $foo;
    is(
        exception { $foo = MXDriverArgsConfigTest->new_with_config(configfile => $configfile) },
        undef,
        'Did not die with good General configfile',
    );

    is($foo->req_attr, 'foo', 'req_attr works');
    is($foo->direct_attr, 123, 'direct_attr works');
    is($foo->inherited_ro_attr, 'asdf', 'inherited_ro_attr works');
}

use Test::Most tests => 2;
use Cwd;
use FindBin;
use File::Temp;
use YAML::XS;

use lib 'bin';
do 'opentracing_wrapscope_generator';

my $cwd = getcwd();
END { chdir $cwd }                    # don't screw up other tests
chdir "$FindBin::Bin/sample_tree";    # globbing is relative

my @cases = (
    {
        name     => 'everything',
        args     => [ files => [ '*', '*/*' ], ],
        expected => [qw/
            main::run_foo
            TopLvl1::top_1_stuff
            TopLvl1::top_1_something
            TopLvl1::_top_1_private
            TopLvl2::top_2_stuff
            TopLvl2::top_2_something
            TopLvl2::_top_2_private
            Secret::Encryption::get_private_keys
            Secret::Encryption::hash
            Secret::Passwords::get_passwords
        /],
    },
    {
        name     => 'ignore dir',
        args     => [
            files  => [ '*', '*/*' ],
            ignore => [ 'Secret/*' ],
        ],
        expected => [qw/
            main::run_foo
            TopLvl1::top_1_stuff
            TopLvl1::top_1_something
            TopLvl1::_top_1_private
            TopLvl2::top_2_stuff
            TopLvl2::top_2_something
            TopLvl2::_top_2_private
        /],
    },
    {
        name => 'ignore dir but include a sub',
        args => [
            files   => [ '*', '*/*' ],
            ignore  => [ 'Secret/*' ],
            include => [ 'Secret::Encryption::hash' ],
        ],
        expected => [qw/
            main::run_foo
            TopLvl1::top_1_stuff
            TopLvl1::top_1_something
            TopLvl1::_top_1_private
            TopLvl2::top_2_stuff
            TopLvl2::top_2_something
            TopLvl2::_top_2_private
            Secret::Encryption::hash
        /],
    },
    {
        name => 'include a sub with signature',
        args => [
            files   => [ '*', '*/*' ],
            ignore  => [ 'Secret/*' ],
            include => [ 'Secret::Encryption::hash(@args)' ],
        ],
        expected => [qw/
            main::run_foo
            TopLvl1::top_1_stuff
            TopLvl1::top_1_something
            TopLvl1::_top_1_private
            TopLvl2::top_2_stuff
            TopLvl2::top_2_something
            TopLvl2::_top_2_private
            Secret::Encryption::hash(@args)
        /],
    },
    {
        name     => '.pm only',
        args     => [ files => [ '*.pm', '*/*.pm' ], ],
        expected => [qw/
            TopLvl1::top_1_stuff
            TopLvl1::top_1_something
            TopLvl1::_top_1_private
            TopLvl2::top_2_stuff
            TopLvl2::top_2_something
            TopLvl2::_top_2_private
            Secret::Encryption::get_private_keys
            Secret::Encryption::hash
            Secret::Passwords::get_passwords
        /],
    },
    {
        name => 'exclude subs',
        args => [
            files => [ '*.pm', '*/*.pm' ],
            exclude => [qw/
                TopLvl1::top_1_something
                TopLvl2::top_2_something
            /],
        ],
        expected => [qw/
            TopLvl1::top_1_stuff
            TopLvl1::_top_1_private
            TopLvl2::top_2_stuff
            TopLvl2::_top_2_private
            Secret::Encryption::get_private_keys
            Secret::Encryption::hash
            Secret::Passwords::get_passwords
        /],
    },
    {
        name => 'no private subs',
        args => [
            files   => [ '*.pm', '*/*.pm' ],
            filters => ['exclude_private'],
        ],
        expected => [qw/
            TopLvl1::top_1_stuff
            TopLvl1::top_1_something
            TopLvl2::top_2_stuff
            TopLvl2::top_2_something
            Secret::Encryption::get_private_keys
            Secret::Encryption::hash
            Secret::Passwords::get_passwords
        /],
    },
    {
        name     => 'overlapping globs',
        args     => [ files => [ '*.pm', 'Top*' ], ],
        expected => [qw/
            TopLvl1::top_1_stuff
            TopLvl1::top_1_something
            TopLvl1::_top_1_private
            TopLvl2::top_2_stuff
            TopLvl2::top_2_something
            TopLvl2::_top_2_private
        /],
    },
    {
        name     => 'complexity filter',
        args     => [ files => [ '*.pm' ], filters => ['complexity=3'] ],
        expected => [qw/
            TopLvl1::top_1_stuff
            TopLvl2::top_2_stuff
        /],
    },
);

subtest direct => sub {
    plan tests => scalar @cases;
    foreach (@cases) {
        my ($name, $args, $exp) = @$_{qw[ name args expected ]};
        my @got = OpenTracing::WrapScope::ConfigGenerator::examine_files(@$args);
        cmp_deeply \@got, bag(@$exp), $name or diag explain \@got;
    }
};

subtest spec_file => sub {
    plan tests => scalar @cases;
    foreach (@cases) {
        my ($name, $args, $exp) = @$_{qw[ name args expected ]};

        my $spec_file = File::Temp->new(UNLINK => 1);
        YAML::XS::DumpFile($spec_file->filename, {@$args});

        my $result_file = File::Temp->new(UNLINK => 1);
        OpenTracing::WrapScope::ConfigGenerator::run(
            '--spec' => $spec_file->filename,
            '--out'  => $result_file->filename,
        );

        chomp(my @got = <$result_file>);
        cmp_deeply \@got, bag(@$exp), $name or diag explain \@got;
    }
};

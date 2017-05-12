use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::Install;

sub tune (@);
chdir 't/testmod' or die $!;

my %args;

%args = tune Panda::Install::makemaker_args(NAME => 'TestMod', PAYLOAD => {
    'pronlist.txt' => '',
});
cmp_deeply($args{PM}, {'pronlist.txt' => '/$(FULLEXT).x/payload/pronlist.txt'});

%args = tune Panda::Install::makemaker_args(NAME => 'TestMod', PAYLOAD => {
    'pronlist.txt' => '1.txt',
});
cmp_deeply($args{PM}, {'pronlist.txt' => '/$(FULLEXT).x/payload/1.txt'});

%args = tune Panda::Install::makemaker_args(NAME => 'TestMod', PAYLOAD => {
    'pronlist.txt' => 'misc/',
});
cmp_deeply($args{PM}, {'pronlist.txt' => '/$(FULLEXT).x/payload/misc/pronlist.txt'});

%args = tune Panda::Install::makemaker_args(NAME => 'TestMod', PAYLOAD => {
    'pronlist.txt' => 'misc/1.txt',
});
cmp_deeply($args{PM}, {'pronlist.txt' => '/$(FULLEXT).x/payload/misc/1.txt'});

%args = tune Panda::Install::makemaker_args(NAME => 'TestMod', PAYLOAD => {
    'pronlist.txt' => '',
    'data'         => '',
});
cmp_deeply($args{PM}, {
    'pronlist.txt'           => '/$(FULLEXT).x/payload/pronlist.txt',
    'data/db.db'             => '/$(FULLEXT).x/payload/data/db.db',
    'data/data.txt'          => '/$(FULLEXT).x/payload/data/data.txt',
    'data/ccdat/ccdata1.bin' => '/$(FULLEXT).x/payload/data/ccdat/ccdata1.bin',
    'data/ccdat/ccdata2.bin' => '/$(FULLEXT).x/payload/data/ccdat/ccdata2.bin',
});

%args = tune Panda::Install::makemaker_args(NAME => 'TestMod', PAYLOAD => {
    'pronlist.txt' => '',
    'data'         => '/',
});
cmp_deeply($args{PM}, {
    'pronlist.txt'           => '/$(FULLEXT).x/payload/pronlist.txt',
    'data/db.db'             => '/$(FULLEXT).x/payload/db.db',
    'data/data.txt'          => '/$(FULLEXT).x/payload/data.txt',
    'data/ccdat/ccdata1.bin' => '/$(FULLEXT).x/payload/ccdat/ccdata1.bin',
    'data/ccdat/ccdata2.bin' => '/$(FULLEXT).x/payload/ccdat/ccdata2.bin',
});

%args = tune Panda::Install::makemaker_args(NAME => 'TestMod', PAYLOAD => {
    'pronlist.txt' => '',
    'data'         => 'jopa',
});
cmp_deeply($args{PM}, {
    'pronlist.txt'           => '/$(FULLEXT).x/payload/pronlist.txt',
    'data/db.db'             => '/$(FULLEXT).x/payload/jopa/db.db',
    'data/data.txt'          => '/$(FULLEXT).x/payload/jopa/data.txt',
    'data/ccdat/ccdata1.bin' => '/$(FULLEXT).x/payload/jopa/ccdat/ccdata1.bin',
    'data/ccdat/ccdata2.bin' => '/$(FULLEXT).x/payload/jopa/ccdat/ccdata2.bin',
});

%args = tune Panda::Install::makemaker_args(NAME => 'TestMod', PAYLOAD => {
    'data/ccdat/ccdata1.bin' => '/jopa/',
});
cmp_deeply($args{PM}, {
    'data/ccdat/ccdata1.bin' => '/$(FULLEXT).x/payload/jopa/data/ccdat/ccdata1.bin',
});

%args = tune Panda::Install::makemaker_args(NAME => 'TestMod', PAYLOAD => {
    'data/ccdat/ccdata1.bin' => '/jopa/cc1.bin',
});
cmp_deeply($args{PM}, {
    'data/ccdat/ccdata1.bin' => '/$(FULLEXT).x/payload/jopa/cc1.bin',
});

%args = tune Panda::Install::makemaker_args(NAME => 'TestMod', PAYLOAD => {
    'data/ccdat' => '/jopa/',
});
cmp_deeply($args{PM}, {
    'data/ccdat/ccdata1.bin' => '/$(FULLEXT).x/payload/jopa/ccdata1.bin',
    'data/ccdat/ccdata2.bin' => '/$(FULLEXT).x/payload/jopa/ccdata2.bin',
});

done_testing();

sub tune (@) {
    my %args = @_;
    for (values %{$args{PM}||{}}) {
        s/\$\(INST_ARCHLIB\)//;
        s/\$\(INST_LIB\)//;
    }
    delete @{$args{PM}}{'lib/TestMod.pm', 'lib/TestMod/Pack.pm'};
    return %args;
}
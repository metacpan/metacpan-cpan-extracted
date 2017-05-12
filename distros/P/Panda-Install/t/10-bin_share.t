use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::Install;

sub tune (@);
chdir 't/testmod' or die $!;

my %args;

%args = tune Panda::Install::makemaker_args(NAME => 'TestMod', BIN_SHARE => {
    TYPEMAPS => {'typemap.map' => '', 'src2' => '/', 'src/smap.map' => 'extra/map.map' },
    INC      => '/usr/local/libevent/include',
    INCLUDE  => {'src' => '/', 'src2' => '/'},
    LIBS     => ['-levent -lpthread', '-lev -lpthread'],
    DEFINE   => '-DHAVE_PIZDA',
    CCFLAGS  => '-O2',
    XSOPT    => '-nah',
});
cmp_deeply($args{PM}, {
    'typemap.map'  => '/$(FULLEXT).x/tm/typemap.map',
    'src2/s2.map'  => '/$(FULLEXT).x/tm/s2.map',
    'src/smap.map' => '/$(FULLEXT).x/tm/extra/map.map',
    'blib/info'    => '/$(FULLEXT).x/info',
    'src/sfile1.h' => '/$(FULLEXT).x/i/sfile1.h',
    'src/sfile2.h' => '/$(FULLEXT).x/i/sfile2.h',
    'src2/s2.h'    => '/$(FULLEXT).x/i/s2.h',
});

open my $fh, '<', 'blib/info' or die $!;
my $content = join '', <$fh>;
close $fh;
my $info = eval $content;
cmp_deeply($info, {
    TYPEMAPS => bag(qw{ typemap.map s2.map extra/map.map }),
    INC      => '/usr/local/libevent/include',
    INCLUDE  => 1,
    LIBS     => ['-levent -lpthread', '-lev -lpthread'],
    DEFINE   => '-DHAVE_PIZDA',
    CCFLAGS  => '-O2',
    XSOPT    => '-nah'
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
#!/usr/bin/perl
use 5.012;
use lib 'blib/lib', 'blib/arch';
use Benchmark qw/timethis timethese/;
use Data::Dumper qw/Dumper/;
use Path::Class;
use Panda::Config::Perl;

say "START";

my $cfg = Panda::Config::Perl->process('misc/inner.conf');
say Dumper($cfg);

exit;

my $initial_cfg = {
    a => 1,
    b => 2,
    c => [1,2,3],
    d => {a => 1, b => 2},
    root => Path::Class::Dir->new('/home/syber/poker/root'),
    home => Path::Class::Dir->new('/home/syber/poker'),
};
my $cfg;

$cfg = Panda::Config::Perl->process('misc/my.conf', $initial_cfg);
say Dumper($cfg);

#$cfg = Panda::Config::Perl->process('/home/syber/poker/local.conf', $initial_cfg);
#say Dumper($cfg);

timethese(-1, {
    medium => sub { Panda::Config::Perl->process('misc/my.conf', $initial_cfg); },
    #big    => sub { Panda::Config::Perl->process('/home/syber/poker/local.conf', $initial_cfg); },
}) unless $INC{'Devel/NYTProf.pm'};

#Panda::Config::Perl->process('/home/syber/poker/local.conf', $initial_cfg) for 1..1000;

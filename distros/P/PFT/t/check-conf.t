#!/usr/bin/perl -w

use v5.16;

use strict;
use warnings;
use utf8;

use Test::More tests => 12;

use PFT::Conf;

use File::Spec;
use File::Temp qw/tempdir/;
use Encode;
use Encode::Locale;

# Checks about the underneath opts-to-hash system

my %hashy = (
    site => {
        author => 'dachiav',
        encoding => 'utf8',
    },
    remote => {
        path => 'foo/bar',
    },
);
my @listy = (
    'site-author' => 'dachiav',
    'site-encoding' => 'utf8',
    'remote-path' => 'foo/bar',
);

is_deeply(
    PFT::Conf::_hashify(@listy),
    \%hashy,
    "Hashify works"
);

is(
    scalar eval{PFT::Conf::_hashify(
        'site-author' => 'self',
        'site-author-deep' => 1,
    )},
    undef,
    "Broken spec",
);
ok($@ =~ /\Wsite-author-deep\W/,
    "Error message is sound"
);

is(
    scalar eval{PFT::Conf::_hashify(
        'site-author-deep' => 1,
        'site-author' => 'self',
    )},
    undef,
    "Broken spec",
);
ok($@ =~ /\Wsite-author\W/,
    "Error message is sound"
);

do {
    my $conf = PFT::Conf->new_default;
    delete $conf->{site}{author};
    is(eval{$conf->_check_assign}, undef, "Missing check");
    ok($@ =~ /\Wsite-author\W/, "Error message is sound");
};

my $dir = tempdir(CLEANUP => 1);
is(PFT::Conf::locate($dir), undef, "Find dir failure");

# Hope you are not testing this from within a PFT site structure!
is(PFT::Conf::locate(), undef, "Find cwd failure");

my $conf = PFT::Conf->new_default;
die "$dir" unless -e "$dir";
$conf->save_to($dir);
do{
    diag("Conf file dump:");
    open my $f,
        '<:encoding(locale)',
        encode(locale_fs => File::Spec->catfile($dir, $PFT::Conf::CONF_NAME))
    or die $!;
    diag "> $_" for <$f>;
    close $f;
    diag("End")
};
isnt(PFT::Conf::locate($dir), undef, "Find dir success");

is_deeply(PFT::Conf->new_load($dir), $conf, "Load works fine");

mkdir File::Spec->catdir($dir, "foo") or die $!;
mkdir my $subdir = File::Spec->catdir($dir, "foo", "bar") or die $!;
is_deeply(PFT::Conf->new_load_locate($subdir), $conf,
    "Load+locate works fine"
);

done_testing()

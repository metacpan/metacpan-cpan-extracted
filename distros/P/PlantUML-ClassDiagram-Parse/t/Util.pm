package t::Util;

use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', 'lib'));

use parent qw/Exporter/;
our @EXPORT = qw/slurp load_fixture/;

sub slurp {
    my $fname = shift;
    open my $fh, '<:encoding(UTF-8)', $fname or die "$fname: $!";
    do { local $/; <$fh> };
}

sub load_fixture {
    my $fixture_name = shift;
    my $fpath = File::Spec->catdir(dirname(__FILE__), 'fixture', $fixture_name);
    return slurp($fpath);
}


1;

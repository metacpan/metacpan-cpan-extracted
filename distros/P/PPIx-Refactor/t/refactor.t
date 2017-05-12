#!/usr/bin/env perl;
use strictures 2;
use Test::More;
use PPIx::Refactor;
use PPIx::Shorthand qw/get_ppi_class/;
use PPI::Dumper;
use FindBin qw/$Bin/;
use File::Copy;
use File::Temp qw/tempfile/;

my $orig = "$Bin/data/script.pl";
my ($fh, $script) = tempfile();
copy $orig, $script;

my $finder = sub {
    my ($elem, $doc) = @_;
    my $comment = get_ppi_class('comment');
    my $pod = get_ppi_class('pod');
    return 0 unless $elem->isa($comment) || $elem->isa($pod);
    return 0 if $elem->isa($comment) && $elem =~ m{^#!};
    return 1; # comment or pod
};

my $writer = sub {
    my ($finds) = @_;
    foreach my $f (@{$finds}) {
        $f->set_content('');
    }
};



my $ppr = PPIx::Refactor->new(file => $script, ppi_find => $finder, writer => $writer);

is (ref $ppr->finds, 'ARRAY', "got an array ref");
is (scalar @{$ppr->finds}, 4, "four elements returned");
$ppr->rewrite();
my $check = PPIx::Refactor->new(file => $script, ppi_find => $finder);
is (ref $check->finds, 'ARRAY', "second parse results also an array ref");
is (scalar @{$check->finds}, 0, "zero elements returned for rewritten script");
done_testing;

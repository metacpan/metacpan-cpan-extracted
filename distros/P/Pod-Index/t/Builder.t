use strict;
use warnings;
use Test::More;

use File::Spec::Functions;
my ($volume, $dirstring, $file) = File::Spec->splitpath($0);
my @dirs = File::Spec->splitdir($dirstring);
pop @dirs while (@dirs and $dirs[-1] =~ /^(t|)$/);

#plan 'no_plan';
plan tests => 3;

use_ok("Pod::Index::Builder");

my $p = Pod::Index::Builder->new(pi_base => catdir(@dirs));

isa_ok($p, "Pod::Index::Builder");

$p->parse_from_file(catfile(@dirs, 't','test.pod'));

open my $fh, ">", \(my $got) or die;
$p->print_index($fh);

open my $fh_exp, "<", catfile(@dirs, 't', 'test.txt') or die;
my $expected = do { local $/; <$fh_exp> };

is($got, $expected, "index ok");
#use Data::Dumper; print Dumper $p->pod_index;

# create dot from yaml files in example directory and compare

use strict;
use warnings;
use File::Slurp qw(slurp);
use File::Temp;
use Test::More tests => 4;

use OSPF::LSDB::YAML;
use OSPF::LSDB::View;
use OSPF::LSDB::View6;

my %tmpargs = (
    SUFFIX => ".dot",
    TEMPLATE => "ospfview-example-view-XXXXXXXXXX",
    TMPDIR => 1,
    UNLINK => 1,
);

my %todo = (
    cluster  => 1,
    boundary => { aggregate => 1 },
    summary  => { aggregate => 1 },
    external => { aggregate => 1 },
);
my @files = map { "example/$_.yaml" } qw(all ospf);

foreach my $file (@files) {
    (my $dot = $file) =~ s/\.yaml$/.dot/;
    my $yaml = OSPF::LSDB::YAML->new();
    $yaml->LoadFile($file);
    my $class = $file =~ /6/ ? 'OSPF::LSDB::View6' : 'OSPF::LSDB::View';
    my $view = $class->new($yaml);
    my $got = $view->graph(%todo);
    my $expected = slurp($dot);
    is($got, $expected, $dot) or do {
	my $tmp = File::Temp->new(%tmpargs);
	print $tmp $got;
	system('diff', '-up', $dot, $tmp->filename);
    };
}

my @dots = map { "example/legend$_.dot" } ("", 6);

foreach my $dot (@dots) {
    my $class = $dot =~ /6/ ? 'OSPF::LSDB::View6' : 'OSPF::LSDB::View';
    my $got = $class->legend();
    my $expected = slurp($dot);
    # XXX ignore color for now as unimplemented features are red
    $got =~ s/^\s*color=.*\n//mg;
    $expected =~ s/^\s*color=.*\n//mg;
    is($got, $expected, $dot) or do {
	my $tmp = File::Temp->new(%tmpargs);
	print $tmp $got;
	system('diff', '-up', $dot, $tmp->filename);
    };
}

# create dot files from yaml and check content
# test cases are slurped from t/dot6-tests.pl

use strict;
use warnings;
use File::Temp;
use Getopt::Long qw(GetOptionsFromArray :config posix_default bundling);
use Test::NoWarnings;
use Test::More tests => 4*64 + 1;

use OSPF::LSDB::YAML;
use OSPF::LSDB::View6;

# check wether graphviz dot is installed
`dot -?`;
my $skipdot = ($? != 0) || $ENV{OSPFVIEW_DOT_SKIP};

my %tmpargs = (
    SUFFIX => ".eps",
    TEMPLATE => "ospfview-dot6-XXXXXXXXXX",
    TMPDIR => 1,
    UNLINK => 1,
);

my $tests = [ do "t/dot6-tests.pl" ];

foreach my $t (@$tests) {
    next if $ARGV[0] && $ARGV[0] ne $t->{id};
    note($t->{text});

    my %todo;
    $todo{warning}{single} = 1;
    GetOptionsFromArray([$t->{options}],
	b => sub { $todo{boundary}{generate}  = 1 },
	B => sub { $todo{boundary}{aggregate} = 1 },
	c => sub { $todo{cluster} = 1 },
	e => sub { $todo{external}{generate}  = 1 },
	E => sub { $todo{external}{aggregate} = 1 },
	s => sub { $todo{summary}{generate}   = 1 },
	S => sub { $todo{summary}{aggregate}  = 1 },
    ) or die("Bad option: $t->{option}");

    my $ospf = OSPF::LSDB::YAML->new();
    $t->{yaml} .= "ipv6: 1\n";
    $ospf->Load($t->{yaml});
    $ospf = OSPF::LSDB::View6->new($ospf);
    my $dot = $ospf->graph(%todo);

    my @errors = sort $ospf->get_errors();
    is_deeply(\@errors, $t->{errors}, "$t->{id}: errors")
      or diag(explain \@errors);

    my %colors;
    while ($dot =~ /\scolor="(\w+)"\s/g) {
	my $c = $1;
	$colors{$c}++ unless $c =~ /^gray/;
    }
    is_deeply(\%colors, $t->{colors}, "$t->{id}: colors")
      or diag(explain \%colors);

    my %clusters;
    while ($dot =~ /\ssubgraph "cluster ([\w.\/]+)" \{\s/g) {
	$clusters{$1}++;
    }
    is_deeply(\%clusters, $t->{clusters}, "$t->{id}: clusters")
      or diag(explain \%clusters);

    SKIP: {
	skip "graphviz dot is not installed", 1 if $skipdot;

	my $tmp = File::Temp->new(%tmpargs,
	    TEMPLATE => "ospfview-dot6-$t->{id}-XXXXXXXXXX",
	);
	my @cmd = ("dot", "-Tps", "-o", $tmp->filename);
	open(my $fh, '|-', @cmd) or die "Open pipe to '@cmd' failed: $!";
	print $fh $dot;
	close($fh) or $! && die "Close pipe to '@cmd' failed: $!";
	is($?, 0, "$t->{id}: dot exit code");

	# set the environment variable OSPFVIEW_DOT_GV to view the result
	system("gv", $tmp->filename) if $ENV{OSPFVIEW_DOT_GV};
    }
}

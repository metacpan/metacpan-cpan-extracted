
use Test::More qw/no_plan/;
use RRDTool::OO;
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

$SIG{__WARN__} = sub {
    use Carp qw(cluck);
    print cluck();
};

##############################################
# Configuration
##############################################
my $LOGLEVEL = $INFO;  # Level of detail
##############################################

my $rrd = RRDTool::OO->new(file => "foo");

######################################################################
# Create a RRD "foo"
######################################################################

my $start_time     = 1080460200;
my $step           = 60;
my $nof_iterations = 40;
my $end_time       = $start_time + $nof_iterations * $step;

my $rc = $rrd->create(
    start     => $start_time - 10,
    step      => $step,
    data_source => { name      => 'load1',
                     type      => 'GAUGE',
                     min       => 0,
                     max       => 10.0,
                   },
    data_source => { name      => 'load2',
                     type      => 'GAUGE',
                     min       => 0,
                     max       => 10.0,
                   },
    archive     => { cfunc    => 'MAX',
                     xff      => '0.5',
                     cpoints  => 1,
                     rows     => $nof_iterations + 1,
                   },
    archive     => { cfunc    => 'MIN',
                     xff      => '0.5',
                     cpoints  => 1,
                     rows     => $nof_iterations + 1,
                   },
);

is($rc, 1, "create ok");
ok(-f "foo", "RRD exists");

for (0..$nof_iterations) {
    my $time = $start_time + $_ * $step;
    my $value = sprintf("%.2f", 2 + $_ * 0.1);

    $rrd->update(time => $time, values => { 
        load1 => $value,
        load2 => $value+1,
    });
}

############################
## Do some real test here ##
############################
my $results = $rrd->xport(
	start => $start_time,
 	end => $end_time ,
	step => $step,
	def => [{
		vname => "load1_vname",
		file => "foo",
		dsname => "load1",
		cfunc => "MAX",
	},
	{
		vname => "load2_vname",
		file => "foo",
		dsname => "load2",
		cfunc => "MIN",
	}],
	xport => [{
		vname => "load1_vname",
		legend => "it_gonna_be_legend",
	},
	{
		vname => "load2_vname",
		legend => "wait_for_it___dary",
	}],
);

# use Data::Dumper;
# open(D, ">", "/tmp/dumper.txt");
# print D Dumper($results), "\n";
# print D "EndTime: $end_time\n";
# print D "StartTime: $start_time\n";
# close(D);
 
ok(defined($results), "RRDs::xport returns something");

my $meta = $results->{meta};
my $data = $results->{data};

my $r_end = $meta->{end} % $end_time;
my $r_start = $meta->{start} % $start_time;

ok((($r_end == $step) or ($r_end == 0)), "EndTime matches");
ok((($r_start == $step) or ($r_start == 0)), "StartTime matches");
# ok($meta->{rows} == $nof_iterations, "Number of rows matches");
ok(ref($meta->{legend}) eq "ARRAY", "Legend is an ARRAY ref");
ok($meta->{legend}->[0] eq "it_gonna_be_legend", "First legend matches");
ok($meta->{legend}->[1] eq "wait_for_it___dary", "Second legend matches");

# MetaData check
ok($meta->{rows} == scalar @$data, "Number of rows matches metadata");
ok($data->[0]->[0] == $meta->{start}, "First data timestamp matches");
ok($data->[-1]->[0] == $meta->{end}, "Last data timestamp matches");
ok($data->[2]->[0] - $data->[1]->[0] == $meta->{step}, "Step is respected between two entries");

# Some cleanup
unlink("foo");

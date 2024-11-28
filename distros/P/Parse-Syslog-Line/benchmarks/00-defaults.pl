#!perl

use v5.14;
use warnings;
use Dumbbench;
use Const::Fast;
use Parse::Syslog::Line;

use FindBin;
use lib "$FindBin::Bin/../t/lib";
use test::Data;

# Disable warnings
$ENV{PARSE_SYSLOG_LINE_QUIET} = 1;

const my @msgs => map { $_->{string} } values %{ get_test_data() };

my $last = '';
my @copy = ();
my $stub = sub {
    my ($test) = @_;
    @copy = @msgs unless @copy and $last ne $test;
    $last=$test;
    parse_syslog_line(shift @copy);
};

my $bench = Dumbbench->new(
    target_rel_precision => 0.005,
    initial_runs         => 1000,
);

$bench->add_instances(
    Dumbbench::Instance::PerlSub->new( code => sub { $stub->('Defaults') } ),
);

$bench->run();
$bench->report();

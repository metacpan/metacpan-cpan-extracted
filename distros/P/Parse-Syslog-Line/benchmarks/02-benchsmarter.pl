#!perl

use v5.14;
use warnings;
use Const::Fast;
use Dumbbench;
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
    initial_runs         => 1_000,
);

$bench->add_instances(
    Dumbbench::Instance::PerlSub->new(
        name => 'Recommended',
        code => sub {
            local $Parse::Syslog::Line::PruneEmpty          = 1;
            local $Parse::Syslog::Line::AutoDetectKeyValues = 1;
            local $Parse::Syslog::Line::AutoDetectJSON      = 1;
            $stub->('Recommended');
        },
    ),
    Dumbbench::Instance::PerlSub->new(
        name => 'Defaults',
        code => sub { $stub->('Defaults') },
    ),
    Dumbbench::Instance::PerlSub->new(
        name => 'RFC5424Strict',
        code => sub {
            local $Parse::Syslog::Line::RFC5424StructuredDataStrict = 1;
            $stub->('RFC5424Strict')
        },
    ),
    Dumbbench::Instance::PerlSub->new(
        name => 'PruneEmpty',
        code => sub {
            local $Parse::Syslog::Line::PruneEmpty      = 1;
            $stub->('PruneEmpty');
        },
    ),
    Dumbbench::Instance::PerlSub->new(
        name => 'No Dates, Pruned',
        code => sub {
            local $Parse::Syslog::Line::DateParsing     = 0;
            local $Parse::Syslog::Line::PruneRaw        = 1;
            local $Parse::Syslog::Line::PruneEmpty      = 1;
            $stub->('No Dates, Pruned');
        },
    ),
    Dumbbench::Instance::PerlSub->new(
        name => 'No Dates',
        code => sub {
            local $Parse::Syslog::Line::DateParsing     = 0;
            $stub->('No Dates');
        },
    ),
);
$bench->run();
$bench->report();

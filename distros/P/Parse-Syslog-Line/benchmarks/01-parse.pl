#!perl

use v5.16;
use warnings;
use Benchmark qw/timethese cmpthese/;
use Const::Fast;
use Parse::Syslog::Line;

use FindBin;
use lib "$FindBin::Bin/../t/lib";
use test::Data;

# Disable warnings
$ENV{PARSE_SYSLOG_LINE_QUIET} = 1;

const my $COUNT => 50_000;

my %MESSAGES = ();
foreach my $test ( sort { $a->{string} cmp $b->{string} } values %{ get_test_data() } ) {
    my $type = $test->{expected}{datetime_raw} =~ /^\d{4}-\d{2}-\d{2}/ ? 'iso' : 'legacy';
    push @{ $MESSAGES{$type} }, $test->{string};
    push @{ $MESSAGES{mixed} }, $test->{string};
}

header(sprintf "Data sets loaded, messages in: ISO8601=%d, Legacy=%d, Mixed=%d",
    scalar( @{ $MESSAGES{iso} } ),
    scalar( @{ $MESSAGES{legacy} } ),
    scalar( @{ $MESSAGES{mixed} } )
);

my $results = timethese($COUNT, {
    Defaults   => make_test_sub('mixed'),
    PruneEmpty => sub {
        local $Parse::Syslog::Line::PruneEmpty = 1;
        state $stub = make_test_sub();
        $stub->();
    },
    NoDates => sub {
        local $Parse::Syslog::Line::DateParsing = 0;
        state $stub = make_test_sub();
        $stub->();
    },
    JSON => sub {
        local $Parse::Syslog::Line::AutoDetectJSON = 1;
        state $stub = make_test_sub();
        $stub->();
    },
    KV => sub {
        local $Parse::Syslog::Line::AutoDetectKeyValues = 1;
        state $stub = make_test_sub();
        $stub->();
    },
    NoRFCSDATA => sub {
        local $Parse::Syslog::Line::RFC5424StructuredData = 0;
        state $stub = make_test_sub();
        $stub->();
    },
    StrictRFC => sub {
        local $Parse::Syslog::Line::RFC5424StructuredDataStrict = 1;
        state $stub = make_test_sub();
        $stub->();
    },
    AutoSDATA => sub {
        local $Parse::Syslog::Line::AutoDetectJSON = 1;
        local $Parse::Syslog::Line::AutoDetectKeyValues = 1;
        state $stub = make_test_sub();
        $stub->();
    },
});

print "\n";
cmpthese($results);

header("Compare parse timings of ISO8601 and Legacy formats");

my $results_pure = timethese($COUNT, {
    ISO8601 => make_test_sub('iso'),
    Legacy  => make_test_sub('legacy'),
    Mixed   => make_test_sub(),
    NoDates => sub {
        local $Parse::Syslog::Line::DateParsing     = 0;
        state $stub = make_test_sub();
        $stub->();
    },
});

print "\n";
cmpthese($results_pure);
print "\n";

print "Done.\n";

sub make_test_sub {
    my ($dataset) = @_;
    $dataset ||= 'mixed';
    my $i = 0;
    my $set = $MESSAGES{$dataset};
    return sub {
        $i = 0 if $i >= scalar(@{ $set });
        my $m = parse_syslog_line($set->[$i]);
        $i++;
    }
}

sub header {
    my ($header) = @_;
    chomp($header);

    printf "\n%s\n%s\n",
        $header,
        "=" x length($header);
}


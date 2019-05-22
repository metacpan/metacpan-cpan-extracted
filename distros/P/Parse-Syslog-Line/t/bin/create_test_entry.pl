#!perl
#
use strict;
use warnings;

use CLI::Helpers qw(:all);
use Digest::MD5 qw(md5_hex);
use FindBin;
use Getopt::Long::Descriptive;
use Path::Tiny qw(path);
use Test::MockTime;
use YAML ();

# We're in t/bin so ../../lib is the dist lib
use lib "$FindBin::Bin/../../lib";
use Parse::Syslog::Line qw(:with_timezones);

my ($opt,$usage) = describe_options('%c %o',
    ["Tool for generating test data from the command line"],
    [],
    ['options|o|opt=s%',      "Options for Parse::Syslog::Line, ie -o AutoDetectKeyValues=1"],
    ['regenerate|r',     "Regenerate the data foreach existing test case"],
    ['noconfirm|auto|n', "Assume the results are valid, don't prompt for review"],
    [],
    [help => 'Display this help', { shortcircuit => 1 }],
);

if( $opt->help ) {
    print $usage->text;
    exit 0;
}

my $dataDir = path($FindBin::Bin)->parent->child('data');

# Avoid Issues with not being able to source timezone
set_syslog_timezone('UTC');

# this avoids HTTP::Date weirdnes with dates "in the future"
Test::MockTime::set_fixed_time("2018-12-01T00:00:00Z");

my %Options = ();
if ( $opt->options ) {
    %Options = %{ $opt->options };
    foreach my $k ( sort keys %Options ) {
        no strict 'refs';
        verbose({color=>'yellow'}, "Setting Parse::Syslog::Line::$k = $Options{$k}");
        ${"Parse::Syslog::Line::$k"} = $Options{$k};
    }
}

if( $opt->regenerate ) {
    $dataDir->visit(sub {
        my ($p) = @_;
        # Only read YAML Data
        return unless $p->is_file and $p->stringify =~ /\.yaml/;
        # Reading is fatal if it fails, that's cool
        my $contents = YAML::LoadFile( $p->stringify );
        # Generate the Test Case
        generate_test_data( $contents );
    });
}
else {
    output({color=>'magenta'}, "Please enter log entries newline delimited:");
    while(my $msg = <>) {
        chomp($msg);
        generate_test_data({ string => $msg });
    }
}

sub generate_test_data {
    my ($entry) = @_;

    die "Missing 'string' element in the test case"
        unless $entry->{string};

    my $id_str = $entry->{string};
    $id_str   .= YAML::Dump( \%Options ) if $opt->options;
    my $id = md5_hex($id_str);

    $entry->{options}  = \%Options if $opt->options;
    $entry->{expected} = parse_syslog_line($entry->{string});

    output({clear => 1, color=>'cyan'}, $entry->{string});
    output({indent => 1}, split /\r?\n/, YAML::Dump($entry->{expected}));
    next unless $opt->noconfirm or confirm("Does this look correct?");
    $entry->{name} ||= prompt("What name would you give this test? ", default => $id);

    my $file = $dataDir->child("${id}.yaml");
    YAML::DumpFile( $file->absolute->stringify, $entry );
    output({color=>'green'}, sprintf "Created %s for test: %s",
        $file->stringify,
        $entry->{name},
    );
}

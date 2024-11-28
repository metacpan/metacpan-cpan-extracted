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

if( $opt->regenerate ) {
    die "Can't use --options with --regenerate!" if $opt->options;
    $dataDir->visit(sub {
        my ($p) = @_;
        # Only read YAML Data
        return unless $p->is_file and $p->stringify =~ /\.yaml/;
        # Reading is fatal if it fails, that's cool
        my $contents = YAML::LoadFile( $p->stringify );
        # Generate the Test Case in a child to isolate test options
        if ( my $pid = fork() ) {
            while( wait() != -1 ) {}
        }
        else {
            generate_test_data( $contents, id => $p->basename('.yaml') );
            exit 0;
        }
    });
}
else {
    output({color=>'magenta'}, "Please enter log entries newline delimited:");
    while(my $msg = <<>>) {
        chomp($msg);
        generate_test_data({ string => $msg }, options => $opt->options);
    }
}

sub generate_test_data {
    my ($entry,%args) = @_;

    die "Missing 'string' element in the test case"
        unless $entry->{string};

    # Handle options
    $entry->{options}  = $args{options} if $args{options};
    if ( $entry->{options} ) {
        foreach my $k ( keys %{ $entry->{options} } ) {
            no strict 'refs';
            ${"Parse::Syslog::Line::$k"} = $entry->{options}{$k};
        }
    }

    # Generate the data
    $entry->{expected} = parse_syslog_line($entry->{string});

    # Generate a Test ID
    my $id_str = $entry->{string};
    $id_str .= YAML::Dump( $entry->{options} ) if $entry->{options};
    my $id = $args{id} || md5_hex($id_str);

    output({clear => 1, color=>'cyan'}, $entry->{string});
    output({indent => 1}, split /\r?\n/, YAML::Dump($entry->{expected}));
    return unless $opt->noconfirm or confirm("Does this look correct?");
    $entry->{name} ||= prompt("What name would you give this test? ", default => $id);

    my $file = $dataDir->child("${id}.yaml");
    YAML::DumpFile( $file->absolute->stringify, $entry );
    output({color=>'green'}, sprintf "Created %s for test: %s",
        $file->stringify,
        $entry->{name},
    );
}

#!perl

use strict;
use warnings;

use FindBin;
use Data::Dumper;
use Module::Load qw( load );
use Path::Tiny qw(path);
use Test::MockTime;
use Test::More;
use YAML ();

use Parse::Syslog::Line qw/:with_timezones/;

# Avoid Issues with not being able to source timezone
set_syslog_timezone('UTC');

# this avoids HTTP::Date weirdnes with dates "in the future"
Test::MockTime::set_fixed_time("2018-12-01T00:00:00Z");

my $dataDir = path("$FindBin::Bin")->child('data');
my @TESTS = ();

my $JSON_OK;
eval {
    load 'JSON::MaybeXS';
    $JSON_OK++;
};

$dataDir->visit(sub {
    my ($p) = @_;

    # Skip non-yaml files
    return unless $p->is_file and $p->stringify =~ /\.yaml/;

    # Load the Test Data, fatal errors will cause test failures
    eval {
        my $test = YAML::LoadFile( $p->stringify );
        if( $test->{options} and $test->{options}{AutoDetectJSON} ) {
            push @TESTS, $test if $JSON_OK;
        }
        else {
            push @TESTS, $test;
        }
        1;
    } or do {
        my $err = $@;
        fail(sprintf "loading YAML in %s failed: %s",
            $p->stringify,
            $err,
        );
    };
});


my @dtfields = qw/time datetime_obj epoch datetime_str/;

subtest "Basic Functionality Test" => sub {
    # There's other tests for scrutinizing the date data
    my @_delete = qw(datetime_obj epoch offset);

    foreach my $test (sort { $a->{name} cmp $b->{name} } @TESTS) {
        my %restore = ();
        # Adjust Test Settings
        if( $test->{options} ) {
            foreach my $k ( keys %{ $test->{options} } ) {
                no strict 'refs';
                $restore{$k} = ${"Parse::Syslog::Line::$k"};
                ${"Parse::Syslog::Line::$k"} = $test->{options}{$k};
            }
        }
        my $msg = parse_syslog_line($test->{string});
        delete $msg->{$_} for grep { exists $msg->{$_} } @_delete;
        delete $test->{expected}{$_} for grep { exists $test->{expected}{$_} } @_delete;
        is_deeply( $msg, $test->{expected}, $test->{name} ) || diag( Dumper $msg );
        # Restore Defaults
        if( keys %restore ) {
            foreach my $k ( keys %restore ) {
                no strict 'refs';
                ${"Parse::Syslog::Line::$k"} = $restore{$k};
            }
        }
    }

    # Disable Program extraction
    do {
        local $Parse::Syslog::Line::ExtractProgram = 0;
        foreach my $test (sort { $a->{name} cmp $b->{name} } @TESTS) {
            # Skip tests with specific options
            next if exists $test->{options};
            my $msg = parse_syslog_line($test->{string});
            my %expected = %{ $test->{expected} };
            delete $msg->{$_} for @_delete;
            $expected{$_} = undef for qw(program_name program_sub program_pid);

            if( $msg->{content} && $expected{program_raw} ) {
                my $expected_program = $expected{program_raw};
                my $content = delete $msg->{content};
                my $expected_content = delete $expected{content};
                like( $content, qr/\Q$expected_program\E(\s-|:)\s\Q$expected_content\E/, "Content correct" );
            }
            undef($expected{program_raw});

            is_deeply( $msg, \%expected, "$test->{name} (no extract program)" ) || diag(Dumper $msg);
        }
    };
};

subtest 'Custom parser' => sub {

    sub parse_func {
        my ($date) = @_;
        $date //= " ";
        my $modified = "[$date]";

        return $modified;
    }

    local $Parse::Syslog::Line::FmtDate = \&parse_func;

    foreach my $test (sort { $a->{name} cmp $b->{name} } @TESTS) {
        # Skip tests with specific options
        next if exists $test->{options};
        my %resp = %{ $test->{expected} };
        foreach my $part (@dtfields) {
            $resp{$part} = undef;
        }
        $resp{date} = "[" . $resp{datetime_raw} . "]";
        my $msg = parse_syslog_line($test->{string});
        is_deeply( $msg, \%resp, "FmtDate " . $test->{name} );
    }
    done_testing();
};

done_testing();

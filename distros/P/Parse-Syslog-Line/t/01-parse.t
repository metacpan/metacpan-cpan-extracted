#!perl

use strict;
use warnings;

use FindBin;
use Test::MockTime;
use Test::More;
use YAML::XS ();

use lib "$FindBin::Bin/lib";
use test::Data;

use Parse::Syslog::Line qw/:with_timezones/;

# Avoid Issues with not being able to source timezone
use_utc_syslog();

# this avoids HTTP::Date weirdnes with dates "in the future"
Test::MockTime::set_fixed_time("2018-12-01T00:00:00Z");

# Datetime Fields
my @dtfields = qw/date datetime_local datetime_str datetime_utc epoch time tz/;

subtest "Basic Functionality Test" => sub {
    my @delete = qw(datetime_obj);
    my $TESTS = get_test_data();
    foreach my $file (sort keys %{ $TESTS })  {
        my $test = $TESTS->{$file};
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
        delete $msg->{$_} for grep { exists $msg->{$_} } @delete;
        delete $test->{expected}{$_} for grep { exists $test->{expected}{$_} } @delete;
        is_deeply( $msg, $test->{expected}, "$file - $test->{name}" )
            || diag( YAML::XS::Dump($msg) );
        # Restore Defaults
        if( keys %restore ) {
            foreach my $k ( keys %restore ) {
                no strict 'refs';
                ${"Parse::Syslog::Line::$k"} = $restore{$k};
            }
        }
    }
};

subtest 'Disable Program Extraction' => sub {
    local $Parse::Syslog::Line::ExtractProgram = 0;
    my @delete = ();
    my $TESTS = get_test_data();
    foreach my $file (sort keys %{ $TESTS })  {
        my $test = $TESTS->{$file};
        # Skip tests with specific options
        next if exists $test->{options};
        my $msg = parse_syslog_line($test->{string});
        my %expected = %{ $test->{expected} };
        delete $msg->{$_} for @delete;
        $expected{$_} = undef for qw(program_name program_sub program_pid);

        if( $msg->{content} && $expected{program_raw} ) {
            my $expected_program = $expected{program_raw};
            my $content = delete $msg->{content};
            my $expected_content = delete $expected{content};
            like( $content, qr/\Q$expected_program\E(\s-|:)\s\Q$expected_content\E/, "Content correct in $file" );
        }
        undef($expected{program_raw});

        is_deeply( $msg, \%expected, "$file - $test->{name} (no extract program)" )
            || diag( YAML::XS::Dump($msg) );
    }
};

subtest 'Custom parser' => sub {

    sub parse_func {
        my ($date) = @_;
        $date //= " ";
        my $modified = "[$date]";
        return $modified;
    }

    local $Parse::Syslog::Line::FmtDate = \&parse_func;

    my $TESTS = get_test_data();
    foreach my $file (sort keys %{ $TESTS })  {
        my $test = $TESTS->{$file};
        # Skip tests with specific options
        next if exists $test->{options};
        my %resp = %{ $test->{expected} };
        foreach my $part (@dtfields) {
            $resp{$part} = undef;
        }
        $resp{date} = "[" . $resp{datetime_raw} . "]";
        my $msg = parse_syslog_line($test->{string});
        is_deeply( $msg, \%resp, "FmtDate " . $test->{name} )
            || diag( YAML::XS::Dump($msg) );
    }
};

done_testing();

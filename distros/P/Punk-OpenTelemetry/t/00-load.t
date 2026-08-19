#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 11;

BEGIN {
    use_ok( 'Punk::OpenTelemetry' )           || print "Bail out!\n";
    use_ok( 'Punk::OpenTelemetry::Encode' )   || print "Bail out!\n";
    use_ok( 'Punk::OpenTelemetry::OTLP' )     || print "Bail out!\n";
    use_ok( 'Punk::OpenTelemetry::Exporter' ) || print "Bail out!\n";
    use_ok( 'Punk::OpenTelemetry::Tracer' )   || print "Bail out!\n";
    use_ok( 'Punk::OpenTelemetry::Resource' ) || print "Bail out!\n";
    use_ok( 'Punk::OpenTelemetry::Propagate' ) || print "Bail out!\n";
    use_ok( 'Punk::OpenTelemetry::Instrument' ) || print "Bail out!\n";
    use_ok( 'Punk::OpenTelemetry::Meter' )      || print "Bail out!\n";
    use_ok( 'Punk::OpenTelemetry::Logs' )       || print "Bail out!\n";
    use_ok( 'Punk::OpenTelemetry::GRPC' )       || print "Bail out!\n";
}

diag( "Testing Punk::OpenTelemetry $Punk::OpenTelemetry::VERSION, Perl $], $^X" );

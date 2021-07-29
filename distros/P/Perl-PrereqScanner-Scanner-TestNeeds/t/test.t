#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Perl::PrereqScanner;

main();

sub main {
    my $scanner = Perl::PrereqScanner->new( { scanners => ['TestNeeds'] } );

    my $prereqs = $scanner->scan_string(q{use Test::Needs 'Local::Module1'});
    is_deeply( $prereqs->as_string_hash, { 'Local::Module1' => 0 }, 'need one module' );

    $prereqs = $scanner->scan_string(q{use Test::Needs 'Local::Module2', 'Local::Module3'});
    is_deeply( $prereqs->as_string_hash, { 'Local::Module2' => 0, 'Local::Module3' => 0 }, 'need multiple module' );

    $prereqs = $scanner->scan_string(q{use Test::Needs { 'Local::Module4' => '1.050' } });
    is_deeply( $prereqs->as_string_hash, { 'Local::Module4' => '1.050' }, 'need a specific version of a module' );

    $prereqs = $scanner->scan_string(q{use Test::Needs { 'Local::Module5' => '1.006', 'Local::Module6' => '1.007100' } });
    is_deeply( $prereqs->as_string_hash, { 'Local::Module5' => '1.006', 'Local::Module6' => '1.007100' }, 'need a specific version of multiple module' );

    $prereqs = $scanner->scan_string(q{use Test::Needs { 'Local::Module7' => '1.005' }, 'Local::Module8' });
    is_deeply( $prereqs->as_string_hash, { 'Local::Module7' => '1.005', 'Local::Module8' => 0 }, 'need a specific version of a module and one with a version' );

    $prereqs = $scanner->scan_string(q{use Test::Needs { perl => 5.020 } });
    is_deeply( $prereqs->as_string_hash, { perl => '5.020' }, 'Perl 5.20' );

    $prereqs = $scanner->scan_string(q{use Test::Needs { perl => 5.020100 } });
    is_deeply( $prereqs->as_string_hash, { perl => '5.020100' }, 'Perl 5.20.100' );

    $prereqs = $scanner->scan_string(q{use Test::Needs { perl => 5.020001 } });
    is_deeply( $prereqs->as_string_hash, { perl => '5.020001' }, 'Perl 5.20.1' );

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl

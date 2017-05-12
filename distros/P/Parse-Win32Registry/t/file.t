use strict;
use warnings;

use Test::More 'no_plan';
use Parse::Win32Registry 0.60;

sub find_file
{
    my $filename = shift;
    return -d 't' ? "t/$filename" : $filename;
}

{
    my $filename = find_file('win95_key_tests.rf');

    my $registry = Parse::Win32Registry->new($filename);
    ok(defined($registry), 'registry defined');
    isa_ok($registry, 'Parse::Win32Registry::Win95::File');

    my $timestamp_as_string = '(undefined)';

    my $desc = "95";

    ok(fileno($registry->get_filehandle),
        "$desc get_filehandle");
    is($registry->get_filename, $filename,
        "$desc get_filename");
    cmp_ok($registry->get_length, '==', -s $filename,
        "$desc get_length");
    ok(!defined($registry->get_timestamp),
        "$desc get_timestamp undefined (no timestamp)");
    is($registry->get_timestamp_as_string, $timestamp_as_string,
        "$desc get_timestamp_as_string");
    ok(!defined($registry->get_embedded_filename),
        "$desc get_embedded_filename undefined (no embedded filename)");
}

{
    my $filename = find_file('winnt_key_tests.rf');

    my $registry = Parse::Win32Registry->new($filename);
    ok(defined($registry), 'registry defined');
    isa_ok($registry, 'Parse::Win32Registry::WinNT::File');

    my $timestamp = 1162637840;
    my $timestamp_as_string = '2006-11-04T10:57:20Z';
    my $embedded_filename = 'ttings\Administrator\ntuser.dat';

    my $desc = "NT";

    ok(fileno($registry->get_filehandle),
        "$desc get_filehandle");
    is($registry->get_filename, $filename,
        "$desc get_filename");
    cmp_ok($registry->get_length, '==', -s $filename,
        "$desc get_length");
    cmp_ok($registry->get_timestamp, '==', $timestamp,
        "$desc get_timestamp");
    is($registry->get_timestamp_as_string, $timestamp_as_string,
        "$desc get_timestamp_as_string");
    is($registry->get_embedded_filename, $embedded_filename,
        "$desc get_embedded_filename");
}

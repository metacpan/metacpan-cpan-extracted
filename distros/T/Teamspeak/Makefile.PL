#!/usr/bin/perl -w

use strict;
use warnings;
use ExtUtils::MakeMaker qw( WriteMakefile prompt );

my %config = (
    NAME          => 'Teamspeak',
    AUTHOR        => 'Martin von Oertzen <maletin@cpan.org>',
    VERSION_FROM  => 'lib/Teamspeak.pm',
    ABSTRACT_FROM => 'lib/Teamspeak.pm',
    PREREQ_PM     => {
        'Test::More'       => 0,
        'DBI'              => 0,
        'Net::Telnet'      => 0,
        'WWW::Mechanize'   => 0,
        'Test::Signature'  => 1.04,
        'Module::Signature' => 0.22,
    },
    SIGN => 1,
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

my @patterns = qw( t/*.t );
print "Running the extended test needs a running TS-Server!\n";
my $answer = prompt( 'use telnet to connect?', 'no' );
if ( $answer =~ m/^y/i ) {
    print "include Telnet-Tests.\n";
    push @patterns, 't/telnet/*.t';
}
else {
    print "Skipping Telnet-Tests.\n";
}
$answer = prompt( 'use mysql to connect?', 'no' );
if ( $answer =~ m/^y/i ) {
    print "include MySQL-Tests.\n";
    push @patterns, 't/mysql/*.t';
}
else {
    print "Skipping MySQL-Tests.\n";
}
$answer = prompt( 'use sqlite to connect?', 'no' );
if ( $answer =~ m/^y/i ) {
    print "include SQLite-Tests.\n";
    push @patterns, 't/sqlite/*.t';
}
else {
    print "Skipping SQLite-Tests.\n";
}
$answer = prompt( 'use Web-Interface to connect?', 'no' );
if ( $answer =~ m/^y/i ) {
    print "include Web-Tests.\n";
    push @patterns, 't/web/*.t';
}
else {
    print "Skipping Web-Tests.\n";
}
$config{test} = { TESTS => join ' ', map {glob} @patterns };
WriteMakefile(%config);

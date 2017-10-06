#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use File::Basename;
use File::Spec;
use Test::More;
use Test::LongString;

use OTRS::OPM::Installer::Logger;

my $logger = OTRS::OPM::Installer::Logger->new(
    path => File::Spec->catfile( dirname(__FILE__), 'test.log' ),
);

diag "Testing *::Logger version " . OTRS::OPM::Installer::Logger->VERSION;

isa_ok $logger, 'OTRS::OPM::Installer::Logger';

ok $logger->log;

my $file = $logger->log;

is substr( $file, -8 ), 'test.log';

my $start_log = slurp( $file );

like_string $start_log,
    qr/
        ^
        \[DEBUG\] \s+
        \[\d{4}-\d{2}-\d{2} \s \d{2}:\d{2}:\d{2}\] \s+
        Start \s installation \.\.\.
    /xms;

$logger->debug( test => 1 );
my $debug_log = slurp( $file );

like_string $debug_log,
    qr/
        ^
        \[DEBUG\] \s+
        \[\d{4}-\d{2}-\d{2} \s \d{2}:\d{2}:\d{2}\] \s+
        test="1"
    /xms;

$logger->notice( area => 'cpan', module => 'test', message => 'test"msg' );
my $notice_log = slurp( $file );

like_string $notice_log,
    qr/
        ^
        \[NOTICE\] \s+
        \[\d{4}-\d{2}-\d{2} \s \d{2}:\d{2}:\d{2}\] \s+
        area="cpan" \s message="test\\"msg" \s  module="test"
    /xms;


unlink $file;

done_testing();

sub slurp {
    my ($file) = @_;

    return '' if !-f $file;

    my $content;
    {
        local $/ = $file;
        open my $fh, '<', $file;
        $content = <$fh>;
        close $fh;
    }

    return $content;
}

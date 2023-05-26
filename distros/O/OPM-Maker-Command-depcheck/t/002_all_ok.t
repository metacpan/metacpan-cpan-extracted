#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Capture::Tiny ':all';
use t::lib::depcheck;

use_ok 'OPM::Maker::Command::depcheck';

my @packages = (
    { type => 'cpan', name => 'File::Temp', version => 0 },
    { type => 'opm',  name => 'FAQ', version => '6.0.0' },
);

my $file = t::lib::depcheck::build_sopm( @packages );

my ($stdout, $stderr) = capture {
    OPM::Maker::Command::depcheck::execute( undef, { home => $t::lib::depcheck::home}, [ $file ] );
};

ok !$stderr;
unlike $stdout, qr/FAQ/;
unlike $stdout, qr/File::Temp/;

t::lib::depcheck::teardown();

done_testing();

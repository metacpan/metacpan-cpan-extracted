#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Capture::Tiny ':all';

use File::Basename;
use lib dirname(__FILE__) . '/../';

use t::lib::depcheck;

use_ok 'OPM::Maker::Command::depcheck';

my @packages = (
    { type => 'cpan', name => 'File::Temp', version => 0 },
    { type => 'opm',  name => 'FAQ', version => 7 },
);

my $file = t::lib::depcheck::build_sopm( @packages );

my ($stdout, $stderr) = capture {
    OPM::Maker::Command::depcheck::execute( undef, { home => $t::lib::depcheck::home}, [ $file ] );
};

ok !$stderr;
like $stdout, qr/Missing: Addon FAQ 7/;
unlike $stdout, qr/File::Temp/;

t::lib::depcheck::teardown();

done_testing();

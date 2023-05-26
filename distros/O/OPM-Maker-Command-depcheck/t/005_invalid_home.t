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

eval {
    OPM::Maker::Command::depcheck::validate_args( 'OPM::Maker::Command::depcheck', { home => '/tmp/likely/this/doesnt/exist' }, [ $file ] );
};

like $@, qr{No ticketsystem found};

t::lib::depcheck::teardown();

done_testing();

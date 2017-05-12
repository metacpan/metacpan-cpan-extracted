#!/usr/local/bin/perl
use strict;
use inc::Module::Install;

name            'Slash-OurNet';
all_from        'lib/Slash/OurNet.pm';
readme_from     'lib/Slash/OurNet.pm';

requires
    'OurNet::BBS'                   => 1.64,
    'Locale::Maketext::Lexicon'     => 0.32,
    'HTML::FromANSI'                => 0,
    'HTML::FromText'                => 0,
    'Template'                      => 0,
    'Date::Format'                  => 0,
    'Date::Parse'                   => 0,
    'Lingua::ZH::Wrap'              => 0.02,
    'if'                            => 0.03,
    'Devel::Hints'                  => 0.02,
    'PerlIO::via::trap'             => 0.09;

sign; WriteAll;

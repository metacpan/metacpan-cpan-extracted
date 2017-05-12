#!/usr/bin/perl
use inc::Module::Install;

all_from 'lib/MooseX/Types/UniStr.pm';
readme_from 'lib/MooseX/Types/UniStr.pm';

requires qw(
    ok                  0
    Moose               0.50
    MooseX::Types       0
    namespace::clean    0.08
);

sign; WriteAll;

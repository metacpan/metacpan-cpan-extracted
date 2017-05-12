#!/usr/bin/perl
use inc::Module::Install;

license 'CC0';
all_from 'lib/MooseX/Types/Buf.pm';
readme_from 'lib/MooseX/Types/Buf.pm';

requires qw(
    ok                  0
    Moose               0.50
    MooseX::Types       0
    namespace::clean    0.08
);

sign; WriteAll;

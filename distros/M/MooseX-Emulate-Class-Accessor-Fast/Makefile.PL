#! /usr/bin/perl -w

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'MooseX-Emulate-Class-Accessor-Fast';
all_from 'lib/MooseX/Emulate/Class/Accessor/Fast.pm';

# Specific dependencies
requires 'Moose' => '0.84';
requires 'namespace::clean' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::Exception' => 0;

WriteAll;

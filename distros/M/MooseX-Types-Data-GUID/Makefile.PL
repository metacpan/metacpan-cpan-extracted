#! /usr/bin/perl -w

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'MooseX-Types-Data-GUID';
abstract 'Moose Type Constraint and Coercions for Data::GUID objects.';
all_from 'lib/MooseX/Types/Data/GUID.pm';

# Specific dependencies
requires 'Moose';
requires 'Data::GUID';
requires 'MooseX::Types';

build_requires 'Test::More' => 0;

WriteAll;

#! /usr/bin/perl -w

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'POE-Component-DirWatch-Object';
abstract 'Directory watcher for POE';
all_from 'lib/POE/Component/DirWatch/Object.pm';

# Specific dependencies
requires 'POE'            => 0.12;
requires 'Moose'          => 0.05;
requires 'Array::Compare' => 1.13;
requires 'Time::HiRes'    => 0;

build_requires 'Test::More';
build_requires 'Test::Warnings';

auto_install;
WriteAll;

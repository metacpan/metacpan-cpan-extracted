#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 5;

use_ok('SIRTX::VM::Chunk');
use_ok('SIRTX::VM::Chunk::Type');
use_ok('SIRTX::VM::Chunk::Type::ColourPalette');
use_ok('SIRTX::VM::Chunk::Type::OctetStream');
use_ok('SIRTX::VM::Chunk::Type::Padding');

exit 0;

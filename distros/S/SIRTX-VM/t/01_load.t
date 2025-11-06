#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 6;

use_ok('SIRTX::VM');
use_ok('SIRTX::VM::Register');
use_ok('SIRTX::VM::RegisterFile');
use_ok('SIRTX::VM::Opcode');
use_ok('SIRTX::VM::Assembler');
use_ok('SIRTX::VM::Disassembler');

exit 0;

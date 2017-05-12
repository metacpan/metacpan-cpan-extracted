#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib', '../lib';
use Test::More tests => 20;

use_ok('OODoc::Text::SubSection');
use_ok('OODoc::Text::Section');
use_ok('OODoc::Text::Chapter');
use_ok('OODoc::Text::Option');
use_ok('OODoc::Text::Diagnostic');
use_ok('OODoc::Text::Example');
use_ok('OODoc::Text::Default');
use_ok('OODoc::Text::Subroutine');
use_ok('OODoc::Text::Structure');
use_ok('OODoc::Format::Html');
use_ok('OODoc::Format::Pod');
#use_ok('OODoc::Format::Pod2');
use_ok('OODoc::Format::Pod3');
use_ok('OODoc::Parser::Markov');
use_ok('OODoc::Format');
use_ok('OODoc::Object');
use_ok('OODoc::Manual');
use_ok('OODoc::Manifest');
use_ok('OODoc::Parser');
use_ok('OODoc::Text');
use_ok('OODoc');

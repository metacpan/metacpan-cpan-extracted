#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

plan tests => 6;

use_ok('Net::OperaLink');
use_ok('Net::OperaLink::Datatype');
use_ok('Net::OperaLink::Bookmark');
use_ok('Net::OperaLink::Note');
use_ok('Net::OperaLink::Speeddial');

ok(1, 'Basic classes loaded');


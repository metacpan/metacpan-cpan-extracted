#!/usr/bin/env perl -w
# CAVEAT EMPTOR: This file is UTF8 encoded (BOM-less)
# Burak Gürsoy <burak[at]cpan[dot]org>
use strict;
use warnings;
use Test::More qw( no_plan );

BEGIN {
   use_ok('Task::Lingua::Any::Numbers');
   ok( defined $Task::Lingua::Any::Numbers::VERSION, 'Simple test' );
}

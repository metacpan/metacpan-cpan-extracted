use strict;
use warnings;
use Test::More 0.96;
use Test::FailWarnings;

use Log::Any::Test;
use Log::Any qw/$log/;

use lib 't/lib';

use MyModule2;

my $obj = new_ok('MyModule2');

my $log_class = ref $obj->_logger;
like( $log_class, qr/^Log::Any/, "logger came is from Log::Any" );

$obj->cry;

$log->contains_ok( qr/I'm sad/, "got log message" );

done_testing;
#
# This file is part of MooX-Role-Logger
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:

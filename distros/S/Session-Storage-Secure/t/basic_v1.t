use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

$ENV{Session_Storage_Secure_Version} = 1;

note "Running basic tests with protocol version 1";

do './t/basic.t' or die $@ || $!;

#
# This file is part of Session-Storage-Secure
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

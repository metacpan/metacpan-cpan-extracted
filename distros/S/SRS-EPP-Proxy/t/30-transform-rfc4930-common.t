#!/usr/bin/perl -w
#
# test script for transformation of RFC4930 requests to SRS requests,
# and SRS responses to RFC4930 responses.

use strict;
use Test::More;

# Includes:
#
#  - RFC4930 session management commands:
#    - login <=> RegistrarDetailsQry
#    - login with newpassword <=> RegistrarUpdate
#
#  - RFC4930 Query commands
#    - <poll>
#      - 'req' <=> GetMessages
#      - 'ack' <=> AckMessages

plan skip_all => "TODO";

# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>
1

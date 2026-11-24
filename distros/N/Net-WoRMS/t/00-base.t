#!/usr/bin/env perl
# MODULE ACCESABILITY ==================================================
# (C) 2026 by A. Weidauer
# Contact: alex.weidauer@huckfinn.de
# ======================================================================
use strict;
use warnings;
use Test::More tests => 7;
require_ok('Pod::Usage');
require_ok('Data::Dumper');
require_ok('Getopt::Long');
require_ok('Moo');
require_ok('MooX::Types::MooseLike::Base');
require_ok('SOAP::Lite');
require_ok('Net::WoRMS');
done_testing();
# EOF ==================================================================

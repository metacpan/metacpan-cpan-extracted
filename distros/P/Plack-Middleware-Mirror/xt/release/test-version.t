#!/usr/bin/perl
#
# This file is part of Plack-Middleware-Mirror
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.006;
use strict;
use warnings;
use Test::More;

eval "use Test::Version 0.04";
plan skip_all => "Test::Version 0.04 required for testing versions"
    if $@;

version_all_ok();
done_testing;

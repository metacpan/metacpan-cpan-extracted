#!perl
#
# This file is part of Plack-Middleware-Mirror
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use Test::More;

eval 'use Test::Mojibake';
plan skip_all => 'Test::Mojibake required for source encoding testing'
    if $@;

all_files_encoding_ok();

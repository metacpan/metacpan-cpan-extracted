#!perl
#
# This file is part of TBX-Min
#
# This software is copyright (c) 2016 by Alan Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use Test::More;

eval "use Test::DistManifest";
plan skip_all => "Test::DistManifest required for testing the manifest"
  if $@;
manifest_ok();

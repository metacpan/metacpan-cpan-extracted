#!/usr/bin/env perl
use strict;
use warnings;

# Reported at:
# https://github.com/bluefeet/MooseX-BuildArgs/issues/1

package WithBuildArgs {
    use Moose::Role;
    use MooseX::BuildArgs;
};

package AnotherRole {
    use Moose::Role;
};

package Combined {
    use Moose;
    with qw(WithBuildArgs AnotherRole);
};

use Test::More;

TODO: {
  local $TODO = 'Broken per GitHub issues #1.';
  can_ok "Combined", "build_args";
}

done_testing;

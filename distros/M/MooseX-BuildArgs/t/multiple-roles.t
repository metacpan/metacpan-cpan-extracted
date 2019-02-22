#!/usr/bin/env perl
use 5.008001;
use strict;
use warnings;
use Test2::V0;

# Reported at:
# https://github.com/bluefeet/MooseX-BuildArgs/issues/1

{
    package WithBuildArgs;
    use Moose::Role;
    use MooseX::BuildArgs;

    package AnotherRole;
    use Moose::Role;

    package Combined;
    use Moose;
    with qw(WithBuildArgs AnotherRole);
}

todo 'Broken per GitHub issues #1.' => sub{
  can_ok "Combined", "build_args";
};

done_testing;

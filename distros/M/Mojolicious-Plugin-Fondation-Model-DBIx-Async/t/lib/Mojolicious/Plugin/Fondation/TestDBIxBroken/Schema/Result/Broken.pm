package Mojolicious::Plugin::Fondation::TestDBIxBroken::Schema::Result::Broken;

# ABSTRACT: Deliberately unloadable Result class — simulates a missing
# dependency (e.g. DBIx::Class::TimeStamp) to test Action::DBIx's fatal
# error handling.

use base 'DBIx::Class::Core';

# Simulates a missing dependency: loading this class dies with
# "Can't locate Does/Not/Exist.pm in @INC".
require 'Does/Not/Exist.pm';

1;

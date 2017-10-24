#!/usr/bin/env perl
use strict;
use warnings;

use Object::HashBase::Inline;

my ($prefix, $version) = @ARGV;

help() and exit 255 unless $prefix;
help() and exit 0 if grep { m/^-+h(elp)?$/i } @ARGV;

Object::HashBase::Inline::inline($prefix, $version);

sub help {
    print <<"    EOT"
Usage: $0 Prefix::Namespace [module version number]

This will create Prefix::Namespace::HashBase in
lib/Prefix/Namespace/HashBase.pm and add t/HashBase.t.

    EOT
}

1;

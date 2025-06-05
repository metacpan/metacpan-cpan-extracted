#
# This file is part of Perl-Types
#
# This software is copyright (c) 2025 by Auto-Parallel Technologies, Inc.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# [[[ HEADER ]]]
# ABSTRACT: the Perl data type system
package types;
use strict;
use warnings;
use Perl::Config;
our $VERSION = 0.007_000;

# [[[ INCLUDES ]]]
# DEV NOTE: `use types;` is just a shortened syntax-sugar wrapper around the `use perltypes;` pragma
use perltypes;

# [[[ EXPORTS ]]]
# export all symbols imported from essential modules; includes (Data::Dumper, English, Carp, and POSIX) via Perl::Config
use Exporter qw(import);
our @EXPORT = (@perltypes::EXPORT);

1;  # end of package

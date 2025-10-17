#
# This file is part of Perl-Types
#
# This software is Copyright (c) 2025 by Perl Community 501(c)(3) nonprofit organization.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
# [[[ HEADER ]]]
package class;  # creating the first useful Perl pragmas in decades, you're welcome!
use strict;
use warnings;
use Perl::Config;
our $VERSION = 0.001_000;

# [[[ INCLUDES ]]]
# DEV NOTE: "use class;" is just a shortened syntax-sugar wrapper around the "use Perl::Class;" OO base class
use parent qw(Perl::Class);
use Perl::Class;

# [[[ EXPORTS ]]]
# export all symbols imported from essential modules; includes (Data::Dumper, English, Carp, and POSIX) via Perl::Config
use Exporter qw(import);
our @EXPORT = (@Perl::Class::EXPORT);

1;  # end of package

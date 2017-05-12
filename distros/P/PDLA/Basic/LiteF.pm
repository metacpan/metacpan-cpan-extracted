=head1 NAME

PDLA::LiteF - minimum PDLA module function loader

=head1 DESCRIPTION

Loads the smallest possible set of modules for
PDLA to work, making the functions available in
the current namespace. If you want something even
smaller see the L<PDLA::Lite|PDLA::Lite> module.

=head1 SYNOPSIS

 use PDLA::LiteF; # Is equivalent to the following:

   use PDLA::Core;
   use PDLA::Ops;
   use PDLA::Primitive;
   use PDLA::Ufunc;
   use PDLA::Basic;
   use PDLA::Slices;
   use PDLA::Bad;
   use PDLA::Version;
   use PDLA::Lvalue;

=cut

# get the version: 
use PDLA::Version;

package PDLA::LiteF;
$VERSION = $PDLA::Version::VERSION;


# Load the fundamental PDLA packages, with imports

sub PDLA::LiteF::import {

my $pkg = (caller())[0];
eval <<EOD;

package $pkg;

use PDLA::Core;
use PDLA::Ops;
use PDLA::Primitive;
use PDLA::Ufunc;
use PDLA::Basic;
use PDLA::Slices;
use PDLA::Bad;
use PDLA::Lvalue;

EOD

die $@ if $@;

}

;# Exit with OK status

1;

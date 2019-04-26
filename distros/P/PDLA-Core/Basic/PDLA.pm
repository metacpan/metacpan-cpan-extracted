package PDLA;

=head1 NAME

PDLA - the Perl Data Language

=head1 DESCRIPTION

(For the exported PDLA constructor, pdl(), see L<PDLA::Core|PDLA::Core>)

PDLA is the Perl Data Language, a perl extension that is designed for
scientific and bulk numeric data processing and display.  It extends
perl's syntax and includes fully vectorized, multidimensional array
handling, plus several paths for device-independent graphics output.

PDLA is fast, comparable and often outperforming IDL and MATLAB in real
world applications. PDLA allows large N-dimensional data sets such as large
images, spectra, etc to be stored efficiently and manipulated quickly. 


=head1 VECTORIZATION 

For a description of the vectorization (also called "threading"), see
L<PDLA::Core|PDLA::Core>.


=head1 INTERACTIVE SHELL

The PDLA package includes an interactive shell. You can learn about it,
run C<perldoc perldla>, or run the shell C<perldla> or C<pdla2> and type
C<help>.

=head1 LOOKING FOR A FUNCTION?

If you want to search for a function name, you should use the PDLA
shell along with the "help" or "apropos" command (to do a fuzzy search).
For example:

 pdla> apropos xval
 xlinvals        X axis values between endpoints (see xvals).
 xlogvals        X axis values logarithmicly spaced...
 xvals           Fills a piddle with X index values...
 yvals           Fills a piddle with Y index values. See the CAVEAT for xvals.
 zvals           Fills a piddle with Z index values. See the CAVEAT for xvals.

To learn more about the PDLA shell, see L<perldla|perldla> or L<pdla2|pdla2>.

=head1 LANGUAGE DOCUMENTATION

Most PDLA documentation describes the language features. The number of
PDLA pages is too great to list here. The following pages offer some
guidance to help you find the documentation you need.


=over 5

=item L<PDLA::FAQ|PDLA::FAQ>

Frequently asked questions about PDLA. This page covers a lot of
questions that do not fall neatly into any of the documentation
categories.

=item L<PDLA::Tutorials|PDLA::Tutorials>

A guide to PDLA's tutorial-style documentation. With topics from beginner
to advanced, these pages teach you various aspects of PDLA step by step.

=item L<PDLA::Modules|PDLA::Modules>

A guide to PDLA's module reference. Modules are organized by level
(foundation to advanced) and by category (graphics, numerical methods,
etc) to help you find the module you need as quickly as possible.

=item L<PDLA::Course|PDLA::Course>

This page compiles PDLA's tutorial and reference pages into a comprehensive
course that takes you from a complete beginner level to expert.

=item L<PDLA::Index|PDLA::Index>

List of all available documentation, sorted alphabetically. If you
cannot find what you are looking for, try here.

=back


=head1 MODULES

PDLA includes about a dozen perl modules that form the core of the
language, plus additional modules that add further functionality.
The perl module "PDLA" loads all of the core modules automatically,
making their functions available in the current perl namespace.
Some notes:

=over 5

=item Modules loaded by default

See the SYNOPSIS section at the end of this document for a list of
modules loaded by default.

=item L<PDLA::Lite|PDLA::Lite> and L<PDLA::LiteF|PDLA::LiteF>

These are lighter-weight alternatives to the standard PDLA module.
Consider using these modules if startup time becomes an issue.

=item Exports

C<use PDLA;> exports a large number of routines into the calling
namespace.  If you want to avoid namespace pollution, you must instead 
C<use PDLA::Lite>, and include any additional modules explicitly.

=item L<PDLA::NiceSlice|PDLA::NiceSlice>

Note that the L<PDLA::NiceSlice|PDLA::NiceSlice> syntax is NOT automatically
loaded by C<use PDLA;>.  If you want to use the extended slicing syntax in 
a standalone script, you must also say C<use PDLA::NiceSlice;>.

=item L<PDLA::Math|PDLA::Math>

The L<PDLA::Math|PDLA::Math> module has been added to the list of modules
for versions later than 2.3.1. Note that PDLA::Math is still
I<not> included in the L<PDLA::Lite|PDLA::Lite> and L<PDLA::LiteF|PDLA::LiteF>
start-up modules.

=back

=head1 SYNOPSIS

 use PDLA; # Is equivalent to the following:

   use PDLA::Core;
   use PDLA::Ops;
   use PDLA::Primitive;
   use PDLA::Ufunc;
   use PDLA::Basic;
   use PDLA::Slices;
   use PDLA::Bad;
   use PDLA::MatrixOps;
   use PDLA::Math;
   use PDLA::Version;
   use PDLA::IO::Misc;
   use PDLA::IO::FITS;
   use PDLA::IO::Pic;
   use PDLA::IO::Storable;
   use PDLA::Lvalue;

=cut

our $VERSION = "2.019105";

# Main loader of standard PDLA package

sub PDLA::import {

my $pkg = (caller())[0];
eval <<"EOD";

package $pkg;

# Load the fundamental packages

use PDLA::Core;
use PDLA::Ops;
use PDLA::Primitive;
use PDLA::Ufunc;
use PDLA::Basic;
use PDLA::Slices;
use PDLA::Bad;
use PDLA::Math;
use PDLA::MatrixOps;
use PDLA::Lvalue;

# Load these for TPJ compatibility

use PDLA::IO::Misc;          # Misc IO (Ascii)
use PDLA::IO::FITS;          # FITS IO (rfits/wfits; used by rpic/wpic too)
use PDLA::IO::Pic;           # rpic/wpic

# Load this so config/install info is available

use PDLA::Config;

# Load this to avoid mysterious Storable segfaults

use PDLA::IO::Storable;

EOD

die $@ if $@;

}

# support: use Inline with => 'PDLA';
# Returns a hash containing parameters accepted by recent versions of
# Inline, to tweak compilation.  Not normally called by anyone but
# the Inline API.
#
# If you're trying to debug the actual code, you're looking for "IFiles.pm"
# which is currently in the Core directory. --CED 23-Feb-2015
sub Inline {
    require PDLA::Install::Files;
    goto &PDLA::Install::Files::Inline;
}

##################################################
# Rudimentary handling for multiple Perl threads #
##################################################
my $clone_skip_should_be_quiet = 0;
sub CLONE_SKIP {
    warn("* If you need to share PDLA data across threads, use memory mapped data, or\n"
		. "* check out PDLA::Parallel::threads, available on CPAN.\n"
        . "* You can silence this warning by saying `PDLA::no_clone_skip_warning;'\n"
        . "* before you create your first thread.\n")
        unless $clone_skip_should_be_quiet;
    PDLA::no_clone_skip_warning();
    # Whether we warned or not, always return 1 to tell Perl not to clone PDLA data
    return 1;
}
sub no_clone_skip_warning {
    $clone_skip_should_be_quiet = 1;
}

# Exit with OK status
1;

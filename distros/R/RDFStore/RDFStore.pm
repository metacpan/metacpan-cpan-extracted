# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# * Changes:
# *     version 0.1 - 2000/11/03 at 04:30 CEST
# *     version 0.31
# *             - added use (include) of all RDFStore modules suite
# *		- updated documentation
# *     version 0.4
# *		- updated documentation
# *		- removed FindIndex module
# *     version 0.50
# *		- updated to be the corner stone of the RDF storage implemented in C and XS (lots of C and XS code really hoping to gain
# *		  some speed and credibility here :) Here is the place where all magics happen....almost
# *

package RDFStore;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD $use_XSLoader);

#disable crapy 'Use of uninitialized value in subroutine entry ' nightmare warnings; can we do it in the XS code in a portable and back-compatible way??
$SIG{__WARN__} = sub { return if($_[0] =~ /^Use of uninitialized value in subroutine entry/); warn $_[0]; };

require Exporter;
use AutoLoader;
BEGIN {
    $use_XSLoader = 1 ;
    eval { require XSLoader } ;

    if ($@) {
        $use_XSLoader = 0 ;
        require DynaLoader;
        @ISA = qw(DynaLoader);
    };
};

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();

$VERSION='0.51';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined RDFStore macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

if ($use_XSLoader) {
	XSLoader::load("RDFStore", $VERSION);
} else { 
	bootstrap RDFStore $VERSION;
};

# Preloaded methods go here.
# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

=head1 NAME

RDFStore - Perl extesion to store and query RDF graphs

=head1 SYNOPSIS

	use RDFStore;

=head1 DESCRIPTION

RDFStore is......

The code is partially derived from B<Windex>, a free-text search perl extension written by Dirk-Willem van Gulik <dirkx@webweaving.org> and Nick Hibma <n_hibma@van-laarhoven.org>.

=head1 Exported constants

=head1 Exported functions

=head1 AUTHORS

	Alberto Reggiori <areggiori@webweaving.org>
	Dirk-Willem van Gulik <dirkx@webweaving.org>

=head1 SEE ALSO

perl(1).

=cut

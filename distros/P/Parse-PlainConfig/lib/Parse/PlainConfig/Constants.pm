# Parse::PlainConfig::Constants -- PPC Constants
#
# (c) 2016 - 2013, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: lib/Parse/PlainConfig/Constants.pm, 3.07 2024/01/10 13:32:06 acorliss Exp $
#
#    This software is licensed under the same terms as Perl, itself.
#    Please see http://dev.perl.org/licenses/ for more information.
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Parse::PlainConfig::Constants;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Exporter;
use Class::EHierarchy qw(:all);
use Paranoid::Debug;

use base qw(Exporter);

($VERSION) = ( q$Revision: 3.07 $ =~ /(\d+(?:\.(\d+))+)/sm );

use constant PPCDLEVEL1   => PDEBUG6;
use constant PPCDLEVEL2   => PDEBUG7;
use constant PPCDLEVEL3   => PDEBUG8;
use constant PPC_DEF_SIZE => 65_536;

use constant MTIME => 9;

use constant DEFAULT_PDLM => ':';
use constant DEFAULT_LDLM => ',';
use constant DEFAULT_HDLM => '=>';
use constant DEFAULT_CMMT => '#';
use constant DEFAULT_SUBI => 8;
use constant DEFAULT_TAB  => 8;
use constant DEFAULT_TW   => 78;
use constant DEFAULT_HDOC => 'EOF';

use constant PPC_SCALAR => CEH_SCALAR;
use constant PPC_ARRAY  => CEH_ARRAY;
use constant PPC_HASH   => CEH_HASH;
use constant PPC_HDOC   => 1024;

@EXPORT    = qw(PPC_SCALAR PPC_ARRAY PPC_HASH PPC_HDOC);
@EXPORT_OK = (
    @EXPORT, qw(PPCDLEVEL1 PPCDLEVEL2 PPCDLEVEL3 PPC_DEF_SIZE
        MTIME DEFAULT_TW DEFAULT_PDLM DEFAULT_LDLM DEFAULT_HDLM
        DEFAULT_CMMT DEFAULT_SUBI DEFAULT_TAB DEFAULT_HDOC)
        );
%EXPORT_TAGS = (
    all   => [@EXPORT_OK],
    std   => [@EXPORT],
    debug => [qw(PPCDLEVEL1 PPCDLEVEL2 PPCDLEVEL3)],
    );

#####################################################################
#
# Module code follows
#
#####################################################################

1;

__END__

=head1 NAME

Parse::PlainConfig::Constants - PPC Constants

=head1 VERSION

$Id: lib/Parse/PlainConfig/Constants.pm, 3.07 2024/01/10 13:32:06 acorliss Exp $

=head1 SYNOPSIS

    use Parse::PlainConfig::Constants;

    $scalarType = PPC_SCALAR;
    $arrayType  = PPC_ARRAY;
    $hashType   = PPC_HASH;
    $hdocType   = PPC_HDOC;

=head1 DESCRIPTION

This module provides a number of constants that are used mostly internally.
That said, the default export provides the basic data types you'll need to
declare your parameter types.

You can also export debug level constants to provide trace information out to
B<STDERR>.

=head1 SUBROUTINES/METHODS

None.

=head1 CONSTANTS

THere are three export sets provided by this module:

    Set     Description
    ----------------------------------------------------
    std     Parameter data type constants
    debug   Debug level constants
    all     All constants (including internall constants

=head2 std

=head3 PPC_SCALAR

Scalar data type.  Leading and trailing white space is trimmed.

=head3 PPC_ARRAY

Array data type.  Leading and trailing white space for all elements is trimmed.

=head3 PPC_HASH

Hash data type.  Leading and trailing white space for all keys and values is
trimmed.

=head3 PPC_HDOC

Here doc data type.  Functionally equivalent to L<PPC_SCALAR>.

=head2 debug

The higher the debug level the more verbose the output.

=head3 PPCDLEVEL1

=head3 PPCDLEVEL2

=head3 PPCDLEVEL3

=head2 all

=head1 DEPENDENCIES

=over

=item o Exporter

=back

=head1 BUGS AND LIMITATIONS 

=head1 AUTHOR 

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl, itself. 
Please see http://dev.perl.org/licenses/ for more information.

(c) 2016 - 2023, Arthur Corliss (corliss@digitalmages.com)


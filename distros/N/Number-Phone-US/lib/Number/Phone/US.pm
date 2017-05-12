# $Id: US.pm,v 1.5 2002/08/10 05:13:25 kennedyh Exp $
=pod

=head1 NAME

Number::Phone::US - Validate US-style phone numbers

=head1 SYNOPSIS

  use Number::Phone::US qw(is_valid_number);

  &do_that_thing if is_valid_number($input);

=head1 DESCRIPTION

Number::Phone::US is a simple module to validate US-sytle phone number formats.

Currently marks as valid, phone numbers of the following forms:

	 (734) 555 1212
	 (734) 555.1212
	 (734) 555-1212
	 (734) 5551212
	 (734)5551212
	 734 555 1212
	 734.555.1212
	 734-555-1212
	 7345551212
	 555 1212
	 555.1212
	 555-1212
	 5551212
	 5 1212
	 5.1212
	 5-1212
	 51212

Currently marks as invalid, phone numbers of the following forms:

         734-555.1212
         734-5551212

=over 8

=cut
  
package Number::Phone::US;

require 5;

use strict;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA);

require Exporter;

@ISA = qw(Exporter);

$VERSION = (split / /, q$Id: US.pm,v 1.5 2002/08/10 05:13:25 kennedyh Exp $ )[2];

%EXPORT_TAGS = ( );
@EXPORT_OK = qw(&validate_number &is_valid_number &get_regex);

#prototypes

sub validate_number($ );
sub get_regex();

my $ROUGH_MATCH_STRING = q{^\d\d\d([-.\s]?)\d\d\d\1\d\d\d\d$|^(:?(:?\(\d\d\d\))?\s*\d\d)?\d[-.\s]?\d\d\d\d$};

############
#  
=pod

=item validate_number($ )

Use like

  if ( validate_number($number) ) { &foo; }

returns true if $number is a properly formatted US phone number.
does _not_ check and see if $number is a functioning number, although
maybe it should.

this function can also be called as: is_valid_number($number)

=cut
#
############  

sub validate_number ($ ) {
  my ($number) = @_;

  return 1 if $number =~ /$ROUGH_MATCH_STRING/o;
  return 0;

}

# *yaay* aliasing
*is_valid_number = \&validate_number;


############
#  
=pod

=item get_regex ()

Use like

  $rough_regex = get_regex;
  if ( $phone =~ /$rough_regex/o ) { &foo }

returns the rough regex string (does not enforce
phone number consistency.)

=cut
#
############  

sub get_regex () {
  return $ROUGH_MATCH_STRING;
}

=pod

=back

=head1 COPYRIGHT

   COPYRIGHT  2000 THE REGENTS OF THE UNIVERSITY OF MICHIGAN
   ALL RIGHTS RESERVED

   PERMISSION IS GRANTED TO USE, COPY, CREATE DERIVATIVE WORKS
   AND REDISTRIBUTE THIS SOFTWARE AND SUCH DERIVATIVE WORKS FOR
   NON-COMMERCIAL EDUCATION AND RESEARCH PURPOSES, SO LONG AS NO
   FEE IS CHARGED, AND SO LONG AS THE COPYRIGHT NOTICE ABOVE,
   THIS GRANT OF PERMISSION, AND THE DISCLAIMER BELOW APPEAR IN
   ALL COPIES MADE; AND SO LONG AS THE NAME OF THE UNIVERSITY
   OF MICHIGAN IS NOT USED IN ANY ADVERTISING OR PUBLICITY
   PERTAINING TO THE USE OR DISTRIBUTION OF THIS SOFTWARE
   WITHOUT SPECIFIC, WRITTEN PRIOR AUTHORIZATION.

   THIS SOFTWARE IS PROVIDED AS IS, WITHOUT REPRESENTATION AS
   TO ITS FITNESS FOR ANY PURPOSE,  AND WITHOUT WARRANTY OF ANY
   KIND,  EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT
   LIMITATION THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
   FITNESS FOR A PARTICULAR PURPOSE. THE REGENTS OF THE
   UNIVERSITY OF MICHIGAN SHALL NOT BE LIABLE FOR ANY DAMAGES,
   INCLUDING SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
   DAMAGES, WITH RESPECT TO ANY CLAIM ARISING OUT OF OR IN
   CONNECTION WITH THE USE OF THE SOFTWARE, EVEN IF IT HAS BEEN
   OR IS HEREAFTER ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Hugh Kennedy <kennedyh@engin.umich.edu>

     __|   \   __|  \ |
    (     _ \  _|  .  |
   \___|_/  _\___|_|\_|

=cut


'utterly false';

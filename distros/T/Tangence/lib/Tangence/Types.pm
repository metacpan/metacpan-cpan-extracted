#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Tangence::Types;

use strict;
use warnings;

our $VERSION = '0.24';

use Exporter 'import';
our @EXPORT = qw(
   TYPE_BOOL
   TYPE_U8
   TYPE_INT
   TYPE_STR
   TYPE_OBJ
   TYPE_ANY

   TYPE_LIST_STR
   TYPE_LIST_ANY

   TYPE_DICT_ANY
);

use Tangence::Type;

use constant TYPE_BOOL => Tangence::Type->new( "bool" );
use constant TYPE_U8   => Tangence::Type->new( "u8" );
use constant TYPE_INT  => Tangence::Type->new( "int" );
use constant TYPE_STR  => Tangence::Type->new( "str" );
use constant TYPE_OBJ  => Tangence::Type->new( "obj" );
use constant TYPE_ANY  => Tangence::Type->new( "any" );

use constant TYPE_LIST_STR => Tangence::Type->new( list => TYPE_STR );
use constant TYPE_LIST_ANY => Tangence::Type->new( list => TYPE_ANY );

use constant TYPE_DICT_ANY => Tangence::Type->new( dict => TYPE_ANY );

0x55AA;

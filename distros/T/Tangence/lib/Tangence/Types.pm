#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Tangence::Types 0.28;

use v5.26;
use warnings;

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

use constant TYPE_BOOL => Tangence::Type->make( "bool" );
use constant TYPE_U8   => Tangence::Type->make( "u8" );
use constant TYPE_INT  => Tangence::Type->make( "int" );
use constant TYPE_STR  => Tangence::Type->make( "str" );
use constant TYPE_OBJ  => Tangence::Type->make( "obj" );
use constant TYPE_ANY  => Tangence::Type->make( "any" );

use constant TYPE_LIST_STR => Tangence::Type->make( list => TYPE_STR );
use constant TYPE_LIST_ANY => Tangence::Type->make( list => TYPE_ANY );

use constant TYPE_DICT_ANY => Tangence::Type->make( dict => TYPE_ANY );

0x55AA;

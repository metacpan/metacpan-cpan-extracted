#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2016 -- leonerd@leonerd.org.uk

package Tangence::Constants;

use strict;
use warnings;

our $VERSION = '0.25';

use Exporter 'import';
our @EXPORT = qw(
   MSG_CALL
   MSG_SUBSCRIBE
   MSG_UNSUBSCRIBE
   MSG_EVENT
   MSG_GETPROP
   MSG_SETPROP
   MSG_WATCH
   MSG_UNWATCH
   MSG_UPDATE
   MSG_DESTROY
   MSG_GETPROPELEM
   MSG_WATCH_CUSR
   MSG_CUSR_NEXT
   MSG_CUSR_DESTROY
   MSG_GETROOT
   MSG_GETREGISTRY
   MSG_INIT

   MSG_OK
   MSG_ERROR
   MSG_RESULT
   MSG_SUBSCRIBED
   MSG_WATCHING
   MSG_WATCHING_CUSR
   MSG_CUSR_RESULT
   MSG_INITED

   DIM_SCALAR
   DIM_HASH
   DIM_QUEUE
   DIM_ARRAY
   DIM_OBJSET

   DIMNAMES

   CHANGE_SET
   CHANGE_ADD
   CHANGE_DEL
   CHANGE_PUSH
   CHANGE_SHIFT
   CHANGE_SPLICE
   CHANGE_MOVE

   CHANGETYPES

   CUSR_FIRST
   CUSR_LAST
   CUSR_FWD
   CUSR_BACK

   DATA_NUMBER
   DATA_STRING
   DATA_LIST
   DATA_DICT
   DATA_OBJECT
   DATA_RECORD
   DATA_META

   DATANUM_BOOLFALSE
   DATANUM_BOOLTRUE
   DATANUM_UINT8
   DATANUM_SINT8
   DATANUM_UINT16
   DATANUM_SINT16
   DATANUM_UINT32
   DATANUM_SINT32
   DATANUM_UINT64
   DATANUM_SINT64
   DATANUM_FLOAT16
   DATANUM_FLOAT32
   DATANUM_FLOAT64

   DATAMETA_CONSTRUCT
   DATAMETA_CLASS
   DATAMETA_STRUCT

   VERSION_MAJOR
   VERSION_MINOR
);

# Message types

# Requests
use constant MSG_CALL => 0x01;
use constant MSG_SUBSCRIBE => 0x02;
use constant MSG_UNSUBSCRIBE => 0x03;
use constant MSG_EVENT => 0x04;
use constant MSG_GETPROP => 0x05;
use constant MSG_SETPROP => 0x06;
use constant MSG_WATCH => 0x07;
use constant MSG_UNWATCH => 0x08;
use constant MSG_UPDATE => 0x09;
use constant MSG_DESTROY => 0x0a;
use constant MSG_GETPROPELEM => 0x0b;
use constant MSG_WATCH_CUSR => 0x0c;
use constant MSG_CUSR_NEXT => 0x0d;
use constant MSG_CUSR_DESTROY => 0x0e;

use constant MSG_GETROOT => 0x40;
use constant MSG_GETREGISTRY => 0x41;
use constant MSG_INIT => 0x7f;

# Responses
use constant MSG_OK => 0x80;
use constant MSG_ERROR => 0x81;
use constant MSG_RESULT => 0x82;
use constant MSG_SUBSCRIBED => 0x83;
use constant MSG_WATCHING => 0x84;
use constant MSG_WATCHING_CUSR => 0x85;
use constant MSG_CUSR_RESULT => 0x86;

use constant MSG_INITED => 0xff;


# Property dimensions
use constant DIM_SCALAR => 1;
use constant DIM_HASH   => 2;
use constant DIM_QUEUE  => 3;
use constant DIM_ARRAY  => 4;
use constant DIM_OBJSET => 5;

use constant DIMNAMES => [
   undef,
   "scalar",
   "hash",
   "queue",
   "array",
   "objset",
];

# Property change types
use constant CHANGE_SET    => 1;
use constant CHANGE_ADD    => 2;
use constant CHANGE_DEL    => 3;
use constant CHANGE_PUSH   => 4;
use constant CHANGE_SHIFT  => 5;
use constant CHANGE_SPLICE => 6;
use constant CHANGE_MOVE   => 7;

use constant CHANGETYPES => {
   DIM_SCALAR() => [qw( on_set )],
   DIM_HASH()   => [qw( on_set on_add on_del )],
   DIM_QUEUE()  => [qw( on_set on_push on_shift )],
   DIM_ARRAY()  => [qw( on_set on_push on_shift on_splice on_move )],
   DIM_OBJSET() => [qw( on_set on_add on_del )],
};

# Cursor messages
use constant CUSR_FIRST => 1;
use constant CUSR_LAST => 2;
use constant CUSR_FWD => 1;
use constant CUSR_BACK => 2;

# Stream data types
use constant DATA_NUMBER => 0;
use constant DATANUM_BOOLFALSE => 0;
use constant DATANUM_BOOLTRUE  => 1;
use constant DATANUM_UINT8     => 2;
use constant DATANUM_SINT8     => 3;
use constant DATANUM_UINT16    => 4;
use constant DATANUM_SINT16    => 5;
use constant DATANUM_UINT32    => 6;
use constant DATANUM_SINT32    => 7;
use constant DATANUM_UINT64    => 8;
use constant DATANUM_SINT64    => 9;
use constant DATANUM_FLOAT16   => 16;
use constant DATANUM_FLOAT32   => 17;
use constant DATANUM_FLOAT64   => 18;
use constant DATA_STRING => 1;
use constant DATA_LIST   => 2;
use constant DATA_DICT   => 3;
use constant DATA_OBJECT => 4;
use constant DATA_RECORD => 5;
use constant DATA_META   => 7;
use constant DATAMETA_CONSTRUCT => 1;
use constant DATAMETA_CLASS     => 2;
use constant DATAMETA_STRUCT    => 3;

use constant VERSION_MAJOR => 0;
use constant VERSION_MINOR => 4;

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

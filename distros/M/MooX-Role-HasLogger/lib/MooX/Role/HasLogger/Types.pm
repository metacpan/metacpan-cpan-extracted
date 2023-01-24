#<<<
use strict; use warnings;
#>>>

package MooX::Role::HasLogger::Types;

our $VERSION = '0.001';

use Type::Library -base, -declare => qw( Logger );
use Types::Standard qw( HasMethods );
use Type::Utils     qw( declare as );

declare 'Logger',
  as HasMethods [ qw( is_trace trace is_debug debug is_info info is_warn warn is_error error is_fatal fatal ) ];

1;

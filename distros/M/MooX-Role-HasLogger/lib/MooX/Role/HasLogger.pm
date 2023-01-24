#<<<
use strict; use warnings;
#>>>

package MooX::Role::HasLogger;

our $VERSION = '0.001';

use Log::Any                     qw();
use MooX::Role::HasLogger::Types qw( Logger );
use Moo::Role                    qw( has );

has logger => ( is => 'ro', isa => Logger, lazy => 1, builder => 'build_logger' );

sub build_logger {
  return Log::Any->get_logger( category => ref shift );
}

1;

#line 1
package Test2::Event::Waiting;
use strict;
use warnings;

our $VERSION = '1.302073';


BEGIN { require Test2::Event; our @ISA = qw(Test2::Event) }

sub global { 1 };

sub summary { "IPC is waiting for children to finish..." }

1;

__END__

#line 61

package QPicture;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require QPaintDevice;

@ISA = qw(DynaLoader QPaintDevice);

$VERSION = '0.02';
bootstrap QPicture $VERSION;

1;
__END__

=head1 NAME

QPicture - Interface to the Qt QPicture class

=head1 SYNOPSIS

C<use QPicture;>

Inherits QPaintDevice.

=head2 Member functions

=head1 DESCRIPTION

What you see is what you get.

=head1 SEE ALSO

QPicture(3qt)

=head1 AUTHOR

Ashley Winters <jql@accessone.com>

package Spreadsheet::Engine::Fn::depreciation;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::math';

sub signature { 'n', 'n', '>=1' }
sub result_type { Spreadsheet::Engine::Value->new(type => 'n$') }

1;

__END__

=head1 NAME

Spreadsheet::Engine::Fn::depreciation - base class for depreciation functions

=head1 SYNOPSIS

  use base 'Spreadsheet::Engine::Fn::depreciation';

  sub depreciate { ... }

=head1 DESCRIPTION

This provides a base class for spreadsheet functions that perform
different methods of depreciation.

=head1 INSTANCE METHODS

=head2 depreciate

Subclasses should provide a 'depreciate' function that will be called with 
the cost, salvage, and lifetime operands. (Other operands can be taken
from the stack if required.)

=head1 HISTORY

This is a Modified Version of code extracted from SocialCalc::Functions
in SocialCalc 1.1.0

=head1 COPYRIGHT

Portions (c) Copyright 2005, 2006, 2007 Software Garden, Inc.
All Rights Reserved.

Portions (c) Copyright 2007 Socialtext, Inc.
All Rights Reserved.

Portions (c) Copyright 2008 Tony Bowden

=head1 LICENCE

The contents of this file are subject to the Artistic License 2.0;
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
  http://www.perlfoundation.org/artistic_license_2_0



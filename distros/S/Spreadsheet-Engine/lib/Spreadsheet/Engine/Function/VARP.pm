package Spreadsheet::Engine::Function::VARP;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Function::VAR';

sub result_from {
  my ($self, $A) = @_;
  die Spreadsheet::Engine::Error->div0 unless $A->{count} > 1;
  return $A->{sk} / $A->{count};
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::VARP - Spreadsheet funtion VARP()

=head1 SYNOPSIS

  =VARP(list_of_numbers)

=head1 DESCRIPTION

This returns the variance.

We calculate as per Knuth "The Art of Computer Programming" Vol. 2
3rd edition, page 232

=head1 HISTORY

This is a Modified Version of code extracted from SocialCalc::Functions
in SocialCalc 1.1.0

=head1 COPYRIGHT

Portions (c) Copyright 2005, 2006, 2007 Software Garden, Inc.
All Rights Reserved.

Portions (c) Copyright 2007 Socialtext, Inc.
All Rights Reserved.

Portions (c) Copyright 2007, 2008 Tony Bowden

=head1 LICENCE

The contents of this file are subject to the Artistic License 2.0;
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
  http://www.perlfoundation.org/artistic_license_2_0



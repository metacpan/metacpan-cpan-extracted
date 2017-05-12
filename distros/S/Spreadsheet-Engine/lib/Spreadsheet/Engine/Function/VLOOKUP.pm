package Spreadsheet::Engine::Function::VLOOKUP;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Function::HLOOKUP';

sub _crincs {
  my $self = shift;
  my ($rangesheetdata, $rangecol1num, $nrangecols, $rangerow1num, $nrangerows)
    = $self->_range_data;
  my $of = $self->_offset_op;
  die Spreadsheet::Engine::Error->ref if $of->value > $nrangerows;
  return (0, 0, 0, 1);
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::VLOOKUP - Spreadsheet funtion VLOOKUP()

=head1 SYNOPSIS

  =VLOOKUP(value,range,row,[sorted])

=head1 DESCRIPTION

Find a value in the first column of a table, and return the value from a
corresponding column.

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



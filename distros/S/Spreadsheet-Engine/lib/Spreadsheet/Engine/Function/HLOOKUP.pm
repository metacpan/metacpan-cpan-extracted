package Spreadsheet::Engine::Function::HLOOKUP;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Function::MATCH';
use Spreadsheet::Engine::Sheet 'cr_to_coord';

sub argument_count { -3 => 4 }
sub signature { '*', 'r', '>=1', 'n' }

sub _offset_op { (shift->_ops)[2] }
sub _sorted_op { (shift->_ops)[3] }

sub _gotit {
  my ($self, $cr) = @_;
  my ($c,    $r)  = @{$cr};
  my ($rangesheetdata, $rangecol1num, $nrangecols, $rangerow1num, $nrangerows)
    = $self->_range_data;
  my $offset = $self->_offset_op->value;
  my $coord  = cr_to_coord(
    $rangecol1num + $c + ($self->fname eq 'VLOOKUP' ? $offset - 1 : 0),
    $rangerow1num + $r + ($self->fname eq 'HLOOKUP' ? $offset - 1 : 0)
  );

  return Spreadsheet::Engine::Value->new(
    type  => $rangesheetdata->{valuetypes}->{$coord},
    value => $rangesheetdata->{datavalues}->{$coord},
  );
}

sub _crincs {
  my $self = shift;
  my ($rangesheetdata, $rangecol1num, $nrangecols, $rangerow1num, $nrangerows)
    = $self->_range_data;
  my $of = $self->_offset_op;
  die Spreadsheet::Engine::Error->ref if $of->value > $nrangerows;
  return (0, 0, 1, 0);
}

sub _sorted {
  my $self = shift;
  my $op = $self->_sorted_op or return 1;
  return $op->value ? 1 : 0;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::HLOOKUP - Spreadsheet funtion HLOOKUP()

=head1 SYNOPSIS

  =HLOOKUP(value,range,row,[sorted])

=head1 DESCRIPTION

Find a value in the first row of a table, and return the value from a
corresponding row.

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



package Spreadsheet::Engine::Function::MATCH;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::base';
use Encode;

sub argument_count { -2 => 3 }
sub signature { '*', 'r', 'n' }

use Spreadsheet::Engine::Sheet
  qw/top_of_stack_value_and_type decode_range_parts/;
use Spreadsheet::Engine::Functions qw/cr_to_coord/;

sub _want_op   { (shift->_ops)[0] }
sub _range_op  { (shift->_ops)[1] }
sub _sorted_op { (shift->_ops)[2] }

sub result {
  my $self   = shift;
  my $want   = $self->_want_op;
  my $sorted = $self->_sorted;

  my ($c, $r, $cincr, $rincr) = $self->_crincs;
  my ($rangesheetdata, $rangecol1num, $nrangecols, $rangerow1num, $nrangerows)
    = $self->_range_data;

  my $previousOK = 0;
  while ($r < $nrangerows && $c < $nrangecols) {
    my $cr = cr_to_coord($rangecol1num + $c, $rangerow1num + $r);
    my $got = Spreadsheet::Engine::Value->new(
      value => $rangesheetdata->{datavalues}->{$cr},
      type  => $rangesheetdata->{valuetypes}->{$cr} || 'b',
    );

    my $cmp = _cmp_op($want, $got);
    next unless defined $cmp;
    return $self->_gotit([ $c, $r ]) if $cmp == 0;

    # If sorted, cache possible result
    if (($sorted > 0 && $cmp == 1) || ($sorted < 0 && $cmp == -1)) {
      $previousOK = [ $c, $r ];
      next;
    }

    return $self->_gotit($previousOK) if $previousOK;
  } continue {
    $r += $rincr;
    $c += $cincr;
  }

  # end of range to check, no exact match
  return $self->_gotit($previousOK) if $previousOK;
  die Spreadsheet::Engine::Error->na;
}

sub _gotit {
  my ($self, $cr) = @_;
  my ($c,    $r)  = @{$cr};
  return Spreadsheet::Engine::Value->new(
    type  => 'n',
    value => $c + $r + 1,
  );
}

sub _range_data {
  my $self  = shift;
  my $range = $self->_range_op->value;
  return decode_range_parts($self->sheetdata, @{$range}{qw/value type/});
}

sub _crincs {
  my $self = shift;
  my ($rangesheetdata, $rangecol1num, $nrangecols, $rangerow1num, $nrangerows)
    = $self->_range_data;
  die Spreadsheet::Engine::Error->na if $nrangerows > 1 and $nrangecols > 1;
  my ($cincr, $rincr) = (0, 0);
  $nrangecols > 1 ? $cincr = 1 : $rincr = 1;
  return (0, 0, $cincr, $rincr);
}

sub _sorted {
  my $self = shift;
  my $op = $self->_sorted_op or return 1;
  return $op->value;
}

# TODO promote this to Value with overloading
sub _cmp_op {
  my ($op1, $op2) = @_;
  return unless substr($op1->type, 0, 1) eq substr($op2->type, 0, 1);
  my ($X, $Y) = map $_->value, ($op1, $op2);
  return $X <=> $Y if $op1->is_num;
  return lc(decode('utf8', $X)) cmp lc(decode('utf8', $Y));
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::MATCH - Spreadsheet funtion MATCH()

=head1 SYNOPSIS

  =MATCH(value,range,[matchtype])

=head1 DESCRIPTION

Return the position at which a value was found in a range.

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



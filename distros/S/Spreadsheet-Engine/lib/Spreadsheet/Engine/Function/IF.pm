package Spreadsheet::Engine::Function::IF;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::base';

sub signature { '*', '*', '*' }
sub _error_ops_ok { 1 }

sub result {
  my $self = shift;
  my ($cond, $trueval, $falseval) = $self->_ops;
  return Spreadsheet::Engine::Error->val
    unless $cond->is_num
    or $cond->is_blank;
  return $cond->value ? $trueval : $falseval;
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::IF - Spreadsheet funtion IF()

=head1 SYNOPSIS

  =IF(condition, truevalue, falsevalue)

=head1 DESCRIPTION

This returns the truevalue if condition is true, or falsevalue if it is
false.

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



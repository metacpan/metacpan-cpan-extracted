package Spreadsheet::Engine::Function::LOG;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::math';

sub argument_count { -1 => 2 }
sub signature { '>0', '>0' }
sub _result_type_key { 'oneargnumeric' }

sub calculate {
  my ($self, $value, $base) = @_;
  $base ||= 10;
  return log($value) / log($base);
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::LOG - Spreadsheet funtion LOG()

=head1 SYNOPSIS

  =LOG(value, [base])

=head1 DESCRIPTION

This calculates the logarithm of a number in a specified base. If no
base is specified base 10 is assumed.

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



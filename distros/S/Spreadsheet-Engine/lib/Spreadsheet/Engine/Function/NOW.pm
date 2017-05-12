package Spreadsheet::Engine::Function::NOW;

use strict;
use warnings;

use base 'Spreadsheet::Engine::Fn::base';
use Time::Local;

sub argument_count { 0 }
sub result_type    { 'nd' }

sub _start_time {
  my ($self, $time) = @_;
  return timegm((localtime($time))[ 0 .. 5 ]);
}

sub result {
  my $self             = shift;
  my $startval         = time();
  my $s1970            = 25569;         # 1/1/1970 starting with 1/1/1900 as 1
  my $seconds_in_a_day = 24 * 60 * 60;
  my $time2   = $self->_start_time($startval);
  my $offset  = ($time2 - $startval) / (60 * 60);
  my $nowdays = $s1970 + $time2 / $seconds_in_a_day;
  return Spreadsheet::Engine::Value->new(
    type  => $self->result_type,
    value => $nowdays,
  );
}

1;

__END__

=head1 NAME

Spreadsheet::Engine::Function::NOW - Spreadsheet funtion NOW()

=head1 SYNOPSIS

  =NOW()

=head1 DESCRIPTION

The current date and time.

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



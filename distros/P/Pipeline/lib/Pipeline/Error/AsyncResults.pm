package Pipeline::Error::AsyncResults;

use strict;

use Error;
use base qw( Error );

our $VERSION = "3.12";

sub new {
  my $class = shift;

  my $caller = caller(1);
  my $text = "asynchronous handler returned unexpected results";

  local $Error::Depth = $Error::Depth + 1;
  local $Error::Debug = 1;  # Enables storing of stacktrace

  $class->SUPER::new(-text => $text, @_); 
}

1;

=head1 NAME

Pipeline::Error::AsyncResults - exception thrown from asynchronous segments

=head1 SYNOPSIS

  use Pipeline::Error::AsyncResults;

  throw Pipeline::Error::AsyncResults;

=head1 DESCRIPTION

C<Pipeline::Error::AsyncResults> inherits from C<Error> and will be thrown
whenever results back from asynchronous segments do not match the protocol
expected.

=head1 SEE ALSO

C<Pipeline::Segment::Async> C<Error>

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This module is released under the same license as Perl itself.

=cut

package Pipeline::Error::Abstract;

use strict;

use Error;
use base qw( Error );

our $VERSION = "3.12";

sub new {
  my $class = shift;

  my $caller = caller(1);
  my $text = "cannnot call abstract method in $caller";

  local $Error::Depth = $Error::Depth + 1;
  local $Error::Debug = 1;  # Enables storing of stacktrace

  $class->SUPER::new(-text => $text, @_); 
}

1;

=head1 NAME

Pipeline::Error::Abstract - exception thrown from abstract methods

=head1 SYNOPSIS

  use Pipeline::Error::Abstract;
  
  throw Pipeline::Error::Abstract;
  
=head1 DESCRIPTION

C<Pipeline::Error::Abstract> inherits from C<Error> and will be thrown by
any non-implemented abstract methods in the Pipeline module.

=head1 SEE ALSO

C<Pipeline::Error::Construction> C<Error>

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This module is released under the same license as Perl itself.

=cut

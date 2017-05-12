package Pipeline::Error::Construction;

use strict;

use Error;
use base qw( Error );

our $VERSION = "3.12";

sub new {
  my $class = shift;

  my $caller = caller(1);
  my $text = "cannot create object of type $caller";

  local $Error::Depth = $Error::Depth + 1;
  local $Error::Debug = 1;  # Enables storing of stacktrace

  $class->SUPER::new(-text => $text, @_); 
}

1;


=head1 NAME

Pipeline::Error::Construction - exception thrown during object construction failure

=head1 SYNOPSIS

  use Pipeline::Error::Construction;
  
  throw Pipeline::Error::Construction;
  
=head1 DESCRIPTION

C<Pipeline::Error::Construction> inherits from C<Error> and will be thrown by
any constructor in the Pipeline module that fails to properly assemble itself.

=head1 SEE ALSO

C<Pipeline::Error::Abstract> C<Error>

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This module is released under the same license as Perl itself.

=cut


package MyPipeCleanup;

use strict;
use warnings::register;
use Pipeline::Segment;
use base qw ( Pipeline::Segment );

sub dispatch {
  ## resets the number of instances that the MyPipe class
  ## has created

  $MyPipe::instance = 0;
  return 1;
}

1;

__END__

=head1 NAME

MyPipeCleanup

=head1 DESCRIPTION

C<MyPipeCleanup> is a module used by the C<Pipeline> tests which
resets the C<MyPipe> instance count.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This software is released under the same terms as Perl itself.

=cut

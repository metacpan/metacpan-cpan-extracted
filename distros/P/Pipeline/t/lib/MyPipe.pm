package MyPipe;

use MyPipeCleanup;
use Pipeline::Segment;
use Pipeline::Production;
use base qw ( Pipeline::Segment );
$MyPipe::instance = 0;

sub init {
  my $self = shift;
  $instance++;
  $self->{instance} = $instance;
}

sub dispatch {
  my $self = shift;
  if ($self->{instance} == 2) {
    my $production = Pipeline::Production->new();
    $production->contents( $self );
    return ($production, MyPipeCleanup->new());
  }
}

1;

__END__

=head1 NAME

MyPipe

=head1 DESCRIPTION

C<MyPipe> is a module used by the C<Pipeline> tests which keeps track
of the number of instances of it and returns a production (and a
C<MyPipeCleanup> cleanup handler) if there are two instances of the
object.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This software is released under the same terms as Perl itself.

=cut



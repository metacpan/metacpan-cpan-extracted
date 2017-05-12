package Some::Project;

our $VERSION = 1.23;
use Some::Project::Mite;

has something =>
  is            => 'rw',
  default       => sub { [23, 42] };


=head1 NAME

Some::Project - Some project for testing

=cut

1;

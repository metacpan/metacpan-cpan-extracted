package Some::Project;

our $VERSION = 1.23;
use Some::Project::Mite;

has something =>
  is            => 'rw',
  default       => sub { [23, 42] };

1;

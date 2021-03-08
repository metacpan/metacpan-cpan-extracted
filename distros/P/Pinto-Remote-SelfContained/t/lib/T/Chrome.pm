package
    T::Chrome; # hide from PAUSE

use v5.10;
use Moo;

use namespace::clean;

extends 'Pinto::Remote::SelfContained::Chrome';

has '+verbose' => (default => 1);

has stdout_buf => (is => 'lazy', builder => sub { \ (my $buf = '') });
has '+stdout' => (default => sub { open my $fh, '+>', shift->stdout_buf; $fh });

has stderr_buf => (is => 'lazy', builder => sub { \ (my $buf = '') });
has '+stderr' => (default => sub { open my $fh, '+>', shift->stderr_buf; $fh });

1;

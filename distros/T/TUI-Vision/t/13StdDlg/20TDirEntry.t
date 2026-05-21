use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::StdDlg::DirEntry';
}

lives_ok {
  my $e = TDirEntry->new(
    displayText => 'Home',
    directory   => '/home'
  );
} 'TDirEntry->new() lives with valid arguments';

my $entry = TDirEntry->new(
  displayText => 'Root',
  directory   => '/'
);

isa_ok(
  $entry,
  TDirEntry(),
  'Entry object has correct class'
);

is(
  $entry->{displayText},
  'Root',
  'displayText stored correctly'
);

is(
  $entry->{directory},
  '/',
  'directory stored correctly'
);

lives_ok {
  my $e = new_TDirEntry( 'Tmp', '/tmp' );
} 'TDirEntry->from() lives';

dies_ok {
  TDirEntry->new( displayText => 'MissingDir' );
} 'Missing directory attribute throws exception';

dies_ok {
  TDirEntry->new( directory => '/only' );
} 'Missing displayText attribute throws exception';

done_testing

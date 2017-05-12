package Module::New::ForTest::Config;

use strict;
use warnings;
use base qw( Module::New::Config );

sub new {
  my $self = shift->SUPER::new(@_);

  $self->{config}->{author} ||= 'author';
  $self->{config}->{email}  ||= 'email@localhost';

  $self;
}

sub _default_file { return 'test_config.yaml' }
sub _search { _default_file() }
sub _first_time { return }

END { unlink _default_file() }

1;

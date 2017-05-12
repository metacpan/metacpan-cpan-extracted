package Module::New::ForTest::Context;

use strict;
use warnings;
use base qw( Module::New::Context );
use Module::New::ForTest::LogCache;

sub new {
  my $self = shift->SUPER::new('Module::New::ForTest');
  $self->logger('Module::New::ForTest::LogCache');
  $self;
}

sub has_logged {
  my ($self, $regex) = @_;
  while ( my $log = Module::New::ForTest::LogCache->next ) {
    return 1 if $log =~ /$regex/;
  }
  return;
}

sub dump_logs {
  while ( my $log = Module::New::ForTest::LogCache->next ) {
    warn $log;
  }
}

1;

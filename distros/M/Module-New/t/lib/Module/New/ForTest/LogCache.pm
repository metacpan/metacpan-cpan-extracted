package Module::New::ForTest::LogCache;

use strict;
use warnings;
use Data::Dump;

my @logs;

sub log {
  my ($class, $label, @messages) = @_;
  push @logs, "[$label] ".join '', map { ref $_ ? Data::Dump::dump($_) : $_ } @messages;
}

sub next { shift @logs }

1;

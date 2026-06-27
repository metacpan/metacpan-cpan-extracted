package TestApps::FakeMiddleware;

use strict;
use warnings;

sub new { my ($class) = @_; return bless {}, $class }

sub wrap { my ($self, $app) = @_; return $app }

1;

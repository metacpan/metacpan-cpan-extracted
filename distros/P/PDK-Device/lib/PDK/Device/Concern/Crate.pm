package PDK::Device::Concern::Crate;

use utf8;
use v5.30;
use Moose;
use Carp       qw(croak);
use File::Path qw(make_path);
use Parallel::ForkManager;
use Thread::Queue;
use namespace::autoclean;

has dbi => (is => 'rw', does => 'PDK::DBI::Role', required => 1);

with 'PDK::Device::Concern::Dumper';

__PACKAGE__->meta->make_immutable;
1;

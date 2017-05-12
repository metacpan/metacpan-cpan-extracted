package OSS::Bucket;
use strict;
use warnings;
use Carp;
use File::stat;
use IO::File;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(bucket creation_date account));

sub new {
      my $class = shift;
      my $self  = $class->SUPER::new(@_);
          croak "no bucket"  unless $self->bucket;
          croak "no account" unless $self->account;
          return $self;
    }

1;

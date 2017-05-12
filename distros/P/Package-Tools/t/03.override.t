###################################
# inherit from Package::Base::Devel
###################################

package My::Devel::New;
use strict;
use base qw(Package::Base::Devel);

sub new {
  my($class,%arg) = @_;
  my $self = bless {}, $class;
  $self->init();
  return $self;
}

package My::Devel::Init;
use strict;
use base qw(Package::Base::Devel);

sub init {
  my($self,%arg) = @_;
  return $self;
}

package My::Devel::NewInit;
use strict;
use base qw(Package::Base::Devel);

sub new {
  my($class,%arg) = @_;
  my $self = bless {}, $class;
  $self->init();
  return $self;
}

sub init {
  my($self,%arg) = @_;
  return $self;
}

###################################
# inherit from Package::Base
###################################

package My::New;
use strict;
use base qw(Package::Base);

sub new {
  my($class,%arg) = @_;
  my $self = bless {}, $class;
  $self->init();
  return $self;
}

package My::Init;
use strict;
use base qw(Package::Base);

sub init {
  my($self,%arg) = @_;
  return $self;
}

package My::NewInit;
use strict;
use base qw(Package::Base);

sub new {
  my($class,%arg) = @_;
  my $self = bless {}, $class;
  $self->init();
  return $self;
}

sub init {
  my($self,%arg) = @_;
  return $self;
}

###################################
# main
###################################

package main;
use strict;

BEGIN {
  use Test::More;
  plan tests => 12;

  print STDERR "\nWARNINGS ARE NORMAL HERE\n";
}

ok my $b_n  = My::New->new(),    'b_n';
ok my $b_i  = My::Init->new(),   'b_i';
ok my $b_ni = My::NewInit->new(),'b_ni';
ok $b_n->log->debug('ok'),       'log b_n';
ok $b_i->log->debug('ok'),       'log b_i';
ok $b_ni->log->debug('ok'),      'log b_ni';

ok my $d_n  = My::Devel::New->new();
ok my $d_i  = My::Devel::Init->new();
ok my $d_ni = My::Devel::NewInit->new();

#these return undef, so we can only test that they were successful calls
eval { $d_n->log->debug('ok'); };
ok !$@;
eval { $d_i->log->debug('ok'); };
ok !$@;
eval { $d_ni->log->debug('ok'); };
ok !$@;

1;

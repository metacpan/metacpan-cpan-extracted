use strict;
use warnings;
package Foo::Role::Base;

use Moose::Role;

with 'MooseX::Role::DryRunnable::Base';

sub is_dry_run {
  $ENV{'DRY_RUN'}
}

sub on_dry_run {
  my $self   = shift;
  my $method = shift;
  my $args   = join ",", @_;
  
  print "[DRY RUN] logger: $method($args)\n"
}

1;

package Foo;
use Moose;
with 'Foo::Role::Base';     # the order is important!!
with 'MooseX::Role::DryRunnable' => { 
  methods => [ qw'bar' ]
};

sub bar {
  shift;
  print "Foo::bar @_\n";
}

1;

package main;

my $f = Foo->new();
$f->bar(1,2,3);

__END__

  bash$ perl samples/many_roles.pl 
  Foo::bar 1 2 3
  bash$ DRY_RUN=1 perl samples/many_roles.pl 
  [DRY RUN] logger: bar(1,2,3)

#!perl

use strict;
use warnings;

use blib;

package Scope;

use Scope::Upper qw<reap localize localize_elem localize_delete :words>;

sub new {
 my ($class, $name) = @_;

 localize '$tag' => bless({ name => $name }, $class) => UP;

 reap { print Scope->tag->name, ": end\n" } UP;
}

# Get the tag stored in the caller namespace
sub tag {
 my $l   = 0;
 my $pkg = __PACKAGE__;
 $pkg    = caller $l++ while $pkg eq __PACKAGE__;

 no strict 'refs';
 ${$pkg . '::tag'};
}

sub name { shift->{name} }

# Locally capture warnings and reprint them with the name prefixed
sub catch {
 localize_elem '%SIG', '__WARN__' => sub {
  print Scope->tag->name, ': ', @_;
 } => UP;
}

# Locally clear @INC
sub private {
 for (reverse 0 .. $#INC) {
  # First UP is the for loop, second is the sub boundary
  localize_delete '@INC', $_ => UP UP;
 }
}

package UserLand;

{
 Scope->new("top");      # initializes $UserLand::tag

 {
  Scope->catch;
  my $one = 1 + undef;   # prints "top: Use of uninitialized value..."

  {
   Scope->private;
   eval { delete $INC{"Cwd.pm"}; require Cwd }; # blib loads Cwd
   print $@;             # prints "Can't locate Cwd.pm in @INC (@INC contains:) at..."
  }

  require Cwd;           # loads Cwd.pm
 }

}                        # prints "top: done"

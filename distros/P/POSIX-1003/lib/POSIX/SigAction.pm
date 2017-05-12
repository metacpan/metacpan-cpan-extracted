# Copyrights 2011-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

no warnings 'redefine', 'prototype';  # during release of distribution



sub POSIX::SigAction::new
{   my $class = shift;
    bless {HANDLER => $_[0], MASK => $_[1], FLAGS => $_[2] || 0, SAFE => 0},
       $class;
}

#---------------------------

# We cannot use a "package" statement, because it confuses CPAN: the
# namespace is assigned to the perl core distribution.
no warnings 'redefine';
sub POSIX::SigAction::handler($;$)
{   $_[0]->{HANDLER} = $_[1] if @_ > 1; $_[0]->{HANDLER} }

sub POSIX::SigAction::mask($;$)
{   $_[0]->{MASK} = $_[1] if @_ > 1; $_[0]->{MASK} }

sub POSIX::SigAction::flags($;$)
{   $_[0]->{FLAGS} = $_[1] if @_ > 1; $_[0]->{FLAGS} }

sub POSIX::SigAction::safe($;$)
{   $_[0]->{SAFE} = $_[1] if @_ > 1; $_[0]->{SAFE} }

1;

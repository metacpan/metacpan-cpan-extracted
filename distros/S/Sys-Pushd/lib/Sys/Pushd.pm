# $Id: Pushd.pm 1.7 Tue, 09 Sep 1997 17:07:06 -0400 jesse $

package Sys::Pushd;
use strict;
use Cwd;
use vars qw($VERSION);
# $Format: "$VERSION='$SysPushdRelease$';"$
$VERSION='0.001';

sub new {
  my $class=shift;
  my @dirs=@_;
  my $old=cwd;
  my $dir; foreach $dir (@dirs) {
    chdir $dir or die "Couldn't chdir from $old to $dir: $!";
  }
  bless \$old, $class;
}

sub DESTROY {
  my $self=shift;
  chdir $$self or die "Couldn't chdir back to $$self: $!";
}

1;
__END__

=head1 NAME

B<Sys::Pushd> - change directory temporarily

=head1 SYNOPSIS

 use Sys::Pushd;
 {
   my $ignore=new Sys::Pushd '../new/dir';
   # Cwd is ../new/dir
 }
 # After block exit, cwd is restored

=head1 DESCRIPTION

Synopsis pretty much says it all. Based conceptually on B<SelectSaver>.

Multiple directories may be given, in which case they will be B<chdir>d to in order
encountered.

=head1 BUGS

Will break if immediate-destruction of objects ever ceases to be reliable in Perl.

=head1 AUTHORS

J. Glick B<jglick@sig.bsh.com>.

=head1 REVISION

X<$Format: "F<$Source$> last modified $Date$ release $SysPushdRelease$. $Copyright$"$>
F<Sys-Pushd/lib/Sys/Pushd.pm> last modified Tue, 09 Sep 1997 17:07:06 -0400 release 0.001. Copyright (c) 1997 Strategic Interactive Group. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

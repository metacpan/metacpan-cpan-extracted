#
# $Id: Thread.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Worker::Thread;
use strict;
use warnings;

use base qw(Net::SinFP3::Worker);
our @AS = qw(
   _ts
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::SinFP3::Worker qw(:consts);

BEGIN {
   use Config;

   if (defined($Config{useithreads})) {
      eval "use threads";
      eval "use Thread::Semaphore";
   }
   else {
      warn("[-] ".__PACKAGE__.": Thread-based worker mode not supported by ".
           "your version of Perl. Recompile Perl with threads to run this ".
           "program or use fork-based worker model.\n");
      return;
   }
}

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   my $ts = Thread::Semaphore->new($self->global->jobs);
   $self->_ts($ts);

   return $self;
}

sub init {
   my $self = shift->SUPER::init(@_) or return;
   return $self;
}

sub run {
   my $self = shift->SUPER::run(@_) or return NS_WORKER_FAIL;

   my $cb = $self->callback;

   threads->create(sub {
      $self->_ts->down(1);
      &{$cb}();
      $self->_ts->up(1);
   });

   return $self;
}

sub post {
   my $self = shift->SUPER::post(@_) or return;
   return $self;
}

sub clean {
   my $self = shift;
   for my $thr (threads->list) {
      $thr->join;
   }
   return $self;
}

1;

__END__

=head1 NAME

Net::SinFP3::Worker::Thread - thread-based worker model

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut

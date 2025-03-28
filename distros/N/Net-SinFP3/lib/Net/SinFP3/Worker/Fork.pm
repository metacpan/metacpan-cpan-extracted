#
# $Id: Fork.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Worker::Fork;
use strict;
use warnings;

use base qw(Net::SinFP3::Worker);
our @AS = qw(
   _pm
   _pid
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::SinFP3::Worker qw(:consts);

use Parallel::ForkManager;

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   my $pm = Parallel::ForkManager->new(
      $self->global->jobs,
   );
   $self->_pm($pm);

   return $self;
}

sub init {
   my $self = shift->SUPER::init(@_) or return;
   return $self;
}

sub run {
   my $self = shift->SUPER::run(@_) or return NS_WORKER_FAIL;

   my $cb = $self->callback;

   my $pid = $self->_pm->start and return NS_WORKER_SUCCESS;
   $self->_pid($pid);
   &{$cb}();

   return $self;
}

sub post {
   my $self = shift->SUPER::post(@_) or return;
   $self->_pm->finish;
   return 1;
}

sub clean {
   my $self = shift;
   $self->_pm->wait_all_children;
   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Worker::Fork - fork-based worker model

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut

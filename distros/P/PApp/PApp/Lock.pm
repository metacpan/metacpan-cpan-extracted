##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::Lock - manage locks using sql

=head1 SYNOPSIS

 use PApp::Lock;
 # not auto-imported into .papp-files

 locked {
    ... locked code section
 } "my_app_lock", 60, 60*10;

=head1 DESCRIPTION

This module manages locking (semaphores) using the papp state database
(i.e. it works without filesystem and across hosts).

=over 4

=cut

package PApp::Lock;

use PApp::Config;
use PApp::Exception;
use PApp::SQL;

use base Exporter;

$VERSION = 2.1;
@EXPORT = qw(locked);

=item locked BLOCK name, [timeout, [holdtime]]

Execute the given BLOCK while holding the lock NAME. The lock will be
given up as soon as the block is left. See the C<new> method for the
meaning of the arguments.

=cut

sub locked(&@) {
   my $block = shift;
   $lock = new PApp::Lock @_;
   eval {
      local $SIG{__DIE__} = \&PApp::Exception::diehandler;
      $lock->lock or do {
         require POSIX;
         fancydie "unable to aquire lock", $lock->{name},
                  info => [ breaktime => "The lock expires ".
                            POSIX::strftime("%Y-%m-%d %H:%M:%S %z", localtime $lock->breaktime)],
                  info => [ timeout  => $lock->{timeout} ],
                  info => [ holdtime => $lock->{holdtime} ],
                ;
      };
      &$block;
   };
   {
      local $@;
      $lock->unlock;
   }
   die if $@;
}

=item $lock = new PApp::Lock name, [timeout, [holdtime]]

Create a new lock object (but do not lock it) of name C<name>. The name
might be used case-sensitive or -insensitive, so always use the same
spel[l]ing but don't expect that lock names are case-sensitive. C<timeout> specifies the maximum time
that the program waits until the lock becomes available (default: 5 minutes). C<holdtime> specifies the maximum
age the lock can have (default: 12 hours). A lock older than C<holdtime> is broken.

=cut

sub new($@) {
   my $class    = shift;
   my $lock     = shift;
   my $timeout  = shift || 5*60;
   my $holdtime = shift || 12*60*60;
   bless {
      name => $lock,
      timeout => $timeout,
      holdtime => $holdtime,
   }, $class;
}

=item $ok = $lock->lock([timeout])

Tries to aquire the lock until the timeout is reached. Returns true when
the lock was aquired and false when the lock couldn't be aquired.

See C<new> for the meaning of C<timeout>.

=cut

sub lock {
   my $self = shift;
   local $DBH = PApp::Config::DBH;

   return 1 if $self->{lock}++;

   return 1 if eval {
      local $SIG{__DIE__};
      sql_exec "insert into locks values (?, ?, ?)", $self->{name}, time, "";
   };

   my $timeout = shift || $self->{timeout};
   my $wait = 0.1;
   my $beg = time;

   for(;;) {
      $now = time;
      return 1 if eval {
         sql_exec "delete from locks where id = ? and breaktime < ?", $self->{name}, $now - $self->{holdtime};
         sql_exec "insert into locks values (?, ?, ?)", $self->{name}, $now, "";
      };

      if ($now >= $beg + $timeout) {
         $self->{lock} = 0;
         return ();
      }

      select undef, undef, undef, $wait;
      $wait *= 1.5;
      $wait = 1 if $wait > $timeout * 0.1;
   }
}

=item $lock->breaktime

Returns the time when the lock can be broken (by another
application). This can be called even when the process does not hold the
lock. If the lock is not used it will return nothing.

=cut

sub breaktime {
   my $self = shift;
   local $DBH = PApp::Config::DBH;

   sql_fetch "select breaktime from locks where id = ?", $self->{lock};
}

sub unlock {
   my $self = shift;
   local $DBH = PApp::Config::DBH;

   return if $self->{locked}--;

   sql_exec "delete from locks where id = ?", $self->{name};
}

sub DESTROY {
   $self->unlock while $self->{locked};
}

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut


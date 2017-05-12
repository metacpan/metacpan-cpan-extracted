package P9Y::ProcessTable::Process::Base;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.08'; # VERSION

#############################################################################
# Modules

# use sanity;
use strict qw(subs vars);
no strict 'refs';
use warnings FATAL => 'all';
no warnings qw(uninitialized);

use Moo;

use namespace::clean;
no warnings 'uninitialized';

#############################################################################
# Attributes

has _pt_obj  => (
   is       => 'ro',
   required => 1,
   handles  => [qw(
      fields
      _process_hash
   )],
);

has pid      => ( is => 'ro',  required  => 1 );
has uid      => ( is => 'rwp', predicate => 1 );
has gid      => ( is => 'rwp', predicate => 1 );
has euid     => ( is => 'rwp', predicate => 1 );
has egid     => ( is => 'rwp', predicate => 1 );
has suid     => ( is => 'rwp', predicate => 1 );
has sgid     => ( is => 'rwp', predicate => 1 );
has ppid     => ( is => 'rwp', predicate => 1 );
has pgrp     => ( is => 'rwp', predicate => 1 );
has sess     => ( is => 'rwp', predicate => 1 );

has cwd      => ( is => 'rwp', predicate => 1 );
has exe      => ( is => 'rwp', predicate => 1 );
has root     => ( is => 'rwp', predicate => 1 );
has cmdline  => ( is => 'rwp', predicate => 1 );
has environ  => ( is => 'rwp', predicate => 1 );

has minflt   => ( is => 'rwp', predicate => 1 );
has cminflt  => ( is => 'rwp', predicate => 1 );
has majflt   => ( is => 'rwp', predicate => 1 );
has cmajflt  => ( is => 'rwp', predicate => 1 );
has ttlflt   => ( is => 'rwp', predicate => 1 );
has cttlflt  => ( is => 'rwp', predicate => 1 );
has utime    => ( is => 'rwp', predicate => 1 );
has stime    => ( is => 'rwp', predicate => 1 );
has cutime   => ( is => 'rwp', predicate => 1 );
has cstime   => ( is => 'rwp', predicate => 1 );
has start    => ( is => 'rwp', predicate => 1 );
has time     => ( is => 'rwp', predicate => 1 );
has ctime    => ( is => 'rwp', predicate => 1 );

has priority => ( is => 'rwp', predicate => 1 );
has fname    => ( is => 'rwp', predicate => 1 );
has state    => ( is => 'rwp', predicate => 1 );
has ttynum   => ( is => 'rwp', predicate => 1 );
has ttydev   => ( is => 'rwp', predicate => 1 );
has flags    => ( is => 'rwp', predicate => 1 );
has threads  => ( is => 'rwp', predicate => 1 );
has size     => ( is => 'rwp', predicate => 1 );
has rss      => ( is => 'rwp', predicate => 1 );
has wchan    => ( is => 'rwp', predicate => 1 );
has cpuid    => ( is => 'rwp', predicate => 1 );
has pctcpu   => ( is => 'rwp', predicate => 1 );
has pctmem   => ( is => 'rwp', predicate => 1 );

has winpid   => ( is => 'rwp', predicate => 1 );
has winexe   => ( is => 'rwp', predicate => 1 );

#sub fields {
#   return ( qw/
#      pid uid gid euid egid suid sgid ppid pgrp sess
#      cwd exe root cmdline environ
#      minflt cminflt majflt cmajflt ttlflt cttlflt utime stime cutime cstime start time ctime
#      priority fname state ttynum ttydev flags threads size rss wchan cpuid pctcpu pctmem
#      winpid winexe
#   / );
#}

#############################################################################
# Common Methods (may potentially be redefined with OS-specific ones)

sub refresh {
   my ($self) = @_;
   my $hash = $self->_process_hash($self->pid);
   return unless $hash;

   # use set methods
   foreach my $meth (keys %$hash) {
      next if $meth eq 'pid';
      my $method = "_set_$meth";
      $self->$method($hash->{$meth});
   }

   return $self;
}

sub kill {
   my ($self, $sig) = @_;
   return CORE::kill($sig, $self->pid);
}

around pgrp => sub {
   my ($orig, $self, $pgrp) = @_;
   return $orig->($self) if @_ == 2;

   setpgrp($self->pid, $pgrp);
   $self->_set_pgrp($pgrp);
};

around priority => sub {
   my ($orig, $self, $pri) = @_;
   return $orig->($self) if @_ == 2;

   setpriority(0, $self->pid, $pri);
   $self->_set_priority($pri);
};

42;

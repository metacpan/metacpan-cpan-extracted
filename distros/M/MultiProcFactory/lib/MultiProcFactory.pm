package MultiProcFactory;
# @(#) $Name:  $ $Id: MultiProcFactory.pm,v 1.6 2004/09/21 23:06:49 aaron Exp $
## Aaron Dancygier

## Base class forking object for distributed processing  
## among N children.  Parent aggregates when children are done.

use 5.005;
use strict;
use Carp;
use IO::File;
use IPC::Shareable;

use vars qw($VERSION);
$VERSION = '0.04';

sub catch_int {
  IPC::Shareable->clean_up; 
}

sub factory {
  my $baseclass = shift;
  my (%params) = @_;
                                                                                                                            
  my $obj;

  croak("must have work_by parameter defined cannot create class\n")
    unless (defined($params{work_by}));

  my $class = $params{work_by};

  unless ($class =~ /^\w+(?:\:\:\w+)*$/) {  
    croak("must supply work_by parameter with class name\n");
  }

  eval "use $class";

  if ($@) {
    croak "Error in factory method\n@_, $@";
  }
                                                                                
  return "$class"->new(%params);
}

sub new {
  my ($class, %args) = @_; 

  my $tmp_log_name = $0;

  $tmp_log_name =~ s/\.(?:[^\.]+)$//;

  $args{log_file} ||= "$tmp_log_name.log";
  $args{log_children} = 0 unless(defined($args{log_children})); 
  $args{log_parent} = 1 unless(defined($args{log_parent})); 
  $args{log_child_append} ||= 0;
  $args{log_parent_append} ||= 0;

  ## set parent signal handlers
  $SIG{QUIT} = $SIG{ABRT} = $SIG{TERM} = $SIG{INT} = \&catch_int;

  ## set up default signal handlers
  _set_parent_signals(\%args);

  ## set up default shared data structures
  unless ($args{IPC_OFF}) {
    my $scalar_handle = tie my $shm_scalar, 'IPC::Shareable', undef, {destroy => 1};
    my $hash_handle = tie my %shm_hash, 'IPC::Shareable', undef, {destroy => 1};

    $args{share_scalar}{handle} = $scalar_handle;
    $args{share_scalar}{var} =  \$shm_scalar;
    $args{share_hash}{handle} = $hash_handle;
    $args{share_hash}{var} = \%shm_hash;
  }

  croak("required parameter do_child code reference is missing or not a code reference\n")
    unless (ref($args{do_child}) eq 'CODE');

  croak("required parameter do_parent_final code reference is missing or not a code reference\n")
    unless (ref($args{do_parent_final}) eq 'CODE');

  if (ref($args{do_parent_init})) {
    unless (ref($args{do_parent_init}) eq 'CODE') {
      croak("optional parameter do_parent_init must be a code reference\n")
    }
  } else {
    $args{do_parent_init} = sub { return 1; };
  }

  $args{max_proc} ||= 20;

  my $self = bless \%args, $class; 

  $self->_set_do_parent_init();
  $self->_set_do_parent_final();
  $self->_set_do_child();
  $self->init();

  return $self;
}

sub run {
  my $self = shift;

  my $pfh;

  $self->{log_file} = $self->set_parent_logname();

  my $mode = ($self->{log_parent_append})
    ? '>>'
    : '>'
  ;

  if ($self->{log_parent}) {
    $self->{logp} = IO::File->new("$mode$self->{log_file}") || 
      croak("unable to open parent filehandle $!\n");
    $pfh = $self->{logp};
    $pfh->autoflush(1);
  }

  $self->do_parent_init();

  if ($self->{log_parent}) {
    $self->log_parent(localtime() . " [$$] parent begin\n");
  }

  my ($pid, $prockey);

  my $max_proc = $self->{max_proc};

  my $child_count = 0;

  my @partition_keys = $self->get_prockeys();

  my $proc_count = 0;

  START: while(@partition_keys) {
    while ($child_count < $max_proc and @partition_keys) {
      my $key = shift @partition_keys;
      $pid = fork();
      $child_count ++;
      $proc_count ++;
                                                                                                                            
      if ($pid) {
        ## parent go get another one
        next;
      } elsif(defined($pid)) {
        local $^W = undef;
	$SIG{QUIT} = $SIG{ABRT} = $SIG{TERM} = $SIG{INT} = undef;
        $self->_set_child_signals();
        $prockey = $key;
        last;
      }
    }
    
    if ($pid) {
      my $kid;
                                                                                                                            
      do {
        $kid = waitpid(-1, 0);
                                                                                                                            
        if ($self->{log_parent}) {
	  $self->log_parent(localtime() . " [$$] child_count: $child_count, parent repeaping: $kid\n");
        }

        $child_count --;

        next START;
      } until ($kid == -1);
                                                                                                                            
       next; 
    }

    if ($self->{log_children}) {
      my $tmp_log_name = $self->{log_file};
      $tmp_log_name =~ s/\.log$//;
      $self->{current_child_logname} = "$tmp_log_name\_$proc_count\.log";
      $self->{current_child_logname} = $self->set_child_logname();

      my $mode = ($self->{log_child_append})
        ? '>>'
	: '>'
      ;

      $self->{logc} = IO::File->new("$mode$self->{current_child_logname}") ||
        croak("unable to open child filehandle n child [$$]$!\n");
      $self->{logc}->autoflush(1);
    }

    $self->{prockey} = $prockey;
    $self->do_child_init();
    $self->work();

    if ($self->{log_children}) {
      $self->{logc}->close();
    }

    exit(0);
  }

  my $kid;

  do {
    $kid = waitpid(-1, 0);

    if ($self->{log_parent}) {
      $self->log_parent(localtime() . " [$$] child_count: $child_count, parent repeaping: $kid\n");
    }
                                                                                                                            
    $child_count --;

  } until ($kid == -1);

  $self->do_parent_final();
              
  if ($self->{log_parent}) {
    $self->log_parent(localtime() . " [$$] parent done\n");
    $pfh->close();
  }

  return 1;
}

sub init {
  my $self = shift;

  croak("init() must be implemented in $self->{'work_by'}\n"); 
}

sub do_child_init {
  my $self = shift;

  croak("do_child_init() must be implemented in $self->{'work_by'}\n"); 
}

sub work {
  my $self = shift;

  croak("work() must be implemented in $self->{'work_by'}\n");
}

sub log_parent {
  my ($self, $text) = @_;

  if ($self->{log_parent}) {
    my $pfh = $self->{logp};

    print $pfh $text;
  }
}

sub log_child {
  my ($self, $text) = @_;

  if ($self->{log_children}) {
    my $cfh = $self->{logc};

    print $cfh $text;
  }
}

sub get_prockey {
  my $self = shift;

  return $self->{prockey};
}

sub get_prockeys {
  my $self = shift;

  return (keys %{$self->{partition_hash}});
}

sub scalar_lock {
  my $self = shift;

  (! $self->{IPC_OFF}) 
    ? return $self->{share_scalar}{handle}->shlock()
    : return undef
  ;
}

sub scalar_unlock {
  my $self = shift;

  (! $self->{IPC_OFF}) 
    ? return $self->{share_scalar}{handle}->shunlock()
    : return undef
  ;
}

sub hash_lock {
  my $self = shift;

  (! $self->{IPC_OFF})
    ? return $self->{share_hash}{handle}->shlock()
    : return undef
  ;
}

sub hash_unlock {
  my $self = shift;

  (! $self->{IPC_OFF})
    ? return $self->{share_hash}{handle}->shunlock()
    : return undef
  ;
}

sub set_hash_element {
  my $self = shift;

  my ($key, $value) = @_;
 
  if (! $self->{IPC_OFF}) { 
    $self->hash_lock();
    $self->{share_hash}{var}{$key} = $value;
    $self->hash_unlock();
  }
}

sub get_hash_element {
  my ($self, $key) = @_;

  (! $self->{IPC_OFF})
    ?  return $self->{share_hash}{var}{$key}
    : return undef
  ;
}

sub set_scalar {
  my $self = shift;

  my $value = shift;

  if (! $self->{IPC_OFF}) {
    $self->scalar_lock();
    ${$self->{share_scalar}{var}} = $value;
    $self->scalar_unlock();
  }
}

sub inc_scalar {
  my $self = shift;

  if (! $self->{IPC_OFF}) {
    $self->scalar_lock();
    ${$self->{share_scalar}{var}} ++; 
    $self->scalar_unlock();
  }
}

sub dec_scalar {
  my $self = shift;
  
  if (! $self->{IPC_OFF}) {  
    $self->scalar_lock();
    ${$self->{share_scalar}{var}} --; 
    $self->scalar_unlock();
  }
}

sub get_scalar {
  my $self = shift;

  (! $self->{IPC_OFF})
    ? return ${$self->{share_scalar}{var}}
    : return undef
  ;
}

sub set_parent_logname {
  my ($self) = @_;

  $self->{log_file} .= '.log'
  unless ($self->{log_file} =~ /\.log$/);
  return $self->{log_file};
}

sub set_child_logname {
  my ($self) = @_;

  return $self->{current_child_logname};
}

sub _set_do_child {
  my ($self) = @_;

  {
    local $^W = undef;
    no strict;
    *{ ref($self) . '::' . 'do_child' } = $self->{do_child};
  };
}

sub _set_do_parent_final {
  my ($self) = @_;
                                                                                                                            
  {
    local $^W = undef;
    no strict;
    *{ ref($self) . '::' . 'do_parent_final' } = $self->{do_parent_final};
  };
}

sub _set_do_parent_init {
  my ($self) = @_;
                                                                                                                            
  {
    local $^W = undef;
    no strict;
    *{ ref($self) . '::' . 'do_parent_init' } = $self->{do_parent_init};
  };
}

sub _set_parent_signals {
  my ($self) = @_;
                                                                                                                            
  foreach my $signame (keys %{$self->{parent_sig}}) {
    $SIG{$signame} = $self->{parent_sig}{$signame};
  }
}
                                                                                                                            
sub _set_child_signals {
  my ($self) = @_;
                                                                                                                            
  foreach my $signame (keys %{$self->{child_sig}}) {
    $SIG{$signame} = $self->{child_sig}{$signame};
  }
}

1;

__END__

=head1 NAME

MultiProcFactory - Base class for multiprocess batch processing. 

=head1 SYNOPSIS

  #!/usr/bin/perl

  use strict;
  use MultiProcFactory;

  my $do_child = sub {
    my $self = shift;
    $self->inc_scalar();
    $self->set_hash_element($self->get_prockey() => " $$: " . $self->get_scalar());
  };

  my $do_parent_final =
  sub {
    my $self = shift;

    foreach my $key ($self->get_prockeys()) {
      my $value = $self->get_hash_element($key);
      $self->log_parent("$key: $value\n");
    }
  };

  my $link_obj = MultiProcFactory->factory(
    work_by => 'MultiProcFactory::Generic',
    do_child => $do_child,
    do_parent_final => $do_parent_final,
    partition_list => [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H'
    ]
  );

  $link_obj->run();

=head1 ABSTRACT

  This is a factory framework interface for multiprocess batch processing.
  You need to write a class to inherit from this class that fits your data model.
  Can be a very powerful data processing tool, for system wide application patterns.

=head1 DESCRIPTION

This class is a factory class for multiprocess batch processing. 
The definition of processing bins are defined in subclasses that this object returns.
run method manages child processes and executes code references.  Depending on subclass logic can be used to execute do_child as an iterator for batch processing.  Shared memory through IPC::Shareable (SysV IPC) is available by default.  I have setup two shared variables, a scalar and a hash.

=head1 PUBLIC METHODS

=head2 factory();

This method takes all contructor arguments.  Additional parameters will be needed for your subclassed object.

=head2 Base Class Required Parameters

=over 4

=item * work_by =>'BFI::MultiProcFactory::Schema::Mailing' ## Package name to subclass

=item * do_child => $code_ref_a ## code executed in each child

=item * do_parent_final => $code_ref_b, ## code executed by parent when child procs are complete. 

=back

=head2 Base Class Optional Parameters

=over 4

=item * max_proc => N # max number of concurrent child processes (default 20)

=item * log_children => 0|1 (default 0)

=item * log_parent => 0|1 (default 1)

=item * do_parent_init => $code_ref_c, ## code executed in parent before forking

=item * parent_sig => {INT => $coderef, TERM => $coderef, ...} 

=item * child_sig => {INT => $coderef, TERM => $coderef, ...} 

=item * IPC_OFF => 0|1 (default 0) ## turns off default allocation of shared memory

=back

=head2 run()

This method is called after initialization.  It contains all forking and subroutine execution logic.

=head2 log_parent()

Method logs input string to parent filehandle

=head2 log_child()

Method logs input string to child filehandle

=head2 set_parent_logname()

Default - $0 minus any extensions . '.log'
can override default by redefining in subclass.

=head2 set_child_logname()

Default - $0 minus any extensions . "_$instance\.log"
can override default by redefining in subclass.

=head2 get_prockey()

returns current childs process key.  This key maps back to process slot in partition_hash.
Has no meaning if called from parent and should return undef.

=head2 get_prockeys()

returns list of process keys in partition_hash used for iterating over all children

=head2 scalar_lock()

wrapper for IPC::Shareable shlock() on shared scalar

=head2 hash_lock()

wrapper for IPC::Shareable shlock() on shared hash 

=head2 scalar_unlock()

wrapper for IPC::Shareable shunlock() on shared scalar

=head2 hash_unlock()

wrapper for IPC::Shareable shunlock() on shared hash 

=head2 set_hash_element()

wrapper to set shared hash with key => value.  
Calls hash_lock() and hash_unlock()

=head2 get_hash_element()

wrapper to get value stored in shared hash identified by $key 

=head2 set_scalar()

wrapper to set shared scalar var with $value

=head2 inc_scalar()

wrapper to increment current value in shared scalar by 1

=head2 dec_scalar()

wrapper to decrement value in shared scalar by 1

=head2 get_scalar()

wrapper to access shared scalar value

=head1 PRIVATE METHODS

=head2 new() 

called internally by factory()

=head2 _set_do_child()

sets child code reference

=head2 _set_do_parent_init()

sets parent initialization reference

=head2 _set_do_parent_final()

sets parent cleanup code reference

=head2 _set_parent_signals()

sets parent signal handlers if passed in with hash ref parent_sig =>{},  this allows you to override the default signal handling behavior.

=head2 _set_child_signals()

sets child signal handlers if passed in with hash ref parent_sig =>{},  this allows you to override the default signal handling behavior.

=head1 SIGNALS

* Parent -
by default TERM, ABRT, INT and QUIT are set to call IPC::Shareable->clean_up.  Unless you like calling ipcrm this is a good thing.

* Child -
by default TERM, ABRT, INT and QUIT are reset undef. 

=head1 SHARED MEMORY

* Sets up two shared variables with IPC::Shareable, a scalar and a hash.  

* For the curious semaphores and memory are stored in 

=over 4

=item * $self->{share_scalar}{handle} 

=item * $self->{share_scalar}{var} 

=item * $self->{share_hash}{handle}

=item * $self->{share_hash}{var}

=back

=head1 PUBLIC DATA

=over 4

=item * $self->{prockey} - defines each process bin 

=back

=head1 INTERFACE IMPLENTATION METHODS

=head2 init()

called from constructor. parent contains partitioning algorithm.  Partition algorithm bins data into self->{partition_hash}
Each of these bins is forked.

=head2 do_child_init()

This method does any basic child process level initialization.

=head2 work()

This method at the bare minimum must call do_child().  Can be written to iterate do_child over a result set.

=head1 AUTHOR

Aaron Dancygier, E<lt>adancygier@bigfootinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Aaron Dancygier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO
                                                                                                                            
perl(1), IPC::Shareable, MultiProcFactory::Generic

=cut


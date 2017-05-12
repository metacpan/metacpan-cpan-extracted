package Parallel::Workers;

use warnings;
use strict;
use Carp;
use Scalar::Util qw(blessed dualvar isweak readonly refaddr reftype tainted
                        weaken isvstring looks_like_number set_prototype);
use threads 1.39 ;
use threads::shared;
use Thread::Queue;
use Data::Dumper;
use Parallel::Workers::Transaction;
use Parallel::Workers::Backend;
use Parallel::Workers::Shared;

use version; 

no warnings 'threads';

our (@ISA, @EXPORT, @EXPORT_OK, $VERSION, $WARN, $DEBUG);
@ISA = qw(Exporter);

@EXPORT = qw($VERSION);
@EXPORT_OK = ();

$VERSION = '0.0.9';

$WARN=0;
$DEBUG=0;


# Flag to inform all threads that application is terminating
my $TERM :shared = 0;

# Prevents double detach attempts
my $DETACHING :shared;

my $ID:shared = 0;

my $shared_jobs;


# maxworkers =>64 , maxjobs=>100, 
# transport=> SSH|XMLRPC|LOCAL, constructor=>%options, 
# timeout => max time to thread to live

sub new {
    my $class:shared = shift;
    my %params = @_;
    my $this={};
    
#     shared_hash_set($this, "maxworkers",(defined($params{maxworkers}))?$params{maxworkers}:16);
#     shared_hash_set($this, "maxjobs", (defined($params{maxjobs}))?$params{maxjobs}:32);
#     shared_hash_set($this, "timeout", (defined($params{timeout}))?$params{timeout}:10);
  
    $this->{maxworkers}=(defined($params{maxworkers}))?$params{maxworkers}:16;
    $this->{maxjobs}=(defined($params{maxjobs}))?$params{maxjobs}:32;
    $this->{timeout}=(defined($params{timeout}))?$params{timeout}:10;
    
# Wait for max timeout for threads to finish
    
    my $backend=(defined $params{backend})?"Parallel::Workers::Backend::".$params{backend}:"Parallel::Workers::Backend::Null";
    
    my %constructor=();
    $constructor{backend}=$backend;
    $constructor{constructor}=\%{$params{constructor}} if defined $params{constructor};
    $this->{jobsbackend}=Parallel::Workers::Backend->new(%constructor);
    bless $this, $class;
    
    return $this;
}

sub clear{
  my $this = shift;
  $shared_jobs={};
}

# hosts => @hosts, command=>, params=>
# return $jobid
sub create{
  my $this = shift;
  my %params = @_;
  
#   shared_hash_set($this, "transaction", Parallel::Workers::Transaction->new((defined $params{transaction})?%{$params{transaction}}:undef));  
  $this->{transaction}=Parallel::Workers::Transaction->new((defined $params{transaction})?%{$params{transaction}}:{enable=>0});
  my @hosts=@{$params{hosts}};
  my $totaljobs=@hosts;
  my $jobs=0;
  my $current_job=0;
  # Manage the thread pool until signalled to terminate
  my $id:shared=__genid();
  my $commands={ 
                    cmd=>$params{command}, params=>$params{params}, 
                    pre=>$params{pre}, preparams=>$params{preparams},
                    post=>$params{post}, postparams=>$params{postparams}
  };
  $shared_jobs->{$id}=&share({});
  $shared_jobs->{$id}->{time}=time();
  lock ($id);
  
  while (! $TERM && $totaljobs ) {
    # New thread
    
    threads->new('jobworker', $this, $shared_jobs->{$id}, \$id, $hosts[$current_job++], $commands,$this->{transaction});
    $totaljobs--;
    if ($this->{maxworkers}<=threads->list()){
    #WAITING FOR A NEW THREAD
      print "#WAITING FOR A THREAD EXIT\n" if $WARN;
      cond_wait($id);
    }
    
  }
  #waiting the end of the pool
  $this->join();
  print "job terminated\n" if $WARN;
  return $id;
}

# wait infinity for the end of workers
sub join{
  my $self = shift;
  my %params = @_;
  foreach my $thr (threads->list()) {
    $thr->join() ;
  }
}

# stop the current pool after the timeout done
sub stop{
  my $this = shift;
  my %params = @_;
  $TERM=1;
  
  ### CLEANING UP ###

  # Wait for max timeout for threads to finish
  while ((threads->list() > 0) && $this->{timeout}--) {
    sleep(1);
  }

  # Detach and kill any remaining threads
  foreach my $thr (threads->list()) {
    lock($DETACHING);
    $thr->detach() if ! $thr->is_detached();
    $thr->kill('KILL');
  }  
  $TERM=0;
}

sub info{
  my $this = shift;
  return $shared_jobs;
#  return $shared_jobs;
}

sub __genid{
  return "$$-".$ID++;
}

#private fonction called by thread
sub jobworker{
  my ($this, $job, $id, $host, $params, $transaction)=@_;
  my $tid = threads->tid();
  my %host;
  $host{cmd}=$params->{cmd};
  $host{params}=$params->{params};
  shared_hash_set($job,$host,\%host);
  eval{
  
#   Run preprocessing task
##########################
    if (defined $params->{pre}){
      $job->{$host}->{status}="preprocessing";
      my $pre=$this->{jobsbackend}->pre($id, $host, $params->{pre}, $params->{preparams});
      $job->{$host}->{pre}=shared_share($pre);

      if ($transaction->check($tid,$pre) eq "TRANSACTION_TERM"){
        print ">>>>>>>>>>transaction for thread($tid) on preprocessing return TRANSACTION_TERM\n" if $WARN==1;
        $job->{$host}->{status}=TRANSACTION_TERM;
        shared_hash_set($job,"pre",TRANSACTION_TERM);
        $TERM=1;
        cond_broadcast($$id);
        threads->exit(0);
        return;
      }
    }  
#   Run processing task
##########################
    $job->{$host}->{status}="processing";
    my $do=$this->{jobsbackend}->do($$id, $host, $params->{cmd}, $params->{params});
    $job->{$host}->{do}=shared_share($do);
    if ($transaction->check($tid,$do) eq "TRANSACTION_TERM"){
      print ">>>>>>>>>>transaction for thread($tid) on processing return TRANSACTION_TERM\n" if $WARN==1;
      $job->{$host}->{status}=TRANSACTION_TERM;
      shared_hash_set($job,"do",TRANSACTION_TERM);
      $TERM=1;
      cond_broadcast($$id);
      threads->exit(0);
      return;
    }
#   Run postprocessing task
##########################
    if (defined $params->{post}){
      $job->{$host}->{status}="postprocessing";
      my $post=$this->{jobsbackend}->post($id, $host, $params->{post}, $params->{postparams});
      $job->{$host}->{post}=shared_share($post);
      if ($transaction->check($tid,$post) eq "TRANSACTION_TERM"){
        print ">>>>>>>>>>transaction for thread($tid) on postprocessing return TRANSACTION_TERM\n" if $WARN==1;
        $job->{$host}->{status}=TRANSACTION_TERM;
        shared_hash_set($job,"post",TRANSACTION_TERM);
        $TERM=1;
        cond_broadcast($$id);
        threads->exit(0);
        return;
      }
      
    }    
  }; 
  if ($@){
    $job->{$host}->{error}=$@;
    $job->{$host}->{status}="error";
    print STDERR $job->{$host}->{error}."\n" if $WARN;
    cond_broadcast($$id);
    threads->exit(0);
    return;
  }
  $job->{$host}->{status}="done";
  cond_broadcast($$id);
  return;
}


### Signal Handling ###

# Gracefully terminate application on ^C
# or command line 'kill'
# $SIG{'INT'} = $SIG{'TERM'} =
#     sub {
#         print(">>> Terminating <<<\n");
#         $TERM = 1;
# };

# This signal handler is called inside threads
# that get cancelled by the timer thread
# $SIG{'KILL'} =
#     sub {
# # Tell user we've been terminated
#         printf("           %3d <- Killed\n", threads->tid());
# # Detach and terminate
#         lock($DETACHING);
#         threads->detach() if ! threads->is_detached();
#         threads->exit();
# };

1; # Magic true value required at end of module
__END__

=head1 NAME

Parallel::Workers - run worker tasks in parallel. Worker task is a plugin that you
can implement. The availables are Eval for CODE, SSH and XMLRPC.


=head1 VERSION

This document describes Parallel::Workers version I<$VERSION>



=head1 SYNOPSIS

    use Parallel::Workers;
    
    #Workers that use Eval action with a trantransaction controller
    #                 ^^^^
    
    my $worker=Parallel::Workers->new(maxworkers=>4,timeout=>10, backend=>"Eval");

    my $id=$worker->create(hosts => \@named, command=>"`date`", 
                           transaction=>{error=>TRANSACTION_TERM, type=>'SCALAR',regex => qr/.+/m});
    my $info=$worker->info();
    
    #Workers that use SSH action with a trantransaction controller
    #                 ^^^
    $worker=Parallel::Workers->new(
                                    maxworkers=>16,timeout=>10, 
                                    backend=>"SSH", constructor =>{user=>'demo',pass=>'demo'}
                                  );


    $id=$worker->create(hosts => \@hosts, command=>"cat /proc/cmdline",
                                      transaction=>{error=>TRANSACTION_TERM, type=>'SCALAR',regex => qr/.+/m}); 

  
  
=head1 DESCRIPTION

This I<Parallel::Workers> allow you to run multiples tasks in parallel with or without error check (see I<Parallel::Workers::Transaction>).

You can specify maxworkers value that limit the max parallel task (threads pool). You can specify the backend 
that run the task, currently only Eval, SSH and XMLRPC are implemented, but you can make yours 
for your needs.

Workers run simples tasks that return value. You can specify different way to check the return value and 
on error you decide to stop or continue the main workers (see  I<Parallel::Workers::Transaction>).

        # workers TERM if return value is not in this regex /.+/m
        $id=$worker->create(...,
                            transaction=>{error=>TRANSACTION_TERM, type=>'SCALAR',regex => qr/.+/m }; 
        
        # workers TERM if return value is not 127
        $id=$worker->create(...,
                            transaction=>{error=>TRANSACTION_TERM, type=>'SCALAR',check => 127}; 

        # workers TERM if return value is not an HASH
        $id=$worker->create(...,
                            transaction=>{error=>TRANSACTION_TERM, type=>'ARRAY'}; 

        # workers CONTINUE on error
        $id=$worker->create(...,
                            transaction=>{error=>TRANSACTION_CONT, ...}; 


=head1 METHODS

=head2 new([%h])

Constructor. %h is a hash of attributes :

    maxworkers:16 , the max parallel tasks (threads)
    timeout:10, the time in second before to kill thread (only when stop workers)
    backend:undef, the task 
    constructor:undef, the task constructor
    
=head2 info()

  return all workers results
  
=head2 create(hosts => @hosts, spawn=>0, command=>$cmd, params=>%h|@a|$r, transaction=>%h)
  
=head2 stop
    
=head2 clear

=head2 join
    
=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Parallel::Workers requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-parallel-jobs@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Olivier Evalet  C<< <evaleto@gelux.ch> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Olivier Evalet C<< <evaleto@gelux.ch> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

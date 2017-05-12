package Parallel::MapReduce;

use threads;

use strict;
use warnings;
use Data::Dumper;

require Exporter;
use base qw(Exporter);

use Parallel::MapReduce::Utils;
use Cache::Memcached;

use Storable;
$Storable::Deparse = 1;
$Storable::Eval    = 1;

our $VERSION  = '0.09';

#-- logging infrastructure

use Log::Log4perl;
Log::Log4perl::init( \ q(

#log4perl.rootLogger=DEBUG, Screen
log4perl.rootLogger=INFO, Screen

log4perl.appender.Screen=Log::Log4perl::Appender::Screen
log4perl.appender.Screen.layout=Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern=[%r] %F %L %c - %m%n
			 ) );

our $log = _log();  # lets create a logger, should be used throughout

sub _log {
    return Log::Log4perl->get_logger("MR");
}

=pod

=head1 NAME

Parallel::MapReduce - MapReduce Infrastructure, multithreaded

=head1 SYNOPSIS

  ## THIS IS ALL STILL EXPERIMENTAL!!
  ## DO NOT USE FOR PRODUCTION!!
  ## LOOK AT THE ROADMAP AND FEEDBACK WHAT YOU FIND IMPORTANT!!

  use Parallel::MapReduce;
  my $mri = new Parallel::MapReduce (MemCacheds => [ '127.0.0.1:11211', .... ],
                                     Workers    => [ '10.0.10.1', '10.0.10.2', ...]);

  my $A = {1 => 'this is something ',
           2 => 'this is something else',
           3 => 'something else completely'};

  # apply MR algorithm (word count) on $A
  my $B = $mri->mapreduce (
			     sub {
				 my ($k, $v) = (shift, shift);
				 return map { $_ => 1 } split /\s+/, $v;
			     },
			     sub {
				 my ($k, $v) = (shift, shift);
				 my $sum = 0;
				 map { $sum += $_ } @$v;
				 return $sum;
			     },
			     $A
                           );

  # prefabricate mapreducer
  my $string2lines = $mri->mapreducer (sub {...}, sub {...});
  # apply it
  my $B = &$string2lines ($A);

  # pipeline it with some other mapreducer
  my $pipeline = $mri->pipeline ($string2lines,
                                 $lines2wordcounts);

  # apply that
  my $B = &$pipeline ($A);

=head1 ABSTRACT

The MapReduce framework allows a parallel, and possibly distributed computation of CPU intensive
computations on several, if not many hosts.

For this purpose you will have to formulate your problem into one which only deals with list
traversal (map) and list comprehension (reduce), something which is not unnatural for Perl
programmers. In effect you end up with a hash-to-hash transform and this is exactly what this
package implements.

This package implements MapReduce for local invocations, parallelized (but still local) invocations
and for fully distributed invocations. For the latter it is B<not> using a file system to propagate
data, but instead a pool of C<memcached> servers.

=head1 DESCRIPTION

In a nutshell, the MapReduce algorithm is this (in sequential form):

   sub mapreduce {
       my $mri    = shift;
       my $map    = shift;
       my $reduce = shift;
       my $h1     = shift;

       my %h3;
       while (my ($k, $v) = each %$h1) {
   	my %h2 = &$map ($k => $v);
   	map { push @{ $h3{$_} }, $h2{$_} } keys %h2;
       }
       my %h4;
       while (my ($k, $v) = each %h3) {
   	$h4{$k} = &$reduce ($k => $v);
       }
       return \%h4;
   }

It is the task of the application programmer to determine the functions C<$map> and C<$reduce>,
which when applied to the hash C<$h1> will produce the wanted result. The infrastructure C<$mri> is
not used above, but it becomes relevant when the individual invocations of C<$map> and C<$reduce>
are (a) parallelized or (b) are distributed. And this is what this package does.

=over

=item Master

This is the host where you initiate the computation and this is where the central algorithm will be
executed.

=item Workers

Each worker can execute either the C<$map> function or the C<$reduce> over the subslice of the
overall data. Workers can run local simply as subroutine (see L<Parallel::MapReduce::Worker>, or can
be a thread talking to a remote instance of a worker (see L<Parallel::MapReduce::Worker::SSH>).

When you create your MR infrastructure you can specify which kind of workers you want to use (via a
C<WorkerClass> in the constructor).

B<NOTE>: Feel free to propose more workers.

=item Servers

To exchange hash data between master and workers and also between workers this package makes use of
an existing C<memcached> server pool (see L<http://www.danga.com/memcached/>). Obviously, the more
servers there are running, the merrier.

B<NOTE>: The (Debian-packaged) Perl client is somewhat flaky in multi-threaded environments. I made
some work-arounds, but other options should be investigated.

=back

=cut

use Parallel::MapReduce::Worker;
use Parallel::MapReduce::Worker::FakeRemote;
use Parallel::MapReduce::Worker::SSH;

=pod

=head1 INTERFACE

=head2 Constructor

I<$mri> = new Parallel::MapReduce (...)

The constructor accepts the following options:

=over

=item C<MemCacheds> (default: none)

A list reference to IP:port strings detailing how the C<memcached> can be reached.  You must specify
at least one. If you have no C<memcached> running, your only option is to use
L<Parallel::MapReduce::Testing> instead. That runs the whole thing locally.

=item C<Workers> (default: none)

A list reference to IP addresses on which hosts the workers should be run. You can name one and the
same IP address multiple times to rebalance the load.

For worker implementations which are B<not> farmed out, the IP addresses do not count. But their
number does.

=item C<WorkerClass> (default: C<Parallel::MapReduce::Worker>)

Which worker implementation to be used.

=back

=cut

sub new {
    my $class = shift;
    my %opts  = @_;
    $opts{WorkerClass} ||= 'Parallel::MapReduce::Worker';                 # make sure we have something
    $log->logdie ("no MemCached servers") unless $opts{MemCacheds} &&
	                                       @{ $opts{MemCacheds} };    # complain if there is nowhere to write data to

    my $self  = bless \%opts, $class;
    $self->{_workers} = [ map { $self->{WorkerClass}->new (host => $_) }  # start up all
			  @{ $self->{Workers} }                           # workers
			  ];
    $log->logdie ("no operational workers") unless @{ $self->{_workers} };# complain if there is no one doing any work
    return $self;
}

=pod

=head2 Methods

=over

=item B<shutdown>

I<$mri>->shutdown

Especially when you use the SSH workers you should make sure that you terminate them properly. So
better run this method if you do not want to have plenty of SSH sessions being left over.

=cut

sub shutdown {
    my $self = shift;
    map { $_->shutdown } @{ $self->{_workers} };
}

sub _slices {
    $_ = scalar @{$_[0]} . ':' . scalar grep { $_->{slice} } @{$_[1]};
    return '' if $_ eq '0:0';
    return $_;
}

=pod

=item B<mapreduce>

I<$A> = I<$mri>->mapreduce (I<$map_coderef>, I<$reduce_coderef>, I<$B>)

This method applies to hash (reference) C<$B> the MR algorithm. You have to pass in CODE refs to the
map and the reduce function. The result a reference to a hash.

=cut

sub mapreduce {
    my $self    = shift;
    #--
    my $map    = shift;                                                      # the map function to be used
    my $reduce = shift;                                                      # the reduce function to be used
    my $h1     = shift;                                                      # the incoming hash
    my $job    = shift || 'job1:';                                           # a job id (should be different for every job)

    my $memd = new Cache::Memcached {servers   => $self->{MemCacheds},       # connect to the Memcached cloud
				     namespace => $job };

    threads->create (sub { $memd->set ('map',    $map) })   ->join;          # store map into cloud (see $Storable::Deparse)
    threads->create (sub { $memd->set ('reduce', $reduce) })->join;          # store reduce into cloud (see $Storable::Deparse)

  SLICING:
    my $slices = Hslice ($h1, scalar @{ $self->{_workers} });                # slice the hash into equal parts (as many workers as there are)
    $log->debug ("master sliced ".Dumper $slices) if $log->is_debug;

    my @keys;                                                                # this will be filled in the map phase below
  MAPPHASE:
    while (my $sl4ws = _slices ([ keys %$slices ], $self->{_workers}) ) {    # compute unresolved slices versus operational workers
	if (my ($k) = keys %$slices) {                                       # there is one unhandled
    
	    if (my ($w) = grep { ! defined $_->{thread} }                    # find a non-busy worker
		          @{ $self->{_workers}} ) {                          # from the operational workers
#warn "found free ".$w->{host};
		$w->{slice}  = delete $slices->{$k};                         # task it with slice,  take it off the list for now
                my @chunks = threads->create ({'context' => 'list'},
					      'chunk_n_store',
					      $memd, $w->{slice}, 
					      $job, 1000)->join;             # distribute hash slice over memcacheds
#warn "thread chunks ".Dumper \@chunks;

		$w->{thread} = threads->create (ref ($w).'::map',
 						$w,                          # this is the worker which will be effectively tasked
 						\@chunks,                    # these params are just passed through
 						"slice$k:",
 						$self->{MemCacheds},
 						$job);
	    } else {                     
		# null
	    }
	}
	foreach my $j ( threads->list ( threads::joinable() ) ) {            # see those who are finished
#warn "joining one";
	    push @keys, @{ $j->join() };                                     # harvest
	    my ($w) = grep { $_->{thread} == $j } @{$self->{_workers}};      # find the corresponding worker
#warn " and it is ".$w->{host};
	    $w->{slice} = $w->{thread} = undef;                              # entlaste den
	}
#warn "open slices? ".Dumper $slices;
#warn "outstanding threads? ".Dumper [ map { $_->{slice} } @{$self->{_workers}}];
#warn "   _slices "._slices ([ keys %$slices ], $self->{_workers});
#warn "waiting for something...";
	sleep 1 if $sl4ws eq _slices ([ keys %$slices ], $self->{_workers});    # only if no progress , we are not yet finished?
    }

    $log->debug ("master: all keys after mappers ".Dumper \@keys) if $log->is_debug;
  RESHUFFLING:
    my $Rs = balance_keys (\@keys, $job, scalar @{ $self->{_workers} });     # slice the keys into 'equal' groups
    $log->debug ("master: after balancing ".Dumper $Rs) if $log->is_debug;

    my @chunks;
  REDUCEPHASE:
    while (my $rs4ws = _slices ([ keys %$Rs ], $self->{_workers}) ) {
	if (my ($r) = keys %$Rs) {

	    if (my ($w) = grep { ! defined $_->{thread} }                    # find a non-busy worker
		          @{ $self->{_workers}} ) {                          # from the operational workers
#warn "reduce: found free ".$w->{host};
                $w->{slice}  = delete $Rs->{$r}; 

                $w->{thread} = threads->create (ref ($w).'::reduce',
						$w,
						$w->{slice},
						$self->{MemCacheds}, 
						$job);
	    } else {                     
		# null
	    }
	}
	foreach my $j ( threads->list (threads::joinable) ) {                # see those who are finished
#warn "reduce: joining one";
	    push @chunks, @{ $j->join() };                                   # harvest
	    my ($w) = grep { $_->{thread} == $j } @{$self->{_workers}};      # find the corresponding worker
#warn " and it is ".$w->{host};
	    $w->{slice} = $w->{thread} = undef;                              # entlaste den
	}
#warn "reduce: open R slices? ".Dumper $Rs;
#warn "reduce : outstanding threads? ".Dumper [ map { $_->{slice} } @{$self->{_workers}}];
#warn "   _slices "._slices ([ keys %$Rs ], $self->{_workers});
#warn "reduce: waiting for something...";
	sleep 1 if $rs4ws eq _slices ([ keys %$Rs ], $self->{_workers});     # only if no progress , we are not yet finished?
    }

#    foreach my $r (keys %$Rs) {                                              # for all these slices
#	my ($w) = @{ $self->{_workers} };                                    # take always the first, TODO: random?
#	push @chunks, @{ 
#	               $w->reduce ($Rs->{$r}, $self->{MemCacheds}, $job)     # run the reducer and collect keys of chunks for result hash
#		       };
#    }

#warn "trying to reconstruct from ".Dumper \@chunks;
    my $h4 = threads->create ('fetch_n_unchunk', $memd, \@chunks)->join;
## fetch_n_unchunk ($memd, \@chunks);                             # collect together all these chunks
    $log->debug ("master: reconstructed result ".Dumper $h4) if $log->is_debug;
    return $h4;                                                              # return the result hash
}


=pod

=item B<mapreducer>

I<$op> = I<$mri>->mapreducer (I<$map_coderef>, I<$reduce_coderef>)

This method returns a prefabricated mapreducer (see SYNOPSIS). You also have to pass in CODE refs to
the map and the reduce function.

=cut

sub mapreducer {
    my $self = shift;

    my $map    = $_[0];
    my $reduce = $_[1];
    
    return sub {
	my $mri = $self;
	return $mri->mapreduce ($map, $reduce, @_);
    }
};

=pod

=item B<pipeline>

I<$op> = I<$mri>->pipeline (I<$op1>, I<$op2>, ...)

This method takes a number of prefabricated mapreducers and pipelines them into one. That is
returned.

B<NOTE>: When a pipeline is executed the processor could be clever B<not> to retrieve intermediate
hashes. At the moment, though, this is still the case.

=cut

sub pipeline {
    my $self = shift;
    my @mrs  = @_;
    return sub {
	my $mri = $self;
	my $A = shift;
	foreach my $mr (@mrs) {
	    my $B = &$mr ($A);
	    $A = $B;
	}
	return $A;
    }
}

=pod

=back

=head1 SEE ALSO

L<Parallel::MapReduce::Sequential>, L<Parallel::MapReduce::Testing>, L<Parallel::MapReduce::Worker>, L<Log::Log4perl>

=head1 COPYRIGHT AND LICENSE

Copyright 200[8] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;

__END__





package Parallel::MapReduce::Sequential;

use base 'Parallel::MapReduce';

use strict;
use warnings;
use Data::Dumper;
use Cache::Memcached;
use Parallel::MapReduce::Utils;

our $log;

=pod

=head1 NAME

Parallel::MapReduce::Sequential - MapReduce Infrastructure, single-threaded

=head1 SYNOPSIS

  use Parallel::MapReduce::Sequential;
  my $mri = new Parallel::MapReduce::Sequential
                        (MemCacheds => [ '127.0.0.1:11211', .... ],
                         Workers    => [ '10.0.10.1', '10.0.10.2', ...]);

  # rest like in Parallel::MapReduce

=head1 DESCRIPTION

This subclass of L<Parallel::MapReduce> implements MapReduce as a single thread. Like its superclass
it uses a C<memcached> server pool to distribute the data and the class can also be used in
conjunction of local or remote workers. But everything will happen sequentially.

=cut

sub mapreduce {
    my $self    = shift;
    #--
    my $map    = shift;                                                      # the map function to be used
    my $reduce = shift;                                                      # the reduce function to be used
    my $h1     = shift;                                                      # the incoming hash
    my $job    = shift || 'job1:';                                           # a job id (should be different for every job)

    $log ||= $Parallel::MapReduce::log;

    my $memd = new Cache::Memcached {'servers' => $self->{MemCacheds}, namespace => $job };

    $memd->set ('map',    $map);                                             # store map into cloud (see $Storable::Deparse)
    $memd->set ('reduce', $reduce);                                          # store reduce into cloud (see $Storable::Deparse)

    my $h1_sliced = Hslice ($h1, scalar @{ $self->{_workers} });             # slice the hash into equal parts (as many workers as there are)
    $log->debug ("sliced ".Dumper $h1_sliced) if $log->is_debug;

    my @rkeys;                                                               # here we collect the intermediate keys, values remain in the cloud
    foreach my $k (keys %$h1_sliced) {                                       # for all slices of the original hash
	my @chunks = chunk_n_store ($memd, $h1_sliced->{$k}, $job, 1000);    # distribute hash over memcacheds
	$log->debug ("master created chunks ".Dumper \@chunks) if $log->is_debug;
	my ($w) = @{ $self->{_workers} };                                    # take always the first, TODO: random?
	push @rkeys, @{                                                      # store the returned keys of the ...
	             $w->map (\@chunks, "slice$k:", $self->{MemCacheds}, $job)  # ... run worker
	             };
    }
    $log->debug ("all keys after mappers ".Dumper \@rkeys) if $log->is_debug;

    my $Rs = balance_keys (\@rkeys, $job, scalar @{ $self->{_workers} });    # slice the keys into 'equal' groups

    my @Rchunks;
    foreach my $r (keys %$Rs) {                                              # for all these slices
	my ($w) = @{ $self->{_workers} };                                    # take always the first, TODO: random?
	push @Rchunks, @{ 
	               $w->reduce ($Rs->{$r}, $self->{MemCacheds}, $job)     # run the reducer and collect keys of chunks for result hash
		       };
    }

    $log->debug ("trying to reconstruct from ".Dumper \@Rchunks) if $log->is_debug;
    my $h4 = fetch_n_unchunk ($memd, \@Rchunks);                             # collect together all these chunks
    $log->debug ("reconstructed result ".Dumper $h4) if $log->is_debug;
    return $h4;                                                              # return the result hash
}

=pod

=head1 SEE ALSO

L<Parallel::MapReduce>

=head1 COPYRIGHT AND LICENSE

Copyright 200[8] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = 0.04;

1;

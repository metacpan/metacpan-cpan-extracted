package Parallel::MapReduce::Worker;

use Data::Dumper;

require Exporter;
use base qw(Exporter);

use Parallel::MapReduce::Utils;
use Cache::Memcached;

use Storable;
$Storable::Deparse = 1;
$Storable::Eval = 1;

use Parallel::MapReduce;
our $log = Parallel::MapReduce::_log();

=pod

=head1 NAME

Parallel::MapReduce::Worker - MapReduce, local worker

=head1 SYNOPSIS

  use Parallel::MapReduce::Worker;
  my $w = new Parallel::MapReduce::Worker;

  my @chunks = chunk_n_store ($memd, $A, $job, 1000);
  my $cs = $w->map (\@chunks, 'slice1:', SERVERS, $job);
  ...
  my $ks = $w->reduce (\@cs, SERVERS, $job);

=head1 DESCRIPTION

This class implements a local, sequential worker. You will only know
about it if you want to subclass it to implement your own worker.

=head1 INTERFACE

=head2 Constructor

Nothing important to be said.

=cut

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    return $self;
}

=pod

=head2 Destructor

I<$w>->shutdown

While there is no C<DESTROY> method (for technical reasons), there is a C<shutdown> method. It is
supposed to terminate any background processes a worker might have started.

For a single-thread, local version nothing will be done, but individual subclasses might have to do
substantial work to tear-down network connections, remote servers, etc.

=cut

sub shutdown {
    my $self = shift;
    # nothing in particular there
}

=pod

=head2 Methods

=over

=item B<map>

I<$keys> = I<$w>->map (I<$chunks>, I<$slice>, I<$servers>, I<$job>)

The chunks are keys into the C<memcached> servers. They allow to reconstruct the hash slice to be
worked on. The slice is a simple id for that hash slice. The list reference to the C<memcached>
servers is obviously also necessary and the job id is an identifier for the current MR computation.

=cut

sub map {
    my $self = shift;
    my ($chunks, $slice, $servers, $job) = @_;
#warn "mapper received ".Dumper [ $chunks, $slice, $servers, $job ];

    my $memd = new Cache::Memcached {servers => $servers, namespace => $job };

#warn Dumper \ %Cache::Memcached::Cache;
    my $map  = $memd->get ('map');
    my $h1   = fetch_n_unchunk ($memd, $chunks);
    $log->debug ("generic mapper got h1 ".Dumper $h1) if $log->is_debug;
    my %h3;
    while (my ($k, $v) = each %$h1) {
	my %h2 = &$map ($k => $v);
	map { push @{ $h3{$_} }, $h2{$_} } keys %h2;
    }
    $log->debug ("generic mapper produced h3 ".Dumper \%h3) if $log->is_debug;
    my @cs = Hstore ($memd, \%h3, $slice, $job);
    return \@cs;
}

=pod

=item B<reduce>

I<$chunks> = I<$w>->reduce (I<$keys>, I<$servers>, I<$job>)

The keys are the keys into the intermediate hash within the C<memcached> servers. The list reference
to the C<memcached> servers is obviously also necessary and the job id is an identifier for the
current MR computation.

=cut

sub reduce {
    my $self = shift;
    my ($keys, $servers, $job) = @_;
    my $memd = new Cache::Memcached {'servers' => $servers, namespace => $job };

    my $reduce = $memd->get ('reduce');
    $log->debug ("generic reducer before Hfetch keys ".Dumper $keys) if $log->is_debug;
    my $h3 = Hfetch ($memd, $keys, $job);
    $log->debug ("generic resorted h3 at reducer ".Dumper $h3) if $log->is_debug;
    my %h4;
    while (my ($k, $v) = each %$h3) {
	$h4{$k} = &$reduce ($k => $v);
    }
    $log->debug ("generic reducer produced h4 ".Dumper \%h4) if $log->is_debug;
    
    my @chunks = chunk_n_store ($memd, \%h4, $job);
#warn "reducer chunks ".Dumper \@chunks;
    return \@chunks;
}

=pod

=back

=head1 SEE ALSO

L<Parallel::MapReduce>

=head1 COPYRIGHT AND LICENSE

Copyright 200[8] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = 0.03;

1;

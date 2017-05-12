package Parallel::MapReduce::Worker::SSH;

use strict;
use warnings;

use base 'Parallel::MapReduce::Worker';

use Data::Dumper;
use IPC::Run qw(start pump finish timeout);

our $log = Parallel::MapReduce::_log();

=pod

=head1 NAME

Parallel::MapReduce::Worker::SSH - MapReduce, remote worker via SSH

=head1 SYNOPSIS

  use Parallel::MapReduce::Worker::SSH;
  my $w = new Parallel::MapReduce::Worker::SSH (host => '10.0.10.2');

  # otherwise same interface as parent class Parallel::MapReduce::Worker

=head1 DESCRIPTION

This subclass of L<Parallel::MapReduce::Worker> implements a remote worker using SSH for launching
and the resulting SSH tunnel for communicating.

By default, the package is trying an SSH client C</usr/bin/ssh> and is assuming that the Perl binary
on the remote machine is C</usr/bin/perl>. Tweak the package variables C<$SSH> and C<$PERL> if these
assumptions are wrong.

=cut

our $SSH  = '/usr/bin/ssh';
our $PERL = '/usr/bin/perl';

=pod

=head1 INTERFACE

=head2 Constructor

The construct expects the following fields:

=over

=item C<host> (default: none)

At constructor time an SSH connection to the named host is attempted. Then a remote Perl program to
implement the worker there is started. For this, obviously C<Parallel::MapReduce> must be installed
on the remote machine.

=back

B<NOTE>: Do not forget to call C<shutdown> on an SSH worker, otherwise you will have a lot of
lingering SSH connections.

=cut

sub new {
    my $class = shift;
    my %opts  = @_;
    my $self = bless { host => $opts{host},
		       in   => '',
		       out  => '',
		       err  => '',
		   }, $class;
    $log->debug ("SSH starting up ".$self->{host});
    $self->{harness} = start [ split /\s+/, "$SSH ".$self->{host}." $PERL -I/home/rho/projects/mapreduce/lib -MParallel::MapReduce -MParallel::MapReduce::Worker::SSHRemote -e 'Parallel::MapReduce::Worker::SSHRemote::worker()'" ], 
                             \ $self->{in}, \ $self->{out}, \ $self->{err},
                             timeout( 20 ) ;
    $log->info ("SSH started up at ".$self->{host});
    return $self;
}

sub shutdown {
    my $self = shift;

    $self->{in} .= "exit\n";
    pump $self->{harness};	      # make sure the worker gets exit
    $self->{harness}->finish;           # make sure the worker is dead
}


sub map {
    my $self = shift;
    my $cs = shift;
    my $sl = shift;
    my $ss = shift;
    my $jj = shift;

    $self->{in} = $self->{out} = $self->{err} = '';
    $self->{in} .= "mapper\n";
    $self->{in} .= "$jj\n";
    $self->{in} .= "$sl\n";
    $self->{in} .= join (",",  @$ss ) . "\n";
    $self->{in} .= join ("\n", @$cs ) . "\n\n";
    $log->debug ("SSH map sent chunks: ".Dumper $cs) if $log->is_debug;

    pump $self->{harness} until $self->{out} =~ /\n\n/g;
    $log->debug ("SSH worker (map) sent back err".$self->{err});
    $log->debug ("SSH worker (map) sent back out".$self->{out});

    return [ split /\n/, $self->{out} ];
}

sub reduce {
    my $self = shift;
    my $ks = shift;
    my $ss = shift;
    my $jj = shift;

    $self->{in} = $self->{out} = $self->{err} = '';
    $self->{in} .= "reducer\n";
    $self->{in} .= "$jj\n";
    $self->{in} .= join (",",  @$ss ) . "\n";
    $self->{in} .= join ("\n", @$ks ) . "\n\n";
    $log->debug ("SSH reduce sent ".scalar @$ks." keys") if $log->is_debug;

    pump $self->{harness} until $self->{out} =~ /\n\n/g;
    $log->debug ("SSH worker (reduce) sent back err".$self->{err});
    $log->debug ("SSH worker (reduce) sent back out".$self->{out});
    return [ split /\n/, $self->{out} ];
}


=pod

=head1 SEE ALSO

L<Parallel::MapReduce::Worker>

=head1 COPYRIGHT AND LICENSE

Copyright 200[8] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = 0.05;

1;

__END__

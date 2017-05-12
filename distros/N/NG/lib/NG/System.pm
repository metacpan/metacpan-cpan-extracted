package System;
use warnings;
use strict;
use autodie;
use base 'Object';
use Array;
use IPC::Open3;
use Symbol;
use Sys::CpuAffinity;

sub new {
    my $pkg = shift;
    return bless {}, $pkg;
}

=head2 local_run
    local_run "ls", sub {
	    my ($out, $err) = @_;
	    $out->each(sub{
	       ...
	    })
	    ...
    }
=cut

sub local_run {
    my $inh  = gensym;
    my $outh = gensym;
    my $errh = gensym;
    my $cb;
    if ( ref($cb) ne 'CODE' ) {
        $cb = pop @_;
    }
    my @commands = @_;

    my $ret = open3( $inh, $outh, $errh, @commands );

    my $stdout = Array->new;
    my $stderr = Array->new;
    while (<$outh>) {
        chomp;
        $stdout->push($_);
    }
    while (<$errh>) {
        chomp;
        $stderr->push($_);
    }
    if ( defined $cb ) {
        $cb->( $stdout, $stderr );
        return $ret;
    }
    else {
        return $stdout;
    }
}

=head2 remote_run
TODO: async ssh command
    remote_run @hosts, $cmd, sub {
	    my ($out, $err) = @_;
    }
=cut

sub remote_run {
    my $cb    = pop @_;
    my $cmd   = pop @_;
    my @hosts = @_;
    ...;
}

=head2 taskset
    taskset($subpid, [0, 2])
=cut

sub taskset {
    my ( $pid, @cpus ) = @_;
    Sys::CpuAffinity::setAffinity( $pid, \@cpus );
}

1;

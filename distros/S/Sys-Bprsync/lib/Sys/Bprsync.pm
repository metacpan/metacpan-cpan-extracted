package Sys::Bprsync;
{
  $Sys::Bprsync::VERSION = '0.25';
}
BEGIN {
  $Sys::Bprsync::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Bullet-proof rsync wrapper

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Try::Tiny;

use Sys::Bprsync::Job;
use Job::Manager;
use Sys::CmdMod;

has 'logfile' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 1,
);

has 'jobs' => (
    'is'      => 'rw',
    'isa'     => 'Job::Manager',
    'lazy'    => 1,
    'builder' => '_init_jobs',
);

has 'execpre' => (
    'is'       => 'ro',
    'isa'      => 'ArrayRef[Str]',
    'required' => 0,
    'default'  => sub { [] },
);

has 'execpost' => (
    'is'       => 'ro',
    'isa'      => 'ArrayRef[Str]',
    'required' => 0,
    'default'  => sub { [] },
);

has 'rsync_codes' => (
    'is'      => 'ro',
    'isa'     => 'HashRef',
    'lazy'    => 1,
    'builder' => '_init_rsync_codes',
);

has 'cmdmod' => (
    'is'      => 'rw',
    'isa'     => 'Sys::CmdMod',
    'lazy'    => 1,
    'builder' => '_init_cmdmod',
);

has 'config_prefix' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'lazy'    => 1,
    'builder' => '_init_config_prefix',
);

has 'concurrency' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'default' => 1,
);

has 'sys' => (
    'is'      => 'rw',
    'isa'     => 'Sys::Run',
    'lazy'    => 1,
    'builder' => '_init_sys',
);

with qw(Config::Yak::RequiredConfig Log::Tree::RequiredLogger);

sub _init_sys {
    my $self = shift;

    my $Sys = Sys::Run::->new( {
      'logger'            => $self->logger(),
      'ssh_hostkey_check' => 0,
    } );

    return $Sys;
}

sub _init_cmdmod {
    my $self = shift;

    my $Cmd = Sys::CmdMod::->new({
        'config'    => $self->config(),
        'logger'    => $self->logger(),
    });

    return $Cmd;
}

sub get_cmd_prefix {
    my $self = shift;

    my $prefix = q{};

    return $self->cmdmod()->cmd($prefix);
}

sub _init_rsync_codes {
    my $self = shift;

    # explaination of rsync return codes - taken from dirvish
    # see http://rsync.samba.org/ftp/unpacked/rsync/errcode.h
    my %RSYNC_CODES = (
        0 => [ 'success', 'No errors' ],
        1 => [ 'fatal',   'syntax or usage error' ],
        2 => [ 'fatal',   'protocol incompatibility' ],
        3 => [ 'fatal',   'errors selecting input/output files, dirs' ],
        4 => [ 'fatal',   'requested action not supported' ],
        5 => [ 'fatal',   'error starting client-server protocol' ],

        10 => [ 'error', 'error in socket IO' ],
        11 => [ 'error', 'error in file IO' ],
        12 => [ 'check', 'error in rsync protocol data stream' ],
        13 => [ 'check', 'errors with program diagnostics' ],
        14 => [ 'error', 'error in IPC code' ],
        15 => [ 'error', 'sibling crashed' ],
        16 => [ 'error', 'sibling terminated abnormally' ],

        19 => [ 'error', 'status returned when sent SIGUSR1' ],
        20 => [ 'error', 'status returned when sent SIGUSR1, SIGINT' ],
        21 => [ 'error', 'some error returned by waitpid()' ],
        22 => [ 'error', 'error allocating core memory buffers' ],
        23 => [ 'warning', 'partial transfer' ],

        24 => [ 'warning', 'file vanished on sender' ],
        25 => [ 'warning', 'skipped some deletes due to --max-delete' ],

        30 => [ 'error', 'timeout in data send/receive' ],
        35 => [ 'error', 'timeout waiting for daemon connection' ],

        124 => [ 'fatal', 'remote shell failed' ],
        125 => [ 'error', 'remote shell killed' ],
        126 => [ 'fatal', 'command could not be run' ],
        127 => [ 'fatal', 'command not found' ],
        255 => [ 'fatal', 'unexplained error/missing ssh keys' ],
    );
    return \%RSYNC_CODES;
}

sub _init_config_prefix {
    return 'Sys::Bprsync';
}

sub BUILD {
    my $self = shift;

    # populate execpre and execpost from config if not given explicitly

    if ( !$self->execpre() ) {
        my @vals = $self->config()->get_array( $self->config_prefix() . '::ExecPre' );
        $self->execpre( [@vals] ) if @vals;
    }

    if ( !$self->execpost() ) {
        my @vals = $self->config()->get_array( $self->config_prefix() . '::ExecPost' );
        $self->execpre( [@vals] ) if @vals;
    }

    return 1;
}

sub vaults {
    my $self = shift;

    return [$self->config()->get_array( $self->config_prefix() . '::Jobs' )];
}

sub _init_jobs {
    my $self = shift;

    my $JQ = Job::Manager::->new(
        {
            'logger'      => $self->logger(),
            'concurrency' => $self->concurrency(),
        }
    );
    my $verbose = $self->config()->get( $self->config_prefix() . '::Verbose' ) ? 1 : 0;
    my $dry     = $self->config()->get( $self->config_prefix() . '::Dry' )     ? 1 : 0;

    foreach my $job_name ( @{$self->vaults()} ) {
        try {
            my $Job = Sys::Bprsync::Job::->new(
                {
                    'parent'  => $self,
                    'name'    => $job_name,
                    'verbose' => $verbose,
                    'dry'     => $dry,
                    'logger'  => $self->logger(),
                    'config'  => $self->config(),
                }
            );
            $JQ->add($Job);
        }
        catch {
            $self->logger()->log( message => 'caught error: '.$_, level => 'error', );
        };
    }

    return $JQ;
}

sub _exec_pre {
    my $self = shift;

    my $ok = 1;
    foreach my $cmd ( @{ $self->execpre() } ) {
        if ( !$self->sys()->run_cmd($cmd) ) {
            $ok = 0;
        }
    }
    return $ok;
}

sub _exec_post {
    my $self = shift;

    foreach my $cmd ( @{ $self->execpost() } ) {
        $self->sys()->run_cmd($cmd);
    }
    return 1;
}

sub run {
    my $self = shift;
    $self->_exec_pre()
        or return;
    $self->jobs()->run();
    $self->_exec_post();

    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Bprsync - Bullet-proof rsync wrapper

=head1 NAME

Sys::BPrsync - Bullet-proof rsync wrapper

=head1 METHODS

=head2 BUILD

Initialize pre and post exec queues.

=head2 get_cmd_prefix

Return the command prefix.

=head2 run

Run the sync.

=head2 vaults

Return a list of all vaults.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

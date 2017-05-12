package Sys::Bprsync::Cmd::Command::configcheck;
{
  $Sys::Bprsync::Cmd::Command::configcheck::VERSION = '0.25';
}
BEGIN {
  $Sys::Bprsync::Cmd::Command::configcheck::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: verify the bprsync configuration

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;
use Sys::Bprsync;

# extends ...
extends 'Sys::Bprsync::Cmd::Command';
# has ...
has '_bp' => (
    'is'    => 'ro',
    'isa'   => 'Sys::Bprsync',
    'lazy'  => 1,
    'builder' => '_init_bp',
    'reader' => 'bp',
);

has 'verbose' => (
    'is'            => 'ro',
    'isa'           => 'Bool',
    'required'      => 0,
    'traits'        => [qw(Getopt)],
    'cmd_aliases'   => 'v',
    'documentation' => 'Be more verbose',
);
# with ...
# initializers ...
sub _init_bp {
    my $self = shift;

    my $BP = Sys::Bprsync::->new({
        'config'        => $self->config(),
        'logger'        => $self->logger(),
        'logfile'       => $self->config()->get( 'Sys::Bprsync::Logfile', { Default => '/tmp/bprsync.log', } ),
        'concurrency'   => 1,
    });

    return $BP;
}

# your code here ...
sub execute {
    my $self = shift;

    my $status = 1;
    # do we have at least one job?
    my $jobs = $self->bp()->vaults();
    if($jobs && ref($jobs) eq 'ARRAY') {
        # check each vault if it is accessible
        foreach my $job_name (sort @{$jobs}) {
            my $job = $self->bp()->config()->get($self->bp()->config_prefix().'::Jobs::'.$job_name);
            say 'Job: '.$job_name;
            if($self->verbose()) {
                say "\t".$job->{'source'}.' => '.$job->{'destination'};
                say "\tBwlimit: ".$job->{'bwlimit'} if $job->{'bwlimit'};
                say "\tCompression: ".$job->{'compression'} if $job->{'compression'};
                say "\tDelete: ".$job->{'delete'} if $job->{'delete'};
                say "\tDescription: ".$job->{'description'} if $job->{'description'};
                say "\tExclude: ".$job->{'exclude'} if $job->{'exclude'};
                say "\tExcludefrom: ".$job->{'excludefrom'} if $job->{'excludefrom'};
                say "\tHardlink: ".$job->{'hardlink'} if $job->{'hardlink'};
                say "\tWill cross FS boundaries: ".($job->{'nocrossfs'} ? 'No' : 'Yes');
                say "\tNumeric-IDs: ".$job->{'numericids'} if $job->{'numericids'};
                say "\tRemote-Shell: ".$job->{'rsh'} if $job->{'rsh'};
                say "\tRemote-Shell Options: ".$job->{'rshopts'} if $job->{'rshopts'};
                say "\tTimeframe: ".$job->{'timeframe'} if $job->{'timeframe'};
            }

            # check access ...
            ## for local dirs: check existence and rw
            ## for remotes: check ssh access
            # source
            if($job->{'source'} =~ m/:/) {
                # remote
                if(!$self->_check_remote($job->{'source'},$job->{'rshopts'})) {
                    $status = 0;
                }
            } else {
                # local
                if(!$self->_check_local($job->{'source'})) {
                    $status = 0;
                }
            }
            # destination
            if($job->{'destination'} =~ m/:/) {
                # remote
                if(!$self->_check_remote($job->{'destination'},$job->{'rshopts'})) {
                    $status = 0;
                }
            } else {
                # local
                if(!$self->_check_local($job->{'destination'})) {
                    $status = 0;
                }
            }
        }
    } else {
        my @files_read = @{$self->bp()->config()->files_read()};
        if(@files_read) {
            say 'ERROR - No jobs defined in: '.join(q{:},@files_read);
        } else {
            say 'ERROR - No config files found in '.join(q{:},@{$self->bp()->config()->locations()});
        }
        $status = 0;
    }

    return $status;
}

sub _check_remote {
    my $self = shift;
    my $location = shift;
    my $rshopts = shift || '';

    my ($host, $path) = split /:/, $location, 2;
    if($self->bp()->sys()->check_ssh_login($host, { SSHOpts => $rshopts, })) {
        say ' OK - SSH access to '.$host.' works';
        if($self->bp()->sys()->run_remote_cmd($host,'ls '.$path,, { SSHOpts => $rshopts, })) {
            say ' OK - Remote location '.$path.' is a directory';
            return 1;
        } else {
            say ' ERROR - Remote location '.$path.' not found on host '.$host;
            return;
        }
    } else {
        say ' ERROR - SSH access to '.$host.' failed!';
        return;
    }
}

sub _check_local {
    my $self = shift;
    my $location = shift;

    if(-d $location) {
        say ' OK - Location '.$location.' is a directory';
        if(-w $location) {
            say ' OK - Location '.$location.' is writeable';
            return 1;
        }
    } else {
        say ' ERROR - Location '.$location.' is no directory';
        return;
    }
}

sub abstract {
    return 'Check integrity of the configuration';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Bprsync::Cmd::Command::configcheck - verify the bprsync configuration

=head1 METHODS

=head2 abstract

Workaround.

=head2 execute

Extensive configuration test.

=head1 NAME

Sys::Bprsync::Cmd::Command::configcheck - verify the bprsync configuration

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Sys::RevoBackup::Cmd::Command::run;
{
  $Sys::RevoBackup::Cmd::Command::run::VERSION = '0.27';
}
BEGIN {
  $Sys::RevoBackup::Cmd::Command::run::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: run revobackup

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
use Linux::Pidfile;
use Sys::RevoBackup;

# extends ...
extends 'Sys::RevoBackup::Cmd::Command';
# has ...
has '_pidfile' => (
    'is'    => 'ro',
    'isa'   => 'Linux::Pidfile',
    'lazy'  => 1,
    'builder' => '_init_pidfile',
);

has 'job' => (
  'is'    => 'ro',
  'isa'   => 'Str',
  'default' => '',
  'traits'        => [qw(Getopt)],
  'cmd_aliases'   => 'j',
  'documentation' => 'Only execute this job',
);
# with ...
# initializers ...
sub _init_pidfile {
    my $self = shift;

    my $PID = Linux::Pidfile::->new({
        'pidfile'   => $self->config()->get('Revobackup::Pidfile', { Default => '/var/run/revobackup.pid', }),
        'logger'    => $self->logger(),
    });

    return $PID;
}

# your code here ...
sub execute {
    my $self = shift;

    $self->_pidfile()->create() or die('Script already running.');

    my $bankdir = $self->config()->get('Sys::RevoBackup::Bank');
    if ( !$bankdir ) {
        die('Bankdir not defined. You must set Sys::RevoBackup::bank to an existing directory! Aborting!');
    }
    if ( !-d $bankdir ) {
        die('Bankdir ('.$bankdir.') not found. You must set Sys::RevoBackup::bank to an existing directory! Aborting!');
    }

    my $concurrency = $self->config()->get( 'Sys::RevoBackup::Concurrency', { Default => 1, } );

    my $Revo = Sys::RevoBackup::->new(
        {
            'config'      => $self->config(),
            'logger'      => $self->logger(),
            'logfile'     => $self->config()->get( 'Sys::RevoBackup::Logfile', { Default => '/tmp/revo.log' } ),
            'bank'        => $bankdir,
            'concurrency' => $concurrency,
        }
    );

    if($self->job()) {
      $Revo->job_filter($self->job());
    }

    my $status = $Revo->run();

    $self->_pidfile()->remove();

    return $status;
}

sub abstract {
    return 'Make some backups';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::RevoBackup::Cmd::Command::run - run revobackup

=head1 METHODS

=head2 abstract

Workadound.

=head2 execute

Run the backups.

=head1 NAME

Sys::RevoBackup::Cmd::Command::run - run all backup jobs

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

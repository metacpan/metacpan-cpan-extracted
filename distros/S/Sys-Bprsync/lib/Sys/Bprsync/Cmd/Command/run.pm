package Sys::Bprsync::Cmd::Command::run;
{
  $Sys::Bprsync::Cmd::Command::run::VERSION = '0.25';
}
BEGIN {
  $Sys::Bprsync::Cmd::Command::run::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: run all pending sync jobs

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
use Sys::Bprsync;

# extends ...
extends 'Sys::Bprsync::Cmd::Command';
# has ...
has '_pidfile' => (
    'is'    => 'ro',
    'isa'   => 'Linux::Pidfile',
    'lazy'  => 1,
    'builder' => '_init_pidfile',
);
# with ...
# initializers ...
sub _init_pidfile {
    my $self = shift;

    my $PID = Linux::Pidfile::->new({
        'pidfile'   => $self->config()->get('Bprsync::Pidfile', { Default => '/var/run/bprsync.pid', }),
        'logger'    => $self->logger(),
    });

    return $PID;
}

# your code here ...
sub execute {
    my $self = shift;

    $self->_pidfile()->create() or die('Script already running.');

    my $concurrency = $self->config()->get( 'Sys::Bprsync::Concurrency', { Default => 1, } );

    my $BP = Sys::Bprsync::->new(
        {
            'config'      => $self->config(),
            'logger'      => $self->logger(),
            'logfile'     => $self->config()->get( 'Sys::Bprsync::Logfile', { Default => '/tmp/bprsync.log' } ),
            'concurrency' => $concurrency,
        }
    );

    my $status = $BP->run();
    $self->_pidfile()->remove();

    return $status;
}

sub abstract {
    return 'Do some syncs';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Bprsync::Cmd::Command::run - run all pending sync jobs

=head1 METHODS

=head2 execute

Run the sync.

=head2 DEMOLISH

Remove our pidfile.

=head2 abstract

Workaround

=head1 NAME

Sys::Bprsync::Cmd::Command::run - run all pending sync jobs

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
